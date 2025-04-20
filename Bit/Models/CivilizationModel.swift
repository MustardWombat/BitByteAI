//
//  Untitled.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import Foundation
import Combine

class CivilizationModel: ObservableObject {
    @Published var population: Int = 100
    @Published var resources: Int = 50
    
    // Keys for persistent storage
    private let simulationKey = "CivilizationSimulationData"
    private let lastUpdateKey = "CivilizationLastUpdate"
    
    // How often the simulation runs when the app is active (in seconds)
    private let cycleInterval: TimeInterval = 5
    
    init() {
        loadData()
        // When initializing, update the model using the elapsed time.
        updateFromBackground()
    }
    
    /// Called periodically when the app is running.
    func simulate() {
        simulateCycle()
        saveData()
        updateLastUpdate()
    }
    
    /// Simulates one cycle of population and resource increase.
    private func simulateCycle() {
        // Random increase, adjust the range as desired.
        population += Int.random(in: 1...10)
        resources += Int.random(in: 5...15)
    }
    
    /// Update the simulation based on the time elapsed since the last update.
    func updateFromBackground() {
        let now = Date()
        let lastUpdate = NSUbiquitousKeyValueStore.default.object(forKey: lastUpdateKey) as? Date ?? now
        let elapsedSeconds = now.timeIntervalSince(lastUpdate)
        
        // Determine the number of cycles that should have occurred.
        let cycles = Int(elapsedSeconds / cycleInterval)
        
        // Prevent adding values if no cycles have passed.
        guard cycles > 0 else { return }
        
        // Run simulation cycles to "catch up"
        for _ in 0..<cycles {
            simulateCycle()
        }
        
        saveData()
        updateLastUpdate()
    }
    
    private func updateLastUpdate() {
        NSUbiquitousKeyValueStore.default.set(Date(), forKey: lastUpdateKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private func saveData() {
        let data: [String: Int] = [
            "population": population,
            "resources": resources
        ]
        NSUbiquitousKeyValueStore.default.set(data, forKey: simulationKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private func loadData() {
        if let data = NSUbiquitousKeyValueStore.default.dictionary(forKey: simulationKey) as? [String: Int] {
            population = data["population"] ?? 100
            resources = data["resources"] ?? 50
        }
    }
}
