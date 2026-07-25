import SwiftUI

/// Palette and metrics extracted from the comps in /img.
/// The look is a vintage carnival fortune-teller booth: near-black wood, warm gold,
/// deep stage-curtain reds, and incandescent bulb glows.
enum Theme {

    // MARK: - Colors

    /// Near-black warm background, `#0D0A08`.
    static let background = Color(red: 0x0D / 255, green: 0x0A / 255, blue: 0x08 / 255)

    /// Slightly lifted panel background, the dark leather of card interiors.
    static let panel = Color(red: 0x17 / 255, green: 0x11 / 255, blue: 0x0C / 255)

    /// Primary gold, `#D9A441` — frames, icons, display type.
    static let gold = Color(red: 0xD9 / 255, green: 0xA4 / 255, blue: 0x41 / 255)

    /// Light gold, `#F0D9A8` — body text on dark, subtitles.
    static let goldLight = Color(red: 0xF0 / 255, green: 0xD9 / 255, blue: 0xA8 / 255)

    /// Deep engraved gold for borders that sit behind brighter elements.
    static let goldDark = Color(red: 0x8A / 255, green: 0x62 / 255, blue: 0x28 / 255)

    /// Deep red CTA fill, `#8C2318`.
    static let ctaRed = Color(red: 0x8C / 255, green: 0x23 / 255, blue: 0x18 / 255)

    /// Curtain crimson, `#4A0F0C` — deep red backgrounds, selected tab fill.
    static let crimson = Color(red: 0x4A / 255, green: 0x0F / 255, blue: 0x0C / 255)

    /// Warm amber bulb glow, `#FFB84D`, used at low opacity for halos.
    static let glow = Color(red: 0xFF / 255, green: 0xB8 / 255, blue: 0x4D / 255)

    /// Muted parchment for ribbon banners.
    static let parchment = Color(red: 0xE8 / 255, green: 0xD5 / 255, blue: 0xA9 / 255)

    /// Ink brown used for text on parchment.
    static let ink = Color(red: 0x3A / 255, green: 0x27 / 255, blue: 0x12 / 255)

    // MARK: - Gradients

    /// Full-screen background: warm dark-brown vignette over near-black.
    static var backgroundGradient: RadialGradient {
        RadialGradient(
            colors: [Color(red: 0x2A / 255, green: 0x1A / 255, blue: 0x10 / 255), background],
            center: .center,
            startRadius: 40,
            endRadius: 460
        )
    }

    /// Vertical sheen for gold frames and bevels.
    static var goldBevel: LinearGradient {
        LinearGradient(
            colors: [goldLight, gold, goldDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Red CTA plate fill with a darker base.
    static var ctaFill: LinearGradient {
        LinearGradient(
            colors: [ctaRed, Color(red: 0x5E / 255, green: 0x14 / 255, blue: 0x0D / 255)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Curtain-red panel fill (yearly plan card, banners).
    static var crimsonFill: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0x63 / 255, green: 0x17 / 255, blue: 0x11 / 255), crimson],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Metrics

    static let cornerRadius: CGFloat = 14
    static let screenPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 14
}
