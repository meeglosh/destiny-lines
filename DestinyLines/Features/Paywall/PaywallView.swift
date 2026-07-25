import StoreKit
import SwiftUI

/// DL-paywall.png: close button + wordmark, "UNLOCK YOUR FULL DESTINY", crystal-ball
/// emblem with "YOUR FUTURE AWAITS" plinth, feature trio card, MONTHLY / YEARLY plan
/// cards (yearly ringed with bulbs and badged BEST VALUE / SAVE 33%), green START FREE
/// TRIAL CTA, and the trial / cancel / restore footer.
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
        ScrollView {
            VStack(spacing: 18) {
                header

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("UNLOCK\nYOUR FULL\nDESTINY")
                            .font(Typography.wordmark)
                            .foregroundStyle(Theme.goldBevel)
                            .lineSpacing(2)
                        Sparkle()
                        Text("Go deeper with unlimited, in-depth palm readings.")
                            .font(Typography.bodyText)
                            .foregroundStyle(Theme.goldLight)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    crystalEmblem
                }
                .padding(.horizontal, 24)

                featureTrio

                planCards

                cta

                footer
            }
            .padding(.vertical, 12)
        }
        .screenBackground()
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

    // MARK: - Sections

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle().strokeBorder(Theme.gold.opacity(0.8), lineWidth: 1.4)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Close")

            Spacer()

            VStack(spacing: 0) {
                Text("DESTINY")
                    .font(.custom("Rye-Regular", size: 22, relativeTo: .title2))
                Text("· LINES ·")
                    .font(.custom("Rye-Regular", size: 16, relativeTo: .title3))
            }
            .foregroundStyle(Theme.goldBevel)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
    }

    private var crystalEmblem: some View {
        VStack(spacing: -6) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.glow.opacity(0.9), Theme.crimson.opacity(0.7)],
                            center: .init(x: 0.5, y: 0.4),
                            startRadius: 6,
                            endRadius: 70
                        )
                    )
                Circle()
                    .strokeBorder(Theme.goldBevel, lineWidth: 2)
                Image(systemName: "hand.raised.fingers.spread.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.goldLight)
                    .shadow(color: Theme.glow, radius: 12)
            }
            .frame(width: 130, height: 130)

            OrnateCard(contentPadding: 8) {
                Text("YOUR FUTURE\nAWAITS")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.goldLight)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: 130)
        }
        .accessibilityHidden(true)
    }

    private var featureTrio: some View {
        OrnateCard(contentPadding: 14) {
            HStack(alignment: .top, spacing: 8) {
                feature(icon: "infinity", label: "Unlimited\nreadings")
                divider
                feature(icon: "star.circle.fill", label: "In-depth\ninsights")
                divider
                feature(icon: "moon.stars.fill", label: "Save & share\nreadings")
            }
        }
        .padding(.horizontal, 24)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.goldDark.opacity(0.6))
            .frame(width: 1, height: 74)
    }

    private func feature(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            IconMedallion(systemName: icon, diameter: 46)
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.goldLight)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var planCards: some View {
        HStack(spacing: 14) {
            if store.isLoadingProducts {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.gold)
                    .frame(maxWidth: .infinity, minHeight: 170)
            } else if store.products.isEmpty {
                OrnateCard {
                    Text("Subscriptions are unavailable right now.")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.goldLight)
                }
            } else {
                if let monthly = store.monthly {
                    planCard(monthly, name: "MONTHLY", per: "/month", highlight: false)
                }
                if let yearly = store.yearly {
                    planCard(yearly, name: "YEARLY", per: "/year", highlight: true)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func planCard(_ product: Product, name: String, per: String, highlight: Bool) -> some View {
        let isSelected = product.id == selectedProductID

        return Button {
            selectedProductID = product.id
        } label: {
            VStack(spacing: 6) {
                if highlight {
                    Text("BEST VALUE")
                        .font(Typography.fine)
                        .kerning(1)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.parchment))
                }

                Text(name)
                    .font(Typography.heading)
                    .foregroundStyle(Theme.goldLight)

                Sparkle(size: 9)

                Text(product.displayPrice)
                    .font(.custom("Rye-Regular", size: 30, relativeTo: .title))
                    .foregroundStyle(Theme.goldBevel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(per)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.goldLight.opacity(0.8))

                if highlight {
                    Text("SAVE 33%")
                        .font(Typography.fine)
                        .kerning(1)
                        .foregroundStyle(Theme.goldLight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0x1E / 255, green: 0x46 / 255, blue: 0x2B / 255))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Theme.goldDark, lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 186)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(highlight ? AnyShapeStyle(Theme.crimsonFill) : AnyShapeStyle(Theme.panel))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? AnyShapeStyle(Theme.goldBevel) : AnyShapeStyle(Theme.goldDark.opacity(0.8)),
                                lineWidth: isSelected ? 2.5 : 1.5
                            )
                    )
            )
            .overlay {
                if highlight {
                    bulbRing
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel("\(name), \(product.displayPrice) \(per)\(highlight ? ", best value, save 33 percent" : "")")
    }

    private var bulbRing: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let points = MarqueeFrame<EmptyView>.bulbPositions(in: rect, cornerRadius: 12, spacing: 26)
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                MarqueeBulb(size: 4)
                    .position(point)
            }
        }
        .allowsHitTesting(false)
    }

    private var cta: some View {
        Button {
            Task { await buy() }
        } label: {
            HStack(spacing: 12) {
                Sparkle()
                Group {
                    if isPurchasing {
                        ProgressView().tint(Theme.goldLight)
                    } else {
                        Text(ctaTitle)
                            .font(Typography.cta)
                    }
                }
                Sparkle()
            }
            .foregroundStyle(Theme.goldBevel)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0x2A / 255, green: 0x54 / 255, blue: 0x33 / 255),
                                Color(red: 0x17 / 255, green: 0x33 / 255, blue: 0x1E / 255),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Theme.goldBevel, lineWidth: 2.5)
                    )
                    .shadow(color: Theme.glow.opacity(0.3), radius: 12)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(selectedProduct == nil || isPurchasing || store.isSubscribed)
        .opacity(selectedProduct == nil ? 0.5 : 1)
        .padding(.horizontal, 24)
    }

    private var ctaTitle: String {
        guard let selectedProduct else { return "CONTINUE" }
        let hasTrial = selectedProduct.subscription?.introductoryOffer?.paymentMode == .freeTrial
        return hasTrial ? "START FREE TRIAL" : "SUBSCRIBE"
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Label("3-day free trial", systemImage: "star.fill")
            Text("·")
            Text("Cancel anytime")
            Text("·")
            Button {
                Task { await store.restore() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        }
        .font(Typography.fine)
        .foregroundStyle(Theme.goldLight.opacity(0.8))
        .padding(.bottom, 18)
    }

    // MARK: - Purchase

    private func buy() async {
        guard let selectedProduct else { return }
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
