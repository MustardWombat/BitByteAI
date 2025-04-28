import SwiftUI

struct MainView: View {
    @State private var currentView: String = "Launch" // Updated default tab

    var body: some View {
        ZStack {
            StarOverlay() // Add the starry background to all views
            LayoutShell(currentView: $currentView, content:
                {
                    switch currentView {
                    case "Home":
                        return AnyView(HomeView(currentView: $currentView))
                    case "Planets":
                        return AnyView(PlanetView(currentView: $currentView))
                    case "Launch":
                        return AnyView(LaunchView(currentView: $currentView)) // Updated from "StudyView"
                    case "Shop":
                        return AnyView(ShopView(currentView: $currentView))
                    case "Friends":
                        return AnyView(FriendsView())
                    case "Profile": // Ensure ProfileView is handled
                        return AnyView(ProfileView())
                    default:
                        return AnyView(HomeView(currentView: $currentView))
                    }
                }()
            )
            .id(currentView) // Force reload when switching tabs
        }
    }
}
