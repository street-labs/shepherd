import Foundation
import ComposableArchitecture

/// Persisted watchlist of NIP-34 repository coordinates for PR Browse.
/// Implements `FR-pb-watchlist-manage` (persistence half). UserDefaults, not a
/// file or database: the list is small, non-secret, and user-editable only
/// through the app. ponytail: switch to a file store only if watchlists grow
/// past a few dozen entries or need cross-device sync.
public struct WatchlistClient: Sendable {
    public var load: @Sendable () -> [String]
    public var save: @Sendable ([String]) -> Void

    public init(load: @escaping @Sendable () -> [String], save: @escaping @Sendable ([String]) -> Void) {
        self.load = load
        self.save = save
    }
}

private let watchlistKey = "prbrowse.watchlist"

extension WatchlistClient: DependencyKey {
    public static let liveValue = WatchlistClient(
        load: { UserDefaults.standard.stringArray(forKey: watchlistKey) ?? [] },
        save: { UserDefaults.standard.set($0, forKey: watchlistKey) }
    )

    public static let testValue = WatchlistClient(
        load: { [] },
        save: { _ in }
    )
}

extension DependencyValues {
    public var watchlistClient: WatchlistClient {
        get { self[WatchlistClient.self] }
        set { self[WatchlistClient.self] = newValue }
    }
}

/// A validated NIP-34 repository coordinate `30617:<pubkey>:<d>`.
/// Implements the input-validation half of `FR-pb-watchlist-manage`.
public struct RepoCoordinate: Equatable, Sendable, Identifiable {
    /// The full coordinate string (`30617:<pubkey>:<d>`), used as the `a` tag value.
    public let raw: String
    /// The `d` identifier — the human-recognizable repo name.
    public let d: String

    public var id: String { raw }

    /// Parse `30617:<64-hex-pubkey>:<non-empty d>`. Whitespace-tolerant;
    /// lowercase-normalized pubkey. Returns nil for anything else.
    public static func parse(_ input: String) -> RepoCoordinate? {
        let parts = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        let kind = parts[0].trimmingCharacters(in: .whitespaces)
        let pubkey = parts[1].trimmingCharacters(in: .whitespaces).lowercased()
        let d = parts[2].trimmingCharacters(in: .whitespaces)
        guard kind == "30617", d.contains(":") == false, !d.isEmpty else { return nil }
        guard pubkey.count == 64, pubkey.allSatisfy({ $0.isHexDigit }) else { return nil }
        return RepoCoordinate(raw: "30617:\(pubkey):\(d)", d: d)
    }
}
