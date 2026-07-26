import SwiftUI

/// Reading, rebuilt from components: live header, segmented tabs, and the four painted
/// line medallions in sliced card frames. Everything scrolls; the tier lock routes to
/// the paywall; the entertainment disclaimer sits in the footer.
struct ReadingView: View {
    let reading: Reading

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    enum Tab: Hashable { case overview, inDepth, lines }
    @State private var tab: Tab = Self.initialTab
    @State private var detailLine: PalmLine.Kind? = Self.initialDetail

    private var isFree: Bool { reading.tier == .free }

    var body: some View {
        VStack(spacing: 12) {
            header
                .padding(.top, 4)

            SegmentedTabs(
                tabs: [(Tab.overview, "OVERVIEW"), (.inDepth, "IN-DEPTH"), (.lines, "LINES")],
                selection: $tab
            )
            .padding(.horizontal, 22)

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.cardSpacing) {
                    switch tab {
                    case .overview: overview
                    case .inDepth: inDepth
                    case .lines: linesContent
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }

            footer
        }
        .boothBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $detailLine) { kind in
            LineDetailSheet(kind: kind, line: line(for: kind), isFree: isFree) {
                appState.showPaywall = true
            }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("DESTINY LINES")
                    .font(.custom("Rye-Regular", size: 12))
                    .kerning(2)
                    .foregroundStyle(Theme.gold.opacity(0.8))
                HStack(spacing: 12) {
                    Sparkle()
                    Text("YOUR READING")
                        .font(Typography.title)
                        .foregroundStyle(Theme.goldBevel)
                    Sparkle()
                }
                OrnamentDivider()
                    .padding(.horizontal, 80)
            }
            HStack {
                BackButton { dismiss() }
                Spacer()
                Button {
                    appState.navigate(.share(reading))
                } label: {
                    IconMedallion(systemName: "square.and.arrow.up", diameter: 38)
                }
                .accessibilityLabel("Share this reading")
            }
            .padding(.horizontal, 16)
        }
        .accessibilityElement(children: .contain)
    }

    private var footer: some View {
        VStack(spacing: 2) {
            Text("The future is in your hands.")
                .font(Typography.caption)
                .foregroundStyle(Theme.goldLight.opacity(0.85))
            Text("For entertainment purposes only.")
                .font(Typography.fine)
                .foregroundStyle(Theme.gold.opacity(0.65))
        }
        .padding(.bottom, 8)
    }

    private func line(for kind: PalmLine.Kind) -> PalmLine {
        switch kind {
        case .life: return reading.content.lines.life
        case .head: return reading.content.lines.head
        case .heart: return reading.content.lines.heart
        case .fate: return reading.content.lines.fate
        }
    }

    // MARK: - Overview

    private var overview: some View {
        Group {
            ForEach(reading.content.lines.ordered, id: \.kind) { entry in
                Button {
                    detailLine = entry.kind
                } label: {
                    ArtCard(contentPadding: 12) {
                        HStack(spacing: 14) {
                            ArtMedallionView(kind: entry.kind.artMedallion, diameter: 72)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.line.title.uppercased())
                                    .font(Typography.heading)
                                    .foregroundStyle(Theme.gold)
                                Text(entry.line.subtitle)
                                    .font(Typography.caption)
                                    .foregroundStyle(Theme.goldLight.opacity(0.85))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.gold)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("\(entry.line.title). \(entry.line.subtitle)")
            }

            ArtPlateButton(style: .crimson, text: "VIEW FULL READING") {
                if isFree {
                    appState.showPaywall = true
                } else {
                    tab = .inDepth
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - In-Depth

    private var inDepth: some View {
        Group {
            timelineCard("THE NEAR FUTURE", text: reading.content.timeline.nearFuture, locked: false)
            timelineCard("THIS YEAR", text: reading.content.timeline.thisYear, locked: isFree)
            timelineCard("THE LONG ROAD", text: reading.content.timeline.longTerm, locked: isFree)
            keyInsightsCard
        }
    }

    private func timelineCard(_ title: String, text: String?, locked: Bool) -> some View {
        ArtCard {
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
        ArtCard {
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

    // MARK: - Lines

    private var linesContent: some View {
        ForEach(reading.content.lines.ordered, id: \.kind) { entry in
            ArtCard(contentPadding: 14) {
                VStack(spacing: 10) {
                    HStack(spacing: 14) {
                        ArtMedallionView(kind: entry.kind.artMedallion, diameter: 60)
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

    // MARK: - Debug entry points

    private static var initialTab: Tab {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["DEBUG_ROUTE"] {
        case "reading-indepth": return .inDepth
        case "reading-lines": return .lines
        default: return .overview
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

// MARK: - Detail sheet

/// Detail sheet for one line: painted medallion, large-type reading body.
struct LineDetailSheet: View {
    let kind: PalmLine.Kind
    let line: PalmLine
    let isFree: Bool
    let onUnlock: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ArtMedallionView(kind: kind.artMedallion, diameter: 96)
                    .padding(.top, 18)

                Text(kind.displayTitle)
                    .font(Typography.title)
                    .foregroundStyle(Theme.goldBevel)

                Text(line.subtitle)
                    .font(Typography.bodyText)
                    .foregroundStyle(Theme.goldLight.opacity(0.85))

                OrnamentDivider()
                    .padding(.horizontal, 60)

                ArtCard(contentPadding: 18) {
                    Text(line.body)
                        // Larger than standard body copy: this is the reading itself and
                        // the sheet exists to be read, not skimmed.
                        .font(.custom("AlegreyaSans-Regular", size: 21, relativeTo: .body))
                        .lineSpacing(3)
                        .foregroundStyle(Theme.goldLight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                if let traits = line.traits, !traits.isEmpty {
                    TraitChips(traits: traits)
                        .padding(.horizontal, 16)
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
        .boothBackground(flourishes: false)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
