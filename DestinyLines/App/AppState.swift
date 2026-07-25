import Observation

@Observable
final class AppState {
    var isSignedIn = false
    var isSubscribed = false
}
