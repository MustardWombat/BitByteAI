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

// MARK: - HomeView
struct HomeView: View {
    @Binding var currentView: String
    @State private var path: [String] = []
    @State private var simTimer: Timer? = nil

    @EnvironmentObject var shopModel: ShopModel
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @EnvironmentObject var xpModel: XPModel

    var body: some View {
        ZStack {
            StarOverlay() // Add the starry background
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

                            // Add Earned Planets section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Earned Planets")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                HStack(spacing: 16) {
                                    ForEach(0..<4, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.black.opacity(0.3))
                                            )
                                            .frame(width: 80, height: 80)
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
            }
        }
        .onAppear {
            simTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                // xpModel.addXP(10)
            }
        }
        .onDisappear {
            simTimer?.invalidate()
        }
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
