import SwiftUI

/// The component library sliced from the design comps. Every element here is an
/// independent, reusable piece of the original artwork with its baked lettering removed,
/// so screens compose them in ordinary SwiftUI layouts — responsive, safe-area-aware,
/// with live text — while keeping the comps' painted look.

// MARK: - Booth background

/// The dark leather booth backdrop: tiled texture from the comps, warm center light,
/// vignetted edges, and the comps' corner scrollwork at the bottom.
struct BoothBackground: View {
    var showFlourishes = true

    var body: some View {
        ZStack {
            Theme.background

            Image("booth_texture")
                .resizable(resizingMode: .tile)
                .opacity(0.9)

            RadialGradient(
                colors: [Color(red: 0x2E / 255, green: 0x1C / 255, blue: 0x0F / 255).opacity(0.55), .clear],
                center: .init(x: 0.5, y: 0.42),
                startRadius: 40,
                endRadius: 420
            )

            LinearGradient(
                colors: [.black.opacity(0.35), .clear, .clear, .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )

            if showFlourishes {
                VStack {
                    Spacer()
                    HStack {
                        Image("corner_flourish")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                        Spacer()
                        Image("corner_flourish")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                            .scaleEffect(x: -1)
                    }
                }
                .opacity(0.7)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Standard screen backdrop for all rebuilt screens.
    func boothBackground(flourishes: Bool = true) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BoothBackground(showFlourishes: flourishes))
            .preferredColorScheme(.dark)
    }
}

// MARK: - Ribbon banner

/// The parchment ribbon title (sliced from the comps, lettering removed). Text renders
/// live in the display face so it can shrink on small screens and be localized.
struct RibbonBanner: View {
    let text: String

    var body: some View {
        Image("ribbon_straight")
            .resizable()
            .scaledToFit()
            .overlay(
                GeometryReader { proxy in
                    Text(text)
                        .font(.custom("Rye-Regular", size: proxy.size.height * 0.26))
                        .kerning(1)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .frame(width: proxy.size.width * 0.70)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.52)
                }
            )
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(text)
    }
}

// MARK: - Plates (buttons)

/// The comps' three button plates, lettering removed, with live labels.
enum ArtPlateStyle {
    case marqueeRed   // NEW READING — bulb-ringed marquee plate
    case crimson      // VIEW FULL READING — ornate crimson plate
    case green        // START FREE TRIAL — deep green plate

    var assetName: String {
        switch self {
        case .marqueeRed: return "plate_red"
        case .crimson: return "plate_crimson"
        case .green: return "plate_green"
        }
    }

    /// Label size as a share of the plate's rendered height.
    var textScale: CGFloat {
        switch self {
        case .marqueeRed: return 0.26
        case .crimson: return 0.34
        case .green: return 0.32
        }
    }
}

struct ArtPlateButton: View {
    let style: ArtPlateStyle
    let text: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(style.assetName)
                .resizable()
                .scaledToFit()
                .overlay(
                    GeometryReader { proxy in
                        HStack(spacing: proxy.size.height * 0.12) {
                            Sparkle(size: proxy.size.height * 0.11)
                            Text(text)
                                .font(.custom("Rye-Regular", size: proxy.size.height * style.textScale))
                                .kerning(1.5)
                                .foregroundStyle(Theme.goldBevel)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Sparkle(size: proxy.size.height * 0.11)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
        .accessibilityLabel(Text(text.capitalized))
    }
}

// MARK: - Card frame (9-slice)

/// The comps' ornate card: gold double border with corner flourishes over dark leather,
/// stretched via cap insets so it takes any size without distorting the corners.
struct ArtCard<Content: View>: View {
    var contentPadding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(contentPadding)
            .frame(maxWidth: .infinity)
            .background(
                Image("card_frame")
                    .resizable(
                        capInsets: EdgeInsets(top: 26, leading: 30, bottom: 26, trailing: 30),
                        resizingMode: .stretch
                    )
            )
    }
}

// MARK: - Sliced medallions

/// The painted circular medallions from the reading comp (glowing hand, mind, heart,
/// compass star) plus a code-drawn fallback for icons with no painted counterpart.
enum ArtMedallionKind {
    case life, head, heart, fate
    case symbol(String)   // SF Symbol in the code-drawn gold medallion

