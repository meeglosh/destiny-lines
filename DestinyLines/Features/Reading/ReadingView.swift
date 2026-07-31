import SwiftUI

/// Reading over the painted reading background. Overview lays live titles over the four
/// painted line medallions; In-Depth and Lines are variable-length, so they scroll their
/// own content over the reusable ornate frame.
struct ReadingView: View {
    let reading: Reading

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    enum Tab: Hashable { case overview, inDepth, lines }
    @State private var tab: Tab = Self.initialTab
    @State private var detailLine: PalmLine.Kind? = Self.initialDetail

    private var isFree: Bool { reading.tier == .free }

    /// Vertical origins of the four painted line plates.
    private let plateY: [CGFloat] = [0.268, 0.408, 0.543, 0.688]

    var body: some View {
        Group {
            switch tab {
            case .overview: overviewScreen
            case .inDepth:  scrollingScreen { inDepthContent }
            case .lines:    scrollingScreen { linesContent }
            }
        }
        .sheet(item: $detailLine) { kind in
            LineDetailSheet(kind: kind, line: line(for: kind), isFree: isFree) {
                appState.showPaywall = true
            }
        }
    }

    // MARK: - Overview (live text over the painted plates)

    private var overviewScreen: some View {
        ArtScreen(
            image: "bg_reading",
            // Like Capture and History, this art is narrower/taller than the device box,
            // so a cover-fit always crops vertically. Bias that crop toward the top —
            // the plain gap below the arch (before "DESTINY LINES" starts) absorbs most
            // of it — so the crystal-ball decoration at the very bottom stops being cut
            // off, and the whole screen sits higher instead of leaving a dead gap under
            // the Dynamic Island.
            verticalAnchor: 0.78
        ) { art in
            chrome(
                art,
                // bg_reading's own circular wells, pixel-measured, centered at
                // (13.3%, 11.0%) and (86.7%, 11.0%) of the art.
                backRect: art.rect(0.0887, 0.0887, 0.0881, 0.0417),
                shareRect: art.rect(0.8233, 0.0887, 0.0881, 0.0417)
            )

            ForEach(Array(reading.content.lines.ordered.enumerated()), id: \.offset) { index, entry in
                let y = plateY[index]

                VStack(alignment: .leading, spacing: art.frame.height * 0.004) {
                    Text(entry.line.title.uppercased())
                        .font(.custom("Rye-Regular", size: art.fontSize(0.0185)))
                        .foregroundStyle(Theme.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(entry.line.subtitle)
                        .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0128)))
                        .foregroundStyle(Theme.goldLight.opacity(0.88))
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                }
                // The icon medallion's right edge sits at ~35.6% of the art (measured
                // directly off bg_reading), so the label starts just past it.
                .artFrame(art.rect(0.39, y, 0.43, 0.075), alignment: .leading)
                .allowsHitTesting(false)

                Image(systemName: "chevron.right")
                    .font(.system(size: art.fontSize(0.013), weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .artFrame(art.rect(0.845, y, 0.05, 0.075))
                    .allowsHitTesting(false)

                ArtHotspot(rect: art.rect(0.075, y - 0.012, 0.85, 0.10),
                           label: "\(entry.line.title). \(entry.line.subtitle)") {
                    detailLine = entry.kind
                }
            }

            // VIEW FULL READING plate — pixel-measured at raw y 0.818–0.895, so the
            // text is centered on 0.8565 rather than the plate's old (too-high) rect.
            HStack(spacing: art.frame.width * 0.03) {
                Sparkle(size: art.fontSize(0.011))
                Text("VIEW FULL READING")
                    .font(.custom("Rye-Regular", size: art.fontSize(0.0205)))
                    .kerning(1.2)
                    .foregroundStyle(Theme.goldBevel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                Sparkle(size: art.fontSize(0.011))
            }
            .artFrame(art.rect(0.11, 0.8265, 0.78, 0.060))
            .allowsHitTesting(false)

            ArtHotspot(rect: art.rect(0.06, 0.815, 0.88, 0.083), label: "View Full Reading") {
                if isFree { appState.showPaywall = true } else { tab = .inDepth }
            }

            footer(art)
        }
    }

    // MARK: - Scrolling tabs

    private func scrollingScreen<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ArtScreen(image: "bg_frame") { art in
            chrome(art)

            ScrollView(showsIndicators: false) {
                VStack(spacing: art.frame.height * 0.016) {
                    content()
                }
                .padding(.vertical, art.frame.height * 0.012)
            }
            .artFrame(art.rect(0.09, 0.235, 0.82, 0.665))

            footer(art)
        }
    }

