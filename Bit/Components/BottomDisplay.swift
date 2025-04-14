import SwiftUI

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
            Image(systemName: iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(currentView == viewName ? Color.orange : Color.white)
                .brightness(currentView == viewName ? 0.3 : 0)
        }
    }
}

struct LayoutShell: View {
    @Binding var currentView: String
    let content: AnyView

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            ZStack(alignment: .top) {
                VStack(spacing: 8) { // Slightly increased spacing for better layout
                    // XP bar and coins on the same level, centered
                    HStack(spacing: 16) { // Reduced spacing between XP and coins
                        XPDisplayView()
                        CoinDisplay()
                            .font(.subheadline.monospaced())
                            .foregroundColor(Color(red: 0.0, green: 1, blue: 0.0))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10) // Reduced top padding

                    Spacer()

                    // Welcome text at the bottom
                    Text("Welcome back, Commander!")
                        .font(.subheadline.monospaced())
                        .foregroundColor(Color(red: 0.0, green: 1, blue: 0.0))
                        .padding(.bottom, 10) // Increased bottom padding to prevent cutoff
                }
                .frame(height: 130) // Slightly increased height for the top bar
                .background(Color.clear)
            }

            // Main content area
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom bar
            BottomBar(currentView: $currentView)
        }
        .edgesIgnoringSafeArea(.bottom)
        .background(Color.black) // Black background for the entire layout
    }
}

struct BottomBar: View {
    @Binding var currentView: String

    var body: some View {
        HStack {
            Spacer()
            BottomBarButton(iconName: "house.fill", viewName: "Home", currentView: $currentView)
            Spacer()
            BottomBarButton(iconName: "globe", viewName: "PlanetView", currentView: $currentView)
            Spacer()
            BottomBarButton(iconName: "gearshape.fill", viewName: "StudySession", currentView: $currentView)
            Spacer()
            BottomBarButton(iconName: "cart.fill", viewName: "Shop", currentView: $currentView)
            Spacer()
        }
        .padding(.horizontal, 10) // Reduced horizontal padding
        .padding(.bottom, 20) // Reduced bottom padding
        .background(Color.clear)
    }
}
