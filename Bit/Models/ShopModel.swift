//
//  ShopModel.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation
import Combine

class ShopModel: ObservableObject {
    @Published var purchasedItems: [PurchasedItem] = [] {
        didSet { saveData() }
    }
    private let shopKey = "PurchasedItems"
    
    init() {
        loadData()
    }
    
    func addPurchase(item: ShopItem) {
        if let index = purchasedItems.firstIndex(where: { $0.name == item.name }) {
            purchasedItems[index].quantity += 1
        } else {
            let newItem = PurchasedItem(name: item.name, quantity: 1)
            purchasedItems.append(newItem)
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(purchasedItems) {
            NSUbiquitousKeyValueStore.default.set(encoded, forKey: shopKey)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    private func loadData() {
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: shopKey),
           let items = try? JSONDecoder().decode([PurchasedItem].self, from: data) {
            purchasedItems = items
        }
    }
}
