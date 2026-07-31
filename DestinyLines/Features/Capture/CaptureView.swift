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
        ArtScreen(
            image: "bg_capture",
            // The raw art (863x1822) is narrower/taller than the device box, so a
            // cover-fit crops vertically no matter what. Split that crop between the
            // plain gap above the "CAPTURE YOUR HAND" ribbon and the plain gap below the
            // footer banner, each with a small buffer, so neither ever gets clipped. A
            // small left/right inset also trims part of the baked side margin — the
            // rest of that margin can't be cropped too without eating into the ribbon or
            // the banner, given this image's aspect ratio.
            verticalAnchor: 0.77,
            contentInsets: ArtInsets(left: 0.010, right: 0.010)
        ) { art in
            // bg_capture bakes in the back button's own circular well, so this places
            // just the arrow over it rather than drawing a second, misaligned circle.
            BackButton(showsBackground: false) { dismiss() }
                .artFrame(art.rect(0.0789, 0.0819, 0.102, 0.0478))

            sourceRow(art: art, plateTop: 0.5841, icon: "photo.on.rectangle", iconOffsetY: 0.0035,
                      title: "CHOOSE FROM PHOTOS", subtitle: "Upload from your library") {
                showLibraryPicker = true
            }

            sourceRow(art: art, plateTop: 0.6817, icon: "camera.fill",
                      title: "TAKE PHOTO", subtitle: "Use your camera") {
                appState.navigate(.align(source: .camera))
            }

            // Tip plate — the compass star on its left and the hand illustration on its
            // right are both painted, so the live text sits in the gap between them.
            Text("TIP: Use good lighting and show your full palm.")
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0135)))
                .foregroundStyle(Theme.goldLight)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .artFrame(art.rect(0.33, 0.791, 0.30, 0.045), alignment: .leading)
                .allowsHitTesting(false)

            // §6.1 privacy promise, scoped to us.
            Text("We delete your photo as soon as your reading is ready. We never keep it.")
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0112)))
                .foregroundStyle(Theme.goldLight.opacity(0.78))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .artFrame(art.rect(0.12, 0.855, 0.76, 0.033))
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

    /// Live content over one of the painted source-row plates. `plateTop` is the
    /// measured top border of that plate (row1 0.5841, row2 0.6817); both plates share
    /// the same height (~0.0785) and the same left/right borders (0.185–0.79). The icon
    /// well's center sits a fixed 0.0352 below its plate's top border on both rows —
    /// all measured directly off bg_capture, pixel by pixel.
    @ViewBuilder
    private func sourceRow(
        art: ArtGeometry, plateTop: CGFloat, icon: String, iconOffsetY: CGFloat = 0,
        title: String, subtitle: String, action: @escaping () -> Void
    ) -> some View {
        let plateHeight: CGFloat = 0.0785
        let iconCenterY = plateTop + 0.0352
        let iconCenterX: CGFloat = 0.2897

        Image(systemName: icon)
            .font(.system(size: art.fontSize(0.026), weight: .medium))
            .foregroundStyle(Theme.goldBevel)
            .artFrame(art.rect(iconCenterX - 0.05, iconCenterY - 0.025 + iconOffsetY, 0.10, 0.05))
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
        .artFrame(art.rect(0.375, iconCenterY - 0.025, 0.34, 0.05), alignment: .leading)
        .allowsHitTesting(false)

        Image(systemName: "chevron.right")
            .font(.system(size: art.fontSize(0.0125), weight: .semibold))
            .foregroundStyle(Theme.gold)
            .artFrame(art.rect(0.725, iconCenterY - 0.02, 0.05, 0.04))
            .allowsHitTesting(false)

        ArtHotspot(rect: art.rect(0.185, plateTop, 0.605, plateHeight),
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
