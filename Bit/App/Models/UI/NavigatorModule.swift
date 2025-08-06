import SwiftUI

struct MainView: View {
    @State private var currentView: String = "Home"
    @State private var showOverlay: Bool = false
    @StateObject private var timerModel = StudyTimerModel()
    @StateObject private var router = AppRouter()
    @StateObject private var categoriesViewModel = CategoriesViewModel()
    @StateObject private var taskModel = TaskModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView(
                    onSignIn: {
                        isSignedIn = true
                    },
                    onSkip: {
                        isSignedIn = false
                    },
                    onComplete: {
                        hasCompletedOnboarding = true
                    }
                )
                .environmentObject(categoriesViewModel)
                .environmentObject(taskModel)
            } else {
                StarOverlay()
                #if os(iOS)
                BottomBar(
                    currentView: $currentView,
                    router: router,
                    timerModel: timerModel,
                    makeContentView: makeContentView
                )
                .environmentObject(timerModel)

                if showOverlay {
                    FocusOverlayView(isActive: $showOverlay, timerModel: timerModel)
                        .ignoresSafeArea()
                        .zIndex(99)
                }
                #else
                MacMainView()
                #endif
            }
        }
        .environmentObject(categoriesViewModel)
        .environmentObject(taskModel)
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
