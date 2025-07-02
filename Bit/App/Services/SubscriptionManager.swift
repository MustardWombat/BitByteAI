import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var subscriptionProduct: Product?
    @Published var isLoading = false
    @Published var purchaseSuccess = false
    @Published var purchaseError: Error?

    private let productId = "BitBytePro"  // ← use the exact product identifier from App Store Connect

    init() {
        Task { await loadProduct() }
    }

    func loadProduct() async {
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
        guard let product = subscriptionProduct else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseSuccess = true
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
