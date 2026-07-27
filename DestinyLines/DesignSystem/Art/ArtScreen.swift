import SwiftUI
import UIKit

/// Screens are painted backgrounds (all text, icons and device chrome stripped out in
/// Photoshop) with live SwiftUI content laid over them. Content is positioned in the
/// background's own normalized space, so it stays registered with the baked artwork
/// while every label remains real text that can scale, localize and be read aloud.

// MARK: - Geometry

/// Maps normalized artwork coordinates (0...1 on both axes) to screen points.
struct ArtGeometry {
    let frame: CGRect

    func point(_ nx: CGFloat, _ ny: CGFloat) -> CGPoint {
        CGPoint(x: frame.minX + nx * frame.width, y: frame.minY + ny * frame.height)
    }

    func rect(_ nx: CGFloat, _ ny: CGFloat, _ nw: CGFloat, _ nh: CGFloat) -> CGRect {
        CGRect(x: frame.minX + nx * frame.width,
               y: frame.minY + ny * frame.height,
               width: nw * frame.width,
               height: nh * frame.height)
    }

    /// Type sized as a share of the artwork's height, so it tracks the background
    /// rather than the device — the same relationship the mockup had.
    func fontSize(_ fraction: CGFloat) -> CGFloat { frame.height * fraction }
}

enum ArtLayout {
    private static var sizeCache: [String: CGSize] = [:]

    static func artSize(_ image: String) -> CGSize {
        if let cached = sizeCache[image] { return cached }
        let size = UIImage(named: image)?.size ?? CGSize(width: 863, height: 1822)
        sizeCache[image] = size
        return size
    }

    /// Scale-to-fill the box, cropping the overflow.
    ///
    /// The backgrounds carry a dark decorative margin, so cropping a little of it reads
    /// as intentional full-bleed. `verticalAnchor` decides which end survives: the
    /// artwork's top matters most (titles, arches), so it defaults to 0 — crop the
    /// bottom, never the header.
    static func fillingFrame(for image: String, in box: CGRect, verticalAnchor: CGFloat = 0) -> CGRect {
        let size = artSize(image)
        let scale = max(box.width / size.width, box.height / size.height)
        let width = size.width * scale
        let height = size.height * scale
        return CGRect(
            x: box.midX - width / 2,
            y: box.minY - (height - box.height) * verticalAnchor,
            width: width,
            height: height
        )
    }
}

// MARK: - Screen

/// A painted background with live content laid over it.
struct ArtScreen<Overlay: View>: View {
    let image: String
    /// 0 pins the artwork's top to the safe-area top (crop the bottom); 1 pins the
    /// bottom; 0.5 centres and crops both ends.
    var verticalAnchor: CGFloat = 0
    /// When true the artwork covers the full screen including safe areas. Default keeps
    /// it inside the safe area so baked headers never sit under the Dynamic Island.
    var ignoresSafeArea = false
    /// When true the artwork keeps its full height and scrolls, rather than being cropped.
    /// Used where the painted layout is taller than the space left by the nav bar.
    var scrollable = false
    /// Extra room reserved at the foot of the scroll, so the nav bar never covers content.
    var bottomInset: CGFloat = 0
    @ViewBuilder var overlay: (ArtGeometry) -> Overlay

    var body: some View {
        GeometryReader { proxy in
            let box = CGRect(origin: .zero, size: proxy.size)
            let art = ArtGeometry(
                frame: ArtLayout.fillingFrame(for: image, in: box, verticalAnchor: verticalAnchor)
            )

            let content = ZStack(alignment: .topLeading) {
                Image(image)
                    .resizable()
                    .frame(width: art.frame.width, height: art.frame.height)
                    .offset(x: art.frame.minX, y: art.frame.minY)

                overlay(art)
            }

            if scrollable {
                ScrollView(showsIndicators: false) {
                    content
                        .frame(width: proxy.size.width, height: art.frame.height, alignment: .topLeading)
                        .padding(.bottom, bottomInset)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                content
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                    .clipped()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .modifier(ConditionalFullBleed(enabled: ignoresSafeArea))
    }
}

private struct ConditionalFullBleed: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled { content.ignoresSafeArea() } else { content }
    }
}

extension View {
    /// Place a view at a rect in artwork coordinates.
    ///
    /// Uses `.offset`, never `.position`: `.position` expands a view to fill its parent,
    /// so stacked positioned views each cover the whole screen and swallow every touch
    /// but the topmost. `.offset` keeps a view its own size.
    func artFrame(_ rect: CGRect, alignment: Alignment = .center) -> some View {
        frame(width: rect.width, height: rect.height, alignment: alignment)
            .offset(x: rect.minX, y: rect.minY)
    }
}

/// Invisible tap target over a control painted into the background.
struct ArtHotspot: View {
    let rect: CGRect
    let label: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(ArtDebug.showHotspots ? Color.red.opacity(0.28) : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(ArtPressStyle())
        .disabled(!enabled)
        .artFrame(rect)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

/// Press feedback for controls painted into the artwork: a brief inset and warm dim,
/// since the art itself has no pressed variant.
struct ArtPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                Color.black
                    .opacity(configuration.isPressed ? 0.30 : 0)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            )
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

enum ArtDebug {
    static let showHotspots = ProcessInfo.processInfo.environment["ART_DEBUG"] == "1"
}
