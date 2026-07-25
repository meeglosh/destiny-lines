import StoreKit
import StoreKitTest
import Testing
@testable import DestinyLines

/// Exercises the real StoreKit 2 purchase path against the local Products.storekit
/// configuration, so the flow is verified without App Store Connect or a paid account.
/// Serialized: each test drives one global StoreKit test session, so they cannot overlap.
///
/// Disabled: local StoreKit testing is broken on this development machine's toolchain
/// (Xcode 26.6 + iOS 26.4/26.5 simulators). Proven by control experiment — a minimal
/// from-scratch project with its own .storekit config also loads zero products, from
/// both `xcodebuild` and the Xcode GUI, and SKTestSession operations fail with
/// SKInternalErrorDomain Code=3. Re-enable on a machine where StoreKit testing works;
/// the paywall purchase path is additionally covered by DestinyLinesUITests, which
/// self-skips under the same broken environment.
@MainActor
@Suite(.serialized, .disabled("Local StoreKit testing is broken on this toolchain (see comment); re-enable on a working environment"))
struct StoreManagerTests {

    /// Products.storekit ships read-only inside the code-signed app bundle, but SKTestSession
    /// writes back to the file it is handed, so copy it somewhere writable first.
    private func writableConfigURL() throws -> URL {
        let appBundle = Bundle(for: StoreManager.self)
        let source = try #require(appBundle.url(forResource: "Products", withExtension: "storekit"))
        let destination = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("Products.storekit")

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(contentsOf: try writableConfigURL())
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        return session
    }

    @Test func loadsBothProductsInDeclaredOrder() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = StoreManager()
        await store.loadProducts()

        #expect(store.products.map(\.id) == StoreProducts.all)
        #expect(store.monthly?.displayPrice == "$4.99")
        #expect(store.yearly?.displayPrice == "$39.99")
    }

    @Test func yearlyOffersAThreeDayFreeTrial() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = StoreManager()
        await store.loadProducts()

        let offer = try #require(store.yearly?.subscription?.introductoryOffer)
        #expect(offer.paymentMode == .freeTrial)
        #expect(offer.period.unit == .day)
        #expect(offer.period.value == 3)
    }

    @Test func startsUnsubscribed() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = StoreManager()
        await store.refreshEntitlement()

        #expect(store.isSubscribed == false)
    }

    @Test func purchasingMonthlyGrantsEntitlement() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = StoreManager()
        await store.loadProducts()
        let monthly = try #require(store.monthly)

        let outcome = try await store.purchase(monthly)

        #expect(outcome == .subscribed)
        #expect(store.isSubscribed == true)
    }

    @Test func purchasingYearlyGrantsEntitlement() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = StoreManager()
        await store.loadProducts()
        let yearly = try #require(store.yearly)

        let outcome = try await store.purchase(yearly)

        #expect(outcome == .subscribed)
        #expect(store.isSubscribed == true)
    }

    @Test func expiredSubscriptionDoesNotEntitle() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = StoreManager()
        await store.loadProducts()
        let monthly = try #require(store.monthly)
        _ = try await store.purchase(monthly)
        #expect(store.isSubscribed == true)

        // Expire every transaction, then re-derive entitlement from StoreKit.
        try session.expireSubscription(productIdentifier: StoreProducts.monthly)
        await store.refreshEntitlement()

        #expect(store.isSubscribed == false)
    }

    @Test func refundedSubscriptionDoesNotEntitle() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = StoreManager()
        await store.loadProducts()
        let monthly = try #require(store.monthly)
        _ = try await store.purchase(monthly)

        let transaction = try #require(session.allTransactions().first)
        try await session.refundTransaction(identifier: UInt(transaction.identifier))
        await store.refreshEntitlement()

        #expect(store.isSubscribed == false)
    }

    @Test func entitlementIsMirroredForServerVerification() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let store = StoreManager()
        let mirrored = Mirrored()
        store.mirrorEntitlement = { jws in await mirrored.record(jws) }

        await store.loadProducts()
        let monthly = try #require(store.monthly)
        _ = try await store.purchase(monthly)

        let received = await mirrored.values
        #expect(received.isEmpty == false)
        // A signed JWS, which is what verify-subscription validates.
        #expect(received.allSatisfy { $0.split(separator: ".").count == 3 })
    }
}

private actor Mirrored {
    private(set) var values: [String] = []

    func record(_ jws: String) {
        values.append(jws)
    }
}
