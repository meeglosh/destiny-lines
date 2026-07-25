import SwiftUI

/// Hosts the splash, then the navigation stack for the whole app.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore

    var body: some View {
        @Bindable var appState = appState

        Group {
            switch appState.phase {
            case .launching:
                SplashView {
                    appState.phase = .ready
                }
            case .ready, .offline:
                NavigationStack(path: $appState.path) {
                    HomeView()
                        .navigationDestination(for: AppState.Route.self) { route in
                            destination(for: route)
                        }
                }
                .tint(Theme.gold)
            }
        }
        .fullScreenCover(isPresented: $appState.showPaywall) {
            PaywallView()
        }
        .task { applyDebugRoute() }
    }

    /// Screenshot calibration: DEBUG_ROUTE jumps straight to a screen, seeding a
    /// sample reading when one is needed. Debug builds only.
    private func applyDebugRoute() {
        #if DEBUG
        guard let route = ProcessInfo.processInfo.environment["DEBUG_ROUTE"] else { return }
        appState.phase = .ready

        let sample = Reading(
            id: UUID(),
            createdAt: .now,
            tier: .premium,
            content: ReadingContent(
                version: 1,
                tier: .premium,
                summary: "A palm of rare warmth and steady purpose.",
                lines: PalmLines(
                    life: PalmLine(title: "Life Line", subtitle: "Your vitality and major life changes.",
                                   body: "Deep and unbroken, your life line sweeps wide around the mount of Venus — a sign of stamina and appetite for the world.",
                                   traits: ["Resilient", "Warm", "Steady"]),
                    head: PalmLine(title: "Head Line", subtitle: "Your mind, intellect and decision making.",
                                   body: "Long and gently sloped, your head line shows a mind that weighs before it leaps, then commits without looking back.",
                                   traits: ["Curious", "Deliberate"]),
                    heart: PalmLine(title: "Heart Line", subtitle: "Your emotions, love and relationships.",
                                    body: "Rising toward the first finger, your heart line marks a romantic who chooses carefully and holds on long.",
                                    traits: ["Loyal", "Devoted"]),
                    fate: PalmLine(title: "Fate Line", subtitle: "Your path, purpose and destiny.",
                                   body: "A clear fate line climbing from the wrist speaks of a path chosen early and walked with conviction.",
                                   traits: ["Driven", "Purposeful"])
                ),
                timeline: Timeline(
                    nearFuture: "A door you knocked on months ago finally opens; enter without apology.",
                    thisYear: "The year rewards patient building over quick wins — the lines favor foundations.",
                    longTerm: "The long road bends toward work that carries your name and a table full of friends."
                ),
                keyInsights: [
                    "Strong intuition guides your decisions and your path.",
                    "A loyal heart and deep connections define you.",
                    "Creative thinking brings success in unique ways.",
                    "Bright opportunities lie ahead; stay open to new paths.",
                ]
            )
        )

        switch route {
        case "home": break // phase is already .ready; Home is the stack root
        case "capture": appState.navigate(.capture)
        case "align": appState.navigate(.align(source: .camera))
        case "analyzing": appState.navigate(.analyzing(objectKey: "debug"))
        case "rejection": appState.navigate(.rejection(.tooDark))
        case "reading", "history", "share":
            if readingStore.readings.isEmpty { readingStore.add(sample) }
            if route == "reading" { appState.navigate(.reading(sample)) }
            if route == "history" { appState.navigate(.history) }
            if route == "share" { appState.navigate(.share(sample)) }
        case "settings": appState.navigate(.settings)
        case "paywall": appState.showPaywall = true
        default: break
        }
        #endif
    }

    @ViewBuilder
    private func destination(for route: AppState.Route) -> some View {
        switch route {
        case .capture:
            CaptureView()
        case .align(let source):
            AlignHandView(source: source)
        case .analyzing(let objectKey):
            AnalyzingView(objectKey: objectKey)
        case .rejection(let reason):
            RejectionView(reason: reason)
        case .reading(let reading):
            ReadingView(reading: reading)
        case .history:
            HistoryView()
        case .share(let reading):
            ShareReadingView(reading: reading)
        case .settings:
            SettingsView()
        case .privacyExplainer:
            PrivacyExplainerView()
        }
    }
}
