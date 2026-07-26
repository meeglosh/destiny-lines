import AVFoundation
import SwiftUI
import UIKit

/// Align, rebuilt from components: live camera inside the sliced ornate card frame,
/// the comp's glowing hand-guide overlay (bright art on transparency) on top, tips
/// card, and the CONTINUE plate. No more full-screen alpha-hole art.
struct AlignHandView: View {
    let source: AppState.CaptureSource

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var camera = CameraController()
    @State private var submission = PalmSubmission()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                FlowHeader(title: "ALIGN YOUR HAND") { dismiss() }
                    .padding(.top, 4)

                Text("Center your hand and adjust to fit the guide.")
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.goldLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                viewfinder
                    .padding(.horizontal, 22)

                ArtCard(contentPadding: 12) {
                    HStack(spacing: 12) {
                        IconMedallion(systemName: "lightbulb.fill", diameter: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TIPS FOR BEST RESULTS")
                                .font(Typography.displaySmall)
                                .foregroundStyle(Theme.gold)
                            Text("Use good lighting and a clear background.")
                                .font(Typography.caption)
                                .foregroundStyle(Theme.goldLight)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 22)

                ArtPlateButton(style: .crimson, text: "CONTINUE", enabled: camera.isRunning) {
                    Task { await captureAndSubmit() }
                }
                .padding(.horizontal, 26)
                .frame(maxWidth: 480)
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .boothBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { await camera.start() }
        .onDisappear { camera.stop() }
        .overlay {
            if submission.state != .idle {
                WorkingVeil(text: submission.state == .checking
                            ? "Looking for your hand..."
                            : "Sending to the spirits...")
            }
        }
    }

    private var viewfinder: some View {
        ArtCard(contentPadding: 8) {
            ZStack {
                if camera.isRunning, let session = camera.session {
                    CameraPreview(session: session)
                } else {
                    Rectangle().fill(Color.black.opacity(0.75))
                    if camera.isDenied {
                        Text("Camera access is off.\nEnable it in Settings to take a photo.")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.goldLight)
                            .multilineTextAlignment(.center)
                            .padding(20)
                    } else {
                        ProgressView().tint(Theme.gold)
                    }
                }

                // The comp's glowing hand guide, crosshairs and brackets — bright art
                // on transparency, so the feed shows through around it.
                Image("hand_guide")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .aspectRatio(0.74, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
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
