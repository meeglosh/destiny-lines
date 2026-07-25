import StoreKit
import SwiftUI

/// Functional paywall. Layout and ornamentation come with the design system pass;
/// what matters here is that the purchase, restore, and entitlement paths are real.
struct PaywallView: View {
    @Environment(StoreManager.self) private var store

    @State private var selectedProductID = StoreProducts.yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductID }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("UNLOCK YOUR FULL DESTINY")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Go deeper with unlimited, in-depth palm readings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if store.isSubscribed {
                Label("Subscribed", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            if store.isLoadingProducts {
                ProgressView()
            } else if store.products.isEmpty {
                Text("Subscriptions are unavailable right now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.products) { product in
                    planRow(product)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await buy() }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                    } else {
                        Text(ctaTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedProduct == nil || isPurchasing || store.isSubscribed)

            Button("Restore Purchases") {
                Task { await store.restore() }
            }
            .font(.footnote)

            Text("For entertainment purposes only.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .task {
            await store.loadProducts()
            await store.refreshEntitlement()
        }
    }

    private var ctaTitle: String {
        guard let selectedProduct else { return "Continue" }
        let hasTrial = selectedProduct.subscription?.introductoryOffer?.paymentMode == .freeTrial
        return hasTrial ? "START FREE TRIAL" : "SUBSCRIBE"
    }

    @ViewBuilder
    private func planRow(_ product: Product) -> some View {
        let isSelected = product.id == selectedProductID

        Button {
            selectedProductID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    if let trial = product.subscription?.introductoryOffer,
                       trial.paymentMode == .freeTrial {
                        Text("\(trial.period.value)-day free trial")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.title3.bold())
            }
            .padding()
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.4),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func buy() async {
        guard let selectedProduct else { return }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let outcome = try await store.purchase(selectedProduct)
            if outcome == .pending {
                errorMessage = "Your purchase is awaiting approval."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
