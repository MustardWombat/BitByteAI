import SwiftUI

#if os(iOS)
import UIKit
#endif

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
    @State private var showProfile: Bool = false
    
    var body: some View {
        Group {
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
        .fullScreenCover(isPresented: $showProfile, onDismiss: {
            currentView = "Home"
        }) {
            ProfileView(isPresented: $showProfile)
                .transition(.move(edge: .top))
        }
        .onChange(of: currentView) { oldValue, newValue in
            if newValue == "Profile" {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showProfile = true
                }
                DispatchQueue.main.async {
                    currentView = "Home"
                }
            }
        }
    }
}

// MARK: - BottomBarButton
/// A button for the bottom bar that can be disabled to lock interactions,
/// visually indicating the disabled state by reducing opacity.
struct BottomBarButton: View {
    let iconName: String
    let viewName: String
    @Binding var currentView: String
    var disabled: Bool = false

    var body: some View {
        Button(action: {
            guard !disabled else { return }
            if currentView != viewName {
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                #endif
                currentView = viewName
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(currentView == viewName ? Color.green : Color.white)

                Text(viewName)
                    .font(.caption)
                    .foregroundColor(currentView == viewName ? Color.green : Color.white)
            }
            .opacity(disabled ? 0.5 : 1.0)
        }
        .disabled(disabled)
        .buttonStyle(TransparentButtonStyle())
    }
}

// MARK: - BottomBar
struct BottomBar: View {
    @Binding var currentView: String
    @ObservedObject var router: AppRouter
    let timerModel: StudyTimerModel
    let makeContentView: () -> AnyView
    
    @State private var showProfile: Bool = false
    
    private var isTabBarLocked: Bool { timerModel.isTimerRunning && currentView == "Launch" }
    
    var body: some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            VStack(spacing: 0) {
                AppHeader(currentView: $currentView)
                    .environmentObject(timerModel)
                    .overlay(
                        Button(action: { showProfile = true }) {
                            Rectangle().foregroundColor(.clear)
                        }
                        .accessibilityLabel("Open Profile")
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                    )
                
                TabView(selection: Binding {
                    router.selectedTab
                } set: { newTab in
                    if !isTabBarLocked {
                        router.selectedTab = newTab
                    }
                }) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Tab(value: tab) {
                            AppTabRootView(tab: tab)
                        } label: {
                            Label(tab.title, systemImage: tab.icon)
                        }
                    }
                }
                .tint(.tabs)
                .environmentObject(timerModel)
                .environmentObject(router)
                .background(Color.black.opacity(0.9).allowsHitTesting(!isTabBarLocked))
            }
            .fullScreenCover(isPresented: $showProfile, onDismiss: {
                currentView = "Home"
            }) {
                ProfileView(isPresented: $showProfile)
            }
        } else {
            VStack(spacing: 0) {
                AppHeader(currentView: $currentView)
                    .environmentObject(timerModel)
                    .overlay(
                        Button(action: { showProfile = true }) {
                            Rectangle().foregroundColor(.clear)
                        }
                        .accessibilityLabel("Open Profile")
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                    )
                
                makeContentView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                legacyBottomBar
            }
            .fullScreenCover(isPresented: $showProfile, onDismiss: {
                currentView = "Home"
            }) {
                ProfileView(isPresented: $showProfile)
            }
            .onChange(of: currentView) { newView in
                if newView == "Profile" {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showProfile = true
                    }
                    currentView = "Home"
                }
            }
        }
        #else
        ZStack {
            legacyBottomBar
                .background(Color.black.opacity(0.9).allowsHitTesting(!isTabBarLocked))
        }
        .fullScreenCover(isPresented: $showProfile, onDismiss: {
            currentView = "Home"
        }) {
            ProfileView(isPresented: $showProfile)
        }
        .onChange(of: currentView) { newView in
            if newView == "Profile" {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showProfile = true
                }
                currentView = "Home"
            }
        }
        #endif
    }
    
    private var legacyBottomBar: some View {
        HStack {
            BottomBarButton(iconName: "house.fill", viewName: "Home", currentView: $currentView, disabled: isTabBarLocked)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "globe", viewName: "Tasks", currentView: $currentView, disabled: isTabBarLocked)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "airplane", viewName: "Launch", currentView: $currentView, disabled: false)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "cart.fill", viewName: "Shop", currentView: $currentView, disabled: isTabBarLocked)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "person.2.fill", viewName: "Friends", currentView: $currentView, disabled: isTabBarLocked)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Color Extension
extension Color {
    static let tabs = Color.green
}

