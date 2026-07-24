import Foundation

/// The reviewer's loaded Nostr identity, surfaced to the UI so the reviewer
/// knows which identity their published patch-thread replies will be attributed
/// to. Implements: FR-srm-identity-indicator, FR-sr-reviewer-identity.
///
/// Carries only display fields; the secret key (for a local-key identity) is
/// held by `IdentityClient` (ShepherdDependencies) and never enters observed
/// app state. For a bunker identity, no secret key is held at all.
public struct ReviewerIdentity: Equatable, Sendable {
    /// X-only public key, hex (64 chars). Also the `pubkey` placed on signed events
    /// and compared against `PatchReply.authorPubkey` for the `YOU` self-marker.
    public var pubkeyHex: String
    /// bech32 `npub1...` encoding of the public key, for display / tooltip.
    public var npub: String
    /// Resolved display name (roster name if available, else truncated npub).
    public var displayName: String
    /// Whether the identity is a local secret key or a NIP-46 bunker connection.
    public var source: IdentitySource
    /// For a bunker identity, the current connection state. nil for a local key.
    public var bunkerState: BunkerConnectionState?
    /// For a bunker identity, the relay URL the bunker is reached on. nil for a
    /// local key. Surfaced in the indicator's accessibility label.
    public var bunkerRelayURL: String?

    public init(
        pubkeyHex: String, npub: String, displayName: String,
        source: IdentitySource = .localKey,
        bunkerState: BunkerConnectionState? = nil,
        bunkerRelayURL: String? = nil
    ) {
        self.pubkeyHex = pubkeyHex
        self.npub = npub
        self.displayName = displayName
        self.source = source
        self.bunkerState = bunkerState
        self.bunkerRelayURL = bunkerRelayURL
    }
}

/// Which form the reviewer's identity takes.
public enum IdentitySource: Equatable, Sendable {
    case localKey
    case bunker
}

/// Bunker connection state for the identity indicator.
public enum BunkerConnectionState: Sendable, Equatable {
    case connecting
    case connected
    case failed(String)
}
