import SwiftUI

/// The OVERVIEW / IN-DEPTH / LINES selector from the reading screen: a gold-bordered
/// rail of display-face tabs, the selected one filled curtain-crimson with a sparkle.
struct SegmentedTabs<Tab: Hashable>: View {
    let tabs: [(Tab, String)]
    @Binding var selection: Tab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.0) { tab, label in
                let isSelected = tab == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = tab }
                } label: {
                    HStack(spacing: 5) {
                        if isSelected {
                            Sparkle(size: 9)
                        }
                        Text(label)
                            .font(Typography.displaySmall)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(isSelected ? Theme.goldLight : Theme.gold.opacity(0.75))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.crimsonFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Theme.gold.opacity(0.9), lineWidth: 1.2)
                                    )
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(Theme.goldDark.opacity(0.8), lineWidth: 1.2)
                )
        )
    }
}
