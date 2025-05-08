import Foundation
import SwiftUI
import Combine

// MARK: - Planet Type Enum
enum PlanetType: String, Codable, CaseIterable {
    case rare = "🌟 Rare Planet"
    case common = "🌕 Common Planet"
    case tiny = "🌑 Tiny Asteroid"
}

// MARK: - Planet Model
struct Planet: Identifiable, Codable, Equatable, Hashable { // added Hashable conformance
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
        .tiny: Planet(id: UUID(), name: "Tiny Asteroid", baseMiningTime: 60, miningReward: 5)
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
    private let availablePlanetsKey = "availablePlanets"
    private let availablePlanetsCloudKey = "availablePlanets"
    private let currentMiningPlanetCloudKey = "currentMiningPlanet"

    // MARK: - Init
    init() {
        loadAvailablePlanets() // Load persisted planets if available
        resumeMiningIfNeeded()
        fetchPlanetsFromICloud() // Fetch cloud saved planet data
    }

    // MARK: - Planet Access
    func getPlanet(ofType type: PlanetType) -> Planet? {
        planetIndex[type]
    }

    // MARK: - Start Mining
    func startMining(planet: Planet, inFocusMode: Bool) {
        guard currentMiningPlanet == nil else { return }

        var updatedPlanet = planet
        updatedPlanet.miningStartDate = Date()

        // Remove from list so we don’t show a duplicate.
        availablePlanets.removeAll { $0.id == planet.id }

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

    // MARK: - Persistence for Available Planets
    private func saveAvailablePlanets() {
        do {
            let data = try JSONEncoder().encode(availablePlanets)
            UserDefaults.standard.set(data, forKey: availablePlanetsKey)
        } catch {
            print("❌ Failed to save available planets: \(error)")
        }
    }

    private func loadAvailablePlanets() {
        guard let data = UserDefaults.standard.data(forKey: availablePlanetsKey) else { return }
        do {
            availablePlanets = try JSONDecoder().decode([Planet].self, from: data)
        } catch {
            print("❌ Failed to load available planets: \(error)")
        }
    }

    // Update available planets whenever they change
    func addPlanet(_ planet: Planet) {
        availablePlanets.append(planet)
        saveAvailablePlanets()
        savePlanetsToICloud() // Update cloud
    }

    func removePlanet(_ planet: Planet) {
        availablePlanets.removeAll { $0.id == planet.id }
        saveAvailablePlanets()
        savePlanetsToICloud() // Update cloud
    }

    // MARK: - Finish Mining
    func finishMining() {
        guard let planet = currentMiningPlanet else { return }

        print("⛏️ Finished mining \(planet.name)! Awarding \(planet.miningReward) coins.")

        // ✅ Award coins via the callback
        awardCoins?(planet.miningReward)

        clearSavedMiningState()
        savePlanetsToICloud() // Update cloud after clearing state
        resetMiningState()
    }

    private func resetMiningState() {
        miningTimer?.invalidate()
        miningTimer = nil
        currentMiningPlanet = nil
        miningStartTime = nil
        targetMiningDuration = 0
        miningProgress = 0.0
    }

    // MARK: - iCloud Sync
    func savePlanetsToICloud() {
        let store = NSUbiquitousKeyValueStore.default
        if let data = try? JSONEncoder().encode(availablePlanets) {
            store.set(data, forKey: availablePlanetsCloudKey)
        }
        if let planet = currentMiningPlanet,
           let data = try? JSONEncoder().encode(planet) {
            store.set(data, forKey: currentMiningPlanetCloudKey)
        } else {
            store.removeObject(forKey: currentMiningPlanetCloudKey)
        }
        store.synchronize()
    }

    func fetchPlanetsFromICloud() {
        let store = NSUbiquitousKeyValueStore.default
        if let data = store.data(forKey: availablePlanetsCloudKey),
           let cloudPlanets = try? JSONDecoder().decode([Planet].self, from: data) {
            // Merge by taking all unique planets
            availablePlanets = Array(Set(availablePlanets + cloudPlanets))
        }
        if let data = store.data(forKey: currentMiningPlanetCloudKey),
           let cloudPlanet = try? JSONDecoder().decode(Planet.self, from: data) {
            currentMiningPlanet = cloudPlanet
        }
    }
}
