import SwiftUI

/// Circular medallion control drawn in the booth's style — dark well, double gold ring,
/// gold glyph. Used for the two Home corner controls, which stand where the comp had
/// decorative (non-functional) medallions.
struct ArtMedallionButton: View {
    let systemName: String
    let label: String
    var isGlowing = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { proxy in
                let d = min(proxy.size.width, proxy.size.height)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0x14 / 255, green: 0x0D / 255, blue: 0x08 / 255),
                                    Color(red: 0x08 / 255, green: 0x05 / 255, blue: 0x03 / 255),
                                ],
                                center: .init(x: 0.4, y: 0.35),
                                startRadius: 0,
                                endRadius: d * 0.6
                            )
                        )

                    Circle()
                        .strokeBorder(Theme.goldBevel, lineWidth: d * 0.055)

                    Circle()
                        .strokeBorder(Theme.goldDark.opacity(0.8), lineWidth: d * 0.02)
                        .padding(d * 0.11)

                    Image(systemName: systemName)
                        .font(.system(size: d * 0.34, weight: .medium))
                        .foregroundStyle(Theme.goldBevel)
                        .shadow(color: Theme.glow.opacity(isGlowing ? 0.7 : 0), radius: d * 0.08)
                }
                .frame(width: d, height: d)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Circle())
            }
        }
        .buttonStyle(ArtPressStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

/// Sound toggle for the looping background music.
struct MuteButton: View {
    let isMuted: Bool
    let action: () -> Void

    var body: some View {
        ArtMedallionButton(
            systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
            label: isMuted ? "Sound off" : "Sound on",
            isGlowing: !isMuted,
            action: action
        )
        .accessibilityHint("Toggles the background music")
    }
}
