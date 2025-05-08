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
    
    // Duration description - modified to always return permanent
    var durationDescription: String {
        return "Permanent effect"
    }
}

// Predefined shop catalog
extension ShopItem {
    static let catalog: [ShopItem] = [
        ShopItem(name: "Satelite", 
                type: .xpBooster, 
                description: "A permanent boost to your XP gains", 
                price: 100, 
                effectValue: 1.25, 
                durationInHours: nil),
        
        ShopItem(name: "XP Boost II", 
                type: .xpBooster, 
                description: "A significant permanent boost to your XP gains", 
                price: 250, 
                effectValue: 1.5, 
                durationInHours: nil),
        
        ShopItem(name: "Coin Magnet I", 
                type: .coinBooster, 
                description: "Permanently increases the coins you earn", 
                price: 150, 
                effectValue: 1.25, 
                durationInHours: nil),
        
        ShopItem(name: "Coin Magnet II", 
                type: .coinBooster, 
                description: "Significantly and permanently increases the coins you earn", 
                price: 300, 
                effectValue: 1.5, 
                durationInHours: nil),
                
        ShopItem(name: "Deluxe Coin Boost", 
                type: .coinBooster, 
                description: "Permanently increases your coin gains", 
                price: 1000, 
                effectValue: 1.1, 
                durationInHours: nil)
    ]
}
