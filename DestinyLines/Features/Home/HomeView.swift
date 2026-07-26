import SwiftUI

/// Home, rebuilt from sliced components: arch + wordmark hero, the big hand medallion,
/// live-caption plate, and the NEW READING marquee CTA. Navigation lives in the global
/// tab bar, so the old menu rows are gone; the sound toggle floats top-leading.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(AudioPlayer.self) private var audio

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 700

            ScrollView(showsIndicators: false) {
                VStack(spacing: compact ? 10 : 16) {
                    Image("arch_wordmark")
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel("Destiny Lines. Your future is in your hands.")

                    Image("hand_medallion_big")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: min(proxy.size.width * 0.82, 420))
                        .accessibilityHidden(true)

                    CaptionPlate(text: "ANALYZE YOUR PALM.  DISCOVER YOUR DESTINY.")
                        .frame(maxWidth: 340)
                        .padding(.horizontal, 40)

                    ArtPlateButton(style: .marqueeRed, text: "NEW READING") {
                        appState.navigate(.capture)
                    }
                    .padding(.horizontal, 28)
                    .frame(maxWidth: 460)

                    footer
                        .padding(.top, compact ? 2 : 8)
                }
                .padding(.top, 4)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
            }
            .overlay(alignment: .topLeading) {
                MuteButton(isMuted: audio.isMuted) {
                    audio.toggleMute()
                }
                .frame(width: 44, height: 44)
                .padding(.leading, 14)
                .padding(.top, 2)
            }
        }
        .boothBackground()
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text("TRUST THE SIGNS.")
            Image("crystal_ball_footer")
                .resizable()
                .scaledToFit()
                .frame(height: 56)
                .accessibilityHidden(true)
            Text("FOLLOW YOUR PATH.")
        }
        .font(.custom("Rye-Regular", size: 11))
        .kerning(1)
        .foregroundStyle(Theme.gold.opacity(0.85))
        .padding(.horizontal, 24)
    }
}

/// INSIGHTS tab placeholder (owner decision: visible with a gentle note, not a dead end).
struct InsightsView: View {
    var body: some View {
        VStack(spacing: 18) {
            RibbonBanner(text: "INSIGHTS")
                .padding(.horizontal, 70)
                .padding(.top, 8)

            Spacer()

            Image("crystal_ball_small")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .accessibilityHidden(true)

            ArtCard {
                VStack(spacing: 8) {
                    Text("THE STARS ARE STILL ALIGNING")
                        .font(Typography.displaySmall)
                        .kerning(1.5)
                        .foregroundStyle(Theme.gold)
                    Text("Insights from your readings will gather here in a future version.")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.goldLight.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .boothBackground()
    }
}
