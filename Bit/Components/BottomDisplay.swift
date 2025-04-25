import SwiftUI

// MARK: - BottomBarButton
struct BottomBarButton: View {
    let iconName: String
    let viewName: String
    @Binding var currentView: String

    var body: some View {
        Button(action: {
            if currentView != viewName {
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                #endif
                currentView = viewName
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(currentView == viewName ? Color.green : Color.white)

                Text(viewName)
                    .font(.caption)
                    .foregroundColor(currentView == viewName ? Color.green : Color.white)
            }
        }
    }
}

// MARK: - TopShellSpritePlaceholder
struct TopShellSpritePlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray.opacity(0.5), lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.2)))
            Image("BitDefault")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(width: 44, height: 44)
        .padding(.horizontal, 8)
    }
}

// MARK: - LayoutShell
struct LayoutShell: View {
    @Binding var currentView: String
    let content: AnyView

    @State private var currentXP: Int = 150 // Example current XP value
    @State private var maxXP: Int = 200 // Example max XP value
    @EnvironmentObject var timerModel: StudyTimerModel // Inject StudyTimerModel

    // Define fixed heights for overlays
    private let topBarHeight: CGFloat = 100
    private let bottomBarHeight: CGFloat = 90

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Main content, constrained to not overlap overlays
                VStack(spacing: 0) {
                    Spacer(minLength: topBarHeight)
                    content
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: geo.size.height - topBarHeight - bottomBarHeight
                        )
                    Spacer(minLength: bottomBarHeight)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

                // Top Bar (absolutely positioned)
                VStack {
                    ZStack {
                        BlurView(style: .systemMaterial)
                            .ignoresSafeArea(edges: .top)
                            .frame(height: topBarHeight)
                        VStack(spacing: 4) {
                            // --- Info row with sprite placeholder centered between XP and Coin ---
                            HStack(spacing: 12) {
                                XPDisplayView()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TopShellSpritePlaceholder()
                                CoinDisplay()
                                    .font(.caption.monospaced())
                                    .foregroundColor(Color.green)
                                StreakDisplay()
                                    .environmentObject(timerModel)
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            Text(dynamicWelcomeText(for: currentView))
                                .font(.caption.monospaced())
                                .foregroundColor(Color.green)
                        }
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: topBarHeight)
                        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                    }
                    .frame(height: topBarHeight)
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .zIndex(2)

                // Bottom Bar (absolutely positioned)
                VStack {
                    Spacer()
                    BottomBar(currentView: $currentView)
                        .frame(height: bottomBarHeight)
                        .ignoresSafeArea(edges: .bottom)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                .zIndex(2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            updateXPValues()
        }
    }

    private func dynamicWelcomeText(for view: String) -> String {
        switch view {
        case "Home": return "Welcome back, Commander!"
        case "Planets": return "Explore the galaxy!"
        case "Study": return "Focus and achieve greatness!"
        case "Shop": return "Upgrade your journey!"
        default: return "Welcome back, Commander!"
        }
    }

    private func updateXPValues() {
        // Replace with actual logic to fetch or calculate XP values
        currentXP = 150 // Example current XP value
        maxXP = 200 // Example max XP value
    }
}

// MARK: - BottomBar
struct BottomBar: View {
    @Binding var currentView: String

    var body: some View {
        HStack {
            BottomBarButton(iconName: "house.fill", viewName: "Home", currentView: $currentView)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "globe", viewName: "Planets", currentView: $currentView)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "gearshape.fill", viewName: "Study", currentView: $currentView)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "cart.fill", viewName: "Shop", currentView: $currentView)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "person.crop.circle", viewName: "Profile", currentView: $currentView)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            Color.black.opacity(0.65)
                .cornerRadius(20, corners: [.topLeft, .topRight])
        )
        .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: -5)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - BlurView
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - RoundedCorner Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
