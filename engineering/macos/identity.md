---
product-hash: a4ede6c56444cd114cece487d208c4b87772e3878443548e17071953dc34aca0
product-slugs: [AC-id-active-shown, AC-id-create-new, AC-id-create-persists, AC-id-created-can-publish, AC-id-dismiss-read-only, AC-id-login-invalid, AC-id-login-valid, AC-id-logout, AC-id-no-plaintext, AC-id-out-of-band-skips, AC-id-switch, FR-id-active-indicator, FR-id-create-new, FR-id-logout, FR-id-no-silent-override, FR-id-nsec-login, FR-id-optional-reentry, FR-id-out-of-band-honored, FR-id-persistence, FR-id-screen-when-no-identity, FR-id-show-new-nsec, FR-sr-reviewer-identity, FR-srm-event-sign, FR-srm-identity-indicator, FR-srm-identity-load, NFR-id-key-stays-local, NFR-id-key-validity, NFR-id-login-latency, NFR-id-no-plaintext-key]
---
# Identity — macOS Technical Spec

> Based on requirements in `../../product/identity.md`
> Based on design in `../../design/macos/identity.md`

## What We're Building

A new TCA feature (`IdentityFeature`) that presents an in-app login/create-identity window, backed by the existing `IdentityClient` and `NostrSigner` dependencies. The secret key is persisted in the macOS Keychain (never plaintext on disk), and the existing identity-load precedence is extended so an in-app-stored key is picked up alongside the env/config sources. The feature reuses the existing `ReviewerIdentity` model and `IdentityIndicatorView` so the active identity surfaces consistently whether it came from the in-app screen or an out-of-band source. Key generation uses the already-vendored `swift-secp256k1` (`P256K`) library — no new dependency.

## Technical Approach

The login screen is a standalone TCA reducer with its own window, presented by the app at launch when no identity resolves, and reachable on demand from the review window. It does three things: validate/adopt a pasted `nsec`, generate a new keypair, and persist the adopted key to Keychain. The persisted key flows back into the existing identity-load path: `IdentityClient.loadIdentity` gains a Keychain source added to its precedence list (highest priority, so an in-app login is not silently overridden by a stale env var — see Decision 1). Everything downstream (signing, indicator, publishing) is unchanged because it already keys off the loaded `ReviewerIdentity` + cached secret.

## Data Model

The feature owns no new persistent domain model beyond the secret key in Keychain. It uses the existing `ReviewerIdentity` (`SharedModels/ReviewerIdentity.swift`) as the result of a successful login.

