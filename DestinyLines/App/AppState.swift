import Foundation
import Observation
import SwiftUI

/// App-wide session, entitlement, and navigation state.
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

    // MARK: - Navigation

    enum Route: Hashable {
        case capture
        case align(source: CaptureSource)
        case analyzing(objectKey: String)
        case rejection(RejectionReason)
        case reading(Reading)
        case history
        case share(Reading)
        case settings
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
