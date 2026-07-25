import SwiftUI

/// Renders a design comp as the entire screen, with overlays positioned in the
/// image's normalized coordinate space (0...1 on both axes).
///
/// The comps are used directly per the owner's direction — the app IS the mockups.
/// Art aspect (~0.474) differs from device aspect by ~3%, so the image is stretched
/// to fill; the distortion is imperceptible on ornamental art and keeps every border
/// ornament on-screen. Overlays use the same stretch, so positions stay aligned.
struct ArtScreen<Overlay: View>: View {
    let image: String
    @ViewBuilder var overlay: (ArtGeometry) -> Overlay

    var body: some View {
        GeometryReader { proxy in
            let full = CGRect(
                x: -proxy.safeAreaInsets.leading,
                y: -proxy.safeAreaInsets.top,
                width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            )
            let art = ArtGeometry(frame: full)

            ZStack(alignment: .topLeading) {
                Image(image)
                    .resizable()
                    .frame(width: full.width, height: full.height)
                    .offset(x: full.minX, y: full.minY)

                overlay(art)
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
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
        }
        .buttonStyle(ArtPressStyle())
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .accessibilityLabel(label)
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
