import SwiftUI

/// Two faces, both OFL-licensed (licenses in DestinyLines/Resources/Fonts):
/// - Rye — the western carnival display face for headers and wordmarks, always caps.
/// - Alegreya Sans — the humanist sans for body copy and UI chrome.
///
/// Everything routes through `relativeTo:` so Dynamic Type scales the custom faces.
enum Typography {

    private static let display = "Rye-Regular"
    private static let body = "AlegreyaSans-Regular"
    private static let bodyMedium = "AlegreyaSans-Medium"
    private static let bodyBold = "AlegreyaSans-Bold"

    /// Giant wordmark ("DESTINY LINES" on Home).
    static var wordmark: Font { .custom(display, size: 40, relativeTo: .largeTitle) }

    /// Screen titles in banners ("CAPTURE YOUR HAND").
    static var title: Font { .custom(display, size: 26, relativeTo: .title) }

    /// Section headers and card titles ("LIFE LINE", "MY READINGS" rows).
    static var heading: Font { .custom(display, size: 19, relativeTo: .title3) }

    /// CTA button labels ("NEW READING").
    static var cta: Font { .custom(display, size: 24, relativeTo: .title2) }

    /// Smaller display accents (tab labels, badges, prices).
    static var displaySmall: Font { .custom(display, size: 13, relativeTo: .footnote) }

    /// Standard body copy.
    static var bodyText: Font { .custom(body, size: 17, relativeTo: .body) }

    /// Emphasized body copy.
    static var bodyEmphasis: Font { .custom(bodyMedium, size: 17, relativeTo: .body) }

    /// Bold body, list-row titles when not display face.
    static var bodyStrong: Font { .custom(bodyBold, size: 17, relativeTo: .body) }

    /// Subtitles under row titles, captions.
    static var caption: Font { .custom(body, size: 14, relativeTo: .subheadline) }

    /// Fine print (disclaimers, privacy lines).
    static var fine: Font { .custom(body, size: 12, relativeTo: .caption) }
}
