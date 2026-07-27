import Photos
import SwiftUI

/// Share over the painted card background. The wordmark, ribbon, hand and KEY INSIGHTS
/// header are painted; the insights themselves and both action plates are live.
struct ShareReadingView: View {
    let reading: Reading

    @Environment(\.dismiss) private var dismiss

    @State private var cardImage: UIImage?
    @State private var saveMessage: String?

    /// The four painted insight rows: icon wells on the left, text to their right.
    private let insightY: [CGFloat] = [0.618, 0.652, 0.686, 0.720]

    var body: some View {
        ArtScreen(image: "bg_share") { art in
            BackButton { dismiss() }
                .artFrame(art.rect(0.05, 0.045, 0.11, 0.045))

            ForEach(Array(reading.content.keyInsights.prefix(4).enumerated()), id: \.offset) { index, insight in
                Text(insight)
                    .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0112)))
                    .foregroundStyle(Theme.goldLight)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .artFrame(art.rect(0.285, insightY[index], 0.50, 0.030), alignment: .leading)
                    .allowsHitTesting(false)
            }

            // SHARE NOW plate.
            if let cardImage {
                ShareLink(
                    item: Image(uiImage: cardImage),
                    preview: SharePreview("My Palm Reading", image: Image(uiImage: cardImage))
                ) {
                    plateLabel("SHARE NOW", art: art)
                }
                .buttonStyle(ArtPressStyle())
                .artFrame(art.rect(0.10, 0.812, 0.80, 0.055))
                .accessibilityLabel("Share Now")
            } else {
                plateLabel("PREPARING...", art: art)
                    .opacity(0.6)
                    .artFrame(art.rect(0.10, 0.812, 0.80, 0.055))
                    .allowsHitTesting(false)
            }

            // SAVE TO PHOTOS plate.
            plateLabel("SAVE TO PHOTOS", art: art)
                .artFrame(art.rect(0.10, 0.888, 0.80, 0.055))
                .allowsHitTesting(false)

            ArtHotspot(rect: art.rect(0.08, 0.878, 0.84, 0.072),
                       label: "Save to Photos", enabled: cardImage != nil) {
                Task { await saveToPhotos() }
            }
        }
        .task { renderCard() }
        .alert("Saved", isPresented: Binding(get: { saveMessage != nil }, set: { _ in saveMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private func plateLabel(_ text: String, art: ArtGeometry) -> some View {
        HStack(spacing: art.frame.width * 0.03) {
            Sparkle(size: art.fontSize(0.011))
            Text(text)
                .font(.custom("Rye-Regular", size: art.fontSize(0.0205)))
                .kerning(1.2)
                .foregroundStyle(Theme.goldBevel)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            Sparkle(size: art.fontSize(0.011))
        }
    }

    // MARK: - Card rendering

    /// The shared image: the painted share background with the real insights typeset in,
    /// rendered at full artwork resolution.
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

/// The shareable card: the painted share artwork with live insights typeset into it.
struct ShareCardComposite: View {
    let reading: Reading

    /// Rendered at the artwork's own proportions (863 x 1822 → a story-shaped card).
    private let width: CGFloat = 863
    private let height: CGFloat = 1822
    private let rows: [CGFloat] = [0.612, 0.647, 0.682, 0.717]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("bg_share")
                .resizable()
                .frame(width: width, height: height)

            ForEach(Array(reading.content.keyInsights.prefix(4).enumerated()), id: \.offset) { index, insight in
                Text(insight)
                    .font(.custom("AlegreyaSans-Regular", size: height * 0.0122))
                    .foregroundStyle(Theme.goldLight)
                    .lineLimit(2)
                    .frame(width: width * 0.55, alignment: .leading)
                    .offset(x: width * 0.245, y: height * rows[index])
            }
        }
        .frame(width: width, height: height)
    }
}
