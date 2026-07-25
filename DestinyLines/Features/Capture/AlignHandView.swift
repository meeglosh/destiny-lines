import AVFoundation
import SwiftUI
import UIKit

/// DL-align-hand-camera.png: live camera behind a glowing hand-outline guide with
/// crosshairs and corner brackets, tips card, marquee-bulb edging, CONTINUE button.
struct AlignHandView: View {
    let source: AppState.CaptureSource

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var camera = CameraController()
    @State private var submission = PalmSubmission()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BannerHeader(title: "ALIGN YOUR HAND")
                    .padding(.horizontal, 52)

                Text("Center your hand\nand adjust to fit the guide.")
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.goldLight)
                    .multilineTextAlignment(.center)

                viewfinder

                OrnateCard(contentPadding: 12) {
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
                .padding(.horizontal, 24)

                PrimaryCTAButton(title: "CONTINUE", showsBulbs: false, isEnabled: camera.isRunning) {
                    Task { await captureAndSubmit() }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 10)
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
        .task { await camera.start() }
        .onDisappear { camera.stop() }
        .overlay {
            if submission.state != .idle {
                workingOverlay
            }
        }
    }

    private var viewfinder: some View {
        MarqueeFrame(cornerRadius: 16, bulbSpacing: 34, bulbSize: 4.5) {
            ZStack {
                if camera.isRunning, let session = camera.session {
                    CameraPreview(session: session)
                } else {
                    Rectangle().fill(Color.black.opacity(0.6))
                    VStack(spacing: 10) {
                        Image(systemName: camera.isDenied ? "video.slash.fill" : "video.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.gold.opacity(0.6))
                        Text(camera.isDenied
                             ? "Camera access is off. Enable it in Settings to take a photo."
                             : "Preparing the camera...")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.goldLight.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }

                HandGuideOverlay()
            }
            .frame(height: 430)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 22)
    }

    private var workingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.gold)
                Text(submission.state == .checking ? "Looking for your hand..." : "Sending to the spirits...")
                    .font(Typography.bodyText)
                    .foregroundStyle(Theme.goldLight)
            }
        }
    }

    private func captureAndSubmit() async {
        guard let image = await camera.capturePhoto() else { return }
        if let route = await submission.submit(image) {
            appState.navigate(route)
        }
    }
}

// MARK: - Hand guide overlay

/// Glowing hand outline, dashed crosshairs, and corner brackets over the live preview.
private struct HandGuideOverlay: View {
    var body: some View {
        ZStack {
            // Crosshair guides
            DashedLine(vertical: false)
            DashedLine(vertical: true)

            Image(systemName: "hand.raised.fingers.spread")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 280)
                .foregroundStyle(Theme.glow.opacity(0.85))
                .shadow(color: Theme.glow.opacity(0.9), radius: 12)

            CornerBrackets()
                .stroke(Theme.gold.opacity(0.9), lineWidth: 2)
                .padding(14)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private struct DashedLine: View {
        let vertical: Bool
        var body: some View {
            Rectangle()
                .fill(.clear)
                .overlay(
                    GeometryReader { proxy in
                        Path { p in
                            if vertical {
                                p.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                                p.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
                            } else {
                                p.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                                p.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
                            }
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 6]))
                        .foregroundStyle(Theme.gold.opacity(0.35))
                    }
                )
        }
    }

    private struct CornerBrackets: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            let arm: CGFloat = 22
            for (x, y, dx, dy) in [
                (rect.minX, rect.minY, 1.0, 1.0),
                (rect.maxX, rect.minY, -1.0, 1.0),
                (rect.minX, rect.maxY, 1.0, -1.0),
                (rect.maxX, rect.maxY, -1.0, -1.0),
            ] {
                p.move(to: CGPoint(x: x + dx * arm, y: y))
                p.addLine(to: CGPoint(x: x, y: y))
                p.addLine(to: CGPoint(x: x, y: y + dy * arm))
            }
            return p
        }
    }
}

// MARK: - Camera plumbing

/// Minimal AVFoundation still-capture controller.
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
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)
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

/// UIViewRepresentable wrapper for the AVCaptureVideoPreviewLayer.
private struct CameraPreview: UIViewRepresentable {
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
