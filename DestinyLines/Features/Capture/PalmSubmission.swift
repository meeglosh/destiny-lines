import SwiftUI
import UIKit

/// Orchestrates the client half of the pipeline for one photo:
/// Gate 1 → downscale/EXIF-strip → request-upload → presigned PUT.
/// The image lives only in memory and is released when this finishes (§6.1.5).
@Observable
@MainActor
final class PalmSubmission {
    enum State: Equatable {
        case idle
        case checking       // Gate 1
        case uploading
        case failed(String)
    }

    private(set) var state: State = .idle

    /// Runs the client pipeline. Returns the route to push next.
    ///
    /// - Parameter croppedToAspect: when non-nil, the captured still is cropped to this
    ///   width:height ratio (centered, matching `resizeAspectFill`'s crop) before Gate 1
    ///   or upload sees it. Callers whose capture UI showed the live feed through an
    ///   aspect-filled hole must pass that hole's aspect so the judged/submitted pixels
    ///   match what the user actually aligned — otherwise Gate 1 and the reading model
    ///   see content the user never saw framed in the viewfinder.
    func submit(_ image: UIImage, croppedToAspect aspect: CGFloat? = nil) async -> AppState.Route? {
        state = .checking

        let image = aspect.map { ImageProcessor.crop(image, toAspect: $0) } ?? image

        // GATE 1 — on-device. A miss here never leaves the phone (§6.2).
        let handDetected = (try? await ImageProcessor.detectHand(in: image)) ?? false
        guard handDetected else {
            state = .idle
            return .rejection(.noHand)
        }

        guard let jpeg = ImageProcessor.prepareForUpload(image) else {
            state = .failed("Could not process that photo. Try another.")
            return nil
        }

        state = .uploading
        do {
            let slot = try await SupabaseService.shared.requestUploadSlot()
            try await SupabaseService.shared.upload(jpegData: jpeg, to: slot.uploadURL)
            state = .idle
            return .analyzing(objectKey: slot.objectKey)
        } catch PipelineError.rateLimited {
            state = .failed("The spirits need a moment to rest. Try again shortly.")
            return nil
        } catch {
            state = .failed("The connection to the beyond faltered. Check your network and try again.")
            return nil
        }
    }
}
