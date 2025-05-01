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
        AppContentView()  // Updated to use AppContentView
            .environmentObject(xpModel)
            .environmentObject(timerModel)
            .environmentObject(shopModel)
            .environmentObject(civModel)
            .environmentObject(miningModel)
            .environmentObject(categoriesModel)
            .environmentObject(currencyModel)
            .environmentObject(taskModel)
            .onAppear {
                // Refresh data on startup for all models:
                NSUbiquitousKeyValueStore.default.synchronize()
                xpModel.loadData()
                categoriesModel.categories = categoriesModel.loadCategories() // Explicitly update categories
                taskModel.loadTasks()
                currencyModel.fetchFromICloud()
                shopModel.loadData() // Ensure ShopModel is loaded
                civModel.updateFromBackground()
                miningModel.resumeMiningIfNeeded()
            }
            .sheet(isPresented: $showSignInPrompt, onDismiss: {
                // On dismiss, if now signed in, trigger a merge-sync of local with iCloud
                if isSignedIn {
                    categoriesModel.mergeWithICloudData()
                }
            }) {
                SignInPromptView(onSignIn: {
                    // Present your actual sign‑in flow here.
                    // Once complete, set isSignedIn = true and update the cloud merge.
                    isSignedIn = true
                    showSignInPrompt = false
                    categoriesModel.mergeWithICloudData()
                }, onSkip: {
                    // User chooses to skip; use local data only.
                    showSignInPrompt = false
                })
            }
    }
}

@main
struct BitApp: App {
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


