//
//  StarOverlay.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//
//  The "CategoriesViewModel" component is responsible for the logic
//  behind the storage of "categories" the user can create

import Foundation
import SwiftUI

private let selectedTopicKey = "selectedTopicID"

class CategoriesViewModel: ObservableObject {
    @Published var categories: [Category] = [] {
        didSet {
            saveCategories() // Save merged data to both iCloud and local
        }
    }
    
    @Published var selectedTopic: Category? {
        didSet {
            saveSelectedTopicID(selectedTopic?.id)
        }
    }

    private let storageKey = "savedCategories"
    private let localCategoriesKey = "Local_savedCategories"

    init() {
        // Load local and cloud categories then merge
        let localCats = loadLocalCategories()
        let cloudCats = loadCloudCategories()
        categories = mergeCategories(local: localCats, cloud: cloudCats)
        // Load previously selected topic (if any) after merging.
        selectedTopic = loadSelectedTopic() ?? (categories.first)
    }

    // Add a new category
    func addCategory(name: String, weeklyGoalMinutes: Int = 0) {
        let newCat = Category(name: name, weeklyGoalMinutes: weeklyGoalMinutes)
        categories.append(newCat)
    }

    // Delete a category
    func deleteCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
    }

    // Log study time for a specific category and date.
    func logStudyTime(categoryID: UUID, date: Date, minutes: Int) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }

        let calendar = Calendar.current
        var updatedCategory = categories[index]

        if let logIndex = updatedCategory.dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            updatedCategory.dailyLogs[logIndex].minutes += minutes
        } else {
            let newLog = DailyLog(date: date, minutes: minutes)
            updatedCategory.dailyLogs.append(newLog)
        }

        categories[index] = updatedCategory
    }

    // Retrieve last 7 days of data for a given category
    func weeklyData(for categoryID: UUID) -> [DailyLog] {
        guard let category = categories.first(where: { $0.id == categoryID }) else { return [] }

        let now = Date()
        let calendar = Calendar.current
        var results: [DailyLog] = []

        for offset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: -offset, to: now) {
                let dayStart = calendar.startOfDay(for: day)
                if let log = category.dailyLogs.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
                    results.append(DailyLog(date: dayStart, minutes: log.minutes))
                } else {
                    results.append(DailyLog(date: dayStart, minutes: 0))
                }
            }
        }

        return results.sorted { $0.date < $1.date }
    }

    // MARK: - Updated Persistence for Categories with Merge
    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            // Save to iCloud
            NSUbiquitousKeyValueStore.default.set(data, forKey: storageKey)
            NSUbiquitousKeyValueStore.default.synchronize()
            // Also save locally
            UserDefaults.standard.set(data, forKey: localCategoriesKey)
        } catch {
            print("Failed to save categories: \(error)")
        }
    }

    private func loadLocalCategories() -> [Category] {
        if let data = UserDefaults.standard.data(forKey: localCategoriesKey),
           let cats = try? JSONDecoder().decode([Category].self, from: data) {
            return cats
        }
        return []
    }

    private func loadCloudCategories() -> [Category] {
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: storageKey),
           let cats = try? JSONDecoder().decode([Category].self, from: data) {
            return cats
        }
        return []
    }

    private func mergeCategories(local: [Category], cloud: [Category]) -> [Category] {
        var mergedDict = [UUID: Category]()
        
        // Add all local categories.
        for cat in local {
            mergedDict[cat.id] = cat
        }
        
        // Merge cloud categories.
        for cloudCat in cloud {
            if let localCat = mergedDict[cloudCat.id] {
                // Conflict: add weeklyGoalMinutes.
                let mergedWeeklyGoal = localCat.weeklyGoalMinutes + cloudCat.weeklyGoalMinutes
                
                // Merge daily logs by summing minutes per day.
                var mergedLogsDict = [Date: Int]()
                let calendar = Calendar.current
                for log in localCat.dailyLogs {
                    let day = calendar.startOfDay(for: log.date)
                    mergedLogsDict[day, default: 0] += log.minutes
                }
                for log in cloudCat.dailyLogs {
                    let day = calendar.startOfDay(for: log.date)
                    mergedLogsDict[day, default: 0] += log.minutes
                }
                let mergedLogs = mergedLogsDict.map { DailyLog(date: $0.key, minutes: $0.value) }
                    .sorted { $0.date < $1.date }
                
                // Create merged category (keeping local name/color).
                var mergedCat = localCat
                mergedCat.weeklyGoalMinutes = mergedWeeklyGoal
                mergedCat.dailyLogs = mergedLogs
                mergedDict[cloudCat.id] = mergedCat
            } else {
                // New cloud category.
                mergedDict[cloudCat.id] = cloudCat
            }
        }
        return Array(mergedDict.values)
    }

    // MARK: - Selected Topic Persistence
    func saveSelectedTopicID(_ id: UUID?) {
        if let id = id {
            NSUbiquitousKeyValueStore.default.set(id.uuidString, forKey: selectedTopicKey)
        } else {
            NSUbiquitousKeyValueStore.default.removeObject(forKey: selectedTopicKey)
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func loadSelectedTopic() -> Category? {
        guard let savedID = NSUbiquitousKeyValueStore.default.string(forKey: selectedTopicKey),
              let uuid = UUID(uuidString: savedID) else { return nil }
        return categories.first(where: { $0.id == uuid })
    }

    // Add this function below existing methods
    func mergeWithICloudData() {
        let localCats = loadLocalCategories()
        let cloudCats = loadCloudCategories()
        self.categories = mergeCategories(local: localCats, cloud: cloudCats)
    }
}


