import XCTest

/// Navigation and layout smoke tests for the component-based UI.
///
/// History note: two shipped regressions shaped these assertions. Build 1's hotspots
/// were placed with `.position`, which made every control full-screen and untappable;
/// build 4's aspect-fill art pushed controls off-screen. Controls must therefore have
/// distinct frames, sit fully on screen, and actually navigate.
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

    /// Buttons must be distinct, on-screen, and not full-screen.
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
                "Control '\(button.label)' shares a frame with another — .position regression",
                file: file, line: line
            )
            XCTAssertTrue(
                screen.insetBy(dx: -1, dy: -1).contains(frame),
                "Control '\(button.label)' at \(frame) is cut off by the screen \(screen) — layout is not responsive",
                file: file, line: line
            )
            seen.append(frame)
        }
    }

    // MARK: - Tabs

    func testTabBarReachesEveryTopLevelScreen() throws {
        let app = launch("home")
        assertControlsAreSane(app)

        app.buttons["History"].tap()
        XCTAssertTrue(element(containing: "MY READINGS", in: app).waitForExistence(timeout: 5),
                      "History tab did not show MY READINGS")

        app.buttons["Insights"].tap()
        XCTAssertTrue(element(containing: "STARS ARE STILL ALIGNING", in: app).waitForExistence(timeout: 5),
                      "Insights tab did not show its placeholder")

        app.buttons["Settings"].tap()
        XCTAssertTrue(element(containing: "RESTORE PURCHASES", in: app).waitForExistence(timeout: 5),
                      "Settings tab did not show its rows")

        app.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["New Reading"].waitForExistence(timeout: 5),
                      "Home tab did not return to Home")
    }

    func testReadTabLaunchesCaptureFlow() throws {
        let app = launch("home")
        app.buttons["Read"].tap()
        XCTAssertTrue(element(containing: "CHOOSE FROM PHOTOS", in: app).waitForExistence(timeout: 5),
                      "READ did not open the capture flow")
        // Flow screens hide the tab bar.
        XCTAssertFalse(app.buttons["Insights"].isHittable,
                       "Tab bar should be hidden inside the capture flow")
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
        XCTAssertTrue(element(containing: "TAKE PHOTO", in: app).isHittable)
        XCTAssertTrue(app.buttons["Back"].isHittable)
    }

    func testReadingTabsSwitch() throws {
        let app = launch("reading")
        assertControlsAreSane(app)

        let inDepth = app.buttons["IN-DEPTH"]
        XCTAssertTrue(inDepth.waitForExistence(timeout: 5))
        inDepth.tap()
        XCTAssertTrue(element(containing: "KEY INSIGHTS", in: app).waitForExistence(timeout: 5),
                      "IN-DEPTH tab did not show timeline content")

        app.buttons["LINES"].tap()
        XCTAssertTrue(element(containing: "sweeps wide around the mount", in: app).waitForExistence(timeout: 5),
                      "LINES tab did not show line bodies")
    }

    func testHistorySeededRowOpensReading() throws {
        let app = launch("history-seeded")
        assertControlsAreSane(app)

        let row = element(containing: "In-Depth Reading", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Seeded reading row missing")
        row.tap()
        XCTAssertTrue(app.buttons["OVERVIEW"].waitForExistence(timeout: 5),
                      "Tapping a history row did not open the reading")
    }

    func testShareShowsActions() throws {
        let app = launch("share")
        assertControlsAreSane(app)
        XCTAssertTrue(element(containing: "SAVE TO PHOTOS", in: app).waitForExistence(timeout: 5))
    }

    func testPaywallControlsAreSane() throws {
        let app = launch("paywall")
        assertControlsAreSane(app)
        XCTAssertTrue(app.buttons["Close"].isHittable, "Paywall close button is not hittable")
        XCTAssertTrue(element(containing: "Start Free Trial", in: app).waitForExistence(timeout: 5))
    }
}

/// The sound toggle on Home.
final class MuteButtonTests: XCTestCase {

    func testMuteButtonTogglesAndPersists() throws {
        let app = XCUIApplication()
        app.launchEnvironment["DEBUG_ROUTE"] = "home"
        app.launch()
        RunLoop.current.run(until: Date().addingTimeInterval(3))

        let soundOn = app.buttons["Sound on"]
        let soundOff = app.buttons["Sound off"]
        let startsMuted = soundOff.exists

        // Toggle and expect the state to flip.
        (startsMuted ? soundOff : soundOn).tap()
        XCTAssertTrue((startsMuted ? soundOn : soundOff).waitForExistence(timeout: 3),
                      "Tapping the toggle did not flip the sound state")

        // The choice survives a relaunch.
        app.terminate()
        app.launch()
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        XCTAssertTrue((startsMuted ? soundOn : soundOff).waitForExistence(timeout: 5),
                      "Sound preference did not persist across launches")

        // Restore original state for later runs.
        (startsMuted ? soundOn : soundOff).tap()
    }
}
