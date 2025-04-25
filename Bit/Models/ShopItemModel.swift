//
//  ShopItem.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation

struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Int
}
