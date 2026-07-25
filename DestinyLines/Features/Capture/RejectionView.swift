import SwiftUI

/// §9.3a — no comp exists; designed in the established style. Shown when any gate
/// rejects the image. In-character message keyed to the reason, the same two capture
/// buttons, and explicit reassurance that the free reading is untouched. Never names
/// a moderation category.
struct RejectionView: View {
    let reason: RejectionReason

    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                BannerHeader(title: "THE MIST CLEARS...")
                    .padding(.horizontal, 48)

                MarqueeFrame(cornerRadius: 90, bulbSpacing: 32, bulbSize: 4.5) {
                    ZStack {
                        Circle().fill(Theme.crimsonFill)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.goldBevel)
                    }
                    .frame(width: 150, height: 150)
                }
                .accessibilityHidden(true)

                OrnateCard {
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
                .padding(.horizontal, 24)

                VStack(spacing: Theme.cardSpacing) {
                    ListRow(icon: "photo.on.rectangle", title: "CHOOSE FROM PHOTOS", subtitle: "Upload from your library") {
                        appState.popToRoot()
                        appState.navigate(.capture)
                    }
                    ListRow(icon: "camera.fill", title: "TAKE PHOTO", subtitle: "Use your camera") {
                        appState.popToRoot()
                        appState.navigate(.capture)
                        appState.navigate(.align(source: .camera))
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 12)
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
    }
}
