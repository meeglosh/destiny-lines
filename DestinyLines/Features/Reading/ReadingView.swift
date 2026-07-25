import SwiftUI

/// DL-reading.png used directly for the OVERVIEW tab — every visual there is baked
/// (titles, subtitles, icons are the same for all readings). Tabs and cards get
/// hotspots; tapping a line opens its detail sheet with the real reading text.
/// IN-DEPTH and LINES have no comps, so they render dynamic content over
/// bg_reading_blank (the same art with the content region cleared).
struct ReadingView: View {
    let reading: Reading

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    enum Tab: Hashable { case overview, inDepth, lines }
    @State private var tab: Tab = .overview
    @State private var detailLine: PalmLine.Kind?

    private var isFree: Bool { reading.tier == .free }

    var body: some View {
        Group {
            switch tab {
            case .overview: overviewArt
            case .inDepth: dynamicTab { inDepthContent }
            case .lines: dynamicTab { linesContent }
            }
        }
        .sheet(item: $detailLine) { kind in
            LineDetailSheet(kind: kind, line: line(for: kind), isFree: isFree) {
                appState.showPaywall = true
            }
        }
    }

    private func line(for kind: PalmLine.Kind) -> PalmLine {
        switch kind {
        case .life: return reading.content.lines.life
        case .head: return reading.content.lines.head
        case .heart: return reading.content.lines.heart
        case .fate: return reading.content.lines.fate
        }
    }

    // MARK: - Overview (pure art + hotspots)

    private var overviewArt: some View {
        ArtScreen(image: "bg_reading") { art in
            backHotspot(art)
            tabHotspots(art)

            // Four line cards
            ArtHotspot(rect: art.rect(0.045, 0.218, 0.91, 0.140), label: "Life Line. Your vitality and major life changes.",
                       debug: ArtDebug.showHotspots) { detailLine = .life }
            ArtHotspot(rect: art.rect(0.045, 0.371, 0.91, 0.140), label: "Head Line. Your mind, intellect and decision making.",
                       debug: ArtDebug.showHotspots) { detailLine = .head }
            ArtHotspot(rect: art.rect(0.045, 0.527, 0.91, 0.140), label: "Heart Line. Your emotions, love and relationships.",
                       debug: ArtDebug.showHotspots) { detailLine = .heart }
            ArtHotspot(rect: art.rect(0.045, 0.680, 0.91, 0.140), label: "Fate Line. Your path, purpose and destiny.",
                       debug: ArtDebug.showHotspots) { detailLine = .fate }

            // VIEW FULL READING plate
            ArtHotspot(rect: art.rect(0.10, 0.829, 0.80, 0.067), label: "View Full Reading",
                       debug: ArtDebug.showHotspots) {
                if isFree {
                    appState.showPaywall = true
                } else {
                    tab = .inDepth
                }
            }

            disclaimer(art)
        }
    }

    // MARK: - Dynamic tabs (blank art + real content)

