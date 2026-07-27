import PhotosUI
import SwiftUI

/// Capture over the painted camera background. The ribbon title, preview frame, two row
/// plates and the tip plate are painted; this supplies the live labels, icons and the
/// §6.1 privacy line.
struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var submission = PalmSubmission()
    @State private var photosItem: PhotosPickerItem?
    @State private var showLibraryPicker = false

    var body: some View {
        ArtScreen(image: "bg_capture") { art in
            BackButton { dismiss() }
                .artFrame(art.rect(0.045, 0.055, 0.12, 0.045))

            sourceRow(art: art, y: 0.622, icon: "photo.on.rectangle",
                      title: "CHOOSE FROM PHOTOS", subtitle: "Upload from your library") {
                showLibraryPicker = true
            }

            sourceRow(art: art, y: 0.700, icon: "camera.fill",
                      title: "TAKE PHOTO", subtitle: "Use your camera") {
                appState.navigate(.align(source: .camera))
            }

            // Tip plate — the hand illustration on its right is painted.
            HStack(spacing: art.frame.width * 0.02) {
                Sparkle(size: art.fontSize(0.011))
                Text("TIP: Use good lighting and show your full palm.")
                    .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0135)))
                    .foregroundStyle(Theme.goldLight)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
            }
            .artFrame(art.rect(0.15, 0.775, 0.55, 0.05), alignment: .leading)
            .allowsHitTesting(false)

            // §6.1 privacy promise, scoped to us.
            Text("We delete your photo as soon as your reading is ready. We never keep it.")
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0112)))
                .foregroundStyle(Theme.goldLight.opacity(0.78))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .artFrame(art.rect(0.12, 0.855, 0.76, 0.045))
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
            if case .failed(let message) = submission.state { Text(message) }
        }
    }

    /// Live content over one of the painted source-row plates.
    @ViewBuilder
    private func sourceRow(
        art: ArtGeometry, y: CGFloat, icon: String,
        title: String, subtitle: String, action: @escaping () -> Void
    ) -> some View {
        Image(systemName: icon)
            .font(.system(size: art.fontSize(0.018), weight: .medium))
            .foregroundStyle(Theme.goldBevel)
            .artFrame(art.rect(0.135, y + 0.002, 0.09, 0.045))
            .allowsHitTesting(false)

        VStack(alignment: .leading, spacing: art.frame.height * 0.002) {
            Text(title)
                .font(.custom("Rye-Regular", size: art.fontSize(0.0158)))
                .foregroundStyle(Theme.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(subtitle)
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.012)))
                .foregroundStyle(Theme.goldLight.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .artFrame(art.rect(0.255, y, 0.56, 0.05), alignment: .leading)
        .allowsHitTesting(false)

        Image(systemName: "chevron.right")
            .font(.system(size: art.fontSize(0.0125), weight: .semibold))
            .foregroundStyle(Theme.gold)
            .artFrame(art.rect(0.83, y, 0.06, 0.05))
            .allowsHitTesting(false)

        ArtHotspot(rect: art.rect(0.10, y - 0.008, 0.80, 0.066),
                   label: "\(title). \(subtitle)", action: action)
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
