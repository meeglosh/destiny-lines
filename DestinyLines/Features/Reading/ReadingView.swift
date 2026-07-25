import SwiftUI

/// DL-reading.png: "YOUR READING" header, OVERVIEW / IN-DEPTH / LINES segmented tabs.
/// Overview lists the four line cards plus "View Full Reading"; In-Depth holds the
/// timeline sections; Lines is the four cards expanded. Free-tier locked sections show
/// a blurred teaser that routes to the paywall.
struct ReadingView: View {
    let reading: Reading

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    enum Tab: Hashable { case overview, inDepth, lines }
    @State private var tab: Tab = .overview
    @State private var expandedLine: PalmLine.Kind?

    private var isFree: Bool { reading.tier == .free }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                SegmentedTabs(
                    tabs: [(Tab.overview, "OVERVIEW"), (.inDepth, "IN-DEPTH"), (.lines, "LINES")],
                    selection: $tab
                )
                .padding(.horizontal, 24)

                switch tab {
                case .overview: overview
                case .inDepth: inDepth
                case .lines: linesTab
                }

                footer
            }
            .padding(.vertical, 8)
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.navigate(.share(reading))
                } label: {
                    IconMedallion(systemName: "square.and.arrow.up", diameter: 38)
                }
                .accessibilityLabel("Share this reading")
            }
        }
    }

    // MARK: - Header / footer

    private var header: some View {
        VStack(spacing: 4) {
            Text("DESTINY LINES")
                .font(Typography.displaySmall)
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
                .padding(.horizontal, 70)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            crystalDot
            Text("The future is in your hands.\nKeep exploring your destiny.")
                .font(Typography.caption)
                .foregroundStyle(Theme.goldLight.opacity(0.8))
                .multilineTextAlignment(.center)
            // Required disclaimer, shown on every reading (§9).
            Text("For entertainment purposes only.")
                .font(Typography.fine)
                .foregroundStyle(Theme.gold.opacity(0.6))
                .padding(.top, 4)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
    }

    private var crystalDot: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Theme.glow.opacity(0.9), .clear],
                    center: .center, startRadius: 1, endRadius: 16
                )
            )
            .frame(width: 26, height: 26)
            .accessibilityHidden(true)
    }

    // MARK: - Overview

    private var overview: some View {
        VStack(spacing: Theme.cardSpacing) {
            summaryCard

            ForEach(reading.content.lines.ordered, id: \.kind) { entry in
                lineCard(kind: entry.kind, line: entry.line)
            }

            PrimaryCTAButton(title: "VIEW FULL READING", showsBulbs: false) {
                if isFree {
                    appState.showPaywall = true
                } else {
                    tab = .inDepth
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
    }

    private var summaryCard: some View {
        OrnateCard {
            VStack(spacing: 8) {
                Text("WHAT THE LINES SAY")
                    .font(Typography.displaySmall)
                    .kerning(1.5)
                    .foregroundStyle(Theme.gold)
                Text(reading.content.summary)
                    .font(Typography.bodyText)
                    .foregroundStyle(Theme.goldLight)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func lineCard(kind: PalmLine.Kind, line: PalmLine) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedLine = expandedLine == kind ? nil : kind
            }
        } label: {
            OrnateCard(contentPadding: 12) {
                VStack(spacing: 10) {
                    HStack(spacing: 14) {
                        IconMedallion(systemName: kind.icon, diameter: 56)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(line.title.uppercased())
                                .font(Typography.heading)
                                .foregroundStyle(Theme.gold)
                            Text(line.subtitle)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.goldLight.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: expandedLine == kind ? "chevron.down" : "chevron.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                            .accessibilityHidden(true)
                    }

                    if expandedLine == kind {
                        lineDetail(line)
                    }
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(expandedLine == kind ? "Collapses the detail" : "Expands the detail")
    }

    private func lineDetail(_ line: PalmLine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            OrnamentDivider()
            Text(line.body)
                .font(Typography.bodyText)
                .foregroundStyle(Theme.goldLight)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let traits = line.traits, !traits.isEmpty {
                FlowTraits(traits: traits)
            }
        }
    }

    // MARK: - In-Depth

    private var inDepth: some View {
        VStack(spacing: Theme.cardSpacing) {
            timelineSection("THE NEAR FUTURE", text: reading.content.timeline.nearFuture, locked: false)
            timelineSection("THIS YEAR", text: reading.content.timeline.thisYear, locked: isFree)
            timelineSection("THE LONG ROAD", text: reading.content.timeline.longTerm, locked: isFree)

            keyInsightsCard
        }
        .padding(.horizontal, 24)
    }

    private func timelineSection(_ title: String, text: String?, locked: Bool) -> some View {
        OrnateCard {
            VStack(spacing: 8) {
                Text(title)
                    .font(Typography.displaySmall)
                    .kerning(1.5)
                    .foregroundStyle(Theme.gold)

                if locked || text == nil {
                    lockedTeaser
                } else {
                    Text(text ?? "")
                        .font(Typography.bodyText)
                        .foregroundStyle(Theme.goldLight)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    /// Blurred teaser for free-tier locked sections; tapping routes to the paywall.
    private var lockedTeaser: some View {
        Button {
            appState.showPaywall = true
        } label: {
            ZStack {
                Text(placeholderProse)
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

    private var placeholderProse: String {
        "The road bends toward brighter seasons, and what you plant in quiet months will flower in full view. Watch for a door that opens twice."
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
                        Sparkle(size: 10)
                            .padding(.top, 4)
                        Text(insight)
                            .font(Typography.bodyText)
                            .foregroundStyle(Theme.goldLight)
                    }
                }
            }
        }
    }

    // MARK: - Lines tab

    private var linesTab: some View {
        VStack(spacing: Theme.cardSpacing) {
            ForEach(reading.content.lines.ordered, id: \.kind) { entry in
                OrnateCard(contentPadding: 14) {
                    VStack(spacing: 10) {
                        HStack(spacing: 14) {
                            IconMedallion(systemName: entry.kind.icon, diameter: 50)
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
                        lineDetail(entry.line)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

/// Trait chips laid out in rows.
private struct FlowTraits: View {
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