    private func dynamicTab<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ArtScreen(image: "bg_reading_blank") { art in
            backHotspot(art)
            tabHotspots(art)

            ScrollView {
                VStack(spacing: Theme.cardSpacing) {
                    content()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
            .artFrame(art.rect(0.03, 0.215, 0.94, 0.62))

            disclaimer(art)
        }
    }

    private var inDepthContent: some View {
        Group {
            timelineCard("THE NEAR FUTURE", text: reading.content.timeline.nearFuture, locked: false)
            timelineCard("THIS YEAR", text: reading.content.timeline.thisYear, locked: isFree)
            timelineCard("THE LONG ROAD", text: reading.content.timeline.longTerm, locked: isFree)
            keyInsightsCard
        }
    }

    private var linesContent: some View {
        ForEach(reading.content.lines.ordered, id: \.kind) { entry in
            OrnateCard(contentPadding: 14) {
                VStack(spacing: 10) {
                    HStack(spacing: 14) {
                        IconMedallion(systemName: entry.kind.icon, diameter: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.line.title.uppercased())
                                .font(Typography.heading)
                                .foregroundStyle(Theme.gold)
                            Text(entry.line.subtitle)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.goldLight.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    OrnamentDivider()
                    Text(entry.line.body)
                        .font(Typography.bodyText)
                        .foregroundStyle(Theme.goldLight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let traits = entry.line.traits, !traits.isEmpty {
                        TraitChips(traits: traits)
                    }
                }
            }
        }
    }

    private func timelineCard(_ title: String, text: String?, locked: Bool) -> some View {
        OrnateCard {
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

    private var keyInsightsCard: some View {
        OrnateCard {
            VStack(alignment: .leading, spacing: 12) {
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
                    HStack(alignment: .top, spacing: 10) {
                        Sparkle(size: 10).padding(.top, 4)
                        Text(insight)
                            .font(Typography.bodyText)
                            .foregroundStyle(Theme.goldLight)
                    }
                }
            }
        }
    }

    // MARK: - Shared hotspots

    private func backHotspot(_ art: ArtGeometry) -> some View {
        ArtHotspot(rect: art.rect(0.02, 0.055, 0.13, 0.062), label: "Back",
                   debug: ArtDebug.showHotspots) {
            dismiss()
        }
    }

    @ViewBuilder
    private func tabHotspots(_ art: ArtGeometry) -> some View {
        ArtHotspot(rect: art.rect(0.045, 0.163, 0.325, 0.052), label: "Overview tab",
                   debug: ArtDebug.showHotspots) { tab = .overview }
        ArtHotspot(rect: art.rect(0.378, 0.163, 0.28, 0.052), label: "In-Depth tab",
                   debug: ArtDebug.showHotspots) { tab = .inDepth }
        ArtHotspot(rect: art.rect(0.665, 0.163, 0.29, 0.052), label: "Lines tab",
                   debug: ArtDebug.showHotspots) { tab = .lines }

        // Selected-tab indicator when off Overview (the art bakes Overview as selected).
        if tab != .overview {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.gold, lineWidth: 1.6)
                .artFrame(
                    tab == .inDepth
                        ? art.rect(0.378, 0.163, 0.28, 0.052)
                        : art.rect(0.665, 0.163, 0.29, 0.052)
                )
                .allowsHitTesting(false)
        }
    }

    private func disclaimer(_ art: ArtGeometry) -> some View {
        // Required disclaimer on readings (§9): slim strip pinned under the art's footer.
        Text("For entertainment purposes only.")
            .font(Typography.fine)
            .foregroundStyle(Theme.gold.opacity(0.7))
            .artFrame(art.rect(0, 0.978, 1, 0.022))
            .background(Theme.background)
            .allowsHitTesting(false)
    }
}

extension PalmLine.Kind {
    var displayTitle: String {
        switch self {
        case .life: return "LIFE LINE"
        case .head: return "HEAD LINE"
        case .heart: return "HEART LINE"
        case .fate: return "FATE LINE"
        }
    }
}

/// Detail sheet for one line, in the established style (no comp exists for it).
struct LineDetailSheet: View {
    let kind: PalmLine.Kind
    let line: PalmLine
    let isFree: Bool
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                IconMedallion(systemName: kind.icon, diameter: 74)
                    .padding(.top, 24)

                Text(kind.displayTitle)
                    .font(Typography.title)
                    .foregroundStyle(Theme.goldBevel)

                Text(line.subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.goldLight.opacity(0.85))

                OrnamentDivider()
                    .padding(.horizontal, 60)

                OrnateCard {
                    Text(line.body)
                        .font(Typography.bodyText)
                        .foregroundStyle(Theme.goldLight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)

                if let traits = line.traits, !traits.isEmpty {
                    TraitChips(traits: traits)
                        .padding(.horizontal, 20)
                } else if isFree {
                    Button(action: onUnlock) {
                        Label("Unlock traits with Premium", systemImage: "lock.fill")
                            .font(Typography.bodyEmphasis)
                            .foregroundStyle(Theme.gold)
                    }
                }

                Button("Close") { dismiss() }
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.gold)
                    .padding(.bottom, 24)
            }
        }
        .screenBackground()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Blurred locked teaser routing to the paywall.
struct LockedTeaser: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Text("The road bends toward brighter seasons, and what you plant in quiet months will flower in full view. Watch for a door that opens twice.")
                    .font(Typography.bodyText)
                    .foregroundStyle(Theme.goldLight)
                    .multilineTextAlignment(.center)
                    .blur(radius: 6)
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22))
                    Text("Unlock with Premium")
                        .font(Typography.bodyEmphasis)
                }
                .foregroundStyle(Theme.gold)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Locked. Unlock with Premium.")
    }
}

/// Trait chips.
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

extension PalmLine.Kind {
    // Identifiable for .sheet(item:)
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
                rows.append(current)
                current = Row()
                x = 0
            }
            current.indices.append(index)
            current.height = max(current.height, size.height)
            x += size.width + spacing
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}
