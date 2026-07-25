import AVFoundation
import SwiftUI
import UIKit

/// DL-align-hand-camera.png used directly. The viewfinder interior of the art has been
/// made luminance-transparent, so the live camera feed shows through the dark glass
/// while the baked glowing hand guide, crosshairs, and brackets stay on top.
struct AlignHandView: View {
    let source: AppState.CaptureSource

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var camera = CameraController()
    @State private var submission = PalmSubmission()

    /// Viewfinder interior in art-normalized coordinates (matches the alpha hole).
    private let viewfinder = (x: 0.140, y: 0.276, w: 0.722, h: 0.449)

    var body: some View {
        GeometryReader { proxy in
            let full = CGRect(
                x: -proxy.safeAreaInsets.leading,
                y: -proxy.safeAreaInsets.top,
                width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            )
            let art = ArtGeometry(frame: full)
            let holeRect = art.rect(viewfinder.x, viewfinder.y, viewfinder.w, viewfinder.h)

            ZStack(alignment: .topLeading) {
                // Live camera behind the art's transparent viewfinder.
                if camera.isRunning, let session = camera.session {
                    CameraPreview(session: session)
                        .frame(width: holeRect.width, height: holeRect.height)
                        .position(x: holeRect.midX, y: holeRect.midY)
                } else {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: holeRect.width, height: holeRect.height)
                        .position(x: holeRect.midX, y: holeRect.midY)
                }

                Image("bg_align")
                    .resizable()
                    .frame(width: full.width, height: full.height)
                    .offset(x: full.minX, y: full.minY)
                    .allowsHitTesting(false)

                if camera.isDenied {
                    Text("Camera access is off.\nEnable it in Settings to take a photo.")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.goldLight)
                        .multilineTextAlignment(.center)
                        .position(x: holeRect.midX, y: holeRect.midY)
                }

                ArtHotspot(rect: art.rect(0.02, 0.02, 0.14, 0.05), label: "Back",
                           debug: ArtDebug.showHotspots) {
                    dismiss()
                }

                // CONTINUE plate
                ArtHotspot(rect: art.rect(0.13, 0.872, 0.74, 0.075), label: "Continue. Takes the photo.",
                           debug: ArtDebug.showHotspots) {
                    Task { await captureAndSubmit() }
                }

                if submission.state != .idle {
                    WorkingVeil(text: submission.state == .checking
                                ? "Looking for your hand..."
                                : "Sending to the spirits...")
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
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
