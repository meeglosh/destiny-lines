import StoreKit
import SwiftUI

/// §9.10: restore purchases, manage subscription, "Your Privacy" explainer row,
/// policy/terms, delete account, contact — plus the entertainment disclaimer.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var confirmDelete = false
    @State private var deleteFailed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BannerHeader(title: "SETTINGS")
                    .padding(.horizontal, 80)

                VStack(spacing: Theme.cardSpacing) {
                    ListRow(
                        icon: "arrow.clockwise",
                        title: "RESTORE PURCHASES",
                        subtitle: isRestoring ? "Restoring..." : "Recover an existing subscription"
                    ) {
                        Task { await restore() }
                    }

                    ListRow(icon: "crown.fill", title: "MANAGE SUBSCRIPTION", subtitle: "Change or cancel your plan") {
                        openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                    }

                    // §6.1 — the dedicated privacy row.
                    ListRow(icon: "lock.shield.fill", title: "YOUR PRIVACY", subtitle: "How we handle your photo") {
                        appState.navigate(.privacyExplainer)
                    }

                    ListRow(icon: "doc.text.fill", title: "PRIVACY POLICY", subtitle: "The full policy") {
                        openURL(URL(string: "https://destinylines.app/privacy")!)
                    }

                    ListRow(icon: "doc.plaintext.fill", title: "TERMS OF USE", subtitle: "The rules of the road") {
                        openURL(URL(string: "https://destinylines.app/terms")!)
                    }

                    ListRow(icon: "envelope.fill", title: "CONTACT", subtitle: "Reach the keepers of the booth") {
                        openURL(URL(string: "mailto:support@destinylines.app")!)
                    }

                    ListRow(icon: "trash.fill", title: "DELETE ACCOUNT", subtitle: "Remove your data for good") {
                        confirmDelete = true
                    }
                }
                .padding(.horizontal, 24)

                OrnamentDivider()
                    .padding(.horizontal, 60)

                // Required disclaimer placement (§9).
                Text("Destiny Lines is for entertainment purposes only. Readings are not medical, psychological, financial, or legal advice.")
                    .font(Typography.fine)
                    .foregroundStyle(Theme.goldLight.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 24)
            }
            .padding(.vertical, 10)
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
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
        ScrollView {
            VStack(spacing: 16) {
                BannerHeader(title: "YOUR PRIVACY")
                    .padding(.horizontal, 64)

                OrnateCard {
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
                .padding(.horizontal, 24)

                Text("The full privacy policy names every processor and retention window.")
                    .font(Typography.fine)
                    .foregroundStyle(Theme.goldLight.opacity(0.7))
                    .padding(.bottom, 24)
            }
            .padding(.vertical, 10)
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
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
