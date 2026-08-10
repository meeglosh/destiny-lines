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
    ///
    /// Values are the text rect's *top* edge (see `art.rect`'s contract), derived from
    /// the wells' pixel-measured centers in bg_share.png — star/heart/sun/moon ring
    /// centroids at raw y fractions 0.5786, 0.6174, 0.6580, 0.6986 (luminance-threshold
    /// scan of the well column, x 221-281px of the 863x1822 export) — minus half the
    /// 0.030 row height, so each text vertically centers on its well. The previous
    /// values were shifted a full row low: text 0 sat beside well 1, and the 4th text
    /// had no well beneath it at all.
    private let insightY: [CGFloat] = [0.5636, 0.6024, 0.6430, 0.6836]

    var body: some View {
        ArtScreen(image: "bg_share", scrollable: true, bottomInset: 28) { art in
            BackButton { dismiss() }
                .artFrame(ArtChrome.backFrame())

            ForEach(Array(reading.content.keyInsights.prefix(4).enumerated()), id: \.offset) { index, insight in
                Text(insight)
                    .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0112)))
                    .foregroundStyle(Theme.goldLight)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    // x nudged from the previous 0.285 to 0.33: the well's own ring
                    // clears out to ~0.316 of the raw art (pixel-measured), so 0.285
                    // rendered the first letter of every row behind the well's glow.
                    .artFrame(art.rect(0.33, insightY[index], 0.45, 0.030), alignment: .leading)
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
    /// Same well-centered rows as the live preview's `insightY` (see `ShareReadingView`);
    /// this composite is rendered at the raw art's own 863x1822 dimensions, so the
    /// fractions are directly comparable.
    private let rows: [CGFloat] = [0.5636, 0.6024, 0.6430, 0.6836]

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
                    .frame(width: width * 0.45, alignment: .leading)
                    .offset(x: width * 0.33, y: height * rows[index])
            }
        }
        .frame(width: width, height: height)
    }
}
