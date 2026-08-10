import SwiftUI

/// Rejection state (§9.3a — no comp exists; composed on the ornate frame). Shown when any
/// gate turns the photo away: an in-character message keyed to the reason, the two capture
/// options again, and explicit reassurance that the free reading is untouched. Never names
/// a moderation category.
struct RejectionView: View {
    let reason: RejectionReason

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ArtScreen(image: "bg_frame") { art in
            BackButton { dismiss() }
                .artFrame(ArtChrome.backFrame())

            VStack(spacing: art.frame.height * 0.014) {
                Text("THE MIST CLEARS...")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.026)))
                    .foregroundStyle(Theme.goldBevel)
                    .shadow(color: Theme.glow.opacity(0.35), radius: 8)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                OrnamentDivider()
                    .frame(width: art.frame.width * 0.55)

                IconMedallion(systemName: "moon.stars.fill", diameter: art.frame.width * 0.22)
                    .padding(.vertical, art.frame.height * 0.012)

                Text(reason.message)
                    .font(.custom("AlegreyaSans-Medium", size: art.fontSize(0.0158)))
                    .foregroundStyle(Theme.goldLight)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your free reading has not been used.")
                    .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0128)))
                    .foregroundStyle(Theme.gold)
                    .padding(.top, art.frame.height * 0.004)
            }
            .artFrame(art.rect(0.13, 0.20, 0.74, 0.40))

            VStack(spacing: art.frame.height * 0.010) {
                ArtRow(icon: "photo.on.rectangle", title: "CHOOSE FROM PHOTOS",
                       subtitle: "Upload from your library") {
                    appState.popToRoot()
                    appState.navigate(.capture)
                }
                ArtRow(icon: "camera.fill", title: "TAKE PHOTO", subtitle: "Use your camera") {
                    appState.popToRoot()
                    appState.navigate(.capture)
                    appState.navigate(.align(source: .camera))
                }
            }
            .artFrame(art.rect(0.115, 0.645, 0.77, 0.19))
        }
        .navigationBarBackButtonHidden()
    }
}
