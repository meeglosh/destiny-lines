import SwiftUI

@main
struct DestinyLinesApp: App {
    @State private var appState = AppState()
    @State private var store = StoreManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            PaywallView()
                .environment(appState)
                .environment(store)
        }
        .onChange(of: scenePhase) { _, phase in
            // Re-derive entitlement on every foreground (CLAUDE.md §7.8).
            if phase == .active {
                Task { await store.refreshEntitlement() }
            }
        }
    }
}
