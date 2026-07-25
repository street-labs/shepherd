import Foundation

// Cross-platform home-directory resolution for out-of-band Nostr config reads
// (`~/.config/nostr/...`). On macOS this is the user's home; on iOS it is the app
// sandbox home, where those paths do not exist so reads fail gracefully (no
// out-of-band sources on iOS — `FR-id-ios-screen-is-only-path`).
extension FileManager {
    public var shepherdHome: URL {
        // `URL.homeDirectory` resolves to the user home on macOS and the app sandbox
        // home on iOS (where ~/.config/nostr/... does not exist → reads fail gracefully).
        return URL.homeDirectory
    }
}
