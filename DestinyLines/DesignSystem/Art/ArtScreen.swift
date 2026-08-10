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
    /// The safe-area box `ArtScreen` renders into (origin always `.zero`). Used for
    /// chrome that is positioned in screen space rather than artwork space — see
    /// `ArtChrome`.
    var box: CGRect = .zero

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

/// Fraction of the raw artwork, on each edge, that is dead margin baked into the PNG
/// rather than content — measured once per asset by scanning for the first/last row or
/// column above a luminance floor. `fillingFrame` crops to the content rect instead of
/// the raw image so that margin never reads as a letterboxing bar.
struct ArtInsets {
    var top: CGFloat = 0
    var bottom: CGFloat = 0
    var left: CGFloat = 0
    var right: CGFloat = 0

    static let zero = ArtInsets()

    /// Per-asset baked margins, measured once against the current art export.
    ///
    /// Method: band-scan luminance > 14 across the middle band of each edge, first/last
    /// row or column that clears the floor is the content edge; the margin outside it is
    /// reported as a fraction of the raw image's own width/height. Measured 2026-08-08.
    /// Re-measure and update this table whenever an asset is re-exported.
    static let measured: [String: ArtInsets] = [
        "bg_splash":       ArtInsets(top: 0.0088, bottom: 0.0165, left: 0.0023, right: 0.0000),
        "bg_home":         ArtInsets(top: 0.0108, bottom: 0.0087, left: 0.0081, right: 0.0139),
        "bg_capture":      ArtInsets(top: 0.0637, bottom: 0.0274, left: 0.0579, right: 0.0579),
        "bg_align":        ArtInsets(top: 0.0626, bottom: 0.0121, left: 0.0220, right: 0.0220),
        "bg_frame":        ArtInsets(top: 0.0626, bottom: 0.0121, left: 0.0220, right: 0.0220),
        "bg_reading":      ArtInsets(top: 0.0285, bottom: 0.0231, left: 0.0521, right: 0.0510),
        "bg_history_list": ArtInsets(top: 0.0664, bottom: 0.0845, left: 0.0753, right: 0.0776),
        // Bake is asymmetric (left 0.0603, right 0.0162); cropping both by these values
        // is what makes the art read as symmetric on screen.
        "bg_share":        ArtInsets(top: 0.0307, bottom: 0.0318, left: 0.0603, right: 0.0162),
        "bg_paywall":      ArtInsets(top: 0.0179, bottom: 0.0173, left: 0.0351, right: 0.0372),
    ]

    static func `for`(_ image: String) -> ArtInsets { measured[image] ?? .zero }
}

/// Fixed screen-space positions for chrome that must land in the same spot on every
/// screen — back buttons, close buttons, the mirrored top-right control — regardless of
/// what each background happens to bake in. Coordinates are relative to the safe-area
/// box `ArtScreen` renders into (top-left is `.zero`), not to artwork fractions.
enum ArtChrome {
    static let backCenter = CGPoint(x: 42, y: 40)
    static let controlSize: CGFloat = 40

    static func backFrame(size: CGFloat = controlSize) -> CGRect {
        CGRect(x: backCenter.x - size / 2, y: backCenter.y - size / 2, width: size, height: size)
    }

    /// A control mirrored to the opposite edge (e.g. Reading's share button), expressed
    /// relative to the box width so it clears the same margin on any device width.
    static func mirroredFrame(boxWidth: CGFloat, size: CGFloat = controlSize) -> CGRect {
        CGRect(x: boxWidth - backCenter.x - size / 2, y: backCenter.y - size / 2, width: size, height: size)
    }
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
    ///
    /// `contentInsets` sizes the cover-fit off a trimmed content sub-rect of the raw
    /// image instead of the full raw dimensions, so a baked margin gets cropped away
    /// like real overflow rather than rendered as a visible bar. The full image is still
    /// positioned and rendered (just shifted so the content rect lands where the raw
    /// rect used to), so `art.rect(nx, ny, ...)` overlay coordinates stay relative to the
    /// full raw image everywhere — this only changes what's visible, not the coordinate
    /// contract.
    static func fillingFrame(
        for image: String,
        in box: CGRect,
        verticalAnchor: CGFloat = 0,
        contentInsets: ArtInsets = .zero
    ) -> CGRect {
        let size = artSize(image)
        let contentWidth = size.width * (1 - contentInsets.left - contentInsets.right)
        let contentHeight = size.height * (1 - contentInsets.top - contentInsets.bottom)
        let scale = max(box.width / contentWidth, box.height / contentHeight)
        let width = size.width * scale
        let height = size.height * scale
        let contentScaledWidth = contentWidth * scale
        let contentScaledHeight = contentHeight * scale
        let contentX = box.midX - contentScaledWidth / 2
        let contentY = box.minY - (contentScaledHeight - box.height) * verticalAnchor
        return CGRect(
            x: contentX - contentInsets.left * size.width * scale,
            y: contentY - contentInsets.top * size.height * scale,
            width: width,
            height: height
        )
    }

