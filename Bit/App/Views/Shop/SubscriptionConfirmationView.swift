import SwiftUI
import StoreKit

struct SubscriptionConfirmationView: View {
    @Binding var isPresented: Bool
    @ObservedObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("BitByte Pro")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                }
                
                // Product Info
                if let product = subscriptionManager.subscriptionProduct {
                    VStack(spacing: 16) {
                        Text(product.displayName)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        Text(product.displayPrice)
                            .font(.title)
                            .foregroundColor(.green)
                            .bold()
                        
                        // Benefits list
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "star.fill", text: "2x XP from all activities")
                            FeatureRow(icon: "dollarsign.circle.fill", text: "2x Coins from all sources")
                            FeatureRow(icon: "timer", text: "Extended time for challenges")
                            FeatureRow(icon: "brain.head.profile", text: "Enhanced focus abilities")
                        }
                        .padding(.vertical)
                    }
                    
                    Spacer()
                    
                    // Purchase Button
                    Button(action: {
                        Task { 
                            await subscriptionManager.purchase()
                            isPresented = false
                        }
                    }) {
                        if subscriptionManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Subscribe Now")
                                .font(.headline)
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(subscriptionManager.isLoading)
                    
                } else {
                    ProgressView("Loading subscription details...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    SubscriptionConfirmationView(
        isPresented: .constant(true),
        subscriptionManager: SubscriptionManager()
    )
}
