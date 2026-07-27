import AVFoundation
import Observation
import SwiftUI

/// Looping background music for the whole app.
///
/// Uses the `.ambient` session category so the track respects the ring/silent switch and
/// mixes with anything else the user is playing — background music in a novelty app should
/// never hijack someone's podcast. The mute choice persists across launches.
@Observable
@MainActor
final class AudioPlayer {
    private static let mutedKey = "audio.muted"
    private static let trackName = "Glass-Palm-Carousel"

    private var player: AVAudioPlayer?

    private(set) var isMuted: Bool {
        didSet { UserDefaults.standard.set(isMuted, forKey: Self.mutedKey) }
    }

    init() {
        isMuted = UserDefaults.standard.bool(forKey: Self.mutedKey)
    }

    /// Prepare the session and begin looping, unless the user muted us previously.
    func start() {
        guard player == nil else {
            if !isMuted { player?.play() }
            return
        }

        guard let url = Bundle.main.url(forResource: Self.trackName, withExtension: "mp3") else {
            // Missing audio must never be fatal; the app is fully usable in silence.
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1   // loop forever
            player.volume = 0.55        // sits behind the UI, not over it
            player.prepareToPlay()
            self.player = player

            if !isMuted { player.play() }
        } catch {
            // Same reasoning: audio failures are never worth interrupting a reading.
        }
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            player?.pause()
        } else {
            start()
            player?.play()
        }
    }

    /// True while a screen with its own soundtrack (the analyzing clip) is showing.
    private var suspendedForVideo = false

    /// Duck out for a screen that plays its own audio, so the two don't fight.
    func pauseForVideo() {
        suspendedForVideo = true
        player?.pause()
    }

    func resumeAfterVideo() {
        suspendedForVideo = false
        if !isMuted { player?.play() }
    }

    /// Called when the app leaves/returns to the foreground.
    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if !isMuted, !suspendedForVideo { player?.play() }
        case .inactive, .background:
            player?.pause()
        @unknown default:
            break
        }
    }
}
