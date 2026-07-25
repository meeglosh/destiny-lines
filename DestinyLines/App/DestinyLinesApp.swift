import SwiftUI

@main
struct DestinyLinesApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootPlaceholderView()
                .environment(appState)
        }
    }
}

private struct RootPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("DESTINY LINES")
                .font(.title.bold())
            Text("Project scaffold — screens coming next")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
