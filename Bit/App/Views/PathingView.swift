import SwiftUI

struct PathingContentView: View {  // Renamed from ContentView to avoid conflict
    var body: some View {
        MainTabView()
    }
}

struct MainTabView: View {
    @State private var currentView: String = "Home"  // Add this state property
    
    var body: some View {
        TabView {
            HomeView(currentView: $currentView)  // Fix the binding
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

struct PathingContentView_Previews: PreviewProvider {  // Also renamed Preview struct
    static var previews: some View {
        PathingContentView()
    }
}
