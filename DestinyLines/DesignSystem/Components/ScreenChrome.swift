import SwiftUI

/// Standard screen backdrop: near-black warm vignette, ignoring safe areas.
struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}

/// Circular gold back button used on Capture / Reading / Share.
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.black.opacity(0.45))
                Circle().strokeBorder(Theme.gold.opacity(0.9), lineWidth: 1.4)
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Back")
    }
}

/// Gold divider with a center sparkle, used between sections.
struct OrnamentDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            line
            Sparkle(size: 11)
            line
        }
        .accessibilityHidden(true)
    }

    private var line: some View {
        LinearGradient(
            colors: [.clear, Theme.gold.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }
}
