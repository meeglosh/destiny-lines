import SwiftUI

/// Dark leather panel with a thin gold double border and corner ticks —
/// the standard container for list rows, cards, and framed content in the comps.
struct OrnateCard<Content: View>: View {
    var fill: AnyShapeStyle = AnyShapeStyle(Theme.panel)
    var cornerRadius: CGFloat = Theme.cornerRadius
    var contentPadding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(contentPadding)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Theme.gold.opacity(0.85), lineWidth: 1.5)
                    RoundedRectangle(cornerRadius: cornerRadius - 3)
                        .strokeBorder(Theme.goldDark.opacity(0.5), lineWidth: 1)
                        .padding(3)
                    CornerTicks(cornerRadius: cornerRadius)
                        .stroke(Theme.gold.opacity(0.9), lineWidth: 1.2)
                        .padding(6)
                }
            )
    }
}

/// Small L-shaped ticks in each corner, echoing the engraved corner flourishes.
private struct CornerTicks: Shape {
    var cornerRadius: CGFloat
    private let arm: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let corners: [(CGPoint, CGVector, CGVector)] = [
            (CGPoint(x: rect.minX, y: rect.minY), CGVector(dx: 1, dy: 0), CGVector(dx: 0, dy: 1)),
            (CGPoint(x: rect.maxX, y: rect.minY), CGVector(dx: -1, dy: 0), CGVector(dx: 0, dy: 1)),
            (CGPoint(x: rect.minX, y: rect.maxY), CGVector(dx: 1, dy: 0), CGVector(dx: 0, dy: -1)),
            (CGPoint(x: rect.maxX, y: rect.maxY), CGVector(dx: -1, dy: 0), CGVector(dx: 0, dy: -1)),
        ]
        for (corner, h, v) in corners {
            p.move(to: CGPoint(x: corner.x + h.dx * arm, y: corner.y))
            p.addLine(to: corner)
            p.addLine(to: CGPoint(x: corner.x, y: corner.y + v.dy * arm))
        }
        return p
    }
}
