import SwiftUI

@main
struct DestinyLinesApp: App {
    @State private var appState = AppState()
    @State private var store = StoreManager()
    @State private var readingStore = ReadingStore()
    @State private var audio = AudioPlayer()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(store)
                .environment(readingStore)
                .environment(audio)
                .task {
                    audio.start()

                    // Mirror entitlement to the server whenever StoreKit reports it (§7.8).
                    store.mirrorEntitlement = { jws in
                        guard SupabaseConfig.isConfigured else { return }
                        try? await SupabaseService.shared.verifySubscription(jws: jws)
                    }
                    await store.refreshEntitlement()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            audio.handleScenePhase(phase)
            // Re-derive entitlement on every foreground (§7.8).
            if phase == .active {
                Task { await store.refreshEntitlement() }
            }
        }
    }
}
