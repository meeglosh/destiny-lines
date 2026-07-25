import Foundation
import StoreKit

/// Result of attempting a purchase, in terms the paywall cares about.
enum PurchaseOutcome: Equatable {
    case subscribed
    case pending
    case cancelled
}

enum StoreError: LocalizedError {
    case failedVerification
    case productUnavailable

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "That purchase could not be verified. Please try again."
        case .productUnavailable:
            return "That subscription is not available right now."
        }
    }
}

/// StoreKit 2 wrapper. Owns product loading, purchasing, and the local view of entitlement.
///
/// Entitlement shown here is a convenience for the UI. `analyze-palm` enforces entitlement
/// server-side (CLAUDE.md §6.5), and this type mirrors transactions up to Supabase so the
/// server has something to enforce against.
@Observable
@MainActor
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var isSubscribed = false
    private(set) var isLoadingProducts = false

    /// Called with the signed transaction JWS whenever entitlement changes, so it can be
    /// POSTed to the `verify-subscription` Edge Function. Set by the app layer once the
    /// Supabase client exists; unset until then, which leaves the local entitlement intact.
    var mirrorEntitlement: ((String) async -> Void)?

    private var updatesTask: Task<Void, Never>?

    var monthly: Product? { products.first { $0.id == StoreProducts.monthly } }
    var yearly: Product? { products.first { $0.id == StoreProducts.yearly } }

    init() {
        // Must run for the app's lifetime to catch renewals, refunds, Ask-to-Buy approvals,
        // and purchases made on another device (CLAUDE.md §7.8).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(update)
            }
        }
    }

    // No deinit cancelling `updatesTask`: this type is app-scoped and the listener is meant
    // to run for the app's lifetime, so there is no teardown path to handle.

    // MARK: - Products

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: StoreProducts.all)
            // Preserve the order declared in StoreProducts rather than StoreKit's ordering.
            products = StoreProducts.all.compactMap { id in
                loaded.first { $0.id == id }
            }
        } catch {
            products = []
        }
    }

    // MARK: - Purchasing

    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await mirror(verification)
            await transaction.finish()
            await refreshEntitlement()
            return .subscribed

        case .pending:
            // Ask-to-Buy or SCA. The Transaction.updates listener picks it up on approval.
            return .pending

        case .userCancelled:
            return .cancelled

        @unknown default:
            return .cancelled
        }
    }

    /// Restore Purchases, required on the paywall (CLAUDE.md §7.8).
    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    // MARK: - Entitlement

    /// Recompute entitlement from StoreKit. Call on launch and on every foreground.
    func refreshEntitlement() async {
        var entitled = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expiry = transaction.expirationDate, expiry <= Date() { continue }
            if StoreProducts.all.contains(transaction.productID) {
                entitled = true
                await mirror(result)
            }
        }

        isSubscribed = entitled
    }

    // MARK: - Private

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard let transaction = try? checkVerified(result) else { return }
        await mirror(result)
        await transaction.finish()
        await refreshEntitlement()
    }

    /// Never trust an `unverified` result (CLAUDE.md §7.8).
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// Push the signed transaction to the server so entitlement is enforceable there.
    /// Failure here is deliberately silent: if the server cannot be reached but StoreKit
    /// says the user is subscribed, we fail open toward the paying customer and reconcile
    /// on a later refresh (CLAUDE.md §7.8).
    private func mirror(_ result: VerificationResult<Transaction>) async {
        guard let mirrorEntitlement else { return }
        await mirrorEntitlement(result.jwsRepresentation)
    }
}
