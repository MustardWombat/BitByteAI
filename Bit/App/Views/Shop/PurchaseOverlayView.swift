import SwiftUI

struct PurchaseOverlayView: View {
    @Binding var isPresented: Bool
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

            // Confirmation overlay
            if isPresented, let item = selectedItem {
                // blurred, semi-transparent glass effect background
                Color.clear.background(.ultraThinMaterial).ignoresSafeArea()
                    .onTapGesture { withAnimation { isPresented = false } }

                // Confirmation card (was in PurchaseConfirmationView)
                VStack(spacing: 16) {
                    Text("Purchase Item")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 100, height: 100)
                        Image(systemName: getIconForItemType(item.type))
                            .resizable().scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .scaleEffect(1.05)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
                    }
                    .padding(.bottom, 10)

                    Text(item.name)
                        .font(.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(item.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Divider().background(.ultraThinMaterial).padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bolt.fill").foregroundColor(.yellow)
                            Text(item.effectDescription).foregroundColor(.white)
                        }
                        HStack {
                            Image(systemName: "clock.fill").foregroundColor(.green)
                            Text(item.durationDescription).foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)

                    Divider().background(Color.gray.opacity(0.3)).padding(.horizontal)

                    HStack {
                        Image("coin").resizable().scaledToFit().frame(width: 24, height: 24)
                        Text("\(item.price)")
                            .font(.headline)
                            .foregroundColor(currencyModel.canAfford(item.price) ? .white : .red)
                    }

                    HStack(spacing: 20) {
                        Button("Cancel") {
                            withAnimation { isPresented = false }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)

                        Button("Purchase") {
                            isPresented = false
                            if currencyModel.spend(item.price) {
                                shopModel.addPurchase(item: item)
                                withAnimation { showSuccess = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { showSuccess = false }
                                }
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(currencyModel.canAfford(item.price) ? Color.green : Color.gray.opacity(0.5))
                        .cornerRadius(8)
                        .disabled(!currencyModel.canAfford(item.price))
                    }
                    .padding(.bottom, 20)
                }
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding(.horizontal, 30)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .zIndex(1)
            }
        }
    }

    // helper from former PurchaseConfirmationView
    private func getIconForItemType(_ type: ItemType) -> String {
        switch type {
        case .xpBooster: return "star.fill"
        case .coinBooster: return "dollarsign.circle.fill"
        case .timerExtender: return "timer"
        case .focusEnhancer: return "brain.head.profile"
        }
    }
}
