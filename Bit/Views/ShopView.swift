import SwiftUI

struct ShopView: View {
    @Binding var currentView: String
    @EnvironmentObject var currencyModel: CurrencyModel
    @EnvironmentObject var shopModel: ShopModel
    
    @State private var items: [ShopItem] = [
        ShopItem(name: "Solar Panel", price: 30),
        ShopItem(name: "Habitat Module", price: 50),
        ShopItem(name: "Space Tractor", price: 100)
    ]
    
    var body: some View {
        ZStack {
            StarOverlay() // Add the starry background
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Add padding to the top of the assets
                        ForEach(items) { item in
                            HStack {
                                Text(item.name)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(item.price) Coins")
                                    .foregroundColor(.white)
                                Button("Buy") {
                                    buy(item: item)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                            }
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .padding(.top, 100) // Added top padding for the assets
                }
                // Optionally, you could add a bottom bar here if desired.
            }
            .padding(.horizontal, 20) // Added horizontal padding for consistent spacing
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    func buy(item: ShopItem) {
        if currencyModel.balance >= item.price {
            currencyModel.balance -= item.price
            shopModel.addPurchase(item: item)
        }
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView(currentView: .constant("Shop"))
            .environmentObject(CurrencyModel())
            .environmentObject(ShopModel())
    }
}
