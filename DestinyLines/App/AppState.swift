import Foundation
import Observation
import SwiftUI

/// App-wide session, tab, and flow-navigation state.
@Observable
@MainActor
final class AppState {
    // MARK: - Session

    enum Phase {
        case launching
        case ready
        case offline
    }

    var phase: Phase = .launching

    // MARK: - Top-level tabs (global nav bar)

    var tab: MainTab = .home {
        didSet {
            // READ is an action, not a destination: bounce back so the bar never rests
            // on it while the capture flow is pushed over the shell.
            if tab == .read { tab = oldValue == .read ? .home : oldValue }
        }
    }

    // MARK: - Flow routes (pushed over the shell; nav bar not shown)

    enum Route: Hashable {
        case capture
        case align(source: CaptureSource)
        case analyzing(objectKey: String)
        case rejection(RejectionReason)
        case reading(Reading)
        case share(Reading)
        case privacyExplainer
    }

    enum CaptureSource: Hashable {
        case camera
        case library
    }

    var path = NavigationPath()
    var showPaywall = false

    func navigate(_ route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path = NavigationPath()
    }

    /// Pop the pipeline screens and land on the finished reading.
    func showReading(_ reading: Reading) {
        path = NavigationPath()
        path.append(Route.reading(reading))
    }
}
