import Foundation

/// Supabase project coordinates. These are shippable by design: the publishable key is
/// public and Row Level Security enforces access (CLAUDE.md §1.1). Secrets never appear here.
enum SupabaseConfig {
    static let url = URL(string: "https://lbcenouizvrsroxpfqxw.supabase.co")!
    static let anonKey = "sb_publishable_4JKmmydYrtm4vKiSW_avJQ_wdDHbJFd"

    /// True once real project values are present.
    static var isConfigured: Bool {
        anonKey.hasPrefix("sb_publishable_") || anonKey.hasPrefix("eyJ")
    }
}
