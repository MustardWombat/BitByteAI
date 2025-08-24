import SwiftUI
import StoreKit

struct SubscriptionConfirmationView: View {
    @Binding var isPresented: Bool
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var isRestoring = false
    @State private var restoreResultMessage: String?
    @State private var showRestoreAlert = false
    
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
                
                VStack(spacing: 16) {
                    Text(subscriptionManager.subscriptionProduct?.displayName ?? "Loading...")
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(subscriptionManager.subscriptionProduct?.displayPrice ?? "...")
                        .font(.title)
                        .foregroundColor(.green)
                        .bold()
                    
                    // Benefits list
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "star.fill", text: "2x XP from all activities")
                        FeatureRow(icon: "dollarsign.circle.fill", text: "2x Coins from all sources")
                        FeatureRow(icon: "folder.fill", text: "Unlimited categories")
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
                    Text("Subscribe Now")
                        .font(.headline)
                        .bold()
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
                .disabled(subscriptionManager.isLoading || isRestoring)
                
                // Restore Purchase Button
                Button(action: {
                    Task {
                        isRestoring = true
                        do {
                            await subscriptionManager.loadProduct()
                            try await AppStore.sync()
                            restoreResultMessage = "Restore completed successfully."
                        } catch {
                            restoreResultMessage = "Restore failed: \(error.localizedDescription)"
                        }
                        isRestoring = false
                        showRestoreAlert = true
                    }
                }) {
                    Text("Restore Purchase")
                        .font(.headline)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(subscriptionManager.isLoading || isRestoring)
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
            .alert(restoreResultMessage ?? "", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) { }
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
