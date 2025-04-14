import SwiftUI
import Charts

struct WeeklyProgressChart: View {
    @EnvironmentObject var viewModel: CategoriesViewModel

    var body: some View {
        VStack {
            Text("Weekly Progress")
                .font(.headline)
                .padding(.bottom, 5)

            if #available(iOS 16.0, *) {
                if viewModel.categories.isEmpty {
                    Text("No study data available")
                        .foregroundColor(.white)
                        .frame(height: 200)
                        .background(Color.black.opacity(0.7))
                } else {
                    Chart {
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
                    .chartYScale(domain: 0...Double(maxOverallMinutes()))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .frame(height: 250)
                    .animation(.easeInOut, value: viewModel.categories) // Smooth transition
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
        let weeklyData = viewModel.categories.flatMap { viewModel.weeklyData(for: $0.id) }
        print("DEBUG: Weekly Data for all categories: \(weeklyData)")
        
        let minutesArray = weeklyData.map { $0.minutes }
        print("DEBUG: Minutes Array: \(minutesArray)")
        
        let maxMinutes = minutesArray.max() ?? 10
        print("DEBUG: maxOverallMinutes computed as \(maxMinutes)")
        return maxMinutes
    }
}

extension CategoriesViewModel {
    func updateCategory(at index: Int) {
        categories[index] = categories[index]
        categories = categories  // This forces a new array reference.
    }
}
