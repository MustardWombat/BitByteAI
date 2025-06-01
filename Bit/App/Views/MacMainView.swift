import SwiftUI

struct MacMainView: View {
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var shopModel: ShopModel
    @EnvironmentObject var taskModel: TaskModel
    @EnvironmentObject var currencyModel: CurrencyModel
    
    @State private var selectedSection: String = "Home"
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(selection: $selectedSection) {
                Section("Study") {
                    NavigationLink(value: "Home") {
                        Label("Home", systemImage: "house")
                    }
                    
                    NavigationLink(value: "Planet") {
                        Label("Tasks", systemImage: "list.bullet")
                    }
                    
                    NavigationLink(value: "Study") {
                        Label("Study", systemImage: "timer")
                    }
                }
                
                Section("Rewards") {
                    NavigationLink(value: "Shop") {
                        Label("Shop", systemImage: "bag")
                    }
                    
                    NavigationLink(value: "Profile") {
                        Label("Profile", systemImage: "person")
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            
        } detail: {
            // Main content area
            ZStack {
                // Create background for the main content
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                // Add StarOverlay for visual appeal
                StarOverlay()
                    .opacity(0.5)
                
                // Main content view based on selection
                Group {
                    switch selectedSection {
                    case "Home":
                        HomeView(currentView: $selectedSection)
                    case "Planet":
                        PlanetView(currentView: $selectedSection)
                   case "Study":
                        StudyTimerView()
                    case "Shop":
                        ShopView(currentView: $selectedSection)
                    case "Profile":
                        ProfileView()
                    default:
                        HomeView(currentView: $selectedSection)
                    }
                }
                .padding()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct MacMainView_Previews: PreviewProvider {
    static var previews: some View {
        MacMainView()
            .environmentObject(CategoriesViewModel())
            .environmentObject(XPModel())
            .environmentObject(ShopModel())
            .environmentObject(TaskModel())
            .environmentObject(CurrencyModel())
    }
}
