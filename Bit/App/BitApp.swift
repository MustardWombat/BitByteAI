import SwiftUI
import WidgetKit

struct BitAppView: View {
    @StateObject var xpModel: XPModel
    @StateObject var miningModel: MiningModel
    @StateObject var timerModel: StudyTimerModel
    @StateObject var shopModel = ShopModel()
    @StateObject var civModel = CivilizationModel()
    @StateObject var categoriesModel = CategoriesViewModel()
    @StateObject var currencyModel = CurrencyModel()
    @StateObject var taskModel = TaskModel()

    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @State private var showSignInPrompt: Bool = false
    @State private var showSplash = true

    init() {
        let xp = XPModel()
        let mining = MiningModel()
        let currency = CurrencyModel()

        // Hook the mining reward to the currency model
        mining.awardCoins = { amount in
            currency.deposit(amount)
        }

        _xpModel = StateObject(wrappedValue: xp)
        _miningModel = StateObject(wrappedValue: mining)
        _timerModel = StateObject(wrappedValue: StudyTimerModel(xpModel: xp, miningModel: mining))
        _currencyModel = StateObject(wrappedValue: currency)
    }

    var body: some View {
        Group {
            if showSplash {
                // Show only the splash screen during initial loading
                SplashScreenOverlay()
                    .onAppear {
                        // Load critical data first
                        NSUbiquitousKeyValueStore.default.synchronize()
                        
                        // Hide splash after animation completes and data is loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showSplash = false
                            }
                            
                            // Load remaining data after splash screen is dismissed
                            DispatchQueue.main.async {
                                loadRemainingData()
                            }
                        }
                    }
            } else {
                // Show the main app content only after splash is dismissed
                AppContentView()
                    .environmentObject(xpModel)
                    .environmentObject(timerModel)
                    .environmentObject(shopModel)
                    .environmentObject(civModel)
                    .environmentObject(miningModel)
                    .environmentObject(categoriesModel)
                    .environmentObject(currencyModel)
                    .environmentObject(taskModel)
            }
        }
        .sheet(isPresented: $showSignInPrompt, onDismiss: {
            if isSignedIn {
                categoriesModel.mergeWithICloudData()
            }
        }) {
            SignInPromptView(onSignIn: {
                isSignedIn = true
                showSignInPrompt = false
                categoriesModel.mergeWithICloudData()
            }, onSkip: {
                showSignInPrompt = false
            })
        }
    }
    
    // Move data loading to a separate function to defer non-critical operations
    private func loadRemainingData() {
        xpModel.loadData()
        categoriesModel.categories = categoriesModel.loadCategories()
        taskModel.loadTasks()
        currencyModel.fetchFromICloud()
        shopModel.loadData()
        civModel.updateFromBackground()
        miningModel.resumeMiningIfNeeded()
    }
}

@main
struct CosmosApp: App {
    var body: some Scene {
        WindowGroup {
            BitAppView()
                .preferredColorScheme(.dark)  // Forces everything into Dark Mode
                .onAppear {
                    NSUbiquitousKeyValueStore.default.synchronize()
                }
        }
    }
}


