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
            // Fallback shell display for non iOS platforms.
            VStack {
                Picker("", selection: $currentView) {
                    Text("Home").tag("Home")
                    Text("Planets").tag("Planets")
                    Text("Launch").tag("Launch")
                    Text("Shop").tag("Shop")
                    Text("Friends").tag("Friends")
                    Text("Profile").tag("Profile")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                Spacer()

                switch currentView {
                case "Home":
                    HomeView(currentView: $currentView)
                case "Planets":
                    PlanetView(currentView: $currentView)
                case "Launch":
                    LaunchView(currentView: $currentView)
                case "Shop":
                    ShopView(currentView: $currentView)
                case "Friends":
                    FriendsView()
                case "Profile":
                    ProfileView()
                default:
                    HomeView(currentView: $currentView)
                }
            }
            .padding()
            #endif
        }
    }
}
