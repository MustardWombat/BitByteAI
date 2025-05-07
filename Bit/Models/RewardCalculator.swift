import Foundation

class RewardCalculator {
    static func calculateReward(using seconds: Int, miningModel: MiningModel?) -> PlanetType {
        var planetType: PlanetType
        if seconds >= 1800 {
            planetType = .rare      // 30+ minutes gets a rare planet
        } else if seconds >= 900 {
            planetType = .common    // 15-30 minutes gets a common planet
        } else {
            planetType = .tiny      // 5-15 minutes gets a tiny asteroid
        }
        
        if let planet = miningModel?.getPlanet(ofType: planetType) {
            miningModel?.availablePlanets.append(planet)
            // Removed the savePlanets call since we don't save planets anymore
            print("Added planet: \(planet.name)")
        }
        
        return planetType
    }
    
    // New method to calculate coin rewards based on study time
    static func calculateCoinReward(using seconds: Int) -> Int {
        let minutes = Double(seconds) / 60.0
        
        // Enhanced reward system (since rewards are permanent):
        // - Short sessions: 2 coins per minute
        // - Medium sessions: 3 coins per minute
        // - Long sessions: 4 coins per minute
        if seconds >= 1800 { // 30+ minutes
            return Int(minutes * 4.0)
        } else if seconds >= 900 { // 15-30 minutes
            return Int(minutes * 3.0)
        } else {
            return Int(minutes * 2.0)
        }
    }
}
