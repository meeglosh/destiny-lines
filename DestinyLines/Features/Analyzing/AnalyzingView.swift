import SwiftUI

/// Analyzing interstitial: the animated halo clip plays with its own audio, and the app
/// only moves on once BOTH the clip has run at least once end-to-end AND the server has
/// answered. The clip carries its own banner, caption and framing; the empty plate at
/// the bottom is deliberately blank so the live copy below can sit inside it.
struct AnalyzingView: View {
    let objectKey: String

    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(AudioPlayer.self) private var audio

    /// Interior of the plate baked into the video, in the clip's normalized space.
    /// Measured from the artwork: the frame runs 0.115...0.885 across, 0.815...0.950
    /// down, with a divider ornament at 0.920.
    private let plate = (x: 0.115, y: 0.815, width: 0.770, height: 0.135)

    @State private var outcome: Outcome?
    @State private var clipFinished = false
    @State private var failureMessage = ""
    @State private var showFailure = false

    private enum Outcome {
        case reading(Reading)
        case rejected(RejectionReason)
        case paywall
        case failed(String)
    }

    var body: some View {
        GeometryReader { proxy in
            // The clip is 684x1278; fit it whole so none of its framing is cropped,
            // and let the booth backdrop fill the letterbox.
            let clipAspect: CGFloat = 684.0 / 1278.0
            let fitted = fittedRect(in: proxy.size, aspect: clipAspect)

            ZStack {
                LoopingVideoView(
                    resource: "analyzing_halo",
                    fileExtension: "mp4",
                    isMuted: audio.isMuted
                ) {
                    clipFinished = true
                    advanceIfReady()
                }
                .frame(width: fitted.width, height: fitted.height)
                .position(x: fitted.midX, y: fitted.midY)
                .accessibilityLabel("Reading your lines. Analyzing your palm.")

                // Live copy inside the clip's empty plate.
                VStack(spacing: fitted.height * 0.012) {
                    Text("This may take a few seconds.")
                        .font(Typography.bodyText)
                        .foregroundStyle(Theme.goldLight)

                    // §6.1 privacy line for this screen.
                    Text("We delete your photo as soon as this finishes.")
                        .font(Typography.fine)
                        .foregroundStyle(Theme.goldLight.opacity(0.72))
                }
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .frame(
                    width: fitted.width * plate.width,
                    height: fitted.height * plate.height
                )
                .position(
                    x: fitted.minX + fitted.width * (plate.x + plate.width / 2),
                    y: fitted.minY + fitted.height * (plate.y + plate.height / 2)
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .boothBackground(flourishes: false)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .task { await analyze() }
        .onAppear {
            // The clip has its own soundtrack; the looping booth music would fight it.
            audio.pauseForVideo()
        }
        .onDisappear { audio.resumeAfterVideo() }
        .alert("The Vision Faded", isPresented: $showFailure) {
            Button("Try Again") {
                appState.popToRoot()
                appState.navigate(.capture)
            }
            Button("Not Now", role: .cancel) {
                appState.popToRoot()
            }
        } message: {
            Text(failureMessage)
        }
    }

    /// Aspect-fit rect, centered.
    private func fittedRect(in size: CGSize, aspect: CGFloat) -> CGRect {
        let scale = min(size.width / aspect, size.height) / size.height
        let height = size.height * scale
        let width = height * aspect
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    // MARK: - Pipeline

    private func analyze() async {
        do {
            let content = try await withTimeout(seconds: 60) {
                try await SupabaseService.shared.analyzePalm(objectKey: objectKey)
            }
            let reading = Reading(id: UUID(), createdAt: .now, tier: content.tier, content: content)
            readingStore.add(reading)
            outcome = .reading(reading)
        } catch PipelineError.rejected(let reason) {
            outcome = .rejected(reason)
        } catch PipelineError.paywallRequired {
            outcome = .paywall
        } catch PipelineError.rateLimited {
            outcome = .failed("The spirits need a moment to rest. Try again shortly.")
        } catch {
            outcome = .failed("The vision would not come into focus. Your free reading has not been used — try again.")
        }
        advanceIfReady()
    }

    /// Leave only when the clip has played through AND the server has answered, so the
    /// animation is never cut off mid-flourish.
    private func advanceIfReady() {
        guard clipFinished, let outcome else { return }

        switch outcome {
        case .reading(let reading):
            appState.showReading(reading)
        case .rejected(let reason):
            appState.popToRoot()
            appState.navigate(.rejection(reason))
        case .paywall:
            appState.popToRoot()
            appState.showPaywall = true
        case .failed(let message):
            failureMessage = message
            showFailure = true
        }
    }
}

/// Race a task against a timeout.
func withTimeout<T: Sendable>(
    seconds: Double,
    _ work: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await work() }
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw PipelineError.timeout
        }
        guard let first = try await group.next() else { throw PipelineError.timeout }
        group.cancelAll()
        return first
    }
}
