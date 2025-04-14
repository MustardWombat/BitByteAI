import SwiftUI
import Charts

// MARK: - Rotating Planet Sprite
struct SpinningPlanetView: View {
    @State private var rotation: Angle = .zero

    var body: some View {
        Image("planet01")
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
                        //SpinningPlanetView()
                        WeeklyProgressChart()
                            .environmentObject(categoriesVM)

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

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 100)
                    .padding(.horizontal, 20)
                    .zIndex(1)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationBarBackButtonHidden(true)
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
