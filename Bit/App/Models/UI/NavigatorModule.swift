import SwiftUI

struct MainView: View {
    @State private var currentView: String = "Home" // Updated default tab

    var body: some View {
        ZStack {
            StarOverlay() // Add the starry background to all views
            #if os(iOS)
            LayoutShell(currentView: $currentView, content: AnyView(
                Group {
                    switch currentView {
                    case "Home":
                        HomeView(currentView: $currentView)
                    case "Planets":
                        PlanetView(currentView: $currentView)
                    case "Launch":
                        LaunchView(currentView: $currentView) // Updated from "StudyView"
                    case "Shop":
                        ShopView(currentView: $currentView)
                    case "Friends":
                        FriendsView()
                    case "Profile": // Ensure ProfileView is handled
                        ProfileView()
                    default:
                        HomeView(currentView: $currentView)
                    }
                }
            ))
            #else
            MacMainView() // Use the new macOS-specific view
            #endif
        }
    }
}
