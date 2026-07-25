import Foundation

/// Product identifiers, kept in one place so switching pricing options (CLAUDE.md §7.6)
/// is a configuration change plus an App Store Connect edit, never a redesign.
enum StoreProducts {
    static let monthly = "com.destinylines.premium.monthly"
    static let yearly = "com.destinylines.premium.yearly"

    /// Everything the paywall loads, in display order.
    static let all = [monthly, yearly]
}
