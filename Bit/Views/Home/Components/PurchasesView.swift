import SwiftUI

struct PurchasesView: View {
    @EnvironmentObject var shopModel: ShopModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Purchases")
                .font(.title2)
                .bold()
                .foregroundColor(.orange)

            if shopModel.purchasedItems.isEmpty {
                Text("No items purchased yet.")
                    .foregroundColor(.gray)
            } else {
                ForEach(shopModel.purchasedItems) { item in
                    HStack {
                        Text(item.name)
                            .foregroundColor(.white)
                        Spacer()
                        Text("Qty: \(item.quantity)")
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}
