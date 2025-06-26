import SwiftUI

struct MainView: View {
    @State private var currentView: String = "Home" // Updated default tab
    @State private var showOverlay: Bool = false   // new binding for FocusOverlay
    @StateObject private var timerModel = StudyTimerModel() // shared timer

    var body: some View {
        ZStack {
            StarOverlay() // Add the starry background to all views
            #if os(iOS)
            LayoutShell(
                currentView: $currentView,
                content: makeContentView()
            )
            .environmentObject(timerModel)

            if showOverlay {
                FocusOverlayView(isActive: $showOverlay, timerModel: timerModel)
                    .ignoresSafeArea()
                    .zIndex(99)
            }
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
            return AnyView(LaunchView(currentView: $currentView)) // removed showOverlay
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
