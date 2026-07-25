import StoreKit
import SwiftUI

/// DL-paywall.png used directly. All pricing visuals are baked (and match the §7.6
/// products); this view adds hotspots, a selection ring, and the StoreKit flow.
/// The comp's aspect is wider than the device, so it letterboxes vertically over
/// the same near-black backdrop rather than stretching 20%.
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
        GeometryReader { proxy in
            let screen = CGSize(
                width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            )
            // Fill the screen. The art is slightly wider-aspect; anchor to the LEFT edge
            // so the close button stays whole and the crop falls on the right margin.
            let artWidth = max(screen.width, screen.height * (847.0 / 1578.0))
            let artHeight = artWidth * (1578.0 / 847.0)
            let frame = CGRect(
                x: -proxy.safeAreaInsets.leading,
                y: -proxy.safeAreaInsets.top - (artHeight - screen.height) / 2,
                width: artWidth,
                height: artHeight
            )
            let art = ArtGeometry(frame: frame)

            ZStack(alignment: .topLeading) {
                Theme.background.ignoresSafeArea()

                Image("bg_paywall")
                    .resizable()
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)

                ArtHotspot(rect: art.rect(0.015, 0.020, 0.13, 0.062), label: "Close",
                           debug: ArtDebug.showHotspots) {
                    dismiss()
                }

                // MONTHLY plan card
                planHotspot(art.rect(0.045, 0.643, 0.425, 0.190), id: StoreProducts.monthly,
                            label: "Monthly, $4.99 per month")

                // YEARLY plan card (baked as highlighted BEST VALUE)
                planHotspot(art.rect(0.505, 0.630, 0.455, 0.205), id: StoreProducts.yearly,
                            label: "Yearly, $39.99 per year, best value, save 33 percent")

                // START FREE TRIAL plate
                ArtHotspot(rect: art.rect(0.075, 0.856, 0.85, 0.075), label: ctaLabel,
                           debug: ArtDebug.showHotspots) {
                    Task { await buy() }
                }

                // Restore Purchases (right third of the footer row)
                ArtHotspot(rect: art.rect(0.63, 0.945, 0.35, 0.045), label: "Restore Purchases",
                           debug: ArtDebug.showHotspots) {
                    Task { await store.restore() }
                }

                if isPurchasing {
                    WorkingVeil(text: "Consulting the stars...")
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
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

    private var ctaLabel: String {
        guard let selectedProduct else { return "Subscribe" }
        let hasTrial = selectedProduct.subscription?.introductoryOffer?.paymentMode == .freeTrial
        return hasTrial ? "Start free trial" : "Subscribe"
    }

    @ViewBuilder
    private func planHotspot(_ rect: CGRect, id: String, label: String) -> some View {
        ArtHotspot(rect: rect, label: label, debug: ArtDebug.showHotspots) {
            selectedProductID = id
        }

        if selectedProductID == id {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.goldLight, lineWidth: 2.5)
                .shadow(color: Theme.glow.opacity(0.7), radius: 7)
                .artFrame(rect)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Purchase

    private func buy() async {
        guard let selectedProduct else {
            errorMessage = "Subscriptions are unavailable right now. Check your connection and try again."
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let outcome = try await store.purchase(selectedProduct)
            switch outcome {
            case .subscribed:
                dismiss()
            case .pending:
                errorMessage = "Your purchase is awaiting approval."
            case .cancelled:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
