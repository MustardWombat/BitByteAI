@main
struct CosmosApp: App {
    // ...existing state object declarations...
    var body: some Scene {
        WindowGroup {
            CosmosAppView()
                // ...existing environmentObject modifiers...
                .onAppear {
                    // ...existing onAppear code...
                    NSUbiquitousKeyValueStore.default.synchronize()
                    xpModel.loadData()
                    categoriesModel.categories = categoriesModel.loadCategories()
                    taskModel.loadTasks()
                    currencyModel.fetchFromICloud()
                    shopModel.loadData()
                    civModel.updateFromBackground()
                    miningModel.resumeMiningIfNeeded()
                    // NEW: Activate notifications at app launch
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
