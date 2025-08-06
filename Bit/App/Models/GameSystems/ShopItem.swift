import Foundation

struct ShopItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: ItemType
    let description: String
    let price: Int
    let effectValue: Double // Multiplier or bonus amount
    let durationInHours: Int? // nil means permanent
    let level: Int // New: upgrade level
    let basePrice: Int // New: base price for cost calculation
    
    // New: Cookie Clicker style naming
    var displayName: String {
        switch type {
        case .xpBooster:
            return getXPBoosterName(level: level)
        case .coinBooster:
            return getCoinBoosterName(level: level)
        case .timerExtender:
            return getTimerExtenderName(level: level)
        case .focusEnhancer:
            return getFocusEnhancerName(level: level)
        }
    }
    
    // Computed property to get a user-friendly description of the effect
    var effectDescription: String {
        let percentIncrease = Int((effectValue - 1.0) * 100)
        switch type {
        case .xpBooster:
            return "+\(percentIncrease)% XP per study session"
        case .coinBooster:
            return "+\(percentIncrease)% coins per completion"
        case .timerExtender:
            return "+\(percentIncrease)% session duration"
        case .focusEnhancer:
            return "+\(percentIncrease)% focus efficiency"
        }
    }
    
    var durationDescription: String {
        return "Permanent upgrade"
    }
    
    // Cookie Clicker style upgrade names
    private func getXPBoosterName(level: Int) -> String {
        let names = ["Study Buddy", "Knowledge Crystal", "Wisdom Orb", "Scholar's Crown", "Enlightenment Beacon", 
                    "Master's Tome", "Sage's Staff", "Academic Throne", "University of Mind", "Omniscience Core"]
        return level <= names.count ? names[level - 1] : "Transcendent Mind Lv.\(level - names.count)"
    }
    
    private func getCoinBoosterName(level: Int) -> String {
        let names = ["Piggy Bank", "Coin Magnet", "Money Tree", "Golden Goose", "Treasure Chest",
                    "Midas Touch", "Fortune Fountain", "Wealth Palace", "Economic Empire", "Infinite Mint"]
        return level <= names.count ? names[level - 1] : "Cosmic Wealth Lv.\(level - names.count)"
    }
    
    private func getTimerExtenderName(level: Int) -> String {
        let names = ["Pocket Watch", "Time Crystal", "Chronometer", "Temporal Lens", "Duration Engine",
                    "Time Dilation Field", "Temporal Mastery", "Chronos Throne", "Time Empire", "Eternal Clockwork"]
        return level <= names.count ? names[level - 1] : "Time Lord Lv.\(level - names.count)"
    }
    
    private func getFocusEnhancerName(level: Int) -> String {
        let names = ["Focus Ring", "Clarity Gem", "Meditation Stone", "Concentration Crown", "Mindfulness Core",
                    "Zen Master", "Mental Fortress", "Consciousness Throne", "Awareness Empire", "Enlightened Mind"]
        return level <= names.count ? names[level - 1] : "Mental Deity Lv.\(level - names.count)"
    }
}

// Cookie Clicker style upgrade generation
extension ShopItem {
    // Generate next upgrade for a specific type based on current ownership
    static func nextUpgrade(for type: ItemType, currentLevel: Int) -> ShopItem {
        let nextLevel = currentLevel + 1
        let basePrice = getBasePrice(for: type)
        let scaledPrice = calculatePrice(basePrice: basePrice, level: nextLevel)
        let effectValue = calculateEffectValue(for: type, level: nextLevel)
        
        return ShopItem(
            name: "", // Will use displayName
            type: type,
            description: getDescription(for: type, level: nextLevel),
            price: scaledPrice,
            effectValue: effectValue,
            durationInHours: nil,
            level: nextLevel,
            basePrice: basePrice
        )
    }
    
    private static func getBasePrice(for type: ItemType) -> Int {
        switch type {
        case .xpBooster: return 15
        case .coinBooster: return 100
        case .timerExtender: return 500
        case .focusEnhancer: return 1200
        }
    }
    
    // Cookie Clicker exponential pricing: price = basePrice * (1.15^level)
    private static func calculatePrice(basePrice: Int, level: Int) -> Int {
        return Int(Double(basePrice) * pow(1.15, Double(level)))
    }
    
    // Diminishing returns: each level provides less benefit
    private static func calculateEffectValue(for type: ItemType, level: Int) -> Double {
        switch type {
        case .xpBooster:
            // Each level: +1% base, but diminishing
            return 1.0 + (0.01 * Double(level) * pow(0.98, Double(level - 1)))
        case .coinBooster:
            // Each level: +2% base, but diminishing
            return 1.0 + (0.02 * Double(level) * pow(0.97, Double(level - 1)))
        case .timerExtender:
            // Each level: +5% base, but diminishing
            return 1.0 + (0.05 * Double(level) * pow(0.95, Double(level - 1)))
        case .focusEnhancer:
            // Each level: +3% base, but diminishing
            return 1.0 + (0.03 * Double(level) * pow(0.96, Double(level - 1)))
        }
    }
    
    private static func getDescription(for type: ItemType, level: Int) -> String {
        switch type {
        case .xpBooster:
            return "Enhances your learning ability and knowledge retention"
        case .coinBooster:
            return "Increases the rewards from your productive activities"
        case .timerExtender:
            return "Extends your focus sessions for deeper work"
        case .focusEnhancer:
            return "Improves your concentration and mental clarity"
        }
    }
    
    // Legacy catalog for backward compatibility (now empty as we generate dynamically)
    static let catalog: [ShopItem] = []
}
