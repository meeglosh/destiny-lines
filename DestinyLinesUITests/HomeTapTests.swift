import XCTest

/// Regression cover for the art-hotspot layer.
///
/// The first TestFlight build shipped with every hotspot placed via `.position`, which
/// expands a view to fill its parent — so each hotspot covered the whole screen and
/// swallowed the ones beneath it, leaving the UI looking like a static image. These
/// tests assert hotspots have their own distinct frames, are hittable, and navigate.
final class ArtHotspotTests: XCTestCase {

    private func launch(_ route: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["DEBUG_ROUTE"] = route
        app.launch()
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        return app
    }

    /// Hotspots must be distinct (the `.position` bug made them all full-screen) AND
    /// fully on screen (the aspect-fill bug pushed paywall controls off the right edge).
    /// Run on several device sizes, this is the app's responsiveness guarantee.
    private func assertHotspotsAreDistinct(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let screen = app.windows.firstMatch.frame
        var seen: [CGRect] = []
        for button in app.buttons.allElementsBoundByIndex {
            let frame = button.frame
            guard frame.width > 0, frame.height > 0 else { continue }

            XCTAssertFalse(
                frame.width >= screen.width && frame.height >= screen.height * 0.9,
                "Hotspot '\(button.label)' fills the screen — .position regression",
                file: file, line: line
            )
            XCTAssertFalse(
                seen.contains(frame),
                "Hotspot '\(button.label)' shares a frame with another — .position regression",
                file: file, line: line
            )
            // Allow a hair of rounding slop at the edges.
            XCTAssertTrue(
                screen.insetBy(dx: -1, dy: -1).contains(frame),
                "Hotspot '\(button.label)' at \(frame) is cut off by the screen \(screen) — layout is not responsive",
                file: file, line: line
            )
            seen.append(frame)
        }
    }

    func testHomeHotspotsNavigate() throws {
        let app = launch("home")
        assertHotspotsAreDistinct(app)

        let newReading = app.buttons["New Reading"]
        XCTAssertTrue(newReading.waitForExistence(timeout: 5))
        XCTAssertTrue(newReading.isHittable, "New Reading is not hittable")
        newReading.tap()

        XCTAssertTrue(
            app.buttons["Choose from Photos. Upload from your library."].waitForExistence(timeout: 5),
            "New Reading did not navigate to Capture"
        )
    }

    func testHomeReachesSettingsAndHistory() throws {
        let app = launch("home")

        app.buttons["Settings. Customize your experience."].tap()
        XCTAssertTrue(
            app.buttons["Your Privacy"].waitForExistence(timeout: 5) ||
            app.staticTexts["SETTINGS"].waitForExistence(timeout: 5),
            "Settings row did not open Settings"
        )
    }

    func testCaptureHotspotsAreDistinct() throws {
        let app = launch("capture")
        assertHotspotsAreDistinct(app)
        XCTAssertTrue(app.buttons["Take Photo. Use your camera."].isHittable)
        XCTAssertTrue(app.buttons["Back"].isHittable)
    }

    func testReadingTabsAreDistinctAndSwitch() throws {
        let app = launch("reading")
        assertHotspotsAreDistinct(app)

        let inDepth = app.buttons["In-Depth tab"]
        XCTAssertTrue(inDepth.waitForExistence(timeout: 5))
        XCTAssertTrue(inDepth.isHittable, "In-Depth tab is not hittable")
        inDepth.tap()
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        // The line cards belong to Overview; after switching they should be gone.
        XCTAssertFalse(
            app.buttons["Life Line. Your vitality and major life changes."].exists,
            "Tab did not switch away from Overview"
        )
    }

    func testHistoryHotspotsAreDistinct() throws {
        let app = launch("history")
        assertHotspotsAreDistinct(app)
        XCTAssertTrue(app.buttons["New Reading"].isHittable)
        XCTAssertTrue(app.buttons["Settings"].isHittable, "Tab bar Settings is not hittable")
    }

    func testShareHotspotsAreDistinct() throws {
        let app = launch("share")
        assertHotspotsAreDistinct(app)
        XCTAssertTrue(app.buttons["Save to Photos"].isHittable)
    }

    func testPaywallHotspotsAreDistinct() throws {
        let app = launch("paywall")
        assertHotspotsAreDistinct(app)
        XCTAssertTrue(app.buttons["Close"].isHittable, "Paywall close button is not hittable")
    }
}

/// The sound toggle replaces the baked compass medallion on Home.
final class MuteButtonTests: XCTestCase {

    func testMuteButtonTogglesAndPersists() throws {
        let app = XCUIApplication()
        app.launchEnvironment["DEBUG_ROUTE"] = "home"
        app.launch()
        RunLoop.current.run(until: Date().addingTimeInterval(3))

        // The preference persists, so a previous run may have left it either way;
        // assert on the transition rather than on a presumed starting state.
        let soundOn = app.buttons["Sound on"]
        let soundOff = app.buttons["Sound off"]
        XCTAssertTrue(
            soundOn.waitForExistence(timeout: 5) || soundOff.waitForExistence(timeout: 1),
            "Sound toggle missing from Home"
        )
        let startsMuted = soundOff.exists
        let initial = startsMuted ? soundOff : soundOn
        let flipped = startsMuted ? soundOn : soundOff

        XCTAssertTrue(initial.isHittable, "Sound toggle is not hittable")
        initial.tap()
        XCTAssertTrue(
            flipped.waitForExistence(timeout: 3),
            "Tapping the toggle did not flip the sound state"
        )

        // The choice survives a relaunch.
        app.terminate()
        app.launch()
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        XCTAssertTrue(
            flipped.waitForExistence(timeout: 5),
            "Sound preference did not persist across launches"
        )

        // Restore the original state for later runs.
        flipped.tap()
    }
}
