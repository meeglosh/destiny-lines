import StoreKit
import SwiftUI

/// Paywall over the painted background: the crystal trophy, feature wells, plan card
/// frames and the green CTA plate are painted; prices come live from StoreKit.
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID = StoreProducts.yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductID }
    }

    var body: some View {
        ArtScreen(image: "bg_paywall") { art in
            // Close control, top left.
            Button { dismiss() } label: {
                ZStack {
                    Circle().strokeBorder(Theme.gold.opacity(0.8), lineWidth: 1.4)
                    Image(systemName: "xmark")
                        .font(.system(size: art.fontSize(0.014), weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
            }
            .buttonStyle(ArtPressStyle())
            .artFrame(art.rect(0.075, 0.040, 0.085, 0.048))
            .accessibilityLabel("Close")

            // Headline beside the painted crystal.
            VStack(alignment: .leading, spacing: art.frame.height * 0.008) {
                Text("UNLOCK\nYOUR FULL\nDESTINY")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.030)))
                    .foregroundStyle(Theme.goldBevel)
                    .lineSpacing(1)
                    .minimumScaleFactor(0.6)
                Sparkle(size: art.fontSize(0.013))
                Text("Go deeper with unlimited, in-depth palm readings.")
                    .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0135)))
                    .foregroundStyle(Theme.goldLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .artFrame(art.rect(0.115, 0.135, 0.40, 0.21), alignment: .topLeading)
            .allowsHitTesting(false)

            // Feature wells — icons and captions over the painted dividers.
            // Icons sit in the painted wells; captions live on the row beneath them.
            HStack(spacing: 0) {
                featureIcon(art, "infinity")
                featureIcon(art, "star.circle.fill")
                featureIcon(art, "moon.stars.fill")
            }
            .artFrame(art.rect(0.12, 0.498, 0.78, 0.042))
            .allowsHitTesting(false)

            HStack(spacing: 0) {
                featureLabel(art, "Unlimited\nreadings")
                featureLabel(art, "In-depth\ninsights")
                featureLabel(art, "Save & share\nreadings")
            }
            .artFrame(art.rect(0.10, 0.548, 0.82, 0.048))
            .allowsHitTesting(false)

            // Plan cards.
            planCard(art, rect: art.rect(0.125, 0.655, 0.33, 0.145),
                     id: StoreProducts.monthly, name: "MONTHLY",
                     price: store.monthly?.displayPrice ?? "$4.99", per: "/month", highlight: false)

            planCard(art, rect: art.rect(0.535, 0.660, 0.34, 0.140),
                     id: StoreProducts.yearly, name: "YEARLY",
                     price: store.yearly?.displayPrice ?? "$39.99", per: "/year", highlight: true)

            // Green CTA plate.
            HStack(spacing: art.frame.width * 0.03) {
                Sparkle(size: art.fontSize(0.012))
                Text(ctaTitle)
                    .font(.custom("Rye-Regular", size: art.fontSize(0.0215)))
                    .kerning(1.2)
                    .foregroundStyle(Theme.goldBevel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                Sparkle(size: art.fontSize(0.012))
            }
            .artFrame(art.rect(0.16, 0.840, 0.68, 0.052))
            .allowsHitTesting(false)

            ArtHotspot(rect: art.rect(0.12, 0.828, 0.76, 0.078), label: ctaTitle) {
                Task { await buy() }
            }

            // Footer row.
            HStack(spacing: art.frame.width * 0.03) {
                Label("3-day free trial", systemImage: "star.fill")
                Text("·")
                Text("Cancel anytime")
            }
            .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0112)))
            .foregroundStyle(Theme.goldLight.opacity(0.8))
            .artFrame(art.rect(0.10, 0.918, 0.50, 0.032))
            .allowsHitTesting(false)

            Button { Task { await store.restore() } } label: {
                Label("Restore", systemImage: "arrow.clockwise")
                    .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0112)))
                    .foregroundStyle(Theme.goldLight.opacity(0.85))
            }
            .buttonStyle(ArtPressStyle())
            .artFrame(art.rect(0.63, 0.918, 0.28, 0.032))
            .accessibilityLabel("Restore Purchases")

            if isPurchasing {
                WorkingVeil(text: "Consulting the stars...")
            }
        }
        .task {
            await store.loadProducts()
            await store.refreshEntitlement()
        }
        .alert("A Cloud Passes", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: store.isSubscribed) { _, subscribed in
            if subscribed { dismiss() }
        }
    }

    private func featureIcon(_ art: ArtGeometry, _ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: art.fontSize(0.019), weight: .medium))
            .foregroundStyle(Theme.goldBevel)
            .frame(maxWidth: .infinity)
    }

    private func featureLabel(_ art: ArtGeometry, _ label: String) -> some View {
        Text(label)
            .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0105)))
            .foregroundStyle(Theme.goldLight.opacity(0.9))
            .multilineTextAlignment(.center)
            .lineSpacing(-1)
            .minimumScaleFactor(0.65)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func planCard(
        _ art: ArtGeometry, rect: CGRect, id: String,
        name: String, price: String, per: String, highlight: Bool
    ) -> some View {
        let isSelected = selectedProductID == id

        VStack(spacing: art.frame.height * 0.004) {
            Text(name)
                .font(.custom("Rye-Regular", size: art.fontSize(0.0175)))
                .foregroundStyle(Theme.goldLight)
            Sparkle(size: art.fontSize(0.009))
            Text(price)
                .font(.custom("Rye-Regular", size: art.fontSize(0.030)))
                .foregroundStyle(Theme.goldBevel)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(per)
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0118)))
                .foregroundStyle(Theme.goldLight.opacity(0.8))
            if highlight {
                Text("SAVE 33%")
                    .font(.custom("AlegreyaSans-Bold", size: art.fontSize(0.0105)))
                    .kerning(0.8)
                    .foregroundStyle(Theme.goldLight)
            }
        }
        .artFrame(rect)
        .allowsHitTesting(false)

        if isSelected {
            RoundedRectangle(cornerRadius: rect.width * 0.07)
                .strokeBorder(Theme.goldLight, lineWidth: 2)
                .shadow(color: Theme.glow.opacity(0.65), radius: 6)
                .artFrame(rect.insetBy(dx: -rect.width * 0.03, dy: -rect.height * 0.03))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }

        ArtHotspot(rect: rect.insetBy(dx: -rect.width * 0.04, dy: -rect.height * 0.05),
                   label: "\(name), \(price) \(per)\(highlight ? ", best value, save 33 percent" : "")") {
            selectedProductID = id
        }
    }

    private var ctaTitle: String {
        guard let selectedProduct else { return "START FREE TRIAL" }
        let hasTrial = selectedProduct.subscription?.introductoryOffer?.paymentMode == .freeTrial
        return hasTrial ? "START FREE TRIAL" : "SUBSCRIBE"
    }

    private func buy() async {
        guard let selectedProduct else {
            errorMessage = "Subscriptions are unavailable right now. Check your connection and try again."
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            switch try await store.purchase(selectedProduct) {
            case .subscribed: dismiss()
            case .pending:    errorMessage = "Your purchase is awaiting approval."
            case .cancelled:  break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
