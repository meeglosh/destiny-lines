import SwiftUI

/// Launch screen over the painted splash background — the wordmark, hand and tagline are
/// all painted. This adds only the progress indicator, performs anonymous sign-in, and
/// holds for a minimum of 3 seconds so it never flashes past (§9.1).
struct SplashView: View {
    let onFinished: () -> Void

    @State private var progress: CGFloat = 0.05

    var body: some View {
        ArtScreen(image: "bg_splash", cover: true, ignoresSafeAreaEdges: .all) { art in
            VStack(spacing: art.frame.height * 0.010) {
                Text("SEEING POSSIBILITIES...")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.0125)))
                    .kerning(1.6)
                    .foregroundStyle(Theme.gold.opacity(0.9))

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Theme.gold)
                    .frame(width: art.frame.width * 0.42)
            }
            .artFrame(art.rect(0.20, 0.905, 0.60, 0.06))
            .accessibilityLabel("Seeing possibilities")
        }
        .task { await start() }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4)) { progress = 0.9 }
        }
    }

    /// Minimum time on screen — long enough to read the booth and hear the music start.
    private static let minimumDisplay: Duration = .seconds(3)

    private func start() async {
        // Sign-in runs alongside the floor, so a slow network can extend the splash but
        // a fast one can never cut it short.
        async let floor: Void = { try? await Task.sleep(for: Self.minimumDisplay) }()
        async let session: Void = { try? await SupabaseService.shared.ensureSession() }()
        _ = await (floor, session)

        withAnimation(.easeOut(duration: 0.2)) { progress = 1 }
        try? await Task.sleep(for: .milliseconds(180))
        onFinished()
    }
}
