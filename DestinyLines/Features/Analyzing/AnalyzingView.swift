import SwiftUI

/// DL-analyzing-palm.png used directly. Adds a slow breathing glow over the baked
/// bulb ring (skipped under Reduce Motion), runs analyze-palm with the 60s timeout,
/// and routes to the reading, the rejection state, or a retry alert.
struct AnalyzingView: View {
    let objectKey: String

    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulse = false
    @State private var failed = false
    @State private var failureMessage = ""

    var body: some View {
        ArtScreen(image: "bg_analyzing") { art in
            // Breathing halo over the baked ring; pure additive glow, no layout.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.glow.opacity(pulse ? 0.28 : 0.10), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: art.frame.width * 0.42
                    )
                )
                .frame(width: art.frame.width * 0.9, height: art.frame.width * 0.9)
                .position(art.point(0.5, 0.47))
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            // §6.1 privacy line, in the empty band under the patience card.
            Text("We delete your photo as soon as this finishes.")
                .font(Typography.fine)
                .foregroundStyle(Theme.goldLight.opacity(0.75))
                .position(art.point(0.5, 0.955))
        }
        .task { await analyze() }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .alert("The Vision Faded", isPresented: $failed) {
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

    private func analyze() async {
        do {
            let content = try await withTimeout(seconds: 60) {
                try await SupabaseService.shared.analyzePalm(objectKey: objectKey)
            }
            let reading = Reading(id: UUID(), createdAt: .now, tier: content.tier, content: content)
            readingStore.add(reading)
            appState.showReading(reading)
        } catch PipelineError.rejected(let reason) {
            appState.popToRoot()
            appState.navigate(.rejection(reason))
        } catch PipelineError.paywallRequired {
            appState.popToRoot()
            appState.showPaywall = true
        } catch PipelineError.rateLimited {
            failureMessage = "The spirits need a moment to rest. Try again shortly."
            failed = true
        } catch {
            failureMessage = "The vision would not come into focus. Your free reading has not been used — try again."
            failed = true
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
