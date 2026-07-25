import SwiftUI

/// A single incandescent marquee bulb with a warm halo.
struct MarqueeBulb: View {
    var size: CGFloat = 7
    var isLit = true

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: isLit
                        ? [.white, Theme.glow, Theme.glow.opacity(0.0)]
                        : [Theme.goldDark.opacity(0.6), Theme.goldDark.opacity(0.2), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size
                )
            )
            .frame(width: size * 2, height: size * 2)
    }
}

/// A rounded-rectangle border of marquee bulbs, the signature framing device of the comps.
/// Wraps its content in a dark plate with a gold bevel edge and evenly spaced bulbs.
struct MarqueeFrame<Content: View>: View {
    var cornerRadius: CGFloat = Theme.cornerRadius
    var bulbSpacing: CGFloat = 26
    var bulbSize: CGFloat = 5
    /// When true (and Reduce Motion is off) the bulbs twinkle gently.
    var animated = false
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false

    var body: some View {
        content
            .padding(bulbSize * 3.2)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Theme.goldBevel, lineWidth: 2)
                    )
            )
            .overlay(bulbBorder)
            .onAppear {
                guard animated, !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    phase = true
                }
            }
    }

    private var bulbBorder: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let positions = Self.bulbPositions(in: rect, cornerRadius: cornerRadius, spacing: bulbSpacing)
            ForEach(Array(positions.enumerated()), id: \.offset) { index, point in
                MarqueeBulb(size: bulbSize)
                    .opacity(animated && !reduceMotion ? (phase == (index % 2 == 0) ? 1.0 : 0.45) : 1.0)
                    .position(point)
            }
        }
        .allowsHitTesting(false)
    }

    /// Evenly spaced points along the perimeter of a rounded rect.
    static func bulbPositions(in rect: CGRect, cornerRadius r: CGFloat, spacing: CGFloat) -> [CGPoint] {
        let path = Path(roundedRect: rect, cornerRadius: r)
        var points: [CGPoint] = []
        // Walk the path by sampling trimmed positions.
        let perimeter = 2 * (rect.width + rect.height) - 8 * r + 2 * .pi * r
        let count = max(4, Int(perimeter / spacing))
        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count)
            if let point = path.trimmedPath(from: t, to: min(t + 0.0001, 1)).currentPoint {
                points.append(point)
            }
        }
        return points
    }
}
