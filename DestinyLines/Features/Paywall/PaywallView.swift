import StoreKit
import SwiftUI

/// Paywall, rebuilt from components: live headline, the sliced crystal trophy, feature
/// trio, plan cards on the sliced frames (prices live from StoreKit, comp values as
/// placeholders until products load), and the green trial plate. Scrolls on small phones.
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("UNLOCK\nYOUR FULL\nDESTINY")
                            .font(.custom("Rye-Regular", size: 34, relativeTo: .largeTitle))
                            .foregroundStyle(Theme.goldBevel)
                            .lineSpacing(2)
                            .minimumScaleFactor(0.6)
                        Sparkle()
                        Text("Go deeper with unlimited, in-depth palm readings.")
                            .font(Typography.bodyText)
                            .foregroundStyle(Theme.goldLight)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image("crystal_trophy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 24)

                featureTrio
                    .padding(.horizontal, 22)

                planCards
                    .padding(.horizontal, 22)

                ArtPlateButton(style: .green, text: ctaTitle, enabled: !isPurchasing) {
                    Task { await buy() }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 500)

                footer
            }
            .padding(.bottom, 18)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .boothBackground()
        .overlay {
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

    // MARK: - Sections

    private var header: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("DESTINY")
                    .font(.custom("Rye-Regular", size: 22, relativeTo: .title2))
                Text("· LINES ·")
                    .font(.custom("Rye-Regular", size: 15, relativeTo: .title3))
            }
            .foregroundStyle(Theme.goldBevel)

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
            }
            .padding(.horizontal, 18)
        }
        .padding(.top, 8)
    }

    private var featureTrio: some View {
        ArtCard(contentPadding: 14) {
            HStack(alignment: .top, spacing: 8) {
                feature(icon: "infinity", label: "Unlimited\nreadings")
                divider
                feature(icon: "star.circle.fill", label: "In-depth\ninsights")
                divider
                feature(icon: "moon.stars.fill", label: "Save & share\nreadings")
            }
        }
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

    // MARK: - Plan cards

    private var planCards: some View {
        HStack(alignment: .bottom, spacing: 12) {
            planCard(
                id: StoreProducts.monthly,
                name: "MONTHLY",
                price: store.monthly?.displayPrice ?? "$4.99",
                per: "/month",
                highlight: false
            )
            planCard(
                id: StoreProducts.yearly,
                name: "YEARLY",
                price: store.yearly?.displayPrice ?? "$39.99",
                per: "/year",
                highlight: true
            )
        }
    }

    private func planCard(id: String, name: String, price: String, per: String, highlight: Bool) -> some View {
        let isSelected = selectedProductID == id

        return Button {
            selectedProductID = id
        } label: {
            VStack(spacing: 5) {
                if highlight {
                    Text("BEST VALUE")
                        .font(.custom("Rye-Regular", size: 10))
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

                Text(price)
                    .font(.custom("Rye-Regular", size: 30, relativeTo: .title))
                    .foregroundStyle(Theme.goldBevel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

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
            .padding(.vertical, 18)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(
                Image(highlight ? "plan_card_bulbs" : "plan_card_dark")
                    .resizable(
                        capInsets: EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40),
                        resizingMode: .stretch
                    )
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.goldLight, lineWidth: 2.5)
                        .shadow(color: Theme.glow.opacity(0.7), radius: 7)
                        .padding(2)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel("\(name), \(price) \(per)\(highlight ? ", best value, save 33 percent" : "")")
    }

    private var ctaTitle: String {
        guard let selectedProduct else { return "START FREE TRIAL" }
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
