import Foundation

/// The reading payload produced by analyze-palm (§6 of CLAUDE.md).
/// Free and premium share one shape — free is shorter, not structurally different.
struct Reading: Codable, Identifiable, Hashable {
    /// Local identity; server row id when it came from Postgres.
    var id: UUID
    var createdAt: Date
    var tier: Tier
    var content: ReadingContent

    enum Tier: String, Codable {
        case free
        case premium
    }
}

struct ReadingContent: Codable, Hashable {
    var version: Int
    var tier: Reading.Tier
    var summary: String
    var lines: PalmLines
    var timeline: Timeline
    var keyInsights: [String]

    enum CodingKeys: String, CodingKey {
        case version, tier, summary, lines, timeline
        case keyInsights = "key_insights"
    }
}

struct PalmLines: Codable, Hashable {
    var life: PalmLine
    var head: PalmLine
    var heart: PalmLine
    var fate: PalmLine

    var ordered: [(kind: PalmLine.Kind, line: PalmLine)] {
        [(.life, life), (.head, head), (.heart, heart), (.fate, fate)]
    }
}

struct PalmLine: Codable, Hashable {
    var title: String
    var subtitle: String
    var body: String
    var traits: [String]?

    enum Kind: String, CaseIterable, Identifiable {
        case life, head, heart, fate
        var id: String { rawValue }

        /// SF Symbol stand-ins for the comp's medallion illustrations.
        var icon: String {
            switch self {
            case .life: return "hand.raised.fill"
            case .head: return "brain.head.profile"
            case .heart: return "heart.fill"
            case .fate: return "sparkles"
            }
        }
    }
}

struct Timeline: Codable, Hashable {
    var nearFuture: String
    var thisYear: String?
    var longTerm: String?

    enum CodingKeys: String, CodingKey {
        case nearFuture = "near_future"
        case thisYear = "this_year"
        case longTerm = "long_term"
    }
}

/// Rejection reasons from Gates 1 and 3, mapped to in-character retry copy (§6.2).
enum RejectionReason: String, Codable {
    case noHand = "no_hand"
    case backOfHand = "back_of_hand"
    case tooDark = "too_dark"
    case tooBlurry = "too_blurry"
    case partial
    case flagged

    /// In-character retry message. Never reveals a moderation category (§6.2).
    var message: String {
        switch self {
        case .noHand:
            return "The spirits see no hand before them. Show your palm to the lens."
        case .backOfHand:
            return "Turn your palm to face the camera — the lines live on the other side."
        case .tooDark:
            return "The light is too dim for the lines to speak. Find a brighter place."
        case .tooBlurry:
            return "The vision is clouded. Hold steady and try once more."
        case .partial:
            return "Only part of your palm has appeared. Show the whole hand, fingers and all."
        case .flagged:
            return "The crystal cannot read this image. Try a clear photo of your palm."
        }
    }
}
