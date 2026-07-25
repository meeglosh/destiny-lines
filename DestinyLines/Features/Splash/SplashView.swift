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
                .position(art.point(0.5, 0.945))
                .accessibilityLabel("Seeing possibilities")
        }
        .task { await start() }
    }

    private func start() async {
        async let floor: Void = { try? await Task.sleep(for: .seconds(1.2)) }()
        async let session: Void = { try? await SupabaseService.shared.ensureSession() }()
        _ = await (floor, session)
        onFinished()
    }
}
