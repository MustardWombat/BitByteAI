import SwiftUI
import WidgetKit

struct CosmosAppView: View {
    @StateObject var xpModel: XPModel
    @StateObject var miningModel: MiningModel
    @StateObject var timerModel: StudyTimerModel
    @StateObject var shopModel = ShopModel()
    @StateObject var civModel = CivilizationModel()
    @StateObject var categoriesModel = CategoriesViewModel()
    @StateObject var currencyModel = CurrencyModel()
    @StateObject var taskModel = TaskModel() // <-- Add this

    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @State private var showSignInPrompt: Bool = false

    init() {
        let xp = XPModel()
        let mining = MiningModel()
        let currency = CurrencyModel()

        // ✅ Hook the mining reward to the currency model
        mining.awardCoins = { amount in
            currency.deposit(amount)
        }

        _xpModel = StateObject(wrappedValue: xp)
        _miningModel = StateObject(wrappedValue: mining)
        _timerModel = StateObject(wrappedValue: StudyTimerModel(xpModel: xp, miningModel: mining))
        _currencyModel = StateObject(wrappedValue: currency)
    }

    var body: some View {
        ContentView()
            .environmentObject(xpModel)
            .environmentObject(timerModel)
            .environmentObject(shopModel)
            .environmentObject(civModel)
            .environmentObject(miningModel)
            .environmentObject(categoriesModel)
            .environmentObject(currencyModel)
            .environmentObject(taskModel)
            .onAppear {
                // Show the prompt only on first launch if not signed in.
                if !isSignedIn {
                    showSignInPrompt = true
                }
            }
            .sheet(isPresented: $showSignInPrompt, onDismiss: {
                /* On dismiss, if now signed in, trigger a merge-sync of local with iCloud
                 e.g. by calling a method on each model (not shown here) */
            }) {
                SignInPromptView(onSignIn: {
                    // Present your actual sign‑in flow here.
                    // Once complete, set isSignedIn = true and update the cloud merge.
                    isSignedIn = true
                    showSignInPrompt = false
                    categoriesModel.mergeWithICloudData() // New line to merge categories
                }, onSkip: {
                    // User chooses to skip; use local data only.
                    showSignInPrompt = false
                })
            }
    }
}

@main
struct CosmosApp: App {
    var body: some Scene {
        WindowGroup {
            CosmosAppView()
                .preferredColorScheme(.dark)  // Forces everything into Dark Mode
                .onAppear {
                    NSUbiquitousKeyValueStore.default.synchronize()
                }
        }
    }
}


