import PhotosUI
import SwiftUI

/// Capture, rebuilt from components: ribbon title, the sliced preview panel (ornate
/// frame + photographic palm), two source rows, the tip card with live copy, and the
/// §6.1 privacy line. Everything reflows; nothing can sit under device hardware.
struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var submission = PalmSubmission()
    @State private var photosItem: PhotosPickerItem?
    @State private var showLibraryPicker = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                FlowHeader(title: "CAPTURE YOUR HAND") { dismiss() }
                    .padding(.top, 4)

                Text("Take a clear photo of your palm")
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.goldLight)

                Image("preview_panel")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 380)
                    .padding(.horizontal, 40)
                    .accessibilityHidden(true)

                VStack(spacing: Theme.cardSpacing) {
                    ArtListRow(
                        medallion: .symbol("photo.on.rectangle"),
                        title: "CHOOSE FROM PHOTOS",
                        subtitle: "Upload from your library"
                    ) {
                        showLibraryPicker = true
                    }

                    ArtListRow(
                        medallion: .symbol("camera.fill"),
                        title: "TAKE PHOTO",
                        subtitle: "Use your camera"
                    ) {
                        appState.navigate(.align(source: .camera))
                    }

                    tipCard

                    // §6.1 privacy promise, scoped to us.
                    Text("We delete your photo as soon as your reading is ready. We never keep it.")
                        .font(Typography.fine)
                        .foregroundStyle(Theme.goldLight.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.horizontal, 22)
                .frame(maxWidth: 520)
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .boothBackground()
        .toolbar(.hidden, for: .navigationBar)
        .photosPicker(isPresented: $showLibraryPicker, selection: $photosItem, matching: .images)
        .onChange(of: photosItem) { _, item in
            guard let item else { return }
            Task { await handlePicked(item) }
        }
        .overlay {
            if submission.state == .checking || submission.state == .uploading {
                WorkingVeil(text: submission.state == .checking
                            ? "Looking for your hand..."
                            : "Sending to the spirits...")
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

    /// The comp's tip card slice (text erased, hand illustration kept) with live copy.
    private var tipCard: some View {
        Image("tip_card")
            .resizable()
            .scaledToFit()
            .overlay(
                GeometryReader { proxy in
                    HStack(spacing: 8) {
                        Sparkle(size: proxy.size.height * 0.14)
                        Text("TIP: Use good lighting and show your full palm.")
                            .font(.custom("AlegreyaSans-Regular", size: proxy.size.height * 0.17))
                            .foregroundStyle(Theme.goldLight)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(width: proxy.size.width * 0.62, height: proxy.size.height)
                    .position(x: proxy.size.width * 0.38, y: proxy.size.height / 2)
                }
            )
            .accessibilityLabel("Tip: use good lighting and show your full palm.")
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
