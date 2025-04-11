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
            ZStack(alignment: .topLeading) {
                // Full-width black backdrop with slight transparency
                Color.black.opacity(0.6)
                    .frame(height: 20)
                    .ignoresSafeArea(edges: .top)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        XPDisplayView()
                        CoinDisplay()


                            .font(.subheadline.monospaced())
                            .foregroundColor(Color(red: 0.0, green: 1, blue: 0.0))
                    }


                    Text("Welcome back, Commander!")
                        .font(.caption.monospaced())
                        .foregroundColor(Color(red: 0.0, green: 1, blue: 0.0))
                }
                .padding(.top, 10)    // ⬅️ Adjusted padding
                .padding(.leading, 20)
            }

            // 🧩 Main content area
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 🔽 Bottom bar
            BottomBar(currentView: $currentView)
        }
        .edgesIgnoringSafeArea(.bottom)
        .background(Color.clear)
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
        .padding()
        .padding(.bottom, 40)
        .background(Color.clear)
    }
}
