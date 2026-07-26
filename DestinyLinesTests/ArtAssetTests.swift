import Foundation
import Testing
import UIKit
@testable import DestinyLines

/// Guards on properties of the bundled artwork that the app's behaviour depends on.
@MainActor
struct ArtAssetTests {

    /// The Align screen layers the hand-guide slice OVER the live camera feed: bright
    /// guide art opaque, everything else transparent so the camera shows through.
    ///
    /// This class of bug shipped once — a batch image-cleanup script flattened an
    /// alpha channel with `.convert("RGB")` and the camera vanished behind opaque art,
    /// with a green build and no screenshot able to catch it (the simulator has no
    /// camera). Hence a test on the compiled asset.
    @Test func handGuideIsMostlyTransparentWithVisibleArt() throws {
        let image = try #require(UIImage(named: "hand_guide"), "hand_guide missing from the bundle")
        let cgImage = try #require(image.cgImage)

        let sampleWidth = 60
        let sampleHeight = 80
        var pixels = [UInt8](repeating: 0, count: sampleWidth * sampleHeight * 4)
        let context = try #require(
            CGContext(
                data: &pixels,
                width: sampleWidth,
                height: sampleHeight,
                bitsPerComponent: 8,
                bytesPerRow: sampleWidth * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))

        let alphas = stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
        let transparent = Double(alphas.filter { $0 < 40 }.count) / Double(alphas.count)
        // The guide is a soft luminance-keyed glow: almost nothing is fully opaque,
        // so "visible art" means meaningfully semi-opaque pixels.
        let visible = Double(alphas.filter { $0 > 110 }.count) / Double(alphas.count)

        #expect(
            transparent > 0.30,
            "hand_guide is only \(Int(transparent * 100))% transparent — the camera feed would be hidden behind it"
        )
        #expect(
            visible > 0.01,
            "hand_guide has almost no visible pixels (\(visible)) — the guide art itself is missing"
        )
    }

    /// Every sliced component the screens reference must exist in the bundle. A missing
    /// imageset renders as blank space, builds green, and only shows up visually.
    @Test func allComponentSlicesAreBundled() {
        let required = [
            "arch_wordmark", "hand_medallion_big", "caption_plate", "plate_red",
            "plate_crimson", "plate_green", "ribbon_straight", "preview_panel",
            "tip_card", "card_frame", "medallion_life", "medallion_head",
            "medallion_heart", "medallion_fate", "crystal_trophy", "plan_card_dark",
            "plan_card_bulbs", "analyzing_ring_hand", "crystal_ball_small",
            "crystal_ball_footer", "corner_flourish", "booth_texture", "hand_guide",
            "share_card_art", "bg_splash",
        ]
        for name in required {
            #expect(UIImage(named: name) != nil, "Missing bundled component: \(name)")
        }
    }
}
