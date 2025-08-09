//
//  XPModel.swift
//  Cosmos
//
//  Created by James Williams on 4/1/25.
//

import Foundation
import SwiftUI
import Combine
import CloudKit

#if canImport(AppKit)
import AppKit
#endif

class XPModel: ObservableObject {
    @AppStorage("hasSubscription") private var isPro: Bool = false

    @Published var xp: Int = 0 { didSet { saveIfLoaded() } }
    @Published var level: Int = 1 { didSet { saveIfLoaded() } }
    @Published var xpForNextLevel: Int = 100 { didSet { saveIfLoaded() } }
    @Published var upgradeMultiplier: Double = 1.0

    private var isInitialLoadComplete = false
    private let xpKey = "XPModel.xp"
    private let levelKey = "XPModel.level"
    private let xpForNextLevelKey = "XPModel.xpForNextLevel"

    init() {
        loadData()
        checkForLevelUp() // Add level-up check at startup
        isInitialLoadComplete = true
        fetchFromICloud() // new: load cloud data
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleXPBoost),
            name: Notification.Name("ApplyXPBoost"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetXPBoost),
            name: Notification.Name("ResetXPBoost"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetAllBoosts),
            name: Notification.Name("ResetAllBoosts"),
            object: nil
        )
    }
    
    @objc private func handleXPBoost(notification: Notification) {
        if let multiplier = notification.userInfo?["multiplier"] as? Double {
            upgradeMultiplier *= multiplier
        }
    }
    
    @objc private func resetXPBoost(notification: Notification) {
        if let newMultiplier = notification.userInfo?["multiplier"] as? Double {
            DispatchQueue.main.async {
                self.upgradeMultiplier = newMultiplier
            }
        } else {
            DispatchQueue.main.async {
                self.upgradeMultiplier = 1.0
            }
        }
    }
    
    @objc private func resetAllBoosts(notification: Notification) {
        DispatchQueue.main.async {
            self.upgradeMultiplier = 1.0
        }
    }

    func addXP(_ amount: Int) {
        let proAmount = isPro ? amount * 2 : amount
        let boostedAmount = Int(Double(proAmount) * upgradeMultiplier)
        xp += boostedAmount
        checkForLevelUp()
    }

    // New method to check if XP exceeds requirement for level-up
    func checkForLevelUp() {
        while xp >= xpForNextLevel {
            xp -= xpForNextLevel
            level += 1
            xpForNextLevel = 100 * level * level
        }
    }

    func applyUpgrade(multiplier: Double) { upgradeMultiplier *= multiplier }
    func resetXP() {
        xp = 0; level = 1; xpForNextLevel = 100; upgradeMultiplier = 1.0
    }

    private func saveIfLoaded() {
        guard isInitialLoadComplete else { return }
        let defaults = UserDefaults.standard
        defaults.set(xp, forKey: xpKey)
        defaults.set(level, forKey: levelKey)
        defaults.set(xpForNextLevel, forKey: xpForNextLevelKey)
        saveToICloud() // new: save to cloud
    }

    func saveToICloud() {
        let store = NSUbiquitousKeyValueStore.default
        store.set(xp, forKey: xpKey)
        store.set(level, forKey: levelKey)
        store.set(xpForNextLevel, forKey: xpForNextLevelKey)
        store.synchronize()
    }

    func fetchFromICloud() {
        print("🔍 XP: Starting XP fetch from iCloud...")
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        // Try to load both level & xp from key-value store
        let cloudLevel = Int(store.longLong(forKey: levelKey))
        let cloudXP    = Int(store.longLong(forKey: xpKey))

        if cloudLevel > 0 {
            // Atomic update: recompute thresholds & overflow
            print("🔍 XP: Found cloud level \(cloudLevel), xp \(cloudXP)")
            applyCloudProgress(level: cloudLevel, xp: cloudXP)
        }
        else if let rawXP = store.object(forKey: xpKey) as? Int {
            // Fallback: only xp stored (older versions)
            print("🔍 XP: Found raw XP \(rawXP)")
            xp = max(xp, rawXP)
            checkForLevelUp()
            print("🔍 XP: After merge → level \(level), xp \(xp)/\(xpForNextLevel)")
        }
        else {
            print("🔍 XP: No XP found in key-value store")
        }

        // ...existing code for testCloudKitXPAccess...
    }

    private func testCloudKitXPAccess() {
        print("🔍 XP: Testing CloudKit XP access...")
        
        let container = CKContainer.default()
        print("🔍 XP: Using container: \(container.containerIdentifier ?? "unknown")")
        
        let privateDB = container.privateCloudDatabase
        
        // 1. Try to create a simple test record for XP
        let testXPRecord = CKRecord(recordType: "UserXP")
        testXPRecord["xpValue"] = self.xp as CKRecordValue
        testXPRecord["note"] = "Simple XP test" as CKRecordValue
        
        print("🔍 XP: Attempting to save XP record with value: \(self.xp)")
        
        privateDB.save(testXPRecord) { record, error in
            if let error = error {
                print("🔍 XP: CloudKit save error: \(error.localizedDescription)")
                if let ckError = error as? CKError {
                    print("🔍 XP: CKError code: \(ckError.errorCode)")
                    
                    // Print more specific error details
                    switch ckError.errorCode {
                    case CKError.serverRejectedRequest.rawValue:
                        print("🔍 XP: Server rejected request - check your schema")
                    case CKError.notAuthenticated.rawValue:
                        print("🔍 XP: Not authenticated - check iCloud login")
                    case CKError.zoneNotFound.rawValue:
                        print("🔍 XP: Zone not found - check zone configuration")
                    case CKError.permissionFailure.rawValue:
                        print("🔍 XP: Permission failure - check entitlements")
                    case CKError.networkUnavailable.rawValue:
                        print("🔍 XP: Network unavailable - check connectivity")
                    default:
                        print("🔍 XP: Other error code: \(ckError.errorCode)")
                    }
                }
            } else {
                print("🔍 XP: Successfully saved XP record to CloudKit!")
                
                // Try to fetch it back immediately
                privateDB.fetch(withRecordID: testXPRecord.recordID) { fetchedRecord, error in
                    if let error = error {
                        print("🔍 XP: Error fetching XP record: \(error.localizedDescription)")
                    } else if let record = fetchedRecord,
                              let xpValue = record["xpValue"] as? Int {
                        print("🔍 XP: Successfully fetched XP value: \(xpValue)")
                        
                        // Clean up the test record
                        privateDB.delete(withRecordID: record.recordID) { _, error in
                            if let error = error {
                                print("🔍 XP: Error cleaning up XP record: \(error.localizedDescription)")
                            } else {
                                print("🔍 XP: Successfully deleted test XP record")
                            }
                        }
                    }
                }
            }
        }
    }

    func loadData() {
        let defaults = UserDefaults.standard
        xp = defaults.integer(forKey: xpKey)
        level = max(1, defaults.integer(forKey: levelKey)) // Ensure level is at least 1
        xpForNextLevel = defaults.integer(forKey: xpForNextLevelKey) > 0 ? defaults.integer(forKey: xpForNextLevelKey) : 100
    }
}

