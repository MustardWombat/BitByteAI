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
    @Binding var currentView: String // Change from @State to @Binding
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
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView(isPresented: $showProfile)
                .transition(.move(edge: .top))
        }
        .onChange(of: currentView) { newView in
            if newView == "Profile" {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showProfile = true
                }
                // Reset currentView immediately
                currentView = "Home"
            }
        }
    }
}

// MARK: - BottomBarButton
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
        }
        .buttonStyle(TransparentButtonStyle())
    }
}

// MARK: - BottomBar
struct BottomBar: View {
    @Binding var currentView: String
    @ObservedObject var router: AppRouter
    let timerModel: StudyTimerModel
    let makeContentView: () -> AnyView
    
    var body: some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            VStack(spacing: 0) {
                AppHeader(currentView: $currentView)
                    .environmentObject(timerModel)
                
                TabView(selection: $router.selectedTab) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Tab(value: tab) {
                            AppTabRootView(tab: tab, currentView: $currentView) // Pass the binding
                        } label: {
                            Label(tab.title, systemImage: tab.icon)
                        }
                    }
                }
                .tint(.tabs)
                .environmentObject(timerModel)
                .environmentObject(router)
            }
        } else {
            VStack(spacing: 0) {
                AppHeader(currentView: $currentView)
                    .environmentObject(timerModel)
                
                makeContentView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                legacyBottomBar
            }
        }
        #else
        legacyBottomBar
        #endif
    }
    
    private var legacyBottomBar: some View {
        HStack {
            BottomBarButton(iconName: "house.fill", viewName: "Home", currentView: $currentView)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "globe", viewName: "Tasks", currentView: $currentView)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "airplane", viewName: "Launch", currentView: $currentView) 
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "cart.fill", viewName: "Shop", currentView: $currentView)
                .frame(maxWidth: .infinity)
            BottomBarButton(iconName: "person.2.fill", viewName: "Friends", currentView: $currentView)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.9))
        .zIndex(1000)
    }
}

// MARK: - Color Extension
extension Color {
    static let tabs = Color.green
}

