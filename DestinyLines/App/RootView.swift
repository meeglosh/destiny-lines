import SwiftUI

/// Splash, then the main shell (tabbed top-level screens with the global nav bar), with
/// flow screens pushed over it.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore

    /// Black curtain used to cross the splash → Home boundary as a fade rather than a cut.
    @State private var curtain: Double = 0

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            Group {
                switch appState.phase {
                case .launching:
                    SplashView { beginTransitionToHome() }
                case .ready, .offline:
                    NavigationStack(path: $appState.path) {
                        MainShell()
                            .navigationDestination(for: AppState.Route.self) { route in
                                destination(for: route)
                            }
                    }
                    .tint(Theme.gold)
                }
            }

            Color.black
                .ignoresSafeArea()
                .opacity(curtain)
                .allowsHitTesting(false)
        }
        .fullScreenCover(isPresented: $appState.showPaywall) {
            PaywallView()
        }
        .task { applyDebugRoute() }
    }

    private func beginTransitionToHome() {
        Task { @MainActor in
            withAnimation(.easeIn(duration: 0.45)) { curtain = 1 }
            try? await Task.sleep(for: .milliseconds(460))
            appState.phase = .ready
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.easeOut(duration: 0.55)) { curtain = 0 }
        }
    }

    /// Screenshot calibration: DEBUG_ROUTE jumps straight to a screen, seeding a sample
    /// reading when one is needed. Debug builds only.
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
        case "home": appState.tab = .home
        case "read": appState.tab = .read
        case "insights": appState.tab = .insights
        case "settings": appState.tab = .settings
        case "capture": appState.navigate(.capture)
        case "align": appState.navigate(.align(source: .camera))
        case "analyzing": appState.navigate(.analyzing(objectKey: "debug"))
        case "rejection": appState.navigate(.rejection(.tooDark))
        case "reading", "reading-indepth", "reading-lines", "reading-detail", "share":
            if readingStore.readings.isEmpty { readingStore.add(sample) }
            if route.hasPrefix("reading") { appState.navigate(.reading(sample)) }
            if route == "share" { appState.navigate(.share(sample)) }
        case "history":
            if readingStore.readings.isEmpty { readingStore.add(sample) }
            appState.tab = .history
        case "history-empty": appState.tab = .history
        case "paywall": appState.showPaywall = true
        default: break
        }
        #endif
    }

    @ViewBuilder
    private func destination(for route: AppState.Route) -> some View {
        switch route {
        case .capture:            CaptureView()
        case .align(let source):  AlignHandView(source: source)
        case .analyzing(let key): AnalyzingView(objectKey: key)
        case .rejection(let r):   RejectionView(reason: r)
        case .reading(let r):     ReadingView(reading: r)
        case .share(let r):       ShareReadingView(reading: r)
        case .privacyExplainer:   PrivacyExplainerView()
        }
    }
}

/// Top-level shell: the selected tab's screen with the painted nav bar over its foot.
struct MainShell: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .bottom) {
            Group {
                switch appState.tab {
                case .home:     HomeView()
                case .history:  HistoryView()
                case .insights: InsightsView()
                case .settings: SettingsView()
                case .read:     CaptureView(isTabRoot: true)
                }
            }

            ArtNavBar(selection: $appState.tab)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
