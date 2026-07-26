import SwiftUI

/// Ornate card container — now backed by the card frame sliced from the comps
/// (gold double border, corner flourishes, dark leather), 9-slice stretched so it
/// takes any content size without distorting the corners.
struct OrnateCard<Content: View>: View {
    /// Kept for source compatibility with older call sites; the sliced frame's own
    /// leather shows through, so a custom fill just tints it.
    var fill: AnyShapeStyle = AnyShapeStyle(Color.clear)
    var cornerRadius: CGFloat = Theme.cornerRadius
    var contentPadding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(contentPadding)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                        .padding(4)
                    Image("card_frame")
                        .resizable(
                            capInsets: EdgeInsets(top: 26, leading: 30, bottom: 26, trailing: 30),
                            resizingMode: .stretch
                        )
                }
            )
    }
}
