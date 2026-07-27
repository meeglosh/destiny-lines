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
                            // The icon well is painted at roughly 8%–26% of the width.
                            Image(systemName: icon)
                                .font(.system(size: h * 0.34, weight: .medium))
                                .foregroundStyle(Theme.goldBevel)
                                .frame(width: proxy.size.width * 0.175)

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

/// The bottom navigation bar. The art paints five icons with the centre one seated in
/// an ornate plate — that plate is permanent centre-item styling, not selection — so the
/// active tab is signalled with a generated gold glow and lit label instead.
struct ArtNavBar: View {
    @Binding var selection: MainTab
    let onRead: () -> Void

    /// Icon centres measured across the bar art's width.
    private let slots: [(tab: MainTab, x: CGFloat, label: String)] = [
        (.home,     0.155, "HOME"),
        (.read,     0.325, "READ"),
        (.history,  0.475, "HISTORY"),
        (.insights, 0.655, "INSIGHTS"),
        (.settings, 0.825, "SETTINGS"),
    ]

    /// The painted icons sit in the bar's upper third; labels go beneath them, clear of
    /// the centre item's plate.
    private let iconCentreY: CGFloat = 0.25
    private let labelCentreY: CGFloat = 0.80

    var body: some View {
        Image("nav_bar")
            .resizable()
            .scaledToFit()
            .overlay(
                GeometryReader { proxy in
                    let w = proxy.size.width * 0.19
                    let h = proxy.size.height

                    ZStack(alignment: .topLeading) {
                        ForEach(slots, id: \.tab) { slot in
                            let isSelected = slot.tab == selection

                            Button {
                                if slot.tab == .read { onRead() } else { selection = slot.tab }
                            } label: {
                                ZStack(alignment: .top) {
                                    // Selection is a soft warm halo behind the painted
                                    // icon: enough to read as lit, not enough to wash the
                                    // artwork out. Centred on the icon, not the button.
                                    if isSelected {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [Theme.glow.opacity(0.20), .clear],
                                                    center: .center,
                                                    startRadius: 1,
                                                    endRadius: h * 0.22
                                                )
                                            )
                                            .frame(width: h * 0.46, height: h * 0.46)
                                            .offset(y: h * iconCentreY - h * 0.24)
                                    }

                                    Text(slot.label)
                                        .font(.custom("Rye-Regular", size: h * 0.115))
                                        .kerning(0.4)
                                        .foregroundStyle(isSelected ? Theme.gold : Theme.goldDark)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .offset(y: h * labelCentreY - h * 0.06)

                                    Color.clear.contentShape(Rectangle())
                                }
                                .frame(width: w, height: h)
                            }
                            .buttonStyle(.plain)
                            .offset(x: proxy.size.width * slot.x - w / 2)
                            .accessibilityLabel(slot.label.capitalized)
                            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
                        }
                    }
                }
            )
            .accessibilityElement(children: .contain)
    }
}
