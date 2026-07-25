import Foundation

/// Supabase project coordinates. These are shippable by design: the anon key is public
/// and Row Level Security enforces access (CLAUDE.md §1.1). Secrets never appear here.
enum SupabaseConfig {
    // TODO(owner): real values expected in-session; placeholders keep the app bootable.
    static let url = URL(string: "https://YOUR-PROJECT-REF.supabase.co")!
    static let anonKey = "YOUR-ANON-KEY"

    /// True once the constants above have been replaced with real values.
    static var isConfigured: Bool {
        url.host()?.hasPrefix("YOUR-PROJECT-REF") == false && anonKey != "YOUR-ANON-KEY"
    }
}
