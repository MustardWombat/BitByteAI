import SwiftUI

struct MainView: View {
    @State private var currentView: String = "Home"
    @State private var showOverlay: Bool = false
    @StateObject private var timerModel = StudyTimerModel()
    @StateObject private var router = AppRouter()
    @StateObject private var categoriesViewModel = CategoriesViewModel()
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
            } else {
                StarOverlay()
                #if os(iOS)
                if #available(iOS 18.0, *) { // Fixed version number
                    VStack(spacing: 0) {
                        AppHeader(currentView: $currentView)
                            .environmentObject(timerModel)
                        
                        TabView(selection: $router.selectedTab) {
                            ForEach(AppTab.allCases, id: \.self) { tab in
                                Tab(value: tab) {
                                    AppTabRootView(tab: tab)
                                } label: {
                                    Label(tab.title, systemImage: tab.icon)
                                }
                            }
                        }
                        .tint(.tabs)
                        .tabBarMinimizeBehavior(.onScrollDown)
                        .environmentObject(timerModel)
                        .environmentObject(router)
                    }
                } else {
                    LayoutShell(
                        currentView: $currentView,
                        content: makeContentView()
                    )
                    .environmentObject(timerModel)
                }

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

// MARK: - AppTab Enum
enum AppTab: String, CaseIterable, Hashable {
    case home, tasks, compose, shop, friends
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .tasks: return "Tasks"
        case .compose: return "Launch"
        case .shop: return "Shop"
        case .friends: return "Friends"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .tasks: return "globe"
        case .compose: return "airplane"
        case .shop: return "cart.fill"
        case .friends: return "person.2.fill"
        }
    }
}

// MARK: - AppRouter
class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
}

// MARK: - AppTabRootView
struct AppTabRootView: View {
    let tab: AppTab
    @State private var currentView: String = "Home"
    
    var body: some View {
        switch tab {
        case .home:
            HomeView(currentView: $currentView)
        case .tasks:
            TaskListView(currentView: $currentView)
        case .compose:
            LaunchView(currentView: $currentView)
        case .shop:
            ShopView(currentView: $currentView)
        case .friends:
            FriendsView()
        }
    }
}

// MARK: - Color Extension
extension Color {
    static let tabs = Color.green
}
