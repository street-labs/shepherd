import Foundation

/// The reviewer's loaded Nostr identity, surfaced to the UI so the reviewer
/// knows which identity their published patch-thread replies will be attributed
/// to. Implements: FR-srm-identity-indicator, FR-sr-reviewer-identity.
///
/// Carries only display fields; the secret key is held by `IdentityClient`
/// (ShepherdDependencies) and never enters observed app state.
public struct ReviewerIdentity: Equatable, Sendable {
    /// X-only public key, hex (64 chars). Also the `pubkey` placed on signed events
    /// and compared against `PatchReply.authorPubkey` for the `YOU` self-marker.
    public var pubkeyHex: String
    /// bech32 `npub1...` encoding of the public key, for display / tooltip.
    public var npub: String
    /// Resolved display name (roster name if available, else truncated npub).
    public var displayName: String

    public init(pubkeyHex: String, npub: String, displayName: String) {
        self.pubkeyHex = pubkeyHex
        self.npub = npub
        self.displayName = displayName
    }
}
