import XCTest

/// Navigation and layout cover for the painted-background screens.
///
/// Two shipped regressions shaped these assertions: build 1 placed every control with
/// `.position`, which made them all full-screen and untappable; build 4's aspect-fill
/// pushed controls off the right edge. Controls must therefore have distinct frames, sit
/// on screen, and actually navigate.
final class ArtHotspotTests: XCTestCase {

    private func launch(_ route: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["DEBUG_ROUTE"] = route
        app.launch()
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        return app
    }

    private func element(containing text: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", text))
            .firstMatch
    }

    /// A tappable control whose accessibility label contains `text`.
    private func button(containing text: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    private func assertControlsAreSane(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let screen = app.windows.firstMatch.frame
        var seen: [CGRect] = []
        for button in app.buttons.allElementsBoundByIndex {
            let frame = button.frame
            guard frame.width > 0, frame.height > 0 else { continue }

            XCTAssertFalse(
                frame.width >= screen.width && frame.height >= screen.height * 0.9,
                "Control '\(button.label)' fills the screen — .position regression",
                file: file, line: line
            )
            XCTAssertFalse(
                seen.contains(frame),
                "Control '\(button.label)' shares a frame with another",
                file: file, line: line
            )
            seen.append(frame)
        }
    }

    // MARK: - Global navigation

    func testNavBarReachesEveryTopLevelScreen() throws {
        let app = launch("home")
        assertControlsAreSane(app)

        app.buttons["History"].tap()
        XCTAssertTrue(app.buttons["New Reading"].waitForExistence(timeout: 5),
                      "History tab did not appear")

        app.buttons["Insights"].tap()
        XCTAssertTrue(element(containing: "STARS ARE STILL ALIGNING", in: app).waitForExistence(timeout: 5),
                      "Insights tab did not appear")

        app.buttons["Settings"].tap()
        XCTAssertTrue(element(containing: "RESTORE PURCHASES", in: app).waitForExistence(timeout: 5),
                      "Settings tab did not appear")

        app.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["New Reading"].waitForExistence(timeout: 5),
                      "Home tab did not return")
    }

    /// READ is a normal resting tab (it shows Capture as the tab root), not a push — so
    /// the global nav bar stays up, and there's no back button since there's nothing to
    /// pop back to.
    func testReadIsATabThatKeepsNavVisible() throws {
        let app = launch("home")
        app.buttons["Read"].tap()

        XCTAssertTrue(element(containing: "CHOOSE FROM PHOTOS", in: app).waitForExistence(timeout: 5),
                      "READ did not show the capture screen")
        XCTAssertTrue(app.buttons["Insights"].isHittable,
                      "The nav bar should stay visible — READ is a tab, not a pushed flow screen")
        XCTAssertFalse(app.buttons["Back"].exists,
                       "The READ tab root has nothing to pop back to, so it shouldn't show a back button")

        // The plate should now rest on READ like any other tab.
        app.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["New Reading"].waitForExistence(timeout: 5))
        app.buttons["Read"].tap()
        XCTAssertTrue(element(containing: "CHOOSE FROM PHOTOS", in: app).waitForExistence(timeout: 5),
                      "READ did not return to the capture screen")
    }

    // MARK: - Screens

    func testHomeNewReadingNavigates() throws {
        let app = launch("home")
        let newReading = app.buttons["New Reading"]
        XCTAssertTrue(newReading.waitForExistence(timeout: 5))
        XCTAssertTrue(newReading.isHittable, "New Reading is not hittable")
        newReading.tap()

        XCTAssertTrue(element(containing: "CHOOSE FROM PHOTOS", in: app).waitForExistence(timeout: 5),
                      "New Reading did not navigate to Capture")
    }

    func testCaptureControlsAreSane() throws {
        let app = launch("capture")
        assertControlsAreSane(app)
        let takePhoto = button(containing: "TAKE PHOTO", in: app)
        XCTAssertTrue(takePhoto.waitForExistence(timeout: 5), "Take Photo control missing")
        XCTAssertTrue(takePhoto.isHittable, "Take Photo is not hittable")
        XCTAssertTrue(app.buttons["Back"].isHittable)
    }

    func testReadingTabsSwitch() throws {
        let app = launch("reading")
        assertControlsAreSane(app)

        app.buttons["IN-DEPTH"].tap()
        XCTAssertTrue(element(containing: "KEY INSIGHTS", in: app).waitForExistence(timeout: 5),
                      "IN-DEPTH did not show timeline content")

        app.buttons["LINES"].tap()
        XCTAssertTrue(element(containing: "sweeps wide around the mount", in: app).waitForExistence(timeout: 5),
                      "LINES did not show line bodies")
    }

    func testHistoryRowOpensReading() throws {
        let app = launch("history")
        assertControlsAreSane(app)

        let row = element(containing: "In-Depth Reading", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Seeded reading row missing")
        row.tap()
        XCTAssertTrue(app.buttons["OVERVIEW"].waitForExistence(timeout: 5),
                      "Tapping a history row did not open the reading")
    }

    func testSettingsReachesPrivacyExplainer() throws {
        let app = launch("settings")
        assertControlsAreSane(app)

        button(containing: "YOUR PRIVACY", in: app).tap()
        XCTAssertTrue(element(containing: "deleted immediately", in: app).waitForExistence(timeout: 5),
                      "Your Privacy row did not open the explainer")
    }

    func testShareShowsActions() throws {
        let app = launch("share")
        assertControlsAreSane(app)
        XCTAssertTrue(app.buttons["Save to Photos"].waitForExistence(timeout: 5))
    }

    func testPaywallControlsAreSane() throws {
        let app = launch("paywall")
        assertControlsAreSane(app)
        XCTAssertTrue(app.buttons["Close"].isHittable, "Paywall close is not hittable")
        XCTAssertTrue(element(containing: "START FREE TRIAL", in: app).waitForExistence(timeout: 5))
    }
}

/// The sound toggle on Home.
final class MuteButtonTests: XCTestCase {

    func testMuteButtonTogglesAndPersists() throws {
        let app = XCUIApplication()
        app.launchEnvironment["DEBUG_ROUTE"] = "home"
        app.launch()
        RunLoop.current.run(until: Date().addingTimeInterval(3))

        // The preference persists, so assert on the transition, not a presumed start.
        let soundOn = app.buttons["Sound on"]
        let soundOff = app.buttons["Sound off"]
        XCTAssertTrue(
            soundOn.waitForExistence(timeout: 5) || soundOff.waitForExistence(timeout: 1),
            "Sound toggle missing from Home"
        )
        let startsMuted = soundOff.exists
        let initial = startsMuted ? soundOff : soundOn
        let flipped = startsMuted ? soundOn : soundOff

        initial.tap()
        XCTAssertTrue(flipped.waitForExistence(timeout: 3),
                      "Tapping the toggle did not flip the sound state")

        app.terminate()
        app.launch()
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        XCTAssertTrue(flipped.waitForExistence(timeout: 5),
                      "Sound preference did not persist across launches")

        flipped.tap()
    }
}
