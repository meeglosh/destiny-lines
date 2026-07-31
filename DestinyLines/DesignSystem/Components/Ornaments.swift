import SwiftUI

/// Small drawn ornaments that pair with the painted artwork: the four-point sparkle used
/// beside labels, a gold divider, and a circular icon medallion for icons the artwork
/// doesn't paint.

struct Sparkle: View {
    var size: CGFloat = 14
    var color: Color = Theme.gold

    var body: some View {
        SparkleShape()
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private struct SparkleShape: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            let c = CGPoint(x: rect.midX, y: rect.midY)
            let long = rect.width / 2
            let short = rect.width / 7
            p.move(to: CGPoint(x: c.x, y: c.y - long))
            p.addQuadCurve(to: CGPoint(x: c.x + long, y: c.y), control: CGPoint(x: c.x + short, y: c.y - short))
            p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + long), control: CGPoint(x: c.x + short, y: c.y + short))
            p.addQuadCurve(to: CGPoint(x: c.x - long, y: c.y), control: CGPoint(x: c.x - short, y: c.y + short))
            p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - long), control: CGPoint(x: c.x - short, y: c.y - short))
            p.closeSubpath()
            return p
        }
    }
}

/// Gold hairline with a centre sparkle.
struct OrnamentDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            line
            Sparkle(size: 11)
            line
        }
        .accessibilityHidden(true)
    }

    private var line: some View {
        LinearGradient(colors: [.clear, Theme.gold.opacity(0.7)],
                       startPoint: .leading, endPoint: .trailing)
            .frame(height: 1)
    }
}

/// Circular gold-ringed medallion for an SF Symbol, matching the wells painted into the
/// artwork. Used where a screen needs an icon the background doesn't provide.
struct IconMedallion: View {
    let systemName: String
    var diameter: CGFloat = 52

    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.5))
            Circle().strokeBorder(Theme.gold, lineWidth: max(1, diameter * 0.03))
            Circle()
                .strokeBorder(Theme.goldDark.opacity(0.6), lineWidth: 1)
                .padding(diameter * 0.06)
            Image(systemName: systemName)
                .font(.system(size: diameter * 0.4, weight: .medium))
                .foregroundStyle(Theme.goldBevel)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

/// A glyph seated in a well that the artwork already paints — so only the icon is drawn,
/// with no ring of its own to double up on the painted one.
struct WellButton: View {
    let systemName: String
    let label: String
    var size: CGFloat = 22
    var glowing = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(Theme.goldBevel)
                .shadow(color: Theme.glow.opacity(glowing ? 0.5 : 0), radius: size * 0.25)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Circle())
        }
        .buttonStyle(ArtPressStyle())
        .accessibilityLabel(label)
    }
}

/// Circular back control used on flow screens.
///
/// Draws its own circle and ring by default. Where the background art already bakes in
/// a matching well (Capture does), set `showsBackground: false` and position this over
/// that well instead — otherwise the two circles show up stacked and mismatched.
struct BackButton: View {
    var showsBackground = true
    var size: CGFloat = 40
    var iconSize: CGFloat = 16
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if showsBackground {
                    Circle().fill(Color.black.opacity(0.45))
                    Circle().strokeBorder(Theme.gold.opacity(0.9), lineWidth: 1.4)
                }
                Image(systemName: "arrow.left")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(ArtPressStyle())
        .accessibilityLabel("Back")
    }
}

/// Standard dark backdrop for sheets and screens without their own painted background.
extension View {
    func screenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}
