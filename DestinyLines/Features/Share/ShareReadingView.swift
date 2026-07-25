import Photos
import SwiftUI

/// DL-share-reading.png: card preview, SHARE NOW (ShareLink), SAVE TO PHOTOS
/// (add-only authorization), and the footer motto.
struct ShareReadingView: View {
    let reading: Reading

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    @State private var cardImage: UIImage?
    @State private var saveMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("SHARE YOUR READING")
                        .font(Typography.title)
                        .foregroundStyle(Theme.goldBevel)
                    Text("Share your destiny with the world")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.goldLight.opacity(0.85))
                }
                .accessibilityAddTraits(.isHeader)

                // Card preview at fit-to-screen scale.
                ShareCardView(reading: reading)
                    .frame(width: 1080, height: 1920)
                    .scaleEffect(0.28, anchor: .top)
                    .frame(width: 1080 * 0.28, height: 1920 * 0.28)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Theme.gold.opacity(0.8), lineWidth: 1.5)
                    )
                    .accessibilityLabel("Preview of your share card")

                VStack(spacing: Theme.cardSpacing) {
                    if let cardImage {
                        ShareLink(
                            item: Image(uiImage: cardImage),
                            preview: SharePreview("My Palm Reading", image: Image(uiImage: cardImage))
                        ) {
                            sharePlate(title: "SHARE NOW", icon: "square.and.arrow.up", prominent: true)
                        }
                        .buttonStyle(PressableButtonStyle())
                    } else {
                        sharePlate(title: "PREPARING...", icon: "hourglass", prominent: true)
                            .opacity(0.6)
                    }

                    Button {
                        Task { await saveToPhotos() }
                    } label: {
                        sharePlate(title: "SAVE TO PHOTOS", icon: "arrow.down.to.line", prominent: false)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(cardImage == nil)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 8) {
                    Sparkle(size: 10)
                    Text("Your reading. Your story. Share your destiny.")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.goldLight.opacity(0.8))
                    Sparkle(size: 10)
                }
                .padding(.bottom, 20)
            }
            .padding(.vertical, 8)
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
        .task { renderCard() }
        .alert("Saved", isPresented: Binding(get: { saveMessage != nil }, set: { _ in saveMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private func sharePlate(title: String, icon: String, prominent: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
            Text(title)
                .font(Typography.cta)
        }
        .foregroundStyle(prominent ? AnyShapeStyle(Theme.goldBevel) : AnyShapeStyle(Theme.gold))
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(prominent ? AnyShapeStyle(Theme.ctaFill) : AnyShapeStyle(Theme.panel))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(prominent ? AnyShapeStyle(Theme.goldBevel) : AnyShapeStyle(Theme.goldDark), lineWidth: 2)
                )
        )
    }

    /// Render the 1080x1920 card with ImageRenderer on the main actor (§10).
    @MainActor
    private func renderCard() {
        let renderer = ImageRenderer(content: ShareCardView(reading: reading).frame(width: 1080, height: 1920))
        renderer.scale = 3
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

/// The 1080x1920 story-format card itself (§10): large wordmark, banner, hand emblem,
/// at most 4 insight bullets, high-contrast gold on near-black, footer URL.
struct ShareCardView: View {
    let reading: Reading

    var body: some View {
        VStack(spacing: 40) {
            Spacer().frame(height: 30)

            VStack(spacing: 0) {
                Text("DESTINY")
                    .font(.custom("Rye-Regular", size: 110))
                Text("LINES")
                    .font(.custom("Rye-Regular", size: 110))
            }
            .foregroundStyle(Theme.goldBevel)
            .shadow(color: Theme.glow.opacity(0.5), radius: 30)

            Text("MY PALM READING")
                .font(.custom("Rye-Regular", size: 44))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 60)
                .padding(.vertical, 22)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.parchment)
                )

            Image(systemName: "hand.raised.fingers.spread.fill")
                .font(.system(size: 330))
                .foregroundStyle(Theme.goldBevel)
                .shadow(color: Theme.glow.opacity(0.7), radius: 60)

            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    Spacer()
                    Text("✦  KEY INSIGHTS  ✦")
                        .font(.custom("Rye-Regular", size: 42))
                        .foregroundStyle(Theme.gold)
                    Spacer()
                }
                ForEach(Array(reading.content.keyInsights.prefix(4)), id: \.self) { insight in
                    HStack(alignment: .top, spacing: 22) {
                        Text("✦")
                            .font(.system(size: 34))
                            .foregroundStyle(Theme.gold)
                        Text(insight)
                            .font(.custom("AlegreyaSans-Medium", size: 38))
                            .foregroundStyle(Theme.goldLight)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Theme.gold.opacity(0.9), lineWidth: 3)
                    )
            )
            .padding(.horizontal, 60)

            Spacer()

            Text("✦  Read yours at DestinyLines.app  ✦")
                .font(.custom("AlegreyaSans-Medium", size: 36))
                .foregroundStyle(Theme.gold)
                .padding(.bottom, 60)
        }
        .frame(width: 1080, height: 1920)
        .background(
            RadialGradient(
                colors: [Color(red: 0x2A / 255, green: 0x16 / 255, blue: 0x0C / 255), Theme.background],
                center: .center,
                startRadius: 100,
                endRadius: 1100
            )
        )
    }
}
