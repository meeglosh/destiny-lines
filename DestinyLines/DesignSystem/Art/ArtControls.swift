import SwiftUI

/// Controls built from the supplied component art. Each is a painted plate with live
/// text and icons over it, so labels resize, localize and read aloud while the artwork
/// stays exactly as drawn. None of the plates ship a pressed variant, so press feedback
/// is generated (inset + warm dim) by `ArtPressStyle`.

// MARK: - Plate buttons

enum ArtButtonStyle {
    /// Bulb-framed marquee plate — the primary call to action (NEW READING).
    case ornate
    /// Slimmer bulb-framed red plate.
    case primary
    /// Red plate without bulbs, for secondary emphasis.
    case primaryAlt
    /// Deep green plate — subscription / confirm.
    case secondary

    var assetName: String {
        switch self {
        case .ornate: return "btn_ornate"
        case .primary: return "btn_primary"
        case .primaryAlt: return "btn_primary_alt"
        case .secondary: return "btn_secondary"
        }
    }

    /// Label height as a share of the plate height, tuned per plate's inner margin.
    var textScale: CGFloat {
        switch self {
        case .ornate: return 0.30
        case .primary: return 0.34
        case .primaryAlt: return 0.36
        case .secondary: return 0.36
        }
    }

    /// Horizontal room for the label inside the plate's ornament.
    var textWidth: CGFloat {
        switch self {
        case .ornate: return 0.74
        case .primary: return 0.76
        case .primaryAlt: return 0.80
        case .secondary: return 0.80
        }
    }
}

struct ArtButton: View {
    let style: ArtButtonStyle
    let title: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(style.assetName)
                .resizable()
                .scaledToFit()
                .overlay(
                    GeometryReader { proxy in
                        Text(title)
                            .font(.custom("Rye-Regular", size: proxy.size.height * style.textScale))
                            .kerning(1.2)
                            .foregroundStyle(Theme.goldBevel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                            .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                            .frame(width: proxy.size.width * style.textWidth,
                                   height: proxy.size.height)
                            .offset(x: proxy.size.width * (1 - style.textWidth) / 2)
                    }
                )
        }
        .buttonStyle(ArtPressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .accessibilityLabel(title.capitalized)
    }
}

// MARK: - Tertiary row

/// The dark list row plate: circular icon well on the left, title and subtitle beside it,
/// chevron at the trailing edge. Used wherever a screen needs a variable number of rows.
struct ArtRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("btn_tertiary")
                .resizable()
                .scaledToFit()
                .overlay(
                    GeometryReader { proxy in
                        let h = proxy.size.height
                        HStack(spacing: 0) {
                            // The well's ring is pixel-measured at center (10.8%, 47%) of
                            // the plate, not the geometric center of this 17.5%-wide band
                            // (8.75%), so the icon needs a small nudge to sit inside it.
                            Image(systemName: icon)
                                .font(.system(size: h * 0.34, weight: .medium))
                                .foregroundStyle(Theme.goldBevel)
                                .frame(width: proxy.size.width * 0.175)
                                .offset(x: proxy.size.width * 0.0205, y: -h * 0.03)

                            VStack(alignment: .leading, spacing: h * 0.04) {
                                Text(title)
                                    .font(.custom("Rye-Regular", size: h * 0.235))
                                    .foregroundStyle(Theme.gold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                if let subtitle {
                                    Text(subtitle)
                                        .font(.custom("AlegreyaSans-Regular", size: h * 0.175))
                                        .foregroundStyle(Theme.goldLight.opacity(0.85))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // The well's right edge sits at ~20.6% of the plate; clear it
                            // before the label starts.
                            .padding(.leading, proxy.size.width * 0.04)

                            Image(systemName: "chevron.right")
                                .font(.system(size: h * 0.20, weight: .semibold))
                                .foregroundStyle(Theme.gold.opacity(0.9))
                                .frame(width: proxy.size.width * 0.10)
                        }
                        .padding(.trailing, proxy.size.width * 0.02)
                        .frame(width: proxy.size.width, height: h)
                    }
                )
        }
        .buttonStyle(ArtPressStyle())
        .disabled(!enabled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.map { "\(title). \($0)" } ?? title)
    }
}

