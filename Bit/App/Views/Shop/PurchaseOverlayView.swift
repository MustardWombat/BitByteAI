import SwiftUI

struct PurchaseOverlayView: View {
    @Binding var isPresented: Bool        // was showConfirmation
    @Binding var showSuccess: Bool
    @Binding var selectedItem: ShopItem?
    @EnvironmentObject var currencyModel: CurrencyModel
    @EnvironmentObject var shopModel: ShopModel

    var body: some View {
        ZStack {
            // Success banner
            if showSuccess {
                VStack {
                    Spacer()
                    Text("Purchase Successful!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .transition(.move(edge: .bottom))
                    Spacer().frame(height: 100)
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $isPresented) {
            if let item = selectedItem {
                PurchaseConfirmationView(
                    item: item,
                    currencyModel: currencyModel,
                    onConfirm: {
                        isPresented = false
                        if currencyModel.spend(item.price) {
                            shopModel.addPurchase(item: item)
                            withAnimation { showSuccess = true }
                            // auto-hide after 2s
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showSuccess = false }
                            }
                        }
                    },
                    onCancel: {
                        isPresented = false
                    }
                )
            }
        }
    }
}