extension XPModel {
    /// Atomically apply loaded level & xp, looping until xp < threshold
    func applyCloudProgress(level: Int, xp: Int) {
        // Prevent intermediate saves/UI glitches
        isInitialLoadComplete = false

        // Local vars to compute without side-effects
        var newLevel = level
        var remainingXP = xp
        var threshold = 100 * newLevel * newLevel

        // Loop until remainingXP is less than the next-level threshold
        while remainingXP >= threshold {
            remainingXP -= threshold
            newLevel += 1
            threshold = 100 * newLevel * newLevel
        }

        // Commit all at once
        self.level = newLevel
        self.xp = remainingXP
        self.xpForNextLevel = threshold

        // Resume normal saving
        isInitialLoadComplete = true
    }
}

struct XPDisplayView: View {
    @EnvironmentObject var xpModel: XPModel

    var body: some View {
        HStack(spacing: 10) { // Horizontal layout for the text and vertical bar
            // Level and XP text
            VStack(alignment: .trailing, spacing: 4) { // Align text to the right
                Text("Level \(xpModel.level)")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(xpModel.xp) / \(xpModel.xpForNextLevel) XP")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1) // Ensure text fits within the view
                    .minimumScaleFactor(0.8) // Scale down text if needed
            }

            // Vertical XP bar
            ZStack(alignment: .bottom) {
                // Background bar
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 10, height: 50) // Fixed height for the bar
                    .foregroundColor(Color.gray.opacity(0.3))

                // Foreground progress bar
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 10, height: 50 * CGFloat(xpModel.xp) / CGFloat(xpModel.xpForNextLevel)) // Dynamic height
                    .foregroundColor(Color.blue)
            }
        }
        .padding(8) // Add padding for better spacing
        .cornerRadius(8) // Rounded corners for a polished look
    }
}