// MARK: - History row

/// The reading-history list row plate: unlike `ArtRow`, the palm icon and the chevron
/// are both baked into btn_history's own art (every row is a reading, so there's no
/// per-row icon to vary), so only the title and subtitle are live text. The safe text
/// zone (28%–85% of the plate) is pixel-measured to clear the icon well on the left and
/// the chevron on the right.
struct ArtHistoryRow: View {
    let title: String
    var subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("btn_history")
                .resizable()
                .scaledToFit()
                .overlay(
                    GeometryReader { proxy in
                        let h = proxy.size.height
                        VStack(alignment: .leading, spacing: h * 0.04) {
                            Text(title)
                                .font(.custom("Rye-Regular", size: h * 0.235))
                                .foregroundStyle(Theme.gold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            if let subtitle {
                                Text(subtitle)
                                    .font(.custom("AlegreyaSans-Regular", size: h * 0.175))
                                    .foregroundStyle(Theme.goldLight.opacity(0.85))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                        }
                        .frame(width: proxy.size.width * 0.57, alignment: .leading)
                        .offset(x: proxy.size.width * 0.28)
                        .frame(width: proxy.size.width, height: h, alignment: .leading)
                    }
                )
        }
        .buttonStyle(ArtPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.map { "\(title). \($0)" } ?? title)
    }
}

// MARK: - Segmented selector

/// Three-piece segmented control. The default pieces are supplied art; the selected
/// pieces are generated from them by a luminance-preserving crimson ramp plus a gold
/// rim, so geometry matches exactly and the lit state reads like the mockup.
struct ArtSelector<Tab: Hashable>: View {
    let tabs: [(tab: Tab, label: String)]
    @Binding var selection: Tab

    var body: some View {
        GeometryReader { proxy in
            let h = proxy.size.height
            HStack(spacing: -1) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, entry in
                    let isSelected = entry.tab == selection
                    let piece = pieceName(index: index, count: tabs.count, selected: isSelected)

                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) { selection = entry.tab }
                    } label: {
                        Image(piece)
                            .resizable()
                            .scaledToFill()
                            .overlay(
                                HStack(spacing: h * 0.10) {
                                    if isSelected { Sparkle(size: h * 0.16) }
                                    Text(entry.label)
                                        .font(.custom("Rye-Regular", size: h * 0.26))
                                        .kerning(0.6)
                                        .foregroundStyle(isSelected ? Theme.goldLight : Theme.gold.opacity(0.72))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                                .padding(.horizontal, h * 0.12)
                            )
                            .frame(maxWidth: .infinity)
                            .clipped()
                    }
                    .buttonStyle(ArtPressStyle())
                    .accessibilityLabel(entry.label)
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
                }
            }
            .frame(width: proxy.size.width, height: h)
        }
    }

    private func pieceName(index: Int, count: Int, selected: Bool) -> String {
        let position = index == 0 ? "left" : (index == count - 1 ? "right" : "center")
        return selected ? "selector_\(position)_selected" : "selector_\(position)"
    }
}

// MARK: - Global navigation

enum MainTab: Hashable, CaseIterable {
    case home, read, history, insights, settings
}

/// The bottom navigation, rebuilt in code so selection can move.
///
/// The bar and its icons are drawn rather than sliced, following the mockup's language:
/// a dark strip under a gold hairline, an ornate glyph over a small-caps label, and the
/// bulb-framed plate (the one supplied art here) sliding behind whichever item is active.
struct ArtNavBar: View {
    @Binding var selection: MainTab
    let onRead: () -> Void

    @Namespace private var plateNamespace

    private struct Item {
        let tab: MainTab
        let label: String
        /// READ is an action rather than a destination, so it never takes the plate.
        var isAction: Bool { tab == .read }
    }

    private let items: [Item] = [
        Item(tab: .home, label: "HOME"),
        Item(tab: .read, label: "READ"),
        Item(tab: .history, label: "HISTORY"),
        Item(tab: .insights, label: "INSIGHTS"),
        Item(tab: .settings, label: "SETTINGS"),
    ]

    /// Index the plate rests on. READ never holds it, so it stays where it was.
    private var selectedIndex: Int {
        items.firstIndex { $0.tab == selection } ?? 0
    }

