import SwiftUI

struct PurchaseConfirmationView: View {
    let item: ShopItem
    let currencyModel: CurrencyModel
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onCancel()
                }
            
            // Confirmation card
            VStack(spacing: 16) {
                // Header
                Text("Purchase Item")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Item image (placeholder)
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: getIconForItemType(item.type))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                }
                .padding(.bottom, 10)
                
                // Item details
                Text(item.name)
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(item.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal)
                
                // Effect description
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text(item.effectDescription)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.green)
                        Text(item.durationDescription)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal)
                
                // Price
                HStack {
                    Image("coin") // Assumes you have a coin image asset
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    Text("\(item.price)")
                        .font(.headline)
                        .foregroundColor(currencyModel.canAfford(item.price) ? .white : .red)
                }
                
                // Buttons
                HStack(spacing: 20) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(TransparentButtonStyle())
                    
                    Button(action: onConfirm) {
                        Text("Purchase")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(currencyModel.canAfford(item.price) ? Color.green : Color.gray.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .disabled(!currencyModel.canAfford(item.price))
                }
                .padding(.bottom, 20)
            }
            .background(Color.secondary.opacity(0.2)) // Cross-platform background
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 30)
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func getIconForItemType(_ type: ItemType) -> String {
        switch type {
        case .xpBooster: return "star.fill"
        case .coinBooster: return "dollarsign.circle.fill"
        case .timerExtender: return "timer"
        case .focusEnhancer: return "brain.head.profile"
        }
    }
}
