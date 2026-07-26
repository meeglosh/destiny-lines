import Photos
import SwiftUI

/// Share, rebuilt from components: live header, the composited share card preview
/// (comp card art + real insights), and the two action plates.
struct ShareReadingView: View {
    let reading: Reading

    @Environment(\.dismiss) private var dismiss

    @State private var cardImage: UIImage?
    @State private var saveMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ZStack {
                    VStack(spacing: 4) {
                        Text("SHARE YOUR READING")
                            .font(Typography.title)
                            .foregroundStyle(Theme.goldBevel)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .padding(.horizontal, 70)
                        Text("Share your destiny with the world")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.goldLight.opacity(0.85))
                    }
                    HStack {
                        BackButton { dismiss() }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)

                // scaleEffect keeps the layout box at full size, so the shrunk visual must
                // be re-framed to its scaled dimensions with the default center anchor —
                // an off-center anchor slides the visual out of the frame.
                ShareCardComposite(reading: reading)
                    .scaleEffect(0.42)
                    .frame(width: 610 * 0.42, height: 1099 * 0.42)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Theme.gold.opacity(0.8), lineWidth: 1.5)
                    )
                    .accessibilityLabel("Preview of your share card")

                VStack(spacing: Theme.cardSpacing) {
                    if let cardImage {
                        ShareLink(
                            item: Image(uiImage: cardImage),
                            preview: SharePreview("My Palm Reading", image: Image(uiImage: cardImage))
                        ) {
                            plateLabel("SHARE NOW")
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityLabel("Share Now")
                    } else {
                        plateLabel("PREPARING...")
                            .opacity(0.6)
                    }

                    ArtPlateButton(style: .crimson, text: "SAVE TO PHOTOS", enabled: cardImage != nil) {
                        Task { await saveToPhotos() }
                    }
                }
                .padding(.horizontal, 26)
                .frame(maxWidth: 480)

                HStack(spacing: 8) {
                    Sparkle(size: 10)
                    Text("Your reading. Your story. Share your destiny.")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.goldLight.opacity(0.8))
                    Sparkle(size: 10)
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .boothBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { renderCard() }
        .alert("Saved", isPresented: Binding(get: { saveMessage != nil }, set: { _ in saveMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private func plateLabel(_ text: String) -> some View {
        Image("plate_crimson")
            .resizable()
            .scaledToFit()
            .overlay(
                GeometryReader { proxy in
                    HStack(spacing: proxy.size.height * 0.12) {
                        Sparkle(size: proxy.size.height * 0.11)
                        Text(text)
                            .font(.custom("Rye-Regular", size: proxy.size.height * 0.34))
                            .kerning(1.5)
                            .foregroundStyle(Theme.goldBevel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Sparkle(size: proxy.size.height * 0.11)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            )
    }

    // MARK: - Card rendering

    /// The shared/saved image: the comp's card art with the real insights typeset in.
    @MainActor
    private func renderCard() {
        let renderer = ImageRenderer(content: ShareCardComposite(reading: reading))
        renderer.scale = 2
        cardImage = renderer.uiImage
    }

    private func saveToPhotos() async {
        guard let cardImage else { return }
        // Add-only access; never full library (§10).
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            saveMessage = "Photo access is off. Allow adding photos in Settings to save your card."
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: cardImage)
            }
            saveMessage = "Your reading card is in your photo library."
        } catch {
            saveMessage = "The card could not be saved. Try again."
        }
    }
}

/// The share card: comp card art + real insight text, rendered at story proportions.
struct ShareCardComposite: View {
    let reading: Reading

    // share_card_art is 610x1099; insight rows measured in its own space.
    private let width: CGFloat = 610
    private let height: CGFloat = 1099
    private let rows: [CGFloat] = [0.700, 0.769, 0.838, 0.905]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("share_card_art")
                .resizable()
                .frame(width: width, height: height)

            ForEach(Array(reading.content.keyInsights.prefix(4).enumerated()), id: \.offset) { index, insight in
                Text(insight)
                    .font(.custom("AlegreyaSans-Regular", size: 19))
                    .foregroundStyle(Theme.goldLight)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(width: width * 0.60, alignment: .leading)
                    .position(x: width * 0.585, y: height * rows[index])
            }
        }
        .frame(width: width, height: height)
    }
}
