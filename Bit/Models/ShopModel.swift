//
//  ShopModel.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation
import Combine
import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

class ShopModel: ObservableObject {
    @Published var purchasedItems: [PurchasedItem] = [] {
        didSet { saveData() }
    }
    @Published var availableItems: [ShopItem] = ShopItem.catalog
    @Published var selectedItem: ShopItem? = nil
    @Published var showPurchaseConfirmation = false
    
    private let shopKey = "PurchasedItems"
    private var timer: Timer?
    
    init() {
        loadData()
        startExpirationTimer()
        setupNotificationObservers()
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkForExpiredItems()
        }
        #elseif canImport(AppKit)
        NotificationCenter.default.addObserver(
            forName: NSApplication.willBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkForExpiredItems()
        }
        #endif
    }
    
    private func startExpirationTimer() {
        // Check for expired items every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForExpiredItems()
        }
    }
    
    private func checkForExpiredItems() {
        let currentDate = Date()
        var updated = false
        
        for (index, item) in purchasedItems.enumerated() {
            if let expiration = item.expirationDate, currentDate > expiration && item.isActive {
                // Item has expired, remove its effects
                removeItemEffects(item)
                updated = true
            }
        }
        
        if updated {
            objectWillChange.send()
        }
    }
    
    func addPurchase(item: ShopItem) {
        guard item.price > 0 else { return }
        
        let expirationDate: Date?
        if let hours = item.durationInHours {
            expirationDate = Calendar.current.date(byAdding: .hour, value: hours, to: Date())
        } else {
            expirationDate = nil // Permanent item
        }
        
        let newItem = PurchasedItem(
            name: item.name,
            quantity: 1,
            type: item.type,
            effectValue: item.effectValue,
            purchaseDate: Date(),
            expirationDate: expirationDate,
            description: item.description
        )
        
        if let existingIndex = purchasedItems.firstIndex(where: { $0.name == item.name && $0.isActive }) {
            // Update existing active item
            purchasedItems[existingIndex].quantity += 1
            
            // Update expiration date if applicable
            if let hours = item.durationInHours, let currentExpiration = purchasedItems[existingIndex].expirationDate {
                purchasedItems[existingIndex].expirationDate = Calendar.current.date(
                    byAdding: .hour,
                    value: hours,
                    to: currentExpiration
                )
            }
        } else {
            // Add as new item
            purchasedItems.append(newItem)
        }
        
        // Apply the item's effect
        applyItemEffects(newItem)
    }
    
    func applyItemEffects(_ item: PurchasedItem) {
        switch item.type {
        case .xpBooster:
            NotificationCenter.default.post(
                name: Notification.Name("ApplyXPBoost"),
                object: nil,
                userInfo: ["multiplier": item.effectValue]
            )
            
        case .coinBooster:
            NotificationCenter.default.post(
                name: Notification.Name("ApplyCoinBoost"),
                object: nil,
                userInfo: ["multiplier": item.effectValue]
            )
            
        case .timerExtender, .focusEnhancer:
            // Implement when timer system is enhanced
            break
        }
    }
    
    func removeItemEffects(_ item: PurchasedItem) {
        // Get all active items of the same type
        let activeItems = purchasedItems.filter { 
            $0.type == item.type && $0.isActive && $0.id != item.id 
        }
        
        // Calculate the new combined multiplier from remaining items
        let newMultiplier = activeItems.reduce(1.0) { result, item in
            return result * item.effectValue
        }
        
        // Apply the new multiplier
        switch item.type {
        case .xpBooster:
            NotificationCenter.default.post(
                name: Notification.Name("ResetXPBoost"),
                object: nil,
                userInfo: ["multiplier": newMultiplier]
            )
            
        case .coinBooster:
            NotificationCenter.default.post(
                name: Notification.Name("ResetCoinBoost"),
                object: nil,
                userInfo: ["multiplier": newMultiplier]
            )
            
        case .timerExtender, .focusEnhancer:
            break
        }
    }
    
    // Get active multiplier for a specific item type
    func getActiveMultiplier(for type: ItemType) -> Double {
        let activeItems = purchasedItems.filter { $0.type == type && $0.isActive }
        return activeItems.reduce(1.0) { result, item in
            return result * item.effectValue
        }
    }
    
    func getActiveItems(of type: ItemType) -> [PurchasedItem] {
        return purchasedItems.filter { $0.type == type && $0.isActive }
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(purchasedItems) {
            NSUbiquitousKeyValueStore.default.set(encoded, forKey: shopKey)
            NSUbiquitousKeyValueStore.default.synchronize()
            
            // Also save to UserDefaults as a backup
            UserDefaults.standard.set(encoded, forKey: shopKey)
        }
    }
    
    public func loadData() {
        // Try loading from iCloud first
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: shopKey),
           let items = try? JSONDecoder().decode([PurchasedItem].self, from: data) {
            purchasedItems = items
        } 
        // Fall back to UserDefaults if iCloud data not available
        else if let data = UserDefaults.standard.data(forKey: shopKey),
                let items = try? JSONDecoder().decode([PurchasedItem].self, from: data) {
            purchasedItems = items
        }
        
        // Apply active effects
        reapplyAllActiveEffects()
    }
    
    private func reapplyAllActiveEffects() {
        // Reset all multipliers first
        NotificationCenter.default.post(name: Notification.Name("ResetAllBoosts"), object: nil)
        
        // Group active items by type
        let activeXPBoosters = getActiveItems(of: .xpBooster)
        let activeCoinBoosters = getActiveItems(of: .coinBooster)
        
        // Calculate and apply XP multiplier
        let xpMultiplier = activeXPBoosters.reduce(1.0) { $0 * $1.effectValue }
        if xpMultiplier > 1.0 {
            NotificationCenter.default.post(
                name: Notification.Name("ResetXPBoost"),
                object: nil,
                userInfo: ["multiplier": xpMultiplier]
            )
        }
        
        // Calculate and apply Coin multiplier
        let coinMultiplier = activeCoinBoosters.reduce(1.0) { $0 * $1.effectValue }
        if coinMultiplier > 1.0 {
            NotificationCenter.default.post(
                name: Notification.Name("ResetCoinBoost"),
                object: nil,
                userInfo: ["multiplier": coinMultiplier]
            )
        }
    }
}