    var body: some View {
        GeometryReader { proxy in
            let itemWidth = proxy.size.width / CGFloat(items.count)
            // 33% bigger than the original plate, and touching the top of the bar rather
            // than floating below a gap — per the owner's measurement against the mockup.
            let plateWidth = itemWidth * 0.84 * 1.33
            let plateHeight = plateWidth / (174.0 / 109.0)
            // Clearance for the hairline only; the plate itself now starts right below it.
            let topInset: CGFloat = 6

            ZStack(alignment: .top) {
                // Active plate, sliding to the chosen item, seated at the top of the bar.
                Image("nav_active")
                    .resizable()
                    .frame(width: plateWidth, height: plateHeight)
                    .offset(
                        x: itemWidth * (CGFloat(selectedIndex) - CGFloat(items.count - 1) / 2),
                        y: topInset
                    )
                    .animation(.spring(response: 0.34, dampingFraction: 0.78), value: selectedIndex)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                HStack(spacing: 0) {
                    ForEach(items, id: \.tab) { item in
                        let isSelected = !item.isAction && item.tab == selection

                        Button {
                            if item.isAction { onRead() } else { selection = item.tab }
                        } label: {
                            VStack(spacing: plateHeight * 0.05) {
                                NavGlyph(tab: item.tab)
                                    .frame(width: plateHeight * 0.40, height: plateHeight * 0.40)
                                    .foregroundStyle(isSelected ? AnyShapeStyle(Theme.goldBevel) : AnyShapeStyle(Theme.gold.opacity(0.72)))

                                Text(item.label)
                                    .font(.custom("AlegreyaSans-Bold", size: plateHeight * 0.165))
                                    .kerning(0.7)
                                    .foregroundStyle(isSelected ? Theme.goldLight : Theme.gold.opacity(0.62))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.55)
                            }
                            // Bottom-aligned within the plate's own footprint (with a
                            // few points of breathing room) rather than pinned to the
                            // plate's top, so the label sits near the plate's bottom
                            // edge instead of floating in its upper half.
                            .padding(.bottom, 4)
                            .frame(width: itemWidth, height: plateHeight, alignment: .bottom)
                            .padding(.top, topInset)
                            .frame(width: itemWidth, height: proxy.size.height, alignment: .top)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(NavPressStyle())
                        .accessibilityLabel(item.label.capitalized)
                        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .background(navBackdrop)
        }
        .frame(height: 92)
    }

    /// Dark strip beneath a warm hairline, echoing the mockup's bar.
    private var navBackdrop: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color(red: 0x14 / 255, green: 0x0D / 255, blue: 0x09 / 255),
                    Color(red: 0x08 / 255, green: 0x05 / 255, blue: 0x03 / 255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [.clear, Theme.gold.opacity(0.75), Theme.gold.opacity(0.75), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

/// Slight dim on press; the plate itself carries the selected state.
private struct NavPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Nav glyphs drawn to match the mockup: a compass rose, a palm, an open book, an
/// eight-point star and a gear.
private struct NavGlyph: View {
    let tab: MainTab

    var body: some View {
        switch tab {
        case .home:
            // Compass rose: ring and star both kept inside the frame so the glyph never
            // overflows the active plate.
            ZStack {
                Circle()
                    .strokeBorder(.foreground, lineWidth: 1.1)
                    .opacity(0.5)
                StarBurst(points: 8)
                    .scaleEffect(0.64)
            }
        case .read:
            Image(systemName: "hand.raised.fill").resizable().scaledToFit()
        case .history:
            Image(systemName: "book.fill").resizable().scaledToFit()
        case .insights:
            StarBurst(points: 8)
        case .settings:
            Image(systemName: "gearshape.fill").resizable().scaledToFit()
        }
    }
}

/// Many-pointed star with concave sides, matching the mockup's ornamental stars.
struct StarBurst: Shape {
    var points: Int = 8
    var innerRatio: CGFloat = 0.34

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()

        for index in 0..<(points * 2) {
            let angle = (CGFloat(index) * .pi / CGFloat(points)) - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: centre.x + cos(angle) * radius,
                y: centre.y + sin(angle) * radius
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
