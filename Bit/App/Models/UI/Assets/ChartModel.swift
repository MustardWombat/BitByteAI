import SwiftUI
import Charts

struct WeeklyProgressChart: View {
    @EnvironmentObject var viewModel: CategoriesViewModel
    @State private var selectedCategory: Category? = nil  // New filter state

    var body: some View {
        VStack {
            Text("Weekly Progress")
                .font(.headline)
                .padding(.bottom, 5)
            // --- New filter buttons for topics ---
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button(action: { selectedCategory = nil }) {
                        Text("All Topics")
                            .padding(8)
                            .background(selectedCategory == nil ? Color.green : Color.gray.opacity(0.3))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    ForEach(viewModel.categories, id: \.id) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category.name)
                                .padding(8)
                                .background(selectedCategory?.id == category.id ? category.displayColor : Color.gray.opacity(0.3))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
            }
            // --- Existing Chart Content (modified to filter based on selected topic) ---
            if #available(iOS 16.0, *) {
                if viewModel.categories.isEmpty {
                    Text("No study data available")
                        .foregroundColor(.white)
                        .frame(height: 200)
                        .background(Color.black.opacity(0.7))
                } else {
                    Chart {
                        if let cat = selectedCategory {
                            let logs = viewModel.weeklyData(for: cat.id)
                            ForEach(logs) { log in
                                LineMark(
                                    x: .value("Date", log.date, unit: .day),
                                    y: .value("Minutes", log.minutes)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(cat.displayColor)
                            }
                        } else {
                            ForEach(viewModel.categories, id: \.id) { category in
                                let logs = viewModel.weeklyData(for: category.id)
                                ForEach(logs) { log in
                                    LineMark(
                                        x: .value("Date", log.date, unit: .day),
                                        y: .value("Minutes", log.minutes)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(category.displayColor)
                                    .symbol(by: .value("Topic", category.name))
                                }
                            }
                        }
                    }
                    .chartYScale(domain: 0...Double(maxOverallMinutes()))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .frame(height: 250)
                    .animation(.easeInOut, value: viewModel.categories)
                    .onChange(of: viewModel.categories) { _ in
                        print("🟢 Chart detected a category update")
                    }
                    .onReceive(viewModel.objectWillChange) { _ in
                        print("🟢 Chart view received objectWillChange")
                    }
                }
            } else {
                Text("Swift Charts is only available on iOS 16+.")
                    .foregroundColor(.gray)
                    .frame(height: 200)
            }
        }
        .padding()
    }

    private func maxOverallMinutes() -> Int {
        if let cat = selectedCategory {
            let logs = viewModel.weeklyData(for: cat.id)
            let maxMinutes = logs.map { $0.minutes }.max() ?? 0
            return max(maxMinutes, 10) // Ensure minimum scale of 10
        }
        let weeklyData = viewModel.categories.flatMap { viewModel.weeklyData(for: $0.id) }
        let maxMinutes = weeklyData.map { $0.minutes }.max() ?? 0
        return max(maxMinutes, 10) // Ensure minimum scale of 10
    }
}

extension CategoriesViewModel {
    func updateCategory(at index: Int) {
        categories[index] = categories[index]
        categories = categories  // This forces a new array reference.
    }

    func saveCategories() {
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

    // This function ensures consistent Sunday-Saturday data
    func weeklyData(for categoryId: UUID) -> [DailyLog] {
        guard let category = categories.first(where: { $0.id == categoryId }) else {
            return []
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week (Sunday)
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        
        // Create all 7 days of the week with 0 minutes by default
        var weeklyData: [DailyLog] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                weeklyData.append(DailyLog(date: date, minutes: 0))
            }
        }
        
        // Update with actual logged minutes from category
        for actualLog in category.weeklyLogs {
            if let index = weeklyData.firstIndex(where: { 
                calendar.isDate($0.date, inSameDayAs: actualLog.date) 
            }) {
                weeklyData[index] = actualLog
            }
        }
        
        return weeklyData
    }
    
    // Live data method that includes current session progress
    func liveWeeklyData(for categoryId: UUID, currentSessionMinutes: Int = 0) -> [DailyLog] {
        var data = weeklyData(for: categoryId)
        
        // Add current session minutes to today if this category is active
        let calendar = Calendar.current
        let today = Date()
        
        if let todayIndex = data.firstIndex(where: { 
            calendar.isDate($0.date, inSameDayAs: today) 
        }) {
            data[todayIndex].minutes += currentSessionMinutes
        }
        
        return data
    }
}
