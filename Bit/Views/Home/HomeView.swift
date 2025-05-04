import SwiftUI
import Charts

// MARK: - Rotating Planet Sprite
struct SpinningPlanetView: View {
    @State private var rotation: Angle = .zero

    var body: some View {
        Image("planet")
            .resizable()
            .frame(width: 300, height: 300)
            .rotationEffect(rotation)
            .onAppear {
                withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = .degrees(360)
                }
            }
    }
}

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
    @State private var wavePhase: CGFloat = 0  // new: wave state for animation
    @State private var selectedCategory: Category? = nil  // new: selected category for detail view

    @EnvironmentObject var shopModel: ShopModel
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @EnvironmentObject var xpModel: XPModel

    // New: Automatic claim processing
    private func autoClaimPlanets() {
        if Calendar.current.component(.weekday, from: Date()) == 1 {
            // For each category, process the claim automatically.
            // For example: update xpModel or shopModel based on progress.
            for category in categoriesVM.categories {
                let logs = categoriesVM.weeklyData(for: category.id)
                let totalMinutes = logs.reduce(0) { $0 + $1.minutes }
                let progress = category.weeklyGoalMinutes > 0 ? min(Double(totalMinutes) / Double(category.weeklyGoalMinutes), 1.0) : 0.0
                // Process claiming logic: e.g., award planets or XP based on progress
                print("Claimed planets for \(category.name): \(Int(progress * 100))% achieved.")
                // ...insert additional claim logic here...
            }
        }
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                ScrollView {
                    ZStack(alignment: .top) {
                        // ✅ Background image that scrolls with content
                        Image("SpaceBG")
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .ignoresSafeArea()
                            .zIndex(0)

                        VStack(spacing: 20) {
                            // Add padding to the top of the assets
                            SpinningPlanetView()
                                .padding(.top, 50) // Added top padding for the spinning planet

                            WeeklyProgressChart()
                                .environmentObject(categoriesVM)
                                .padding(.top, 20) // Added top padding for the chart

                            // Earned Planets section – now using wavy fill effect
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Earned Planets")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                HStack(spacing: 16) {
                                    ForEach(categoriesVM.categories, id: \.id) { category in
                                        // Calculate progress based on weekly study minutes
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
                                        .onLongPressGesture {  // new: long press gesture
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

                            // 🛍 Purchases Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your Purchases")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.orange)

                                if shopModel.purchasedItems.isEmpty {
                                    Text("No items purchased yet.")
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(shopModel.purchasedItems) { item in
                                        HStack {
                                            Text(item.name)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("Qty: \(item.quantity)")
                                                .foregroundColor(.white)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                            .padding(.top, 20) // Added top padding for the purchases section

                            Spacer(minLength: 40)
                        }
                        .padding(.top, 100) // Overall top padding for the VStack
                        .padding(.horizontal, 20)
                        .zIndex(1)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationBarBackButtonHidden(true)
                .sheet(item: $selectedCategory) { category in  // new: present detail view sheet
                    PlanetDetailView(category: category)
                        .environmentObject(categoriesVM)
                }
            }
            StarOverlay() // Move StarOverlay here to appear above SpaceBG
                .zIndex(2)
        }
        .onAppear {
            simTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                // xpModel.addXP(10)
            }
            autoClaimPlanets() // Automatically claim planets if today is Sunday
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
