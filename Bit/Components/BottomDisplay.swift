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
                    .foregroundColor(currentView == viewName ? Color.orange : Color.white)

                Text(viewName)
                    .font(.caption)
                    .foregroundColor(currentView == viewName ? Color.orange : Color.white)
            }
        }
    }
}

// MARK: - LayoutShell
struct LayoutShell: View {
    @Binding var currentView: String
    let content: AnyView

    @State private var currentXP: Int = 150 // Example current XP value
    @State private var maxXP: Int = 200 // Example max XP value

    var body: some View {
        ZStack {
            // Main content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 90) // Prevent overlap with BottomBar

            // Overlay Top & Bottom bars
            VStack(spacing: 0) {
                // Top Bar
                ZStack {
                    BlurView(style: .systemMaterial)
                        .ignoresSafeArea(edges: .top) // Extend to the very top of the screen
                        .frame(height: 100) // Reduced height for a more compact top bar

                    VStack(spacing: 4) { // Reduced spacing for compactness
                        // Top Level: XP and Coin Display
                        HStack(spacing: 12) { // Horizontal layout for XP and Coin
                            XPDisplayView() // Ensure XPDisplayView accepts these parameters
                                .frame(maxWidth: .infinity, alignment: .leading) // Align XP display to the far left
                            Spacer() // Add a spacer for better separation
                            CoinDisplay()
                                .font(.caption.monospaced()) // Slightly larger font for better readability
                                .foregroundColor(Color.green)
                        }
                        .padding(.horizontal, 16) // Add horizontal padding to prevent hugging the edges
                        .frame(maxWidth: .infinity)

                        // Bottom Level: Dynamic Welcome Text
                        Text(dynamicWelcomeText(for: currentView)) // Display dynamic text
                            .font(.caption.monospaced()) // Reduced font size for a more compact appearance
                            .foregroundColor(Color.green)
                    }
                    .padding(.top, 4) // Minimal padding to bring content closer to the top
                    .frame(maxWidth: .infinity) // Ensure it spans the full width
                    .frame(height: 100) // Match the reduced height of the top bar
                    .cornerRadius(12, corners: [.bottomLeft, .bottomRight]) // Slightly larger corner radius
                }
                .zIndex(2)

                Spacer()

                // Bottom Bar
                BottomBar(currentView: $currentView)
                    .zIndex(2)
            }
        }
        .onAppear {
            updateXPValues()
        }
    }

    private func dynamicWelcomeText(for view: String) -> String {
        switch view {
        case "Home": return "Welcome back, Commander!"
        case "PlanetView": return "Explore the galaxy!"
        case "StudySession": return "Focus and achieve greatness!"
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
            Spacer()
            BottomBarButton(iconName: "house.fill", viewName: "Home", currentView: $currentView) // Correct view name
            Spacer()
            BottomBarButton(iconName: "globe", viewName: "PlanetView", currentView: $currentView) // Correct view name
            Spacer()
            BottomBarButton(iconName: "gearshape.fill", viewName: "StudySession", currentView: $currentView) // Correct view name
            Spacer()
            BottomBarButton(iconName: "cart.fill", viewName: "Shop", currentView: $currentView) // Correct view name
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            Color.black.opacity(0.65) // ✅ Semi-transparent black background
                .cornerRadius(20, corners: [.topLeft, .topRight]) // Rounded top corners
        )
        .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: -5) // Shadow above the bar
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .bottom) // Extend to the bottom of the screen
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
