import PhotosUI
import SwiftUI

/// DL-camera.png: "CAPTURE YOUR HAND" banner, preview frame, the two source rows,
/// the lighting tip card, the §6.1 privacy line, and the footer banner.
struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var submission = PalmSubmission()
    @State private var photosItem: PhotosPickerItem?
    @State private var showLibraryPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BannerHeader(title: "CAPTURE YOUR HAND")
                    .padding(.horizontal, 44)

                Text("Take a clear photo\nof your palm")
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.goldLight)
                    .multilineTextAlignment(.center)

                previewFrame

                VStack(spacing: Theme.cardSpacing) {
                    ListRow(icon: "photo.on.rectangle", title: "CHOOSE FROM PHOTOS", subtitle: "Upload from your library") {
                        showLibraryPicker = true
                    }
                    ListRow(icon: "camera.fill", title: "TAKE PHOTO", subtitle: "Use your camera") {
                        appState.navigate(.align(source: .camera))
                    }

                    OrnateCard(contentPadding: 12) {
                        HStack(spacing: 12) {
                            Sparkle()
                            Text("TIP: Use good lighting and show your full palm.")
                                .font(Typography.caption)
                                .foregroundStyle(Theme.goldLight)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "hand.raised.fingers.spread")
                                .foregroundStyle(Theme.gold)
                                .accessibilityHidden(true)
                        }
                    }

                    // The §6.1 privacy promise, scoped to us.
                    Text("We delete your photo as soon as your reading is ready. We never keep it.")
                        .font(Typography.fine)
                        .foregroundStyle(Theme.goldLight.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.horizontal, 24)

                BannerHeader(title: "YOUR FUTURE IS IN YOUR HANDS")
                    .padding(.horizontal, 60)
                    .padding(.top, 8)
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
        .photosPicker(isPresented: $showLibraryPicker, selection: $photosItem, matching: .images)
        .onChange(of: photosItem) { _, item in
            guard let item else { return }
            Task { await handlePicked(item) }
        }
        .overlay {
            if submission.state == .checking || submission.state == .uploading {
                workingOverlay
            }
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

    private var previewFrame: some View {
        OrnateCard(contentPadding: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.55))
                Image(systemName: "hand.raised.fingers.spread.fill")
                    .font(.system(size: 130))
                    .foregroundStyle(Theme.gold.opacity(0.5))
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 24)
        .accessibilityHidden(true)
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