- **Keychain entry**: account `shepherd-nostr-identity`, service `com.street-labs.shepherd` (or the app's keychain-access-group equivalent). Value: the 32-byte secret key, stored as data. The public key, npub, and display name are derived in memory from the secret key at load time — never stored separately, so there is no risk of a stale pubkey paired with a replaced key.
- **IdentityFeature.State** (in-memory, not persisted): the entered-nsec string, an optional validation error string, the generated-nsec reveal string (backup-reveal state), whether the window is in on-demand (logged-in) mode, and the currently-active identity (for the logged-in variant).

## API / Interface Design

New dependency: `KeychainClient` (in `ShepherdDependencies`), wrapping the two Keychain operations the feature needs. Keeping it a dependency (not a direct `Security.framework` call in the reducer) preserves the existing testability pattern used by `IdentityClient`, `RelayClient`, etc.

```swift
@DependencyClient
public struct KeychainClient: Sendable {
    /// Read the stored 32-byte secret key, or nil if none is stored.
    public var readSecret: @Sendable () -> Data?
    /// Store the 32-byte secret key (overwrites any existing entry).
    public var writeSecret: @Sendable (Data) -> Void
    /// Delete the stored secret key (logout). No-op if none stored.
    public var deleteSecret: @Sendable () -> Void
}
```

`IdentityClient` is extended with two methods that route through `KeychainClient` and the existing local-key loading logic:

```swift
extension IdentityClient {
    /// Validate an nsec/hex string, adopt it as the active identity, persist it
    /// to Keychain, and return the resulting ReviewerIdentity. Returns nil on
    /// invalid input (caller surfaces the error). Implements: FR-id-nsec-login.
    public var loginWithKey: @Sendable (String) -> ReviewerIdentity?
    /// Generate a fresh 32-byte secret key, adopt it, persist it, and return
    /// the identity plus the bech32 nsec for backup display.
    /// Implements: FR-id-create-new, FR-id-show-new-nsec.
    public var createNewIdentity: @Sendable () -> (identity: ReviewerIdentity, nsec: String)?
    /// Forget the app-stored identity (Keychain delete) and clear the cached
    /// loaded identity. Implements: FR-id-logout.
    public var logout: @Sendable () -> Void
}
```

The existing `loadIdentity` is extended so its precedence list begins with the Keychain source (Decision 1):

1. Keychain (`shepherd-nostr-identity`) — **new, highest precedence**
2. `SHEPHERD_BUNKER` env var
3. `~/.config/nostr/bunker` file
4. `SHEPHERD_NSEC` env var
5. `~/.config/nostr/identity` file
6. No identity

## Component Architecture

- **`IdentityFeature`** (`Sources/IdentityFeature/` — new module): the reducer + view for the login/create window. Mirrors the existing per-feature module layout (`CommentFeature`, `SessionFeature`, etc.).
  - `IdentityFeature.swift` — reducer (state, actions, validation/login/create/logout effects).
  - `IdentityView.swift` — the SwiftUI card described in the design spec.
- **`KeychainClient`** (`Sources/Dependencies/KeychainClient.swift` — new): Keychain read/write/delete with `@DependencyClient` + `liveValue` using `Security.framework` (`SecItemAdd`/`SecItemCopyMatching`/`SecItemDelete`).
- **`IdentityClient`** (`Sources/Dependencies/IdentityClient.swift` — extended): add `loginWithKey`, `createNewIdentity`, `logout`, and the Keychain source to `LoadedIdentity.load`. The cached `LoadedIdentity` is refreshed when a login/create/logout mutates the Keychain.
- **`AppFeature`** (`Sources/AppFeature/AppFeature.swift` — extended): at launch, after `sessionDataLoaded`, resolve identity; if `nil` and no in-app/ out-of-band identity exists, present the Identity window. Add an action/command to reopen the Identity window on demand (`FR-id-optional-reentry`).

## State Management

`IdentityFeature` owns its own state; it does not mutate `AppFeature` state directly. On a successful login/create, it sends a delegate action back to `AppFeature` (`identityAdopted(ReviewerIdentity)`), which sets `state.reviewerIdentity` and dismisses the window — the same field the existing patch-review path sets via `reviewerIdentityLoaded`. On logout, it sends `identityLoggedOut`, which sets `state.reviewerIdentity = nil` (and, if no out-of-band identity remains, re-presents the login window or leaves publishing unavailable per existing no-identity behavior).

## Error Handling

- **Invalid nsec on login**: `loginWithKey` returns nil; the reducer sets an inline error string and stays on the input state (`AC-id-login-invalid`). Errors are not thrown — the synchronous validate-and-adopt path returns an optional.
- **Keychain write failure** (rare: keychain locked, disk full): `loginWithKey`/`createNewIdentity` return nil with a distinct error path (a generic "Could not save identity — check Keychain access" message). The identity is not adopted if it could not be persisted, so the reviewer is not left with an identity that vanishes on next launch.
- **Keychain read failure at launch** (`FR-id-persistence`): if Keychain is unavailable or the entry is corrupt, `loadIdentity` falls through to the out-of-band sources, and if none exist, the login window appears. No silent failure.
- **Generation failure**: `P256K` key generation is a local RNG + scalar validity check; failure is effectively impossible, but `createNewIdentity` returns nil on a malformed scalar and the reducer surfaces a generic error rather than crashing.

## Performance Considerations

Validation, key derivation, and Keychain writes are all synchronous local operations (`NFR-id-login-latency`). Keychain access is the only potentially blocking call and is fast; it runs off the main thread via `.run` effects as the existing identity code does. No caching beyond the existing per-process `LoadedIdentity`.

## Security Considerations

- The secret key is stored in Keychain as data, never written to a file, log, or `UserDefaults` (`NFR-id-no-plaintext-key`, `NFR-id-key-stays-local`). The existing `currentSecret` in-memory cache is unchanged.
- The nsec field is a `SecureField` (masked); the entered string is cleared from feature state as soon as it is adopted or the field is cleared — it is not held longer than needed.
- The backup-reveal `nsec` string is held in feature state only while the reveal view is shown and cleared on dismiss.
- Key generation uses `P256K`'s randomness (`NFR-id-key-validity`); the generated scalar is checked to be in the valid secp256k1 range.
- Logout deletes the Keychain entry; the in-memory cached `LoadedIdentity` is cleared so a subsequent sign attempt fails closed.

## Implementation Plan

1. **`KeychainClient`** — add the dependency with `liveValue` (SecItem wrappers) and a test double. Unlocks persistence for every other step.
2. **Extend `IdentityClient`** — add the Keychain source to `LoadedIdentity.load` (highest precedence), plus `loginWithKey`, `createNewIdentity`, `logout`. Reuses the existing `loadLocalKey` helper for validation + pubkey derivation and `Bech32` for nsec encoding/decoding.
3. **`IdentityFeature` reducer** — state + actions for the input, error, backup-reveal, and logged-in variants; effects calling `identityClient.loginWithKey` / `createNewIdentity` / `logout`; delegate actions back to the parent.
4. **`IdentityView`** — the SwiftUI card from the design spec (SecureField, Sign In / Create / Skip / Log Out / Switch, backup reveal with Copy + confirm).
5. **Wire into `AppFeature`** — present the Identity window at launch when no identity resolves; reopen-on-demand action; handle `identityAdopted` / `identityLoggedOut` delegate actions. Update the existing `reviewerIdentityLoaded` path so an in-app-adopted identity flows through unchanged.
6. **Tests** — unit tests for `KeychainClient`, `IdentityClient.loginWithKey` (valid/invalid/overwrite), `createNewIdentity` (validity + persistence), `logout` (clears key + identity), and `IdentityFeature` reducer states. See QA plan.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-id-nsec-login | engineering/apps/macos/Sources/Dependencies/IdentityClient.swift; engineering/apps/macos/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-create-new | engineering/apps/macos/Sources/Dependencies/IdentityClient.swift; engineering/apps/macos/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-show-new-nsec | engineering/apps/macos/Sources/IdentityFeature/IdentityFeature.swift; engineering/apps/macos/Sources/IdentityFeature/IdentityView.swift | planned |
| FR-id-persistence | engineering/apps/macos/Sources/Dependencies/KeychainClient.swift; engineering/apps/macos/Sources/Dependencies/IdentityClient.swift | planned |
| FR-id-active-indicator | engineering/apps/macos/Sources/ReviewContextFeature/IdentityIndicatorView.swift; engineering/apps/macos/Sources/IdentityFeature/IdentityView.swift | planned |
| FR-id-logout | engineering/apps/macos/Sources/Dependencies/IdentityClient.swift; engineering/apps/macos/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-out-of-band-honored | engineering/apps/macos/Sources/Dependencies/IdentityClient.swift | planned |
| FR-id-no-silent-override | engineering/apps/macos/Sources/Dependencies/IdentityClient.swift | planned |
| FR-id-screen-when-no-identity | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-optional-reentry | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/IdentityFeature/IdentityFeature.swift | planned |
