//
//  XPModel.swift
//  Cosmos
//
//  Created by James Williams on 4/1/25.
//

import Foundation
import SwiftUI
import Combine

#if canImport(AppKit)
import AppKit
#endif

class XPModel: ObservableObject {
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
            upgradeMultiplier = newMultiplier
        } else {
            upgradeMultiplier = 1.0
        }
    }
    
    @objc private func resetAllBoosts(notification: Notification) {
        upgradeMultiplier = 1.0
    }

    func addXP(_ amount: Int) {
        let boostedAmount = Int(Double(amount) * upgradeMultiplier)
        xp += boostedAmount
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
        let store = NSUbiquitousKeyValueStore.default
        let cloudXP = store.object(forKey: xpKey) as? Int ?? 0
        let cloudLevel = max(1, store.object(forKey: levelKey) as? Int ?? 1)
        let cloudXPForNext = store.object(forKey: xpForNextLevelKey) as? Int ?? 0
        
        // Merge local and cloud values by taking the higher ones
        let mergedXP = max(xp, cloudXP)
        let mergedLevel = max(level, cloudLevel)
        let mergedXPForNext = max(xpForNextLevel, cloudXPForNext)
        
        xp = mergedXP
        level = mergedLevel
        xpForNextLevel = mergedXPForNext
        
        // Write back the merged values to both iCloud and local storage
        saveToICloud()
        let defaults = UserDefaults.standard
        defaults.set(mergedXP, forKey: xpKey)
        defaults.set(mergedLevel, forKey: levelKey)
        defaults.set(mergedXPForNext, forKey: xpForNextLevelKey)
    }

    func loadData() {
        let defaults = UserDefaults.standard
        xp = defaults.integer(forKey: xpKey)
        level = max(1, defaults.integer(forKey: levelKey)) // Ensure level is at least 1
        xpForNextLevel = defaults.integer(forKey: xpForNextLevelKey) > 0 ? defaults.integer(forKey: xpForNextLevelKey) : 100
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
