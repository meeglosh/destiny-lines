import AVFoundation
import SwiftUI
import UIKit

/// Align over the painted camera-guide background. The live feed sits inside the painted
/// viewfinder, with the guide artwork drawn on top of it.
struct AlignHandView: View {
    let source: AppState.CaptureSource

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var camera = CameraController()
    @State private var submission = PalmSubmission()

    /// Viewfinder interior in the background's coordinate space — matches the region the
    /// hand-guide overlay was cut from.
    private let viewfinder = (x: 0.10, y: 0.155, w: 0.80, h: 0.545)

    var body: some View {
        ArtScreen(image: "bg_align") { art in
            let hole = art.rect(viewfinder.x, viewfinder.y, viewfinder.w, viewfinder.h)

            // Live feed inside the painted viewfinder…
            Group {
                if camera.isRunning, let session = camera.session {
                    CameraPreview(session: session)
                } else {
                    ZStack {
                        Color.black.opacity(0.9)
                        if camera.isDenied {
                            Text("Camera access is off.\nEnable it in Settings to take a photo.")
                                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0135)))
                                .foregroundStyle(Theme.goldLight)
                                .multilineTextAlignment(.center)
                                .padding(20)
                        } else {
                            ProgressView().tint(Theme.gold)
                        }
                    }
                }
            }
            .artFrame(hole)
            .clipShape(RoundedRectangle(cornerRadius: hole.width * 0.03))

            // …with the painted glow, crosshairs and brackets keyed over the top, so the
            // guide reads against the feed instead of hiding it.
            Image("hand_guide")
                .resizable()
                .artFrame(hole)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            BackButton { dismiss() }
                .artFrame(art.rect(0.045, 0.052, 0.12, 0.045))

            // Tip plate.
            HStack(spacing: art.frame.width * 0.02) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: art.fontSize(0.016)))
                    .foregroundStyle(Theme.goldBevel)
                VStack(alignment: .leading, spacing: 1) {
                    Text("TIPS FOR BEST RESULTS")
                        .font(.custom("Rye-Regular", size: art.fontSize(0.0125)))
                        .foregroundStyle(Theme.gold)
                    Text("Use good lighting and a clear background.")
                        .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0118)))
                        .foregroundStyle(Theme.goldLight.opacity(0.9))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            .artFrame(art.rect(0.145, 0.772, 0.71, 0.048), alignment: .leading)
            .allowsHitTesting(false)

            // CONTINUE plate.
            HStack(spacing: art.frame.width * 0.03) {
                Sparkle(size: art.fontSize(0.011))
                Text("CONTINUE")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.021)))
                    .kerning(1.4)
                    .foregroundStyle(Theme.goldBevel)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                Sparkle(size: art.fontSize(0.011))
            }
            .artFrame(art.rect(0.16, 0.868, 0.68, 0.050))
            .allowsHitTesting(false)

            ArtHotspot(rect: art.rect(0.11, 0.856, 0.78, 0.072),
                       label: "Continue. Takes the photo.",
                       enabled: camera.isRunning) {
                Task { await captureAndSubmit() }
            }

            if submission.state != .idle {
                WorkingVeil(text: submission.state == .checking
                            ? "Looking for your hand..."
                            : "Sending to the spirits...")
            }
        }
        .task { await camera.start() }
        .onDisappear { camera.stop() }
    }

    private func captureAndSubmit() async {
        guard let image = await camera.capturePhoto() else { return }
        if let route = await submission.submit(image) {
            appState.navigate(route)
        }
    }
}

// MARK: - Camera plumbing

@Observable
@MainActor
final class CameraController: NSObject {
    private(set) var isRunning = false
    private(set) var isDenied = false
    private(set) var session: AVCaptureSession?

    private let output = AVCapturePhotoOutput()
    private var continuation: CheckedContinuation<UIImage?, Never>?

    func start() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                isDenied = true
                return
            }
        } else if status != .authorized {
            isDenied = true
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .photo
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output)
        else {
            isDenied = true
            return
        }
        session.addInput(input)
        session.addOutput(output)

        self.session = session
        Task.detached { session.startRunning() }
        isRunning = true
    }

    func stop() {
        let session = session
        Task.detached { session?.stopRunning() }
        isRunning = false
    }

    func capturePhoto() async -> UIImage? {
        guard isRunning else { return nil }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        Task { @MainActor in
            continuation?.resume(returning: image)
            continuation = nil
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
