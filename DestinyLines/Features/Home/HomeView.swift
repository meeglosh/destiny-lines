import SwiftUI

/// Main menu per DL-main-menu.png: marquee-bulb arch over the wordmark, tagline banner,
/// ornate hand medallion in a bulb ring, red NEW READING CTA, then the three list rows
/// and the footer motto.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                BannerHeader(title: "YOUR FUTURE IS IN YOUR HANDS")
                    .padding(.horizontal, 30)

                medallion

                OrnateCard(contentPadding: 10) {
                    Text("ANALYZE YOUR PALM.  DISCOVER YOUR DESTINY.")
                        .font(Typography.displaySmall)
                        .kerning(1)
                        .foregroundStyle(Theme.goldLight)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)

                PrimaryCTAButton(title: "NEW READING") {
                    appState.navigate(.capture)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)

                VStack(spacing: Theme.cardSpacing) {
                    ListRow(icon: "hand.raised.fill", title: "MY READINGS", subtitle: "View your past readings") {
                        appState.navigate(.history)
                    }
                    ListRow(icon: "square.and.arrow.up", title: "SHARE", subtitle: "Share your reading") {
                        if let latest = readingStore.readings.first {
                            appState.navigate(.share(latest))
                        } else {
                            appState.navigate(.capture)
                        }
                    }
                    ListRow(icon: "gearshape.fill", title: "SETTINGS", subtitle: "Customize your experience") {
                        appState.navigate(.settings)
                    }
                }
                .padding(.horizontal, 24)

                footer
            }
            .padding(.vertical, 8)
        }
        .screenBackground()
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 2) {
            HStack {
                IconMedallion(systemName: "star.circle", diameter: 38)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    IconMedallion(systemName: "seal", diameter: 38)
                    if !readingStore.readings.isEmpty {
                        Text("\(readingStore.readings.count)")
                            .font(Typography.fine)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Circle().fill(Color(red: 0.75, green: 0.22, blue: 0.10)))
                            .offset(x: 6, y: -6)
                            .accessibilityLabel("\(readingStore.readings.count) saved readings")
                    }
                }
            }
            .padding(.horizontal, 20)

            MarqueeFrame(cornerRadius: 26, bulbSpacing: 30, bulbSize: 5, animated: true) {
                VStack(spacing: 0) {
                    Text("DESTINY")
                        .font(Typography.wordmark)
                    Text("LINES")
                        .font(Typography.wordmark)
                }
                .foregroundStyle(Theme.goldBevel)
                .shadow(color: Theme.glow.opacity(0.4), radius: 14)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Destiny Lines")
            }
            .padding(.horizontal, 24)
        }
    }

    private var medallion: some View {
        MarqueeFrame(cornerRadius: 110, bulbSpacing: 34, bulbSize: 5, animated: true) {
            ZStack {
                Circle()
                    .fill(Theme.crimsonFill)
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 82, weight: .regular))
                    .foregroundStyle(Theme.goldBevel)
                    .shadow(color: Theme.glow.opacity(0.6), radius: 18)
            }
            .frame(width: 190, height: 190)
        }
        .accessibilityHidden(true)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            OrnamentDivider()
                .padding(.horizontal, 60)
            HStack {
                Text("TRUST THE SIGNS.")
                Spacer()
                Text("FOLLOW YOUR PATH.")
            }
            .font(Typography.displaySmall)
            .kerning(1)
            .foregroundStyle(Theme.gold.opacity(0.85))
            .padding(.horizontal, 44)
        }
        .padding(.top, 10)
        .padding(.bottom, 24)
    }
}
