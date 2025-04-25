import Foundation

struct ShopItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: ItemType
    let description: String
    let price: Int
    let effectValue: Double // Multiplier or bonus amount
    let durationInHours: Int? // nil means permanent
    
    // Computed property to get a user-friendly description of the effect
    var effectDescription: String {
        switch type {
        case .xpBooster:
            return "Increases XP earned by \(Int(effectValue * 100) - 100)%"
        case .coinBooster:
            return "Increases coins earned by \(Int(effectValue * 100) - 100)%"
        case .timerExtender:
            return "Extends timer duration by \(Int(effectValue * 100) - 100)%"
        case .focusEnhancer:
            return "Reduces focus check frequency by \(Int(effectValue * 100) - 100)%"
        }
    }
    
    // Duration description
    var durationDescription: String {
        guard let hours = durationInHours else {
            return "Permanent effect"
        }
        if hours >= 24 {
            let days = hours / 24
            return "\(days) day\(days > 1 ? "s" : "")"
        }
        return "\(hours) hour\(hours > 1 ? "s" : "")"
    }
}

// Predefined shop catalog
extension ShopItem {
    static let catalog: [ShopItem] = [
        ShopItem(name: "XP Boost I", 
                type: .xpBooster, 
                description: "A small boost to your XP gains", 
                price: 100, 
                effectValue: 1.25, 
                durationInHours: 24),
        
        ShopItem(name: "XP Boost II", 
                type: .xpBooster, 
                description: "A significant boost to your XP gains", 
                price: 250, 
                effectValue: 1.5, 
                durationInHours: 24),
        
        ShopItem(name: "Coin Magnet I", 
                type: .coinBooster, 
                description: "Increases the coins you earn", 
                price: 150, 
                effectValue: 1.25, 
                durationInHours: 24),
        
        ShopItem(name: "Coin Magnet II", 
                type: .coinBooster, 
                description: "Significantly increases the coins you earn", 
                price: 300, 
                effectValue: 1.5, 
                durationInHours: 24),
                
        ShopItem(name: "Permanent XP Boost", 
                type: .xpBooster, 
                description: "Permanently increases your XP gains", 
                price: 1000, 
                effectValue: 1.1, 
                durationInHours: nil),
                
        ShopItem(name: "Permanent Coin Boost", 
                type: .coinBooster, 
                description: "Permanently increases your coin gains", 
                price: 1000, 
                effectValue: 1.1, 
                durationInHours: nil)
    ]
}
