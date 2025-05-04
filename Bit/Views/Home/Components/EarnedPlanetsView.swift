import SwiftUI

struct EarnedPlanetsView: View {
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @Binding var wavePhase: CGFloat
    @Binding var selectedCategory: Category?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Earned Planets")
                .font(.title2)
                .foregroundColor(.orange)
            HStack(spacing: 16) {
                ForEach(categoriesVM.categories, id: \.id) { category in
                    let logs = categoriesVM.weeklyData(for: category.id)
                    let totalMinutes = logs.reduce(0) { $0 + $1.minutes }
                    let progress = category.weeklyGoalMinutes > 0 ?
                        min(Double(totalMinutes) / Double(category.weeklyGoalMinutes), 1.0) : 0.0

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(category.displayColor.opacity(0.3))
                            .frame(width: 80, height: 80)

                        WaterWave(progress: CGFloat(progress), phase: wavePhase)
                            .fill(category.displayColor)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                    .onLongPressGesture {
                        selectedCategory = category
                    }
                    .overlay(
                        Text("\(Int(progress * 100))%")
                            .foregroundColor(.white)
                            .bold()
                            .padding(4),
                        alignment: .top
                    )
                }
            }
            .padding(.vertical, 10)
        }
    }
}