    // MARK: - Shared chrome

    /// bg_reading bakes a circular well for the back button at (13.3%, 11.0%) of the
    /// art — pixel-measured — but bg_frame (used by the scrolling tabs) has no matching
    /// well, so only the overview screen aligns to it; the other tabs keep the old
    /// generic top-left/top-right placement.
    @ViewBuilder
    private func chrome(
        _ art: ArtGeometry,
        backRect: CGRect? = nil,
        shareRect: CGRect? = nil
    ) -> some View {
        let back = backRect ?? art.rect(0.028, 0.055, 0.10, 0.048)
        let share = shareRect ?? art.rect(0.865, 0.055, 0.10, 0.048)

        BackButton(showsBackground: backRect == nil) { dismiss() }
            .artFrame(back)

        Button {
            appState.navigate(.share(reading))
        } label: {
            IconMedallion(systemName: "square.and.arrow.up", diameter: share.width, backgroundOpacity: 1)
        }
        .artFrame(share)
        .accessibilityLabel("Share this reading")

        ArtSelector(
            tabs: [(Tab.overview, "OVERVIEW"), (.inDepth, "IN-DEPTH"), (.lines, "LINES")],
            selection: $tab
        )
        .artFrame(art.rect(0.055, 0.176, 0.89, 0.040))
    }

    private func footer(_ art: ArtGeometry) -> some View {
        VStack(spacing: 1) {
            Text("The future is in your hands.")
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0128)))
                .foregroundStyle(Theme.goldLight.opacity(0.85))
            // Required disclaimer on every reading (§9).
            Text("For entertainment purposes only.")
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0108)))
                .foregroundStyle(Theme.gold.opacity(0.65))
        }
        .multilineTextAlignment(.center)
        .artFrame(art.rect(0.10, 0.935, 0.80, 0.045))
        .allowsHitTesting(false)
    }

    private func line(for kind: PalmLine.Kind) -> PalmLine {
        switch kind {
        case .life:  return reading.content.lines.life
        case .head:  return reading.content.lines.head
        case .heart: return reading.content.lines.heart
        case .fate:  return reading.content.lines.fate
        }
    }

    // MARK: - Tab content

    @ViewBuilder
    private var inDepthContent: some View {
        timelineCard("THE NEAR FUTURE", text: reading.content.timeline.nearFuture, locked: false)
        timelineCard("THIS YEAR", text: reading.content.timeline.thisYear, locked: isFree)
        timelineCard("THE LONG ROAD", text: reading.content.timeline.longTerm, locked: isFree)

        ReadingCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Spacer()
                    Sparkle(size: 10)
                    Text("KEY INSIGHTS")
                        .font(Typography.displaySmall)
                        .kerning(1.5)
                        .foregroundStyle(Theme.gold)
                    Sparkle(size: 10)
                    Spacer()
                }
                ForEach(reading.content.keyInsights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Sparkle(size: 9).padding(.top, 5)
                        Text(insight)
                            .font(Typography.bodyText)
                            .foregroundStyle(Theme.goldLight)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var linesContent: some View {
        ForEach(reading.content.lines.ordered, id: \.kind) { entry in
            ReadingCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.line.title.uppercased())
                        .font(Typography.heading)
                        .foregroundStyle(Theme.gold)
                    Text(entry.line.subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.goldLight.opacity(0.85))
                    OrnamentDivider()
                    Text(entry.line.body)
                        .font(Typography.bodyText)
                        .foregroundStyle(Theme.goldLight)
                    if let traits = entry.line.traits, !traits.isEmpty {
                        TraitChips(traits: traits)
                    }
                }
            }
        }
    }

    private func timelineCard(_ title: String, text: String?, locked: Bool) -> some View {
        ReadingCard {
            VStack(spacing: 8) {
                Text(title)
                    .font(Typography.displaySmall)
                    .kerning(1.5)
                    .foregroundStyle(Theme.gold)
                if locked || text == nil {
                    LockedTeaser { appState.showPaywall = true }
                } else {
                    Text(text ?? "")
                        .font(Typography.bodyText)
                        .foregroundStyle(Theme.goldLight)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Debug entry points

    private static var initialTab: Tab {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["DEBUG_ROUTE"] {
        case "reading-indepth": return .inDepth
        case "reading-lines":   return .lines
        default:                return .overview
        }
        #else
        return .overview
        #endif
    }

    private static var initialDetail: PalmLine.Kind? {
        #if DEBUG
        return ProcessInfo.processInfo.environment["DEBUG_ROUTE"] == "reading-detail" ? .life : nil
        #else
        return nil
        #endif
    }
}

/// Simple bordered card for the scrolling reading tabs, styled to sit on the ornate frame.
struct ReadingCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.42))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Theme.gold.opacity(0.55), lineWidth: 1)
                    )
            )
    }
}

