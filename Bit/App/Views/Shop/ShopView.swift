import SwiftUI
import StoreKit

struct ShopView: View {
    @Binding var currentView: String
    @EnvironmentObject var shopModel: ShopModel
    @EnvironmentObject var currencyModel: CurrencyModel
    
    @State private var selectedItem: ShopItem? = nil
    @State private var showPurchaseConfirmation = false
    @State private var showPurchaseSuccess = false
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showSubscriptionSheet = false

    var body: some View {
        ZStack {
            VStack {
                // --- BitByte Pro Subscription Button ---
                Group {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Button(action: {
                            print("🔔 Subscribe tapped")
                            subscribePro()
                        }) {
                            Text("BitByte Pro")
                                .font(.largeTitle).bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .opacity(subscriptionManager.subscriptionProduct == nil ? 0.6 : 1.0)
                    }
                }
                .padding(.horizontal)
                // --- end subscription button ---

                ScrollView {
                    VStack(spacing: 20) {
                        // Shop items section
                        VStack(alignment: .leading) {
                            // XP Boosters
                            UpgradeCategoryView(
                                title: "XP Upgrades",
                                icon: "star.fill",
                                iconColor: .yellow,
                                type: .xpBooster,
                                currentLevel: shopModel.upgradeLevels[.xpBooster] ?? 0,
                                nextUpgrade: shopModel.availableItems.first { $0.type == .xpBooster },
                                onPurchase: { selectItem($0) }
                            )
                            
                            // Coin Boosters
                            UpgradeCategoryView(
                                title: "Coin Upgrades",
                                icon: "dollarsign.circle.fill",
                                iconColor: .green,
                                type: .coinBooster,
                                currentLevel: shopModel.upgradeLevels[.coinBooster] ?? 0,
                                nextUpgrade: shopModel.availableItems.first { $0.type == .coinBooster },
                                onPurchase: { selectItem($0) }
                            )
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }

            // only inject this view when showing
            if showPurchaseConfirmation {
                PurchaseOverlayView(
                    isPresented: $showPurchaseConfirmation,
                    showSuccess: $showPurchaseSuccess,
                    selectedItem: $selectedItem
                )
                .zIndex(1)
            }
        }
        .background(Color.black.ignoresSafeArea())
        // show the sheet for confirming purchase
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionConfirmationView(
                isPresented: $showSubscriptionSheet,
                subscriptionManager: subscriptionManager
            )
        }
        // load product on appear
        .task {
            await subscriptionManager.loadProduct()
        }
        // show success alert
        .alert("Subscription Successful", isPresented: $subscriptionManager.purchaseSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thank you for subscribing to BitByte Pro!")
        }
        // show error alert
        .alert("Subscription Error", isPresented: Binding(
            get: { subscriptionManager.purchaseError != nil },
            set: { _ in subscriptionManager.purchaseError = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(subscriptionManager.purchaseError?.localizedDescription ?? "Unknown error")
        }
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
    
    private func subscribePro() {
        // toggle the sheet instead of calling purchase() directly
        showSubscriptionSheet = true
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

// New: Cookie Clicker style upgrade category
struct UpgradeCategoryView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let type: ItemType
    let currentLevel: Int
    let nextUpgrade: ShopItem?
    let onPurchase: (ShopItem) -> Void
    @EnvironmentObject var currencyModel: CurrencyModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header with current level
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text("Level \(currentLevel)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(4)
            }
            
            if let upgrade = nextUpgrade {
                // Next upgrade card
                Button(action: { onPurchase(upgrade) }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(upgrade.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            HStack(spacing: 4) {
                                Image("coin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                Text("\(upgrade.price)")
                                    .font(.subheadline)
                                    .foregroundColor(currencyModel.canAfford(upgrade.price) ? .white : .red)
                            }
                        }
                        
                        Text(upgrade.effectDescription)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Progress bar showing cost scaling
                        if currentLevel > 0 {
                            HStack {
                                Text("Next level cost:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int((Double(upgrade.price) / Double(ShopItem.nextUpgrade(for: type, currentLevel: max(1, currentLevel)).price)) * 100))% more expensive")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(currencyModel.canAfford(upgrade.price) ? iconColor.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(!currencyModel.canAfford(upgrade.price))
                .opacity(currencyModel.canAfford(upgrade.price) ? 1.0 : 0.6)
            }
        }
        .padding(.vertical, 10)
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView(currentView: .constant("Shop"))
            .environmentObject(CurrencyModel())
            .environmentObject(ShopModel())
    }
}
