import SwiftUI

/// Analyzing, rebuilt from components: ribbon title, the sliced bulb-ring hand with a
/// breathing glow (skipped under Reduce Motion), the crystal ball, patience card, and
/// the §6.1 privacy line. Runs analyze-palm with the 60s timeout.
struct AnalyzingView: View {
    let objectKey: String

    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulse = false
    @State private var failed = false
    @State private var failureMessage = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                RibbonBanner(text: "READING YOUR LINES")
                    .padding(.horizontal, 52)
                    .padding(.top, 8)

                Text("Analyzing your palm...")
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.goldLight)

                Image("analyzing_ring_hand")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 30)
                    .shadow(color: Theme.glow.opacity(pulse ? 0.55 : 0.15), radius: 30)
                    .accessibilityLabel("Reading in progress")

                Image("crystal_ball_small")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110)
                    .opacity(pulse ? 1.0 : 0.75)
                    .accessibilityHidden(true)

                ArtCard(contentPadding: 14) {
                    VStack(spacing: 8) {
                        Text("This may take a few seconds.")
                            .font(Typography.bodyText)
                            .foregroundStyle(Theme.goldLight)
                        Sparkle(size: 10)
                        // §6.1 privacy line for this screen.
                        Text("We delete your photo as soon as this finishes.")
                            .font(Typography.fine)
                            .foregroundStyle(Theme.goldLight.opacity(0.7))
                    }
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: 480)
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .boothBackground()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
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
