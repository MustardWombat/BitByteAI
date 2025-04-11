import Foundation
import SwiftUI
import Combine

// MARK: - Planet Type Enum
enum PlanetType: String, Codable, CaseIterable {
    case rare = "🌟 Rare Planet"
    case common = "🌕 Common Planet"
    case tiny = "🌑 Tiny Asteroid"
    case starter = "Starter Planet"
}

// MARK: - Planet Model
struct Planet: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let baseMiningTime: Int    // in seconds
    let miningReward: Int      // coins earned when mining completes
    var miningStartDate: Date? = nil  // when mining started

    init(id: UUID = UUID(), name: String, baseMiningTime: Int, miningReward: Int, miningStartDate: Date? = nil) {
        self.id = id
        self.name = name
        self.baseMiningTime = baseMiningTime
        self.miningReward = miningReward
        self.miningStartDate = miningStartDate
    }
}

// MARK: - Mining Model
class MiningModel: ObservableObject {
    var awardCoins: ((Int) -> Void)? // Injected from CosmosAppView
    
    // MARK: - Planet Index
    private let planetIndex: [PlanetType: Planet] = [
        .rare: Planet(id: UUID(), name: "Rare Planet", baseMiningTime: 120, miningReward: 50),
        .common: Planet(id: UUID(), name: "Common Planet", baseMiningTime: 90, miningReward: 20),
        .tiny: Planet(id: UUID(), name: "Tiny Asteroid", baseMiningTime: 60, miningReward: 5),
        .starter: Planet(id: UUID(), name: "Starter Planet", baseMiningTime: 150, miningReward: 10)
    ]

    // MARK: - Published Properties
    @Published var availablePlanets: [Planet] = []
    @Published var currentMiningPlanet: Planet? = nil
    @Published var miningProgress: Double = 0.0   // 0.0 to 1.0
    @Published var speedMultiplier: Int = 1

    // MARK: - Private Properties
    private var miningTimer: Timer?
    private var miningStartTime: Date?
    private var targetMiningDuration: Int = 0

    private let savedMiningKey = "currentMiningPlanetData"
    private let savedAvailablePlanetsKey = "availablePlanetsData"

    // MARK: - Init
    init() {
        loadAvailablePlanets() // Load persisted available planets or add starter if missing
        resumeMiningIfNeeded()
    }

    // MARK: - Planet Access
    func getPlanet(ofType type: PlanetType) -> Planet? {
        return planetIndex[type]
    }

    // MARK: - Start Mining
    func startMining(planet: Planet, inFocusMode: Bool) {
        guard currentMiningPlanet == nil else { return }

        var updatedPlanet = planet
        updatedPlanet.miningStartDate = Date()

        // Remove from availablePlanets and persist the change.
        availablePlanets.removeAll { $0.id == planet.id }
        saveAvailablePlanets()

        currentMiningPlanet = updatedPlanet
        speedMultiplier = inFocusMode ? 2 : 1
        targetMiningDuration = updatedPlanet.baseMiningTime
        miningStartTime = updatedPlanet.miningStartDate
        miningProgress = 0.0

        saveCurrentMiningState()
        startMiningUITimer()
    }

    private func startMiningUITimer() {
        miningTimer?.invalidate()
        miningTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateMiningProgress()
        }
    }

    // MARK: - Update Progress
    func updateMiningProgress() {
        guard let start = miningStartTime, currentMiningPlanet != nil else { return }
        let elapsed = Date().timeIntervalSince(start) * Double(speedMultiplier)
        let progress = elapsed / Double(targetMiningDuration)
        miningProgress = min(progress, 1.0)

        if miningProgress >= 1.0 {
            finishMining()
        }
    }

    func refreshMiningProgress() {
        if currentMiningPlanet != nil {
            updateMiningProgress()
        }
    }

    // MARK: - Resume on Launch
    func resumeMiningIfNeeded() {
        restoreSavedMiningState()
    }

    func restoreSavedMiningState() {
        guard let data = UserDefaults.standard.data(forKey: savedMiningKey) else { return }
        do {
            let planet = try JSONDecoder().decode(Planet.self, from: data)
            currentMiningPlanet = planet
            miningStartTime = planet.miningStartDate
            targetMiningDuration = planet.baseMiningTime
            updateMiningProgress()
            startMiningUITimer()
        } catch {
            print("❌ Failed to load mining state: \(error)")
        }
    }

    private func saveCurrentMiningState() {
        guard let planet = currentMiningPlanet else { return }
        do {
            let data = try JSONEncoder().encode(planet)
            UserDefaults.standard.set(data, forKey: savedMiningKey)
        } catch {
            print("❌ Failed to save mining state: \(error)")
        }
    }

    private func clearSavedMiningState() {
        UserDefaults.standard.removeObject(forKey: savedMiningKey)
    }

    // MARK: - Persistence for availablePlanets
    private func saveAvailablePlanets() {
        do {
            let data = try JSONEncoder().encode(availablePlanets)
            UserDefaults.standard.set(data, forKey: savedAvailablePlanetsKey)
        } catch {
            print("❌ Failed to save available planets: \(error)")
        }
    }

    private func loadAvailablePlanets() {
        if let data = UserDefaults.standard.data(forKey: savedAvailablePlanetsKey),
           let planets = try? JSONDecoder().decode([Planet].self, from: data) {
            availablePlanets = planets
        } else if let starter = planetIndex[.starter] {
            availablePlanets = [starter]
            saveAvailablePlanets()
        }
    }

    // MARK: - Finish Mining
    func finishMining() {
        guard let planet = currentMiningPlanet else { return }

        print("⛏️ Finished mining \(planet.name)! Awarding \(planet.miningReward) coins.")

        // Award coins via the callback.
        awardCoins?(planet.miningReward)

        // Do NOT re-add the planet — it's already mined.
        clearSavedMiningState()
        resetMiningState()
    }

    // MARK: - Cancel Mining (disabled)
    func cancelMining() {
        // Disabled
    }

    private func resetMiningState() {
        miningTimer?.invalidate()
        miningTimer = nil
        currentMiningPlanet = nil
        miningStartTime = nil
        targetMiningDuration = 0
        miningProgress = 0.0
    }
}