    /// Standard layout: content width-fill, top-pinned.
    ///
    /// Crops the asset's own registered `ArtInsets.measured` margin off the left/top/right
    /// (never rendering it as a visible bar), scales so the content rect's width matches
    /// the box exactly, and pins the content rect's top-left to the box's top-left. This
    /// is the "every page edge-to-edge with a uniform top line, like Home" mode and is
    /// `ArtScreen`'s default — tall art simply crops at the foot, which on tab pages the
    /// nav bar covers anyway.
    ///
    /// Returns the full image's frame (shifted/scaled like `fillingFrame` does), so
    /// `art.rect(nx, ny, ...)` overlay coordinates stay relative to the full raw image.
    static func standardFrame(for image: String, in box: CGRect) -> CGRect {
        let size = artSize(image)
        let insets = ArtInsets.for(image)
        let contentWidth = size.width * (1 - insets.left - insets.right)
        guard contentWidth > 0 else {
            return CGRect(x: box.minX, y: box.minY, width: size.width, height: size.height)
        }
        let scale = box.width / contentWidth
        let width = size.width * scale
        let height = size.height * scale
        let contentX = box.minX - insets.left * size.width * scale
        let contentY = box.minY - insets.top * size.height * scale
        return CGRect(x: contentX, y: contentY, width: width, height: height)
    }
}

// MARK: - Screen

/// A painted background with live content laid over it.
struct ArtScreen<Overlay: View>: View {
    let image: String
    /// Full-bleed cover-fit (the older layout mode): scales to fill the box, cropping
    /// overflow per `verticalAnchor`/`contentInsets`. Default `false` uses the standard
    /// width-fill, top-pinned layout (`ArtLayout.standardFrame`) that every screen uses
    /// now except Splash, which opts into cover explicitly for true edge-to-edge fill
    /// under the status bar rather than a uniform top line.
    var cover = false
    /// 0 pins the artwork's top to the safe-area top (crop the bottom); 1 pins the
    /// bottom; 0.5 centres and crops both ends. Only used when `cover` is true.
    var verticalAnchor: CGFloat = 0
    /// Which edges the artwork extends past into the safe area. Default `[]` keeps it
    /// inside the safe area on every edge, so baked headers never sit under the Dynamic
    /// Island. Pass `.all` for true edge-to-edge (Splash: nothing painted near the top
    /// edge risks colliding with the status bar/Dynamic Island). Pass `.bottom` alone to
    /// clear the home-indicator band without pushing top content — chrome painted near
    /// the top (wordmark, close button) — under the status bar.
    var ignoresSafeAreaEdges: Edge.Set = []
    /// When true the artwork keeps its full height and scrolls, rather than being cropped.
    /// Used where the painted layout is taller than the space left by the nav bar.
    var scrollable = false
    /// Extra room reserved at the foot of the scroll, so the nav bar never covers content.
    var bottomInset: CGFloat = 0
    /// Baked dead margin on the raw artwork to crop away rather than render. Only used
    /// when `cover` is true — the standard layout reads margins from
    /// `ArtInsets.measured` instead. See `ArtLayout.fillingFrame`.
    var contentInsets: ArtInsets = .zero
    @ViewBuilder var overlay: (ArtGeometry) -> Overlay

    var body: some View {
        GeometryReader { proxy in
            let box = CGRect(origin: .zero, size: proxy.size)
            let art = ArtGeometry(
                frame: cover
                    ? ArtLayout.fillingFrame(
                        for: image, in: box, verticalAnchor: verticalAnchor, contentInsets: contentInsets
                    )
                    : ArtLayout.standardFrame(for: image, in: box),
                box: box
            )

            let content = ZStack(alignment: .topLeading) {
                Image(image)
                    .resizable()
                    .frame(width: art.frame.width, height: art.frame.height)
                    .offset(x: art.frame.minX, y: art.frame.minY)

                overlay(art)
            }

            if scrollable {
                // `art.frame` is the full raw image's frame (per the coordinate contract
                // every overlay relies on), shifted up by the baked top inset so that
                // margin never renders as a bar — its `minY` is therefore <= 0. The
                // visible canvas, top to bottom, runs from that shifted top (which lines
                // up with the box's own top, matching the non-scrollable crop exactly)
                // down to the image's true bottom edge, i.e. `frame.height + frame.minY`.
                // Sizing the scroll content to the *raw* `frame.height` instead (the old
                // bug) left a dead gap of exactly the top-inset's height at the foot of
                // the scroll, understating how far a screen needed to scroll to clear the
                // nav bar without ever revealing extra content.
                let visibleHeight = max(art.frame.height + art.frame.minY, proxy.size.height)
                ScrollView(showsIndicators: false) {
                    content
                        .frame(width: proxy.size.width, height: visibleHeight, alignment: .topLeading)
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
        .modifier(ConditionalFullBleed(edges: ignoresSafeAreaEdges))
    }
}

private struct ConditionalFullBleed: ViewModifier {
    let edges: Edge.Set
    func body(content: Content) -> some View {
        if edges.isEmpty { content } else { content.ignoresSafeArea(edges: edges) }
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
