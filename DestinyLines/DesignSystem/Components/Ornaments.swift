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

/// Circular back control used on flow screens.
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.black.opacity(0.45))
                Circle().strokeBorder(Theme.gold.opacity(0.9), lineWidth: 1.4)
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 40, height: 40)
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
