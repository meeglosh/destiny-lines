import Foundation
import Testing
@testable import DestinyLines

@MainActor
struct AppStateTests {
    @Test func launchesInLaunchingPhaseWithEmptyPath() {
        let state = AppState()
        #expect(state.phase == .launching)
        #expect(state.path.isEmpty)
        #expect(state.showPaywall == false)
    }

    @Test func showReadingResetsPathToSingleReadingRoute() {
        let state = AppState()
        state.navigate(.capture)
        state.navigate(.align(source: .camera))

        let reading = Reading(
            id: UUID(),
            createdAt: .now,
            tier: .free,
            content: ReadingContent(
                version: 1,
                tier: .free,
                summary: "s",
                lines: PalmLines(
                    life: PalmLine(title: "Life Line", subtitle: "s", body: "b", traits: nil),
                    head: PalmLine(title: "Head Line", subtitle: "s", body: "b", traits: nil),
                    heart: PalmLine(title: "Heart Line", subtitle: "s", body: "b", traits: nil),
                    fate: PalmLine(title: "Fate Line", subtitle: "s", body: "b", traits: nil)
                ),
                timeline: Timeline(nearFuture: "n", thisYear: nil, longTerm: nil),
                keyInsights: ["a", "b"]
            )
        )
        state.showReading(reading)
        #expect(state.path.count == 1)
    }
}

/// The §6 reading JSON decodes into the app model, including snake_case keys and
/// free-tier omissions.
struct ReadingDecodingTests {
    @Test func decodesServerReadingJSON() throws {
        let json = """
        {
          "version": 1,
          "tier": "free",
          "summary": "A summary.",
          "lines": {
            "life":  { "title": "Life Line",  "subtitle": "Your vitality and major life changes.", "body": "Body.", "traits": [] },
            "head":  { "title": "Head Line",  "subtitle": "Your mind, intellect and decision making.", "body": "Body.", "traits": [] },
            "heart": { "title": "Heart Line", "subtitle": "Your emotions, love and relationships.", "body": "Body.", "traits": [] },
            "fate":  { "title": "Fate Line",  "subtitle": "Your path, purpose and destiny.", "body": "Body.", "traits": [] }
          },
          "timeline": { "near_future": "Soon.", "this_year": null, "long_term": null },
          "key_insights": ["One.", "Two."]
        }
        """.data(using: .utf8)!

        let content = try JSONDecoder().decode(ReadingContent.self, from: json)
        #expect(content.tier == .free)
        #expect(content.timeline.nearFuture == "Soon.")
        #expect(content.timeline.thisYear == nil)
        #expect(content.keyInsights.count == 2)
        #expect(content.lines.ordered.map(\.kind) == [.life, .head, .heart, .fate])
    }
}
