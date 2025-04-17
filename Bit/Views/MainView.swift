import SwiftUI

struct MainView: View {
    @State private var currentView: String = "Home"

    var body: some View {
        LayoutShell(currentView: $currentView, content:
            {
                switch currentView {
                case "Home":
                    return AnyView(HomeView(currentView: $currentView))
                case "PlanetView":
                    return AnyView(PlanetView(currentView: $currentView))
                case "StudySession":
                    return AnyView(SessionView(currentView: $currentView))
                case "Shop":
                    return AnyView(ShopView(currentView: $currentView))
                case "Profile":
                    return AnyView(ProfileView())
                default:
                    return AnyView(HomeView(currentView: $currentView))
                }
            }()
        )
        .id(currentView) // Force reload when switching tabs
    }
}
