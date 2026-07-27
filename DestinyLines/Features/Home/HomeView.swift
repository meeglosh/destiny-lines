import SwiftUI

/// Home over the painted main-menu background. The arch, wordmark, hand medallion, the
/// caption plate and the CTA plate are all painted; this view supplies the live labels
/// and behaviour, positioned in the background's own coordinate space.
///
/// Navigation now lives in the global nav bar, so the artwork carries no menu rows and
/// the whole screen fits above the bar without scrolling.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(AudioPlayer.self) private var audio

    var body: some View {
        ArtScreen(image: "bg_home", fitsWidth: true) { art in
            // Sound toggle in the painted well, top left. The well itself is artwork,
            // so only the glyph is drawn.
            WellButton(
                systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: audio.isMuted ? "Sound off" : "Sound on",
                size: art.fontSize(0.026),
                glowing: !audio.isMuted
            ) {
                audio.toggleMute()
            }
            .artFrame(art.rect(0.045, 0.068, 0.110, 0.064))

            // Share in the matching well, top right.
            WellButton(
                systemName: "square.and.arrow.up",
                label: "Share your reading",
                size: art.fontSize(0.026)
            ) {
                if let latest = readingStore.readings.first {
                    appState.navigate(.share(latest))
                } else {
                    appState.navigate(.capture)
                }
            }
            .artFrame(art.rect(0.8405, 0.0645, 0.110, 0.064))

            // Caption inside the painted black plate (0.628–0.688).
            Text("ANALYZE YOUR PALM.\nDISCOVER YOUR DESTINY.")
                .font(.custom("Rye-Regular", size: art.fontSize(0.0128)))
                .kerning(0.8)
                .lineSpacing(art.frame.height * 0.002)
                .foregroundStyle(Theme.goldLight)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.55)
                .artFrame(art.rect(0.255, 0.630, 0.49, 0.056))
                .allowsHitTesting(false)

            // NEW READING, centred on the painted plate's red face (0.720–0.790).
            HStack(spacing: art.frame.width * 0.035) {
                Sparkle(size: art.fontSize(0.015))
                Text("NEW READING")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.031)))
                    .kerning(1.6)
                    .foregroundStyle(Theme.goldBevel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                Sparkle(size: art.fontSize(0.015))
            }
            .artFrame(art.rect(0.16, 0.7255, 0.68, 0.066))
            .allowsHitTesting(false)

            ArtHotspot(rect: art.rect(0.10, 0.700, 0.80, 0.105), label: "New Reading") {
                appState.navigate(.capture)
            }
        }
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
