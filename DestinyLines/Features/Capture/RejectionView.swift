import SwiftUI

/// Rejection state (§9.3a — no comp exists; composed from the component library).
/// Shown when any gate rejects the image: in-character message keyed to the reason,
/// the same two capture options, and explicit reassurance that the free reading is
/// untouched. Never names a moderation category.
struct RejectionView: View {
    let reason: RejectionReason

    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                RibbonBanner(text: "THE MIST CLEARS...")
                    .padding(.horizontal, 56)
                    .padding(.top, 8)

                Image("crystal_ball_small")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130)
                    .accessibilityHidden(true)

                ArtCard {
                    VStack(spacing: 10) {
                        Text(reason.message)
                            .font(Typography.bodyEmphasis)
                            .foregroundStyle(Theme.goldLight)
                            .multilineTextAlignment(.center)

                        OrnamentDivider()
                            .padding(.horizontal, 30)

                        Text("Your free reading has not been used.")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.gold)
                    }
                }
                .padding(.horizontal, 22)

                VStack(spacing: Theme.cardSpacing) {
                    ArtListRow(
                        medallion: .symbol("photo.on.rectangle"),
                        title: "CHOOSE FROM PHOTOS",
                        subtitle: "Upload from your library"
                    ) {
                        appState.popToRoot()
                        appState.navigate(.capture)
                    }
                    ArtListRow(
                        medallion: .symbol("camera.fill"),
                        title: "TAKE PHOTO",
                        subtitle: "Use your camera"
                    ) {
                        appState.popToRoot()
                        appState.navigate(.capture)
                        appState.navigate(.align(source: .camera))
                    }
                }
                .padding(.horizontal, 22)
                .frame(maxWidth: 520)
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .boothBackground()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
    }
}
