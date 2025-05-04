import SwiftUI

struct MainView: View {
    @State private var currentView: String = "Home" // Updated default tab

    var body: some View {
        ZStack {
            StarOverlay() // Add the starry background to all views
            #if os(iOS)
            LayoutShell(currentView: $currentView, content: {
                switch currentView {
                case "Home":
                    AnyView(HomeView(currentView: $currentView))
                case "Planets":
                    AnyView(PlanetView(currentView: $currentView))
                case "Launch":
                    AnyView(LaunchView(currentView: $currentView)) // Updated from "StudyView"
                case "Shop":
                    AnyView(ShopView(currentView: $currentView))
                case "Friends":
                    AnyView(FriendsView())
                case "Profile": // Ensure ProfileView is handled
                    AnyView(ProfileView())
                default:
                    AnyView(HomeView(currentView: $currentView))
                }
            })
            #else
            MacMainView() // Use the new macOS-specific view
            #endif
        }
    }
}
