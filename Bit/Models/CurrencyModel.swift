//
//  CurrencyModel.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation
import Combine

class CurrencyModel: ObservableObject {
    @Published var balance: Int = 0

    private let balanceKey = "CurrencyModel.balance"

    init() {
        fetchFromICloud()
    }

    func earn(amount: Int) {
        balance += amount
        saveToICloud()
    }

    func deposit(_ amount: Int) {
        balance += amount
        saveToICloud()
    }

    // --- iCloud Sync ---
    func saveToICloud() {
        NSUbiquitousKeyValueStore.default.set(balance, forKey: balanceKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func fetchFromICloud() {
        let store = NSUbiquitousKeyValueStore.default
        balance = store.longLong(forKey: balanceKey) as? Int ?? 0
    }
}
