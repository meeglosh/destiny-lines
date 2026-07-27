import StoreKit
import SwiftUI

/// Settings has no comp, so it's composed on the reusable ornate frame with a live title
/// and component row plates — which also lets the row list grow without redrawing art.
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
        ArtScreen(image: "bg_frame") { art in
            VStack(spacing: art.frame.height * 0.004) {
                Text("SETTINGS")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.030)))
                    .foregroundStyle(Theme.goldBevel)
                    .shadow(color: Theme.glow.opacity(0.35), radius: 8)
                OrnamentDivider()
                    .frame(width: art.frame.width * 0.5)
            }
            .artFrame(art.rect(0.15, 0.085, 0.70, 0.06))

            ScrollView(showsIndicators: false) {
                VStack(spacing: art.frame.height * 0.012) {
                    ArtRow(icon: "arrow.clockwise", title: "RESTORE PURCHASES",
                           subtitle: isRestoring ? "Restoring..." : "Recover a subscription") {
                        Task { await restore() }
                    }
                    ArtRow(icon: "crown.fill", title: "MANAGE SUBSCRIPTION",
                           subtitle: "Change or cancel your plan") {
                        openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                    }
                    // §6.1 — the dedicated privacy row.
                    ArtRow(icon: "lock.shield.fill", title: "YOUR PRIVACY",
                           subtitle: "How we handle your photo") {
                        appState.navigate(.privacyExplainer)
                    }
                    ArtRow(icon: "doc.text.fill", title: "PRIVACY POLICY", subtitle: "The full policy") {
                        openURL(URL(string: "https://destinylines.app/privacy")!)
                    }
                    ArtRow(icon: "doc.plaintext.fill", title: "TERMS OF USE", subtitle: "The rules of the road") {
                        openURL(URL(string: "https://destinylines.app/terms")!)
                    }
                    ArtRow(icon: "envelope.fill", title: "CONTACT", subtitle: "Reach the keepers of the booth") {
                        openURL(URL(string: "mailto:support@destinylines.app")!)
                    }
                    ArtRow(icon: "trash.fill", title: "DELETE ACCOUNT", subtitle: "Remove your data for good") {
                        confirmDelete = true
                    }

                    // Required disclaimer placement (§9).
                    Text("Destiny Lines is for entertainment purposes only. Readings are not medical, psychological, financial, or legal advice.")
                        .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0108)))
                        .foregroundStyle(Theme.goldLight.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, art.frame.height * 0.012)
                        .padding(.horizontal, 12)
                }
                .padding(.vertical, art.frame.height * 0.008)
            }
            .artFrame(art.rect(0.10, 0.165, 0.80, 0.645))
        }
        .alert("Restore Purchases", isPresented: Binding(get: { restoreMessage != nil }, set: { _ in restoreMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
        .alert("Delete your account?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { Task { await deleteAccount() } }
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

/// The plain-language explainer behind Settings → Your Privacy (§6.1), where the OpenAI
/// processor disclosure lives.
struct PrivacyExplainerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ArtScreen(image: "bg_frame") { art in
            BackButton { dismiss() }
                .artFrame(art.rect(0.055, 0.062, 0.12, 0.045))

            Text("YOUR PRIVACY")
                .font(.custom("Rye-Regular", size: art.fontSize(0.026)))
                .foregroundStyle(Theme.goldBevel)
                .artFrame(art.rect(0.20, 0.085, 0.60, 0.05))

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    point("timer", "Your photo is deleted immediately",
                          "Your palm photo exists on our servers only for the seconds it takes to prepare your reading. As soon as your reading is ready — or if anything goes wrong — the photo is deleted. We never keep it, and it is never saved to your device by this app.")
                    point("eye.slash.fill", "No location, no identity",
                          "Before upload, the photo is re-encoded so it carries no location data, no device details, and no timestamps.")
                    point("arrow.up.forward.app.fill", "One trusted analyst",
                          "To create your reading, the photo is sent to OpenAI, the AI service that studies the lines. OpenAI may keep it briefly for safety monitoring — up to 30 days — and it is not used to train their models. Storage during upload is handled by Cloudflare.")
                    point("iphone", "Checked on your device first",
                          "Photos that don't show a hand are turned away on your device and never uploaded at all.")

                    Text("The full privacy policy names every processor and retention window.")
                        .font(Typography.fine)
                        .foregroundStyle(Theme.goldLight.opacity(0.7))
                        .padding(.top, 4)
                }
                .padding(.vertical, 10)
            }
            .artFrame(art.rect(0.115, 0.165, 0.77, 0.70))
        }
    }

    private func point(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconMedallion(systemName: icon, diameter: 38)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Theme.gold)
                Text(body)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.goldLight)
            }
        }
    }
}
