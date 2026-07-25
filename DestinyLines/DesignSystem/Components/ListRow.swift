import SwiftUI

/// Menu / list row from the comps: circular gold-ringed icon medallion on the left,
/// display-face title with sans subtitle, gold chevron on the right, ornate card frame.
struct ListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { label }
                    .buttonStyle(PressableButtonStyle())
            } else {
                label
            }
        }
    }

    private var label: some View {
        OrnateCard(contentPadding: 12) {
            HStack(spacing: 14) {
                IconMedallion(systemName: icon)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Typography.heading)
                        .foregroundStyle(Theme.gold)
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.goldLight.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Circular icon medallion with a double gold ring on a dark well.
struct IconMedallion: View {
    let systemName: String
    var diameter: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
            Circle()
                .strokeBorder(Theme.gold, lineWidth: 1.6)
            Circle()
                .strokeBorder(Theme.goldDark.opacity(0.6), lineWidth: 1)
                .padding(3)
            Image(systemName: systemName)
                .font(.system(size: diameter * 0.4, weight: .medium))
                .foregroundStyle(Theme.goldBevel)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}
