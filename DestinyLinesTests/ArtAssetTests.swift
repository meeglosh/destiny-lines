import AVFoundation
import Foundation
import Testing
import UIKit
@testable import DestinyLines

/// Guards on properties of the bundled artwork that the app's behaviour depends on.
@MainActor
struct ArtAssetTests {

    /// The Align screen shows the live camera *through* the guide overlay: hand_guide is
    /// luminance-keyed so the painted glow, crosshairs and brackets stay opaque while the
    /// dark glass is transparent.
    ///
    /// This regressed once when a batch image-cleanup script called `.convert("RGB")` over
    /// every asset, flattening the alpha and hiding the camera behind opaque art. Nothing
    /// failed to build and no screenshot caught it, because the simulator has no camera.
    @Test func handGuideIsKeyedForTheCameraFeed() throws {
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
        let visible = Double(alphas.filter { $0 > 110 }.count) / Double(alphas.count)

        #expect(
            transparent > 0.30,
            "hand_guide is only \(Int(transparent * 100))% transparent — the camera feed would be hidden behind it"
        )
        #expect(
            visible > 0.01,
            "hand_guide has almost no visible pixels — the guide art itself is missing"
        )
    }

    /// Every painted background and component the screens reference must be bundled. A
    /// missing imageset renders as blank space, builds green, and only shows up visually.
    @Test func allArtworkIsBundled() {
        let required = [
            // Painted screen backgrounds
            "bg_splash", "bg_home", "bg_capture", "bg_align", "bg_reading",
            "bg_history", "bg_history_list", "bg_share", "bg_paywall", "bg_frame",
            // Components
            "btn_ornate", "btn_primary", "btn_primary_alt", "btn_secondary", "btn_tertiary", "btn_history",
            "nav_active", "hand_guide",
            "selector_left", "selector_center", "selector_right",
            "selector_left_selected", "selector_center_selected", "selector_right_selected",
        ]
        for name in required {
            #expect(UIImage(named: name) != nil, "Missing bundled artwork: \(name)")
        }
    }

    /// The analyzing interstitial is a bundled clip with its own soundtrack; the screen
    /// waits for it to finish before advancing, so a missing file would strand the user.
    @Test func analyzingClipIsBundledWithAudio() async throws {
        let url = try #require(
            Bundle.main.url(forResource: "analyzing_halo", withExtension: "mp4"),
            "analyzing_halo.mp4 missing from the bundle"
        )
        let asset = AVURLAsset(url: url)

        let duration = try await asset.load(.duration).seconds
        #expect(duration > 9 && duration < 11, "Clip should be ~10s, got \(duration)")

        let audio = try await asset.loadTracks(withMediaType: .audio)
        #expect(!audio.isEmpty, "Clip has no audio track — the interstitial should play sound")

        let video = try await asset.loadTracks(withMediaType: .video)
        #expect(!video.isEmpty, "Clip has no video track")
    }
}
