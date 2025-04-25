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
}
