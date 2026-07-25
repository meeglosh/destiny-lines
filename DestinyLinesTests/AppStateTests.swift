import Testing
@testable import DestinyLines

struct AppStateTests {
    @Test func startsSignedOutAndUnsubscribed() {
        let state = AppState()
        #expect(state.isSignedIn == false)
        #expect(state.isSubscribed == false)
    }
}
