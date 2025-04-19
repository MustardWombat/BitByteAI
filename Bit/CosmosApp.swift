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
            .environmentObject(taskModel) // <-- Add this
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


