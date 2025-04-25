//
//  CurrencyModel.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation
import Combine

#if canImport(AppKit)
import AppKit
#endif

class CurrencyModel: ObservableObject {
    @Published var balance: Int = 0
    @Published var coinMultiplier: Double = 1.0

    private let balanceKey = "CurrencyModel.balance"

    init() {
        fetchFromICloud()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCoinBoost),
            name: Notification.Name("ApplyCoinBoost"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetCoinBoost),
            name: Notification.Name("ResetCoinBoost"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetAllBoosts),
            name: Notification.Name("ResetAllBoosts"),
            object: nil
        )
    }
    
    @objc private func handleCoinBoost(notification: Notification) {
        if let multiplier = notification.userInfo?["multiplier"] as? Double {
            coinMultiplier *= multiplier
        }
    }
    
    @objc private func resetCoinBoost(notification: Notification) {
        if let newMultiplier = notification.userInfo?["multiplier"] as? Double {
            coinMultiplier = newMultiplier
        } else {
            coinMultiplier = 1.0
        }
    }
    
    @objc private func resetAllBoosts(notification: Notification) {
        coinMultiplier = 1.0
    }

    func earn(amount: Int) {
        let boostedAmount = Int(Double(amount) * coinMultiplier)
        balance += boostedAmount
        saveToICloud()
    }

    func deposit(_ amount: Int) {
        balance += amount
        saveToICloud()
    }
    
    func canAfford(_ amount: Int) -> Bool {
        return balance >= amount
    }
    
    func spend(_ amount: Int) -> Bool {
        if balance >= amount {
            balance -= amount
            saveToICloud()
            return true
        }
        return false
    }

    // --- iCloud Sync ---
    func saveToICloud() {
        NSUbiquitousKeyValueStore.default.set(balance, forKey: balanceKey)
        NSUbiquitousKeyValueStore.default.synchronize()
        
        // Backup to UserDefaults
        UserDefaults.standard.set(balance, forKey: balanceKey)
    }

    func fetchFromICloud() {
        let store = NSUbiquitousKeyValueStore.default
        let cloudValue = store.longLong(forKey: balanceKey)
        
        // Use UserDefaults as backup
        let localValue = UserDefaults.standard.integer(forKey: balanceKey)
        
        // Use the higher value between cloud and local (prevents progress loss)
        balance = max(Int(cloudValue), localValue)
    }
}
