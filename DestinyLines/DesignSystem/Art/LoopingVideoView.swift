import AVFoundation
import SwiftUI
import UIKit

/// Plays a bundled video on a loop, with its own audio, and reports each time it
/// completes a full pass.
///
/// Used for the analyzing interstitial, where the whole clip must play through at least
/// once before the app moves on. Looping (rather than freezing on the last frame) covers
/// the case where the server takes longer than the clip.
struct LoopingVideoView: UIViewRepresentable {
    let resource: String
    let fileExtension: String
    /// Muted playback still shows the video; used to honour the app's sound toggle.
    var isMuted: Bool
    /// Fired on the main actor every time the clip reaches its end.
    var onLoopComplete: () -> Void

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.configure(resource: resource, fileExtension: fileExtension)
        view.onLoopComplete = onLoopComplete
        view.setMuted(isMuted)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.onLoopComplete = onLoopComplete
        uiView.setMuted(isMuted)
    }

    static func dismantleUIView(_ uiView: PlayerView, coordinator: ()) {
        uiView.teardown()
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private var endObserver: NSObjectProtocol?

        var onLoopComplete: (() -> Void)?

        func configure(resource: String, fileExtension: String) {
            guard
                player == nil,
                let url = Bundle.main.url(forResource: resource, withExtension: fileExtension)
            else { return }

            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer(playerItem: item)
            queuePlayer.actionAtItemEnd = .advance
            // AVPlayerLooper gives gapless repetition; the notification below still fires
            // once per pass because the looper recycles the same underlying item.
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

            playerLayer.player = queuePlayer
            playerLayer.videoGravity = .resizeAspect
            player = queuePlayer

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.onLoopComplete?()
            }

            queuePlayer.play()
        }

        func setMuted(_ muted: Bool) {
            player?.isMuted = muted
        }

        func teardown() {
            player?.pause()
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = nil
            looper = nil
            player = nil
            playerLayer.player = nil
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }
}
