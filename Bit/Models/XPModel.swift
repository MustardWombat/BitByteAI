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
    @Published var xp: Int = 0 {
        didSet { saveData() }
    }

    @Published var level: Int = 1 {
        didSet { saveData() }
    }

    @Published var xpForNextLevel: Int = 100 {
        didSet { saveData() }
    }

    @Published var upgradeMultiplier: Double = 1.0  // Optional: Persist if needed

    // MARK: - Persistence Keys
    private let xpKey = "XPModel.xp"
    private let levelKey = "XPModel.level"
    private let xpForNextLevelKey = "XPModel.xpForNextLevel"

    // MARK: - Init
    init() {
        loadData()
        checkForLevelUp() // Ensure saved XP promotes level if needed
    }

    // MARK: - Add XP
    func addXP(_ amount: Int) {
        let effectiveXP = Int(Double(amount) * upgradeMultiplier)
        xp += effectiveXP
        print("Current XP:", xp)
        checkForLevelUp()
    }

    // MARK: - Level Up Check
    private func checkForLevelUp() {
        while xp >= xpForNextLevel {
            xp -= xpForNextLevel
            level += 1
            xpForNextLevel = calculateXPForNextLevel(for: level)
            print("Leveled up! New level: \(level)")
        }
    }

    // MARK: - XP Formula
    private func calculateXPForNextLevel(for level: Int) -> Int {
        return 100 * level * level
    }

    // MARK: - Upgrade Handling
    func applyUpgrade(multiplier: Double) {
        upgradeMultiplier *= multiplier
    }

    // MARK: - Reset XP
    func resetXP() {
        xp = 0
        level = 1
        xpForNextLevel = calculateXPForNextLevel(for: level)
        upgradeMultiplier = 1.0
    }

    // MARK: - Persistence
    private func saveData() {
        let defaults = UserDefaults.standard
        defaults.set(xp, forKey: xpKey)
        defaults.set(level, forKey: levelKey)
        defaults.set(xpForNextLevel, forKey: xpForNextLevelKey)
    }

    private func loadData() {
        let defaults = UserDefaults.standard

        if let savedXP = defaults.object(forKey: xpKey) as? Int {
            xp = savedXP
        }
        
        if let savedLevel = defaults.object(forKey: levelKey) as? Int {
            level = savedLevel
        } else {
            level = 1
        }
        
        if let savedXPForNextLevel = defaults.object(forKey: xpForNextLevelKey) as? Int {
            xpForNextLevel = savedXPForNextLevel
        } else {
            xpForNextLevel = calculateXPForNextLevel(for: level)
        }
    }
}

struct XPDisplayView: View {
    @EnvironmentObject var xpModel: XPModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Level: \(xpModel.level)")
                .foregroundColor(.white)
            ProgressView(value: Double(xpModel.xp), total: Double(xpModel.xpForNextLevel))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            Text("\(xpModel.xp) / \(xpModel.xpForNextLevel) XP")
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}
