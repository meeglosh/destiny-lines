import SwiftUI

/// Launch screen per DL-splashScreen.png: wordmark over an ornate dark stage,
/// banner tagline, and a slim progress bar with "SEEING POSSIBILITIES...".
/// Performs anonymous sign-in and entitlement refresh; visible ≥1.2s so it never flashes.
struct SplashView: View {
    let onFinished: () -> Void

    @State private var progress: CGFloat = 0.05

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 6) {
                Text("DESTINY")
                    .font(Typography.wordmark)
                Text("LINES")
                    .font(Typography.wordmark)
            }
            .foregroundStyle(Theme.goldBevel)
            .shadow(color: Theme.glow.opacity(0.45), radius: 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Destiny Lines")

            Spacer().frame(height: 26)

            // Ornate hand emblem between lanterns, simplified from the comp's illustration.
            IconMedallion(systemName: "hand.raised.fill", diameter: 120)
                .shadow(color: Theme.glow.opacity(0.35), radius: 22)

            Spacer().frame(height: 30)

            BannerHeader(title: "YOUR FUTURE IS IN YOUR HANDS")
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                OrnamentDivider()
                    .padding(.horizontal, 90)

                Text("SEEING POSSIBILITIES...")
                    .font(Typography.displaySmall)
                    .kerning(2)
                    .foregroundStyle(Theme.gold)

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Theme.gold)
                    .frame(width: 200)
            }
            .padding(.bottom, 60)
        }
        .screenBackground()
        .task { await start() }
    }

    private func start() async {
        withAnimation(.easeInOut(duration: 1.1)) { progress = 0.85 }

        // Floor of 1.2s so the splash never flashes (§9.1), in parallel with real work.
        async let floor: Void = { try? await Task.sleep(for: .seconds(1.2)) }()
        async let session: Void = { try? await SupabaseService.shared.ensureSession() }()
        _ = await (floor, session)

        withAnimation(.easeOut(duration: 0.2)) { progress = 1 }
        try? await Task.sleep(for: .seconds(0.2))
        onFinished()
    }
}
