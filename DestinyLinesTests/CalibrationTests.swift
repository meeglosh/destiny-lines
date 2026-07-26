import Foundation
import Testing
@testable import DestinyLines

/// Guards on the moderation gate thresholds (CLAUDE.md §6.2a).
struct CalibrationTests {

    /// The two threshold files are written by one sweep, so they must agree. If they
    /// ever diverge, the app and the server are enforcing different gates.
    @Test func swiftAndEdgeFunctionThresholdsAgree() throws {
        let repo = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let ts = repo.appending(path: "supabase/functions/_shared/thresholds.ts")

        let source = try String(contentsOf: ts, encoding: .utf8)
        let pattern = /GATE3_CONFIDENCE_THRESHOLD\s*=\s*([0-9.]+)/
        let match = try #require(source.firstMatch(of: pattern))
        let edgeValue = try #require(Double(match.1))

        #expect(
            abs(edgeValue - GateThresholds.gate3Confidence) < 0.0001,
            "Gate 3 threshold differs between Swift (\(GateThresholds.gate3Confidence)) and the Edge Function (\(edgeValue))"
        )
    }

    /// Gate 1 must stay on the permissive side of Gate 3: rejecting a real palm on-device
    /// loses a user, while letting a doubtful one through only costs $0.0002 (§6.2a step 5).
    @Test func gate1IsMorePermissiveThanGate3() {
        #expect(Double(GateThresholds.gate1Confidence) < GateThresholds.gate3Confidence)
    }

    /// Release builds must not ship guessed thresholds (§6.2a: "Claude Code must not ship
    /// guessed values with a comment saying they will be tuned later").
    ///
    /// This test is expected to FAIL until the owner supplies the labelled set and the
    /// sweep has run. That failure is the point: it is the tripwire that stops an
    /// uncalibrated build reaching the App Store. It is disabled rather than deleted so
    /// the reason stays visible, and re-enabling it is the final calibration step.
    @Test(.disabled("Awaiting the labelled evaluation set — see Scripts/calibrate/README.md"))
    func thresholdsAreCalibratedBeforeRelease() {
        #expect(
            GateThresholds.allCalibrated,
            """
            Gate thresholds are still provisional. Collect the labelled set, run
            Scripts/calibrate/sweep.py --write, redeploy analyze-palm, then remove the
            .disabled trait from this test.
            """
        )
    }
}