    var assetName: String? {
        switch self {
        case .life: return "medallion_life"
        case .head: return "medallion_head"
        case .heart: return "medallion_heart"
        case .fate: return "medallion_fate"
        case .symbol: return nil
        }
    }
}

struct ArtMedallionView: View {
    let kind: ArtMedallionKind
    var diameter: CGFloat = 56

    var body: some View {
        Group {
            if let asset = kind.assetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
            } else if case .symbol(let systemName) = kind {
                IconMedallion(systemName: systemName, diameter: diameter)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

extension PalmLine.Kind {
    var artMedallion: ArtMedallionKind {
        switch self {
        case .life: return .life
        case .head: return .head
        case .heart: return .heart
        case .fate: return .fate
        }
    }
}

// MARK: - List row

/// Standard tappable row: medallion, display-face title, sans subtitle, chevron —
/// framed by the sliced card.
struct ArtListRow: View {
    let medallion: ArtMedallionKind
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ArtCard(contentPadding: 12) {
                HStack(spacing: 14) {
                    ArtMedallionView(kind: medallion, diameter: 50)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(Typography.heading)
                            .foregroundStyle(Theme.gold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(Theme.goldLight.opacity(0.85))
                            .lineLimit(2)
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
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Global tab bar

enum MainTab: Hashable, CaseIterable {
    case home, history, insights, settings
}

/// The bottom navigation from the history comp, rebuilt as a global element:
/// dark strip, gold hairline, gold glyphs with display-face labels, selected item lit.
struct ArtTabBar: View {
    @Binding var selection: MainTab
    let onRead: () -> Void

    private struct Item {
        let label: String
        let icon: String
        let tab: MainTab?
    }

    private var items: [Item] {
        [
            Item(label: "HOME", icon: "star.circle", tab: .home),
            Item(label: "READ", icon: "hand.raised.fill", tab: nil),
            Item(label: "HISTORY", icon: "book.fill", tab: .history),
            Item(label: "INSIGHTS", icon: "sparkles", tab: .insights),
            Item(label: "SETTINGS", icon: "gearshape.fill", tab: .settings),
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.label) { item in
                let isSelected = item.tab == selection
                Button {
                    if let tab = item.tab {
                        selection = tab
                    } else {
                        onRead()
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19))
                            .shadow(color: Theme.glow.opacity(isSelected ? 0.8 : 0), radius: 6)
                        Text(item.label)
                            .font(.custom("Rye-Regular", size: 9))
                            .kerning(0.5)
                    }
                    .foregroundStyle(isSelected ? Theme.gold : Theme.goldDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.label.capitalized)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
            }
        }
        .padding(.top, 6)
        .background(
            ZStack(alignment: .top) {
                Rectangle().fill(Color.black.opacity(0.72))
                Image("booth_texture")
                    .resizable(resizingMode: .tile)
                    .opacity(0.35)
                LinearGradient(
                    colors: [Theme.gold.opacity(0.9), Theme.goldDark.opacity(0.4)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1.2)
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Small helpers

/// Small caption plate (sliced, de-texted) with live copy — the "ANALYZE YOUR PALM"
/// strip under Home's medallion.
struct CaptionPlate: View {
    let text: String

    var body: some View {
        Image("caption_plate")
            .resizable()
            .scaledToFit()
            .overlay(
                GeometryReader { proxy in
                    Text(text)
                        .font(.custom("Rye-Regular", size: proxy.size.height * 0.24))
                        .kerning(1.2)
                        .foregroundStyle(Theme.goldLight)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .frame(width: proxy.size.width * 0.86, height: proxy.size.height)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
            )
    }
}

/// Screen header used inside flows: back button + centered display title.
struct FlowHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            RibbonBanner(text: title)
                .padding(.horizontal, 52)
            HStack {
                BackButton(action: onBack)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
}
