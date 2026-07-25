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
    func submit(_ image: UIImage) async -> AppState.Route? {
        state = .checking

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
