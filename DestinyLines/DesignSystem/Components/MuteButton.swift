import SwiftUI

/// Sound toggle that stands in for the baked compass medallion on the Home art.
/// Redraws the medallion — dark well, double gold ring, gold glyph — so it reads as
/// part of the booth rather than a control pasted on top.
struct MuteButton: View {
    let isMuted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { proxy in
                let d = min(proxy.size.width, proxy.size.height)

                ZStack {
                    // Cover the compass beneath with the art's own near-black.
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

                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: d * 0.34, weight: .medium))
                        .foregroundStyle(Theme.goldBevel)
                        .shadow(color: Theme.glow.opacity(isMuted ? 0 : 0.7), radius: d * 0.08)
                }
                .frame(width: d, height: d)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Circle())
            }
        }
        .buttonStyle(ArtPressStyle())
        .accessibilityLabel(isMuted ? "Sound off" : "Sound on")
        .accessibilityHint("Toggles the background music")
        .accessibilityAddTraits(.isButton)
    }
}
