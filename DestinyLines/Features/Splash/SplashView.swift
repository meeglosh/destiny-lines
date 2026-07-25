import SwiftUI

/// DL-splashScreen.png used directly. The comp bakes in the wordmark, tagline banner,
/// and "SEEING POSSIBILITIES..." footer; this view only performs anonymous sign-in
/// with the 1.2s minimum display (§9.1) and a subtle progress shimmer.
struct SplashView: View {
    let onFinished: () -> Void

    var body: some View {
        ArtScreen(image: "bg_splash") { art in
            ProgressView()
                .tint(Theme.gold)
                .artFrame(art.rect(0.35, 0.925, 0.30, 0.040))
                .accessibilityLabel("Seeing possibilities")
        }
        .task { await start() }
    }

    /// Minimum time the splash stays up. Long enough to read the booth and hear the
    /// music start, rather than flashing past.
    private static let minimumDisplay: Duration = .seconds(3)

    private func start() async {
        // Sign-in runs concurrently with the floor, so a slow network delays the splash
        // but a fast one never shortens it.
        async let floor: Void = { try? await Task.sleep(for: Self.minimumDisplay) }()
        async let session: Void = { try? await SupabaseService.shared.ensureSession() }()
        _ = await (floor, session)
        onFinished()
    }
}
