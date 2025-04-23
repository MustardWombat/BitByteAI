//
//  PurchasedItem.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation

struct PurchasedItem: Identifiable, Codable {
    var id: String { name }
    let name: String
    var quantity: Int
    let type: ItemType
    let effectValue: Double
    var purchaseDate: Date
    var expirationDate: Date?
    let description: String
    
    var isActive: Bool {
        if let expiration = expirationDate {
            return Date() < expiration
        }
        return true // Permanent item
    }
    
    var timeRemaining: String {
        guard let expiration = expirationDate else {
            return "Permanent"
        }
        
        let timeInterval = expiration.timeIntervalSince(Date())
        if timeInterval <= 0 {
            return "Expired"
        }
        
        let hours = Int(timeInterval / 3600)
        if hours >= 24 {
            let days = hours / 24
            return "\(days)d remaining"
        }
        return "\(hours)h remaining"
    }
}
