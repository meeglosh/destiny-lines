import SwiftUI

/// Home over the painted main-menu background. The arch, wordmark, hand medallion and
/// the plates for the CTA and three rows are all painted; this view supplies the live
/// labels, icons and behaviour, positioned in the background's own coordinate space.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(AudioPlayer.self) private var audio

    var body: some View {
        ArtScreen(image: "bg_home", scrollable: true, bottomInset: 90) { art in
            // Sound toggle in the painted medallion well, top left.
            MuteButton(isMuted: audio.isMuted) { audio.toggleMute() }
                .artFrame(art.rect(0.055, 0.048, 0.115, 0.055))

            // Caption plate under the medallion.
            Text("ANALYZE YOUR PALM.\nDISCOVER YOUR DESTINY.")
                .font(.custom("Rye-Regular", size: art.fontSize(0.0125)))
                .kerning(1)
                .foregroundStyle(Theme.goldLight)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .artFrame(art.rect(0.16, 0.552, 0.68, 0.042))
                .allowsHitTesting(false)

            // NEW READING marquee plate.
            plateLabel("NEW READING", art: art, size: 0.0245)
                .artFrame(art.rect(0.14, 0.601, 0.72, 0.055))
                .allowsHitTesting(false)

            ArtHotspot(rect: art.rect(0.115, 0.592, 0.77, 0.075), label: "New Reading") {
                appState.navigate(.capture)
            }

            // Three painted rows.
            row(art: art, y: 0.700, icon: "hand.raised.fill",
                title: "MY READINGS", subtitle: "View your past readings") {
                appState.tab = .history
            }
            row(art: art, y: 0.778, icon: "square.and.arrow.up",
                title: "SHARE", subtitle: "Share your reading") {
                if let latest = readingStore.readings.first {
                    appState.navigate(.share(latest))
                } else {
                    appState.navigate(.capture)
                }
            }
            row(art: art, y: 0.856, icon: "gearshape.fill",
                title: "SETTINGS", subtitle: "Customize your experience") {
                appState.tab = .settings
            }

            // Footer motto flanking the painted crystal.
            HStack {
                Text("TRUST THE SIGNS.")
                Spacer()
                Text("FOLLOW YOUR PATH.")
            }
            .font(.custom("Rye-Regular", size: art.fontSize(0.0098)))
            .kerning(0.8)
            .foregroundStyle(Theme.gold.opacity(0.85))
            .artFrame(art.rect(0.10, 0.930, 0.80, 0.026))
            .allowsHitTesting(false)
        }
    }

    /// Label styled for the painted marquee plates.
    private func plateLabel(_ text: String, art: ArtGeometry, size: CGFloat) -> some View {
        HStack(spacing: art.frame.width * 0.03) {
            Sparkle(size: art.fontSize(0.011))
            Text(text)
                .font(.custom("Rye-Regular", size: art.fontSize(size)))
                .kerning(1.4)
                .foregroundStyle(Theme.goldBevel)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            Sparkle(size: art.fontSize(0.011))
        }
    }

    /// Live content over one of the painted list-row plates.
    @ViewBuilder
    private func row(
        art: ArtGeometry,
        y: CGFloat,
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        // Icon sits in the painted circular well.
        Image(systemName: icon)
            .font(.system(size: art.fontSize(0.019), weight: .medium))
            .foregroundStyle(Theme.goldBevel)
            .artFrame(art.rect(0.145, y + 0.004, 0.09, 0.045))
            .allowsHitTesting(false)

        VStack(alignment: .leading, spacing: art.frame.height * 0.003) {
            Text(title)
                .font(.custom("Rye-Regular", size: art.fontSize(0.0165)))
                .foregroundStyle(Theme.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(subtitle)
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0125)))
                .foregroundStyle(Theme.goldLight.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .artFrame(art.rect(0.265, y, 0.56, 0.052), alignment: .leading)
        .allowsHitTesting(false)

        Image(systemName: "chevron.right")
            .font(.system(size: art.fontSize(0.013), weight: .semibold))
            .foregroundStyle(Theme.gold)
            .artFrame(art.rect(0.835, y, 0.06, 0.052))
            .allowsHitTesting(false)

        ArtHotspot(rect: art.rect(0.11, y - 0.006, 0.78, 0.064), label: "\(title). \(subtitle)", action: action)
    }
}

/// INSIGHTS tab — no comp exists, so it's composed on the reusable ornate frame.
struct InsightsView: View {
    var body: some View {
        ArtScreen(image: "bg_frame") { art in
            VStack(spacing: art.frame.height * 0.02) {
                Text("INSIGHTS")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.032)))
                    .foregroundStyle(Theme.goldBevel)
                    .shadow(color: Theme.glow.opacity(0.4), radius: 10)

                OrnamentDivider()
                    .frame(width: art.frame.width * 0.55)

                IconMedallion(systemName: "sparkles", diameter: art.frame.width * 0.22)
                    .padding(.vertical, art.frame.height * 0.02)

                Text("THE STARS ARE STILL ALIGNING")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.0155)))
                    .kerning(1)
                    .foregroundStyle(Theme.gold)
                    .multilineTextAlignment(.center)

                Text("Patterns drawn from your readings will gather here in a future telling.")
                    .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.014)))
                    .foregroundStyle(Theme.goldLight.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(width: art.frame.width * 0.66)
            }
            .artFrame(art.rect(0.13, 0.26, 0.74, 0.42))
        }
    }
}
