import PhotosUI
import SwiftUI

/// DL-camera.png used directly: baked banner, preview frame, source rows, tip card,
/// and footer. This view adds the tap targets, the mandated §6.1 privacy line (not in
/// the comp), the photo picker, and the Gate-1 → upload pipeline.
struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var submission = PalmSubmission()
    @State private var photosItem: PhotosPickerItem?
    @State private var showLibraryPicker = false

    var body: some View {
        ArtScreen(image: "bg_capture") { art in
            ArtHotspot(rect: art.rect(0.02, 0.045, 0.13, 0.062), label: "Back",
                       debug: ArtDebug.showHotspots) {
                dismiss()
            }

            // CHOOSE FROM PHOTOS row
            ArtHotspot(rect: art.rect(0.115, 0.585, 0.77, 0.075), label: "Choose from Photos. Upload from your library.",
                       debug: ArtDebug.showHotspots) {
                showLibraryPicker = true
            }

            // TAKE PHOTO row
            ArtHotspot(rect: art.rect(0.115, 0.685, 0.77, 0.075), label: "Take Photo. Use your camera.",
                       debug: ArtDebug.showHotspots) {
                appState.navigate(.align(source: .camera))
            }

            // §6.1 privacy line — required copy, added in the art's empty band.
            Text("We delete your photo as soon as your reading is ready. We never keep it.")
                .font(Typography.fine)
                .foregroundStyle(Theme.goldLight.opacity(0.8))
                .multilineTextAlignment(.center)
                .artFrame(art.rect(0.10, 0.875, 0.80, 0.040))
                .allowsHitTesting(false)

            if submission.state == .checking || submission.state == .uploading {
                WorkingVeil(text: submission.state == .checking
                            ? "Looking for your hand..."
                            : "Sending to the spirits...")
            }
        }
        .photosPicker(isPresented: $showLibraryPicker, selection: $photosItem, matching: .images)
        .onChange(of: photosItem) { _, item in
            guard let item else { return }
            Task { await handlePicked(item) }
        }
        .alert(
            "Try Again",
            isPresented: Binding(
                get: { if case .failed = submission.state { true } else { false } },
                set: { _ in submission = PalmSubmission() }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if case .failed(let message) = submission.state {
                Text(message)
            }
        }
    }

    private func handlePicked(_ item: PhotosPickerItem) async {
        defer { photosItem = nil }
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
        else { return }

        if let route = await submission.submit(image) {
            appState.navigate(route)
        }
    }
}

/// Dimmed working overlay shared by capture and align.
struct WorkingVeil: View {
    let text: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.gold)
                Text(text)
                    .font(Typography.bodyText)
                    .foregroundStyle(Theme.goldLight)
            }
        }
    }
}
