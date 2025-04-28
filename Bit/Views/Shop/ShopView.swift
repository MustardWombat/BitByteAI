import SwiftUI

struct ShopView: View {
    @Binding var currentView: String
    @EnvironmentObject var shopModel: ShopModel
    @EnvironmentObject var currencyModel: CurrencyModel
    
    @State private var selectedItem: ShopItem? = nil
    @State private var showPurchaseConfirmation = false
    @State private var showPurchaseSuccess = false
    
    var body: some View {
        ZStack {
            // Main shop view
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Active items section
                        if !shopModel.purchasedItems.filter({ $0.isActive }).isEmpty {
                            VStack(alignment: .leading) {
                                Text("Active Boosts")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 5)
                                
                                ForEach(shopModel.purchasedItems.filter { $0.isActive }) { item in
                                    ActiveItemCard(item: item)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                        }
                        
                        // Shop items section
                        VStack(alignment: .leading) {
                            Text("Shop")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            // XP Boosters
                            ItemCategoryView(
                                title: "XP Boosters",
                                icon: "star.fill",
                                iconColor: .yellow,
                                items: shopModel.availableItems.filter { $0.type == .xpBooster },
                                onItemSelected: { selectItem($0) }
                            )
                            
                            // Coin Boosters
                            ItemCategoryView(
                                title: "Coin Boosters",
                                icon: "dollarsign.circle.fill",
                                iconColor: .green,
                                items: shopModel.availableItems.filter { $0.type == .coinBooster },
                                onItemSelected: { selectItem($0) }
                            )
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .padding()
                    .padding(.top, 100) // Added top padding for the assets
                }
            }
            
            // Purchase confirmation overlay
            if showPurchaseConfirmation, let item = selectedItem {
                PurchaseConfirmationView(
                    item: item,
                    currencyModel: currencyModel,
                    onConfirm: {
                        purchaseItem(item)
                        showPurchaseConfirmation = false
                    },
                    onCancel: {
                        showPurchaseConfirmation = false
                    }
                )
                .transition(.opacity)
            }
            
            // Purchase success notification
            if showPurchaseSuccess {
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
                .onAppear {
                    // Auto-hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showPurchaseSuccess = false
                        }
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func selectItem(_ item: ShopItem) {
        selectedItem = item
        withAnimation {
            showPurchaseConfirmation = true
        }
    }
    
    private func purchaseItem(_ item: ShopItem) {
        if currencyModel.spend(item.price) {
            shopModel.addPurchase(item: item)
            withAnimation {
                showPurchaseSuccess = true
            }
        }
    }
}

// Active Item Card Component
struct ActiveItemCard: View {
    let item: PurchasedItem
    
    var body: some View {
        HStack {
            // Icon based on item type
            Image(systemName: getIconForItemType(item.type))
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(getColorForItemType(item.type))
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.5)))
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(item.timeRemaining)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if item.quantity > 1 {
                Text("x\(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    private func getIconForItemType(_ type: ItemType) -> String {
        switch type {
        case .xpBooster: return "star.fill"
        case .coinBooster: return "dollarsign.circle.fill"
        case .timerExtender: return "timer"
        case .focusEnhancer: return "brain.head.profile"
        }
    }
    
    private func getColorForItemType(_ type: ItemType) -> Color {
        switch type {
        case .xpBooster: return .yellow
        case .coinBooster: return .green
        case .timerExtender: return .blue
        case .focusEnhancer: return .purple
        }
    }
}

// Item Category Component
struct ItemCategoryView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [ShopItem]
    let onItemSelected: (ShopItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            ForEach(items) { item in
                ShopItemCard(item: item, onSelect: onItemSelected)
            }
        }
        .padding(.vertical, 10)
    }
}

// Shop Item Card Component
struct ShopItemCard: View {
    let item: ShopItem
    let onSelect: (ShopItem) -> Void
    @EnvironmentObject var currencyModel: CurrencyModel
    
    var body: some View {
        Button(action: { onSelect(item) }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(item.effectDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text(item.durationDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack {
                    Image("coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    
                    Text("\(item.price)")
                        .font(.subheadline)
                        .foregroundColor(currencyModel.canAfford(item.price) ? .white : .red)
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
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
