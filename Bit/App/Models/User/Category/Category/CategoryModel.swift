//
//  Category.swift
//  Cosmos
//
//  Created by James Williams on 3/25/25.
//

import SwiftUI
import Foundation

class Category: ObservableObject, Identifiable, Codable, Hashable {
    var id: UUID
    @Published var name: String
    @Published var weeklyGoalMinutes: Int     // How many minutes per week the user aims for
    @Published var dailyLogs: [DailyLog]        // Each day’s study minutes
    var colorHex: String                        // A persistent color stored as a hex string

    init(name: String, weeklyGoalMinutes: Int = 60, colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.weeklyGoalMinutes = weeklyGoalMinutes
        self.dailyLogs = []
        self.colorHex = colorHex ?? Category.randomColorHex()
    }

    // MARK: - Codable
    enum CodingKeys: CodingKey {
        case id, name, weeklyGoalMinutes, dailyLogs, colorHex
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        weeklyGoalMinutes = try container.decode(Int.self, forKey: .weeklyGoalMinutes)
        dailyLogs = try container.decode([DailyLog].self, forKey: .dailyLogs)
        colorHex = try container.decode(String.self, forKey: .colorHex)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(weeklyGoalMinutes, forKey: .weeklyGoalMinutes)
        try container.encode(dailyLogs, forKey: .dailyLogs)
        try container.encode(colorHex, forKey: .colorHex)
    }

    // MARK: - Computed properties
    var displayColor: Color {
        Color(hex: colorHex)
    }
    
    var weeklyLogs: [DailyLog] {
        let calendar = Calendar.current
        let now = Date()
        var results: [DailyLog] = []
        
        // Find the most recent Sunday (or configured first day of week)
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - calendar.firstWeekday
        
        // Get the start of the week (Sunday in US calendar)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            return []
        }
        
        // Create array for the full week (Sun-Sat)
        for dayOffset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                let dayStart = calendar.startOfDay(for: day)
                if let log = dailyLogs.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
                    results.append(DailyLog(date: dayStart, minutes: log.minutes))
                } else {
                    results.append(DailyLog(date: dayStart, minutes: 0))
                }
            }
        }
        return results.sorted { $0.date < $1.date }
    }
    
    // MARK: - Helper
    static func randomColorHex() -> String {
        let colors = ["#FF6B6B", "#6BCB77", "#4D96FF", "#FFD93D", "#F97316", "#A78BFA"]
        return colors.randomElement() ?? "#FFFFFF"
    }
    
    // For Hashable conformance
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// A simple extension to create a Color from a hex string.
extension Color {
    init(hex: String) {
        // Trim the hash if present
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b: UInt64
        if hexString.count == 6 {
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        } else {
            r = 255
            g = 255
            b = 255
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// A simple struct for logging minutes studied on a given date.
struct DailyLog: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var minutes: Int
}

// Function to update daily logs for a category
func updateDailyLogs(for categories: [Category], categoryID: UUID, date: Date, minutes: Int) {
    guard let category = categories.first(where: { $0.id == categoryID }) else { return }
    let calendar = Calendar.current

    // Force an update notification for deep changes.
    category.objectWillChange.send()

    if let logIndex = category.dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
        category.dailyLogs[logIndex].minutes += minutes
    } else {
        let newLog = DailyLog(date: date, minutes: minutes)
        category.dailyLogs.append(newLog)
    }
}

struct CategorySelectionSheet: View {
    let categories: [Category]
    @Binding var selected: Category?
    @Binding var isPresented: Bool
    var onAddCategory: (String, Int) -> Void
    var onDeleteCategory: (Category) -> Void

    @State private var isShowingCreateTopicView = false
    @State private var newCategoryName = ""
    @State private var weeklyGoalHours: Int = 1
    @State private var weeklyGoalMinutes: Int = 0
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: Category? = nil

    var body: some View {
        ZStack {
            NavigationView {
                List {
                    Button(action: {
                        withAnimation(.spring()) {
                            isShowingCreateTopicView = true
                        }
                    }) {
                        Label("Add New Topic", systemImage: "plus.circle")
                            .foregroundColor(.blue)
                    }

                    ForEach(categories) { category in
                        Button(action: {
                            selected = category
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
                            .contentShape(Rectangle()) // Makes the entire row tappable
                        }
                        .simultaneousGesture(LongPressGesture().onEnded { _ in
                            categoryToDelete = category
                            showDeleteAlert = true
                        })
                    }
                }
                .navigationTitle("Choose Topic")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
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

            if isShowingCreateTopicView {
                CreateNewTopicView(
                    newCategoryName: $newCategoryName,
                    weeklyGoalHours: $weeklyGoalHours,
                    weeklyGoalMinutes: $weeklyGoalMinutes,
                    onCreate: { name, totalMinutes in
                        onAddCategory(name, totalMinutes)
                        newCategoryName = ""
                        weeklyGoalHours = 1
                        weeklyGoalMinutes = 0
                        withAnimation(.spring()) {
                            isShowingCreateTopicView = false
                        }
                    },
                    onCancel: {
                        withAnimation(.spring()) {
                            isShowingCreateTopicView = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                )) // Apply consistent animation
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 2)
                        .shadow(radius: 10)
                )
                .padding()
                .zIndex(1)
            }
        }
        .background(Color.gray)
    }
}

// Custom view for creating a new topic
struct CreateNewTopicView: View {
    @Binding var newCategoryName: String
    @Binding var weeklyGoalHours: Int
    @Binding var weeklyGoalMinutes: Int
    var onCreate: (String, Int) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Topic")
                .font(.headline)
            TextField("Topic Name", text: $newCategoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Combined picker for hours and minutes
            HStack {
                Picker("Hours", selection: $weeklyGoalHours) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour) hr").tag(hour)
                    }
                }
                #if os(iOS)
                .pickerStyle(WheelPickerStyle())
                #endif
                .frame(maxWidth: .infinity)

                Picker("Minutes", selection: $weeklyGoalMinutes) {
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
#if os(iOS)
.pickerStyle(WheelPickerStyle())
#endif
                .frame(maxWidth: .infinity)
            }
            .frame(height: 150) // Adjust height for the wheel pickers

            HStack {
                Button("Create") {
                    let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
                    let totalMinutes = weeklyGoalHours * 60 + weeklyGoalMinutes
                    guard !trimmedName.isEmpty else { return }
                    onCreate(trimmedName, totalMinutes)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Cancel") {
                    onCancel()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}
