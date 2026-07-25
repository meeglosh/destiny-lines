import SwiftUI

/// Parchment ribbon-scroll title banner ("CAPTURE YOUR HAND", "ALIGN YOUR HAND").
/// A stylized flat take on the comps' ribbon: curled tail wedges either side of a
/// gently bowed parchment plate, ink-brown display text on top.
struct BannerHeader: View {
    let title: String

    var body: some View {
        ZStack {
            // Ribbon tails
            HStack(spacing: 0) {
                RibbonTail(pointingLeft: true)
                Spacer()
                RibbonTail(pointingLeft: false)
            }
            .frame(height: 44)
            .offset(y: 6)

            // Main parchment plate
            Text(title)
                .font(Typography.title)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Theme.parchment, Color(red: 0xC9 / 255, green: 0xAE / 255, blue: 0x7B / 255)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.55), radius: 6, y: 3)
                )
        }
        .accessibilityAddTraits(.isHeader)
    }
}

private struct RibbonTail: View {
    let pointingLeft: Bool

    var body: some View {
        TailShape(pointingLeft: pointingLeft)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0xB4 / 255, green: 0x93 / 255, blue: 0x5C / 255),
                        Color(red: 0x8E / 255, green: 0x6F / 255, blue: 0x3E / 255),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 34)
    }

    private struct TailShape: Shape {
        let pointingLeft: Bool

        func path(in rect: CGRect) -> Path {
            var p = Path()
            if pointingLeft {
                p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 4))
                p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.midY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 4))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            } else {
                p.move(to: CGPoint(x: rect.minX, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 4))
                p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.45, y: rect.midY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            }
            p.closeSubpath()
            return p
        }
    }
}
