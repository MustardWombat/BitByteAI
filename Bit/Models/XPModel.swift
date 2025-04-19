//
//  XPModel.swift
//  Cosmos
//
//  Created by James Williams on 4/1/25.
//

import Foundation
import SwiftUI
import Combine

class XPModel: ObservableObject {
    @Published var xp: Int = 0 { didSet { saveIfLoaded() } }
    @Published var level: Int = 1 { didSet { saveIfLoaded() } }
    @Published var xpForNextLevel: Int = 100 { didSet { saveIfLoaded() } }
    @Published var upgradeMultiplier: Double = 1.0
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false

    private var isInitialLoadComplete = false
    private let xpKey = "XPModel.xp"
    private let levelKey = "XPModel.level"
    private let xpForNextLevelKey = "XPModel.xpForNextLevel"
    private let localXPKey = "Local_XPModelData" // new key for local save

    init() {
        loadLocalData()
        if isSignedIn { loadCloudDataAndMerge() }
        isInitialLoadComplete = true
    }

    func addXP(_ amount: Int) {
        xp += Int(Double(amount) * upgradeMultiplier)
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
        // Always save locally:
        let localData: [String: Int] = [
            "xp": xp,
            "level": level,
            "xpForNextLevel": xpForNextLevel
        ]
        UserDefaults.standard.set(localData, forKey: localXPKey)
        // And if signed in, also use iCloud
        guard isInitialLoadComplete && isSignedIn else { return }
        let store = NSUbiquitousKeyValueStore.default
        store.set(xp, forKey: xpKey)
        store.set(level, forKey: levelKey)
        store.set(xpForNextLevel, forKey: xpForNextLevelKey)
        store.synchronize()
    }

    private func loadLocalData() {
        if let localData = UserDefaults.standard.dictionary(forKey: localXPKey) as? [String: Int] {
            xp = localData["xp"] ?? 0
            level = max(1, localData["level"] ?? 1)
            xpForNextLevel = localData["xpForNextLevel"] ?? 100
        }
    }

    private func loadCloudDataAndMerge() {
        let store = NSUbiquitousKeyValueStore.default
        let cloudXP = Int(store.longLong(forKey: xpKey))
        let cloudLevel = max(1, Int(store.longLong(forKey: levelKey)))
        let cloudNext = Int(store.longLong(forKey: xpForNextLevelKey))
        // Merge by choosing the higher value.
        xp = max(xp, cloudXP)
        level = max(level, cloudLevel)
        xpForNextLevel = max(xpForNextLevel, cloudNext)
        // Also update local storage.
        let merged: [String: Int] = [
            "xp": xp,
            "level": level,
            "xpForNextLevel": xpForNextLevel
        ]
        UserDefaults.standard.set(merged, forKey: localXPKey)
    }
}

struct XPDisplayView: View {
    @EnvironmentObject var xpModel: XPModel

    var body: some View {
        HStack(spacing: 10) { // Horizontal layout for the vertical bar and text
            // Vertical XP bar
            ZStack(alignment: .bottom) {
                // Background bar
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 5, height: 50) // Adjusted size for compactness
                    .foregroundColor(Color.gray.opacity(0.3))

                // Foreground progress bar
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 5, height: 50 * CGFloat(xpModel.xp) / CGFloat(xpModel.xpForNextLevel)) // Corrected dynamic height
                    .foregroundColor(Color.blue)
            }

            // Level and XP text
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(xpModel.level)")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(xpModel.xp) / \(xpModel.xpForNextLevel) XP")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1) // Ensure text fits within the view
                    .minimumScaleFactor(0.8) // Scale down text if needed
            }
        }
        .padding(8) // Add padding for better spacing
        .cornerRadius(8) // Rounded corners for a polished look
    }
}
