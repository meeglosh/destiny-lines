import SwiftUI
import UIKit

/// Renders a design comp as the entire screen, with overlays positioned in the
/// image's normalized coordinate space (0...1 on both axes).
///
/// The comps are used directly per the owner's direction — the app IS the mockups.
///
/// **Sizing is aspect-FIT, never fill or stretch.** The comps' aspect ratios differ from
/// each other and from every device (the paywall art is markedly wider than the rest), so
/// filling crops content off-screen and stretching distorts it — badly on short, wide
/// phones like the SE. Fitting guarantees every baked control stays visible on any device;
/// the leftover margin is filled with the art's own near-black, which is invisible in
/// practice because all the comps are dark at the edges.
struct ArtScreen<Overlay: View>: View {
    let image: String
    @ViewBuilder var overlay: (ArtGeometry) -> Overlay

    var body: some View {
        GeometryReader { proxy in
            let container = ArtLayout.container(proxy)
            let art = ArtGeometry(frame: ArtLayout.fittedFrame(for: image, in: container))

            ZStack(alignment: .topLeading) {
                Theme.background
                    .frame(width: container.width, height: container.height)
                    .offset(x: container.minX, y: container.minY)

                Image(image)
                    .resizable()
                    .artFrame(art.frame)

                overlay(art)
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
    }
}

enum ArtLayout {
    /// The full device rect in the GeometryReader's coordinate space, safe areas included.
    static func container(_ proxy: GeometryProxy) -> CGRect {
        CGRect(
            x: -proxy.safeAreaInsets.leading,
            y: -proxy.safeAreaInsets.top,
            width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
            height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
        )
    }

    /// Aspect-fit `image` inside `container`, centered.
    static func fittedFrame(for image: String, in container: CGRect) -> CGRect {
        let size = artSize(image)
        let scale = min(container.width / size.width, container.height / size.height)
        let width = size.width * scale
        let height = size.height * scale
        return CGRect(
            x: container.midX - width / 2,
            y: container.midY - height / 2,
            width: width,
            height: height
        )
    }

    /// Pixel size of a bundled art asset, cached. Falls back to the common comp size.
    private static var sizeCache: [String: CGSize] = [:]

    static func artSize(_ image: String) -> CGSize {
        if let cached = sizeCache[image] { return cached }
        let size = UIImage(named: image)?.size ?? CGSize(width: 863, height: 1822)
        sizeCache[image] = size
        return size
    }
}

/// Maps normalized art coordinates to screen points.
struct ArtGeometry {
    let frame: CGRect

    func point(_ nx: CGFloat, _ ny: CGFloat) -> CGPoint {
        CGPoint(x: frame.minX + nx * frame.width, y: frame.minY + ny * frame.height)
    }

    func rect(_ nx: CGFloat, _ ny: CGFloat, _ nw: CGFloat, _ nh: CGFloat) -> CGRect {
        CGRect(
            x: frame.minX + nx * frame.width,
            y: frame.minY + ny * frame.height,
            width: nw * frame.width,
            height: nh * frame.height
        )
    }
}

extension View {
    /// Place this view at a rect in art coordinates.
    ///
    /// Uses `.offset`, NOT `.position`: `.position` expands the view to fill its parent,
    /// so stacked positioned views each cover the whole screen and swallow every touch
    /// except the topmost one. `.offset` keeps the view its own size, so siblings stay
    /// independently tappable.
    func artFrame(_ rect: CGRect, alignment: Alignment = .center) -> some View {
        frame(width: rect.width, height: rect.height, alignment: alignment)
            .offset(x: rect.minX, y: rect.minY)
    }
}

/// Invisible tap target over a baked-in control in the art.
struct ArtHotspot: View {
    let rect: CGRect
    let label: String
    var debug = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(debug ? Color.red.opacity(0.3) : Color.clear)
                .overlay(debug ? Rectangle().stroke(.red, lineWidth: 1) : nil)
                .contentShape(Rectangle())
        }
        .buttonStyle(ArtPressStyle())
        .artFrame(rect)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

/// Dims slightly on press so baked-art buttons still feel tappable.
struct ArtPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.black.opacity(configuration.isPressed ? 0.18 : 0))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Global switch for hotspot calibration screenshots.
enum ArtDebug {
    static let showHotspots = ProcessInfo.processInfo.environment["ART_DEBUG"] == "1"
}