/// Detail sheet for one line.
struct LineDetailSheet: View {
    let kind: PalmLine.Kind
    let line: PalmLine
    let isFree: Bool
    let onUnlock: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                IconMedallion(systemName: kind.icon, diameter: 84)
                    .padding(.top, 20)

                Text(kind.displayTitle)
                    .font(Typography.title)
                    .foregroundStyle(Theme.goldBevel)

                Text(line.subtitle)
                    .font(Typography.bodyText)
                    .foregroundStyle(Theme.goldLight.opacity(0.85))

                OrnamentDivider().padding(.horizontal, 60)

                ReadingCard {
                    Text(line.body)
                        // Larger than standard body copy: the sheet exists to be read.
                        .font(.custom("AlegreyaSans-Regular", size: 21, relativeTo: .body))
                        .lineSpacing(3)
                        .foregroundStyle(Theme.goldLight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 18)

                if let traits = line.traits, !traits.isEmpty {
                    TraitChips(traits: traits).padding(.horizontal, 18)
                } else if isFree {
                    Button(action: onUnlock) {
                        Label("Unlock traits with Premium", systemImage: "lock.fill")
                            .font(Typography.bodyEmphasis)
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
            .padding(.bottom, 28)
        }
        .screenBackground()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

extension PalmLine.Kind {
    var displayTitle: String {
        switch self {
        case .life:  return "LIFE LINE"
        case .head:  return "HEAD LINE"
        case .heart: return "HEART LINE"
        case .fate:  return "FATE LINE"
        }
    }
}

/// Blurred locked teaser routing to the paywall.
struct LockedTeaser: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Text("The road bends toward brighter seasons, and what you plant in quiet months will flower in full view.")
                    .font(Typography.bodyText)
                    .foregroundStyle(Theme.goldLight)
                    .multilineTextAlignment(.center)
                    .blur(radius: 6)
                    .accessibilityHidden(true)
                VStack(spacing: 6) {
                    Image(systemName: "lock.fill").font(.system(size: 22))
                    Text("Unlock with Premium").font(Typography.bodyEmphasis)
                }
                .foregroundStyle(Theme.gold)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Locked. Unlock with Premium.")
    }
}

struct TraitChips: View {
    let traits: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(traits, id: \.self) { trait in
                Text(trait)
                    .font(Typography.fine)
                    .foregroundStyle(Theme.goldLight)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Theme.crimson.opacity(0.7))
                            .overlay(Capsule().strokeBorder(Theme.goldDark, lineWidth: 1))
                    )
            }
        }
    }
}

/// Minimal flow layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var height: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !current.indices.isEmpty {
                rows.append(current); current = Row(); x = 0
            }
            current.indices.append(index)
            current.height = max(current.height, size.height)
            x += size.width + spacing
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
