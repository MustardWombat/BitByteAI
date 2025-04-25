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
