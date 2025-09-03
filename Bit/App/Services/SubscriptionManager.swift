import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var subscriptionProduct: Product?
    @Published var isLoading = false
    @Published var purchaseSuccess = false
    @Published var purchaseError: Error?
    
    // Temporarily make pro features available by default
    @Published var hasProAccess = true
    private let enableSubscriptions = false // Set to true when ready to enable subscriptions

    private let productId = "BitBytePro"  // ← use the exact product identifier from App Store Connect

    init() {
        // Only load products if subscriptions are enabled
        if enableSubscriptions {
            Task { await loadProduct() }
        }
        // Set pro access to true by default (for free upload)
        hasProAccess = true
        UserDefaults.standard.set(true, forKey: "hasSubscription")
    }

    func loadProduct() async {
        // Skip loading if subscriptions are disabled
        guard enableSubscriptions else { return }
        
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [productId])
            // --- DEBUG: print all fetched product identifiers ---
            print("🛠 Debug – fetched products:", products.map { $0.id })

            subscriptionProduct = products.first
            print("✅ Loaded subscription: \(subscriptionProduct?.displayName ?? "none") @ \(subscriptionProduct?.displayPrice ?? "")")
        } catch {
            purchaseError = error
            print("⛔️ Failed fetching product: \(error)")
        }
    }

    func purchase() async {
        // If subscriptions are disabled, just mark as successful
        guard enableSubscriptions else {
            purchaseSuccess = true
            hasProAccess = true
            UserDefaults.standard.set(true, forKey: "hasSubscription")
            return
        }
        
        guard let product = subscriptionProduct else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseSuccess = true
                hasProAccess = true
                // ← persist Pro status
                UserDefaults.standard.set(true, forKey: "hasSubscription")
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
