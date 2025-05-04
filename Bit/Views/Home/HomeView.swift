import SwiftUI
import Charts

// New: Animated water wave shape for wavy fill effect
struct WaterWave: Shape {
    var progress: CGFloat // fill percentage (0..1)
    var phase: CGFloat    // wave phase for animation
    var amplitude: CGFloat = 5
    var frequency: CGFloat = 2 * .pi  // one full wave across the available width
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let yOffset = rect.height * (1 - progress)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: yOffset))
        for x in stride(from: 0, through: Double(rect.width), by: 1) {
            let relativeX = CGFloat(x) / rect.width
            let sine = sin(relativeX * frequency + phase)
            let y = yOffset + sine * amplitude
            path.addLine(to: CGPoint(x: rect.minX + CGFloat(x), y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - HomeView
struct HomeView: View {
    @Binding var currentView: String
    @State private var path: [String] = []
    @State private var simTimer: Timer? = nil
    @State private var wavePhase: CGFloat = 0
    @State private var selectedCategory: Category? = nil

    @EnvironmentObject var shopModel: ShopModel
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @EnvironmentObject var xpModel: XPModel

    private func autoClaimPlanets() {
        if Calendar.current.component(.weekday, from: Date()) == 1 {
            for category in categoriesVM.categories {
                let logs = categoriesVM.weeklyData(for: category.id)
                let totalMinutes = logs.reduce(0) { $0 + $1.minutes }
                let progress = category.weeklyGoalMinutes > 0 ? min(Double(totalMinutes) / Double(category.weeklyGoalMinutes), 1.0) : 0.0
                print("Claimed planets for \(category.name): \(Int(progress * 100))% achieved.")
            }
        }
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                ScrollView {
                    ZStack(alignment: .top) {
                        Image("SpaceBG")
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .ignoresSafeArea()
                            .zIndex(0)

                        VStack(spacing: 20) {
                            SpinningPlanetView()
                                .padding(.top, 50)

                            WeeklyProgressChart()
                                .environmentObject(categoriesVM)
                                .padding(.top, 20)

                            EarnedPlanetsView(wavePhase: $wavePhase, selectedCategory: $selectedCategory)
                                .environmentObject(categoriesVM)

                            PurchasesView()
                                .environmentObject(shopModel)
                                .padding(.top, 20)

                            Spacer(minLength: 40)
                        }
                        .padding(.top, 100)
                        .padding(.horizontal, 20)
                        .zIndex(1)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationBarBackButtonHidden(true)
                .sheet(item: $selectedCategory) { category in
                    PlanetDetailView(category: category)
                        .environmentObject(categoriesVM)
                }
            }
            StarOverlay()
                .zIndex(2)
        }
        .onAppear {
            simTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in }
            autoClaimPlanets()
            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
        .onDisappear {
            simTimer?.invalidate()
        }
    }
}

// new: Detail view for planet on long press
struct PlanetDetailView: View {
    let category: Category
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        let logs = categoriesVM.weeklyData(for: category.id)
        let totalMinutes = logs.reduce(0) { $0 + $1.minutes }
        let minutesLeft = max(Double(category.weeklyGoalMinutes) - Double(totalMinutes), 0)
        let hoursLeft = minutesLeft / 60

        return VStack(spacing: 16) {
            Text(category.name)
                .font(.largeTitle)
                .foregroundColor(category.displayColor)
            Text(String(format: "Hours needed to finish: %.1f", hoursLeft))
                .font(.title2)
            // ...additional info if needed...
            Button("Dismiss") {
                dismiss()
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(currentView: .constant("Home"))
            .environmentObject(ShopModel())
            .environmentObject(CategoriesViewModel())
            .environmentObject(XPModel())
    }
}
