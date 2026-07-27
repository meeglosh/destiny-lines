import Photos
import SwiftUI

/// DL-share-reading.png used directly (bg_share_clean: the sample insight text has
/// been lifted out of the card). Real key insights are typeset back into the card in
/// the comp's style, both on screen and in the shared/saved image.
struct ShareReadingView: View {
    let reading: Reading

    @Environment(\.dismiss) private var dismiss

    @State private var cardImage: UIImage?
    @State private var saveMessage: String?

    /// The four insight rows in art-normalized space (icon column is baked art).
    private let insightRows: [(y: CGFloat, height: CGFloat)] = [
        (0.582, 0.045), (0.627, 0.045), (0.671, 0.045), (0.714, 0.045),
    ]

    var body: some View {
        ArtScreen(image: "bg_share_clean") { art in
            ArtHotspot(rect: art.rect(0.02, 0.035, 0.14, 0.055), label: "Back",
                       debug: ArtDebug.showHotspots) {
                dismiss()
            }

            // Real insights typeset into the cleaned card region.
            insightTexts(art)

            // SHARE NOW plate
            shareNowHotspot(art)

            // SAVE TO PHOTOS plate
            ArtHotspot(rect: art.rect(0.075, 0.906, 0.85, 0.062), label: "Save to Photos",
                       debug: ArtDebug.showHotspots) {
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

    @ViewBuilder
    private func insightTexts(_ art: ArtGeometry) -> some View {
        let insights = Array(reading.content.keyInsights.prefix(4))
        ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
            let row = insightRows[index]
            Text(insight)
                .font(.custom("AlegreyaSans-Regular", size: art.frame.height * 0.0155))
                .foregroundStyle(Theme.goldLight)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .artFrame(art.rect(0.328, row.y - row.height / 2, 0.50, row.height), alignment: .leading)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func shareNowHotspot(_ art: ArtGeometry) -> some View {
        if let cardImage {
            ShareLink(
                item: Image(uiImage: cardImage),
                preview: SharePreview("My Palm Reading", image: Image(uiImage: cardImage))
            ) {
                Rectangle().fill(Color.clear)
            }
            .buttonStyle(ArtPressStyle())
            .artFrame(art.rect(0.075, 0.821, 0.85, 0.070))
            .accessibilityLabel("Share Now")
        }
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
