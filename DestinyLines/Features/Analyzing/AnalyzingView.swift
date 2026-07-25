import SwiftUI

/// DL-analyzing-palm.png: "READING YOUR LINES" banner, rotating bulb ring around the
/// hand with a sweeping light band, crystal ball below, patience card, privacy line.
/// Runs analyze-palm with a 60s timeout; transitions to the reading or a rejection.
struct AnalyzingView: View {
    let objectKey: String

    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var ringAngle: Angle = .zero
    @State private var sweepOffset: CGFloat = -1
    @State private var failed = false
    @State private var failureMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                BannerHeader(title: "READING YOUR LINES")
                    .padding(.horizontal, 44)

                Text("Analyzing your palm...")
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.goldLight)

                ringAndHand

                crystalBall

                OrnateCard(contentPadding: 14) {
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
                .padding(.horizontal, 28)
            }
            .padding(.vertical, 12)
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
        .task { await analyze() }
        .onAppear { startAnimations() }
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

    // MARK: - Art

    private var ringAndHand: some View {
        ZStack {
            // Rotating bulb ring
            ForEach(0..<24, id: \.self) { i in
                MarqueeBulb(size: 5)
                    .offset(y: -140)
                    .rotationEffect(.degrees(Double(i) / 24 * 360))
            }
            .rotationEffect(ringAngle)

            Circle()
                .strokeBorder(Theme.goldDark.opacity(0.6), lineWidth: 3)
                .frame(width: 252, height: 252)

            Image(systemName: "hand.raised.fingers.spread.fill")
                .font(.system(size: 120))
                .foregroundStyle(Theme.goldBevel)
                .shadow(color: Theme.glow.opacity(0.7), radius: 20)
                .overlay(sweepBand.mask(
                    Image(systemName: "hand.raised.fingers.spread.fill")
                        .font(.system(size: 120))
                ))
        }
        .frame(width: 300, height: 300)
        .accessibilityLabel("Reading in progress")
    }

    private var sweepBand: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [.clear, Theme.glow.opacity(0.9), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * 0.5)
            .offset(x: sweepOffset * proxy.size.width)
        }
    }

    private var crystalBall: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.glow.opacity(0.95), Theme.gold.opacity(0.4), .clear],
                        center: .init(x: 0.5, y: 0.35),
                        startRadius: 2,
                        endRadius: 46
                    )
                )
                .frame(width: 74, height: 74)
            Ellipse()
                .fill(Theme.goldDark)
                .frame(width: 54, height: 14)
                .offset(y: 40)
        }
        .accessibilityHidden(true)
    }

    private func startAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
            ringAngle = .degrees(360)
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
            sweepOffset = 1.4
        }
    }

    // MARK: - Pipeline

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
