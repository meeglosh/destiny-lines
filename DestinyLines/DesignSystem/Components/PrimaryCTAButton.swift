import SwiftUI

/// The big red marquee call-to-action ("NEW READING", "START FREE TRIAL", "CONTINUE"):
/// a deep-red plate with a gold bevel border, display-face label flanked by sparkles,
/// optionally ringed with marquee bulbs.
struct PrimaryCTAButton: View {
    let title: String
    var showsBulbs = true
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Sparkle()
                Text(title)
                    .font(Typography.cta)
                    .foregroundStyle(Theme.goldBevel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Sparkle()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(plate)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }

    @ViewBuilder
    private var plate: some View {
        if showsBulbs {
            base.overlay(bulbs)
        } else {
            base
        }
    }

    private var base: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Theme.ctaFill)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Theme.goldBevel, lineWidth: 2.5)
            )
            .shadow(color: Theme.glow.opacity(0.25), radius: 12)
    }

    private var bulbs: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size).insetBy(dx: -7, dy: -7)
            let points = MarqueeFrame<EmptyView>.bulbPositions(in: rect, cornerRadius: 14, spacing: 30)
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                MarqueeBulb(size: 4.5)
                    .position(x: point.x + 7, y: point.y + 7)
            }
        }
        .padding(-7)
        .allowsHitTesting(false)
    }
}

/// Four-point star sparkle used beside CTA labels and section dividers.
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

/// Slight press-down scale, shared by all tappable plates.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
