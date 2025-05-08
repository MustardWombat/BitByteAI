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
import Combine

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

    internal let storageKey = "savedCategories"
    internal let localCategoriesKey = "Local_savedCategories"

    init() {
        // Load categories from the most recent source
        categories = loadCategories()
        selectedTopic = loadSelectedTopic() ?? categories.first
    }

    // Add a new category (default weekly goal now 1 hour)
    func addCategory(name: String, weeklyGoalMinutes: Int = 60) {
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
        let updatedCategory = categories[index]

        if let logIndex = updatedCategory.dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            updatedCategory.dailyLogs[logIndex].minutes += minutes
        } else {
            let newLog = DailyLog(date: date, minutes: minutes)
            updatedCategory.dailyLogs.append(newLog)
        }

        categories[index] = updatedCategory
    }
   

    // Updated method to update the weekly goal using the Category’s change notification
    func updateWeeklyGoal(for category: Category, newGoalMinutes: Int) {
        category.objectWillChange.send()
        category.weeklyGoalMinutes = newGoalMinutes
        saveCategories()
    }

    // MARK: - Updated Persistence for Categories

    internal func loadCategories() -> [Category] {
        if let cloudData = NSUbiquitousKeyValueStore.default.data(forKey: storageKey),
           let cloudCategories = try? JSONDecoder().decode([Category].self, from: cloudData) {
            return cloudCategories
        } else if let localData = UserDefaults.standard.data(forKey: localCategoriesKey),
                  let localCategories = try? JSONDecoder().decode([Category].self, from: localData) {
            return localCategories
        }
        return []
    }

    internal func loadCloudCategories() -> [Category] {
        if let cloudData = NSUbiquitousKeyValueStore.default.data(forKey: storageKey),
           let cloudCategories = try? JSONDecoder().decode([Category].self, from: cloudData) {
            return cloudCategories
        }
        return []
    }

    internal func mergeCategories(local: [Category], cloud: [Category]) -> [Category] {
        var merged = local
        let cloudOnly = cloud.filter { cloudCategory in
            !local.contains(where: { $0.id == cloudCategory.id })
        }
        merged.append(contentsOf: cloudOnly)
        return merged
    }

    internal func mergeWithICloudData() {
        let localCats = loadCategories()
        let cloudCats = loadCloudCategories()
        self.categories = mergeCategories(local: localCats, cloud: cloudCats)
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

    func showCategorySelection(for binding: Binding<Category?>, onComplete: @escaping () -> Void) {
        #if os(iOS)
        // iOS presentation logic
        #else
        // macOS presentation logic using sheets or popovers
        #endif
    }
}


