import SwiftUI

/// Hosts the splash, then the navigation stack for the whole app.
struct RootView: View {
    @Environment(AppState.self) private var appState

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
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView()
        }
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
