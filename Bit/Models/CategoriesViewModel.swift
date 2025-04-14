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
            saveCategories()
        }
    }

    private let storageKey = "savedCategories"

    init() {
        loadCategories()
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
        // Force an update notification for deep changes.
        categories[index].objectWillChange.send()
        
        if let logIndex = categories[index].dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            categories[index].dailyLogs[logIndex].minutes += minutes
        } else {
            let newLog = DailyLog(date: date, minutes: minutes)
            categories[index].dailyLogs.append(newLog)
        }
        
        // Optionally, reassign the array element to trigger updates.
        categories[index] = categories[index]
    }

    // Retrieve last 7 days of data for a given category
    func weeklyData(for categoryID: UUID) -> [DailyLog] {
        guard let category = categories.first(where: { $0.id == categoryID }) else {
            print("DEBUG: weeklyData - No category found for id \(categoryID)")
            return []
        }
        
        let now = Date()
        let calendar = Calendar.current
        var results: [DailyLog] = []
        
        for offset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: -offset, to: now) {
                let dayStart = calendar.startOfDay(for: day)
                if let log = category.dailyLogs.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
                    print("DEBUG: weeklyData - Found log for \(dayStart): \(log.minutes) minutes")
                    results.append(DailyLog(date: dayStart, minutes: log.minutes))
                } else {
                    print("DEBUG: weeklyData - No log for \(dayStart), inserting 0 minutes")
                    results.append(DailyLog(date: dayStart, minutes: 0))
                }
            }
        }
        
        let sortedResults = results.sorted { $0.date < $1.date }
        print("DEBUG: weeklyData - Final sorted logs: \(sortedResults)")
        return sortedResults
    }

    // MARK: - Selected Topic Persistence
    func saveSelectedTopicID(_ id: UUID?) {
        if let id = id {
            UserDefaults.standard.set(id.uuidString, forKey: selectedTopicKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedTopicKey)
        }
    }

    func loadSelectedTopic() -> Category? {
        guard let savedID = UserDefaults.standard.string(forKey: selectedTopicKey),
              let uuid = UUID(uuidString: savedID) else { return nil }

        return categories.first(where: { $0.id == uuid })
    }

    // MARK: - Category Persistence
    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save categories: \(error)")
        }
    }

    private func loadCategories() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            categories = try JSONDecoder().decode([Category].self, from: data)
        } catch {
            print("Failed to load categories: \(error)")
        }
    }
}

struct CategorySelectionSheet: View {
    let categories: [Category]
    @Binding var selected: Category?
    @Binding var isPresented: Bool
    @State private var newTopicName: String = ""
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: Category?
    
    // New closure to be called when a category is selected.
    var onCategorySelected: (Category) -> Void
    
    var onAddCategory: (String) -> Void
    var onDeleteCategory: (Category) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    Button(action: {
                        selected = category
                        onCategorySelected(category) // persist the selection!
                        isPresented = false
                    }) {
                        HStack {
                            Circle()
                                .fill(category.displayColor)
                                .frame(width: 12, height: 12)
                            Text(category.name)
                            Spacer()
                            if selected?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .simultaneousGesture(LongPressGesture().onEnded { _ in
                        categoryToDelete = category
                        showDeleteAlert = true
                    })
                }

                // New Topic Entry
                HStack {
                    TextField("New Topic", text: $newTopicName)
                    Button("Add") {
                        let trimmed = newTopicName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onAddCategory(trimmed)
                        newTopicName = ""
                        isPresented = false
                    }
                    .disabled(newTopicName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationBarTitle("Choose Topic", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Topic"),
                    message: Text("Are you sure you want to delete '\(categoryToDelete?.name ?? "")'?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let category = categoryToDelete {
                            onDeleteCategory(category)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
