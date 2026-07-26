import StoreKit
import SwiftUI

/// Settings tab: restore purchases, manage subscription, "Your Privacy" explainer row,
/// policy/terms, delete account — plus the entertainment disclaimer.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(StoreManager.self) private var store
    @Environment(\.openURL) private var openURL

    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var confirmDelete = false
    @State private var deleteFailed = false

    var body: some View {
        VStack(spacing: 12) {
            RibbonBanner(text: "SETTINGS")
                .padding(.horizontal, 80)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.cardSpacing) {
                    ArtListRow(
                        medallion: .symbol("arrow.clockwise"),
                        title: "RESTORE PURCHASES",
                        subtitle: isRestoring ? "Restoring..." : "Recover an existing subscription"
                    ) {
                        Task { await restore() }
                    }

                    ArtListRow(medallion: .symbol("crown.fill"), title: "MANAGE SUBSCRIPTION",
                               subtitle: "Change or cancel your plan") {
                        openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                    }

                    // §6.1 — the dedicated privacy row.
                    ArtListRow(medallion: .symbol("lock.shield.fill"), title: "YOUR PRIVACY",
                               subtitle: "How we handle your photo") {
                        appState.navigate(.privacyExplainer)
                    }

                    ArtListRow(medallion: .symbol("doc.text.fill"), title: "PRIVACY POLICY",
                               subtitle: "The full policy") {
                        openURL(URL(string: "https://destinylines.app/privacy")!)
                    }

                    ArtListRow(medallion: .symbol("doc.plaintext.fill"), title: "TERMS OF USE",
                               subtitle: "The rules of the road") {
                        openURL(URL(string: "https://destinylines.app/terms")!)
                    }

                    ArtListRow(medallion: .symbol("envelope.fill"), title: "CONTACT",
                               subtitle: "Reach the keepers of the booth") {
                        openURL(URL(string: "mailto:support@destinylines.app")!)
                    }

                    ArtListRow(medallion: .symbol("trash.fill"), title: "DELETE ACCOUNT",
                               subtitle: "Remove your data for good") {
                        confirmDelete = true
                    }

                    OrnamentDivider()
                        .padding(.horizontal, 40)

                    // Required disclaimer placement (§9).
                    Text("Destiny Lines is for entertainment purposes only. Readings are not medical, psychological, financial, or legal advice.")
                        .font(Typography.fine)
                        .foregroundStyle(Theme.goldLight.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 6)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .boothBackground()
        .alert("Restore Purchases", isPresented: Binding(get: { restoreMessage != nil }, set: { _ in restoreMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
        .alert("Delete your account?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your readings and profile permanently. Subscriptions are managed separately through the App Store.")
        }
        .alert("Something Went Wrong", isPresented: $deleteFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your account could not be deleted right now. Try again, or contact support.")
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        await store.restore()
        restoreMessage = store.isSubscribed
            ? "Your subscription has been restored."
            : "No active subscription was found for this Apple ID."
    }

    private func deleteAccount() async {
        do {
            try await SupabaseService.shared.deleteAccount()
            readingStore.removeAll()
            appState.tab = .home
            appState.phase = .launching
            appState.popToRoot()
        } catch {
            deleteFailed = true
        }
    }
}

/// The plain-language explainer behind Settings → Your Privacy (§6.1).
/// This is where the OpenAI processor disclosure lives.
struct PrivacyExplainerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                FlowHeader(title: "YOUR PRIVACY") { dismiss() }
                    .padding(.top, 4)

                ArtCard {
                    VStack(alignment: .leading, spacing: 14) {
                        privacyPoint(
                            icon: "timer",
                            title: "Your photo is deleted immediately",
                            body: "Your palm photo exists on our servers only for the seconds it takes to prepare your reading. As soon as your reading is ready — or if anything goes wrong — the photo is deleted. We never keep it, and it is never saved to your device by this app."
                        )
                        privacyPoint(
                            icon: "eye.slash.fill",
                            title: "No location, no identity",
                            body: "Before upload, the photo is re-encoded so it carries no location data, no device details, and no timestamps."
                        )
                        privacyPoint(
                            icon: "arrow.up.forward.app.fill",
                            title: "One trusted analyst",
                            body: "To create your reading, the photo is sent to OpenAI, the AI service that studies the lines. OpenAI may keep it briefly for safety monitoring — up to 30 days — and it is not used to train their models. Storage during upload is handled by Cloudflare."
                        )
                        privacyPoint(
                            icon: "iphone",
                            title: "Checked on your device first",
                            body: "Photos that don't show a hand are turned away on your device and never uploaded at all."
                        )
                    }
                }
                .padding(.horizontal, 22)
                .frame(maxWidth: 560)

                Text("The full privacy policy names every processor and retention window.")
                    .font(Typography.fine)
                    .foregroundStyle(Theme.goldLight.opacity(0.7))
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
        .boothBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func privacyPoint(icon: String, title: String, body text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconMedallion(systemName: icon, diameter: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Theme.gold)
                Text(text)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.goldLight)
            }
        }
    }
}
