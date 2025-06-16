import SwiftUI

struct MainView: View {
    @State private var currentView: String = "Home" // Updated default tab

    var body: some View {
        ZStack {
            StarOverlay() // Add the starry background to all views
            #if os(iOS)
            LayoutShell(currentView: $currentView, content: makeContentView())
            #else
            MacMainView() // Use the new macOS-specific view
            #endif
        }
    }
    
    // Helper that returns an explicit AnyView to fix generic inference issues.
    private func makeContentView() -> AnyView {
        switch currentView {
        case "Home":
            return AnyView(HomeView(currentView: $currentView))
        case "Tasks":
            return AnyView(TaskListView(currentView: $currentView))
        case "Launch":
            return AnyView(LaunchView(currentView: $currentView)) // fixed to pass binding
        case "Shop":
            return AnyView(ShopView(currentView: $currentView))
        case "Friends":
            return AnyView(FriendsView())
        case "Profile":
            return AnyView(ProfileView())
        default:
            return AnyView(HomeView(currentView: $currentView))
        }
    }
}
