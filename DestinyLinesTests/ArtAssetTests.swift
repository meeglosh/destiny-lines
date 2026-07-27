import AVFoundation
import Foundation
import Testing
import UIKit
@testable import DestinyLines

/// Guards on properties of the bundled artwork that the app's behaviour depends on.
@MainActor
struct ArtAssetTests {

    /// The Align screen shows the live camera *through* the artwork: the viewfinder
    /// interior of bg_align is luminance-keyed to transparent so the baked glow,
    /// crosshairs and brackets stay painted on top of the feed.
    ///
    /// This regressed once when a batch image-cleanup script called `.convert("RGB")`
    /// over every asset, silently flattening the alpha and leaving the camera hidden
    /// behind opaque art. Nothing failed to build and no screenshot caught it, because
    /// the simulator has no camera. Hence this test, which inspects the compiled asset.
    @Test func alignArtViewfinderIsTransparent() throws {
        let image = try #require(UIImage(named: "bg_align"), "bg_align missing from the bundle")
        let cgImage = try #require(image.cgImage)

        // Must match AlignHandView.viewfinder.
        let viewfinder = (x: 0.140, y: 0.276, w: 0.722, h: 0.449)
        let width = cgImage.width
        let height = cgImage.height

        let region = CGRect(
            x: Int(viewfinder.x * Double(width)),
            y: Int(viewfinder.y * Double(height)),
            width: Int(viewfinder.w * Double(width)),
            height: Int(viewfinder.h * Double(height))
        )
        let cropped = try #require(cgImage.cropping(to: region))

        // Render into a known RGBA buffer so we can read the alpha channel directly.
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
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))

        let alphas = stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
        let transparentShare = Double(alphas.filter { $0 < 40 }.count) / Double(alphas.count)

        #expect(
            transparentShare > 0.25,
            """
            bg_align's viewfinder is \(Int(transparentShare * 100))% transparent — the camera \
            feed will not be visible through it. The alpha channel was probably flattened by \
            an image-processing step; regenerate the asset preserving RGBA.
            """
        )
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
