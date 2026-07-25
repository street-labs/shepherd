---
product-hash: 759a7eb8999156e9454875a44bb0df553a15e1756c8d20e8d5047df09b755718
product-slugs: [AC-id-active-shown, AC-id-bunker-can-publish, AC-id-bunker-connect-failure, AC-id-bunker-login-invalid-uri, AC-id-bunker-login-valid, AC-id-bunker-logout, AC-id-bunker-no-host-key, AC-id-bunker-persists, AC-id-create-new, AC-id-create-persists, AC-id-created-can-publish, AC-id-dismiss-read-only, AC-id-login-invalid, AC-id-login-valid, AC-id-logout, AC-id-no-plaintext, AC-id-out-of-band-skips, AC-id-switch, FR-id-active-indicator, FR-id-bunker-connect-failure, FR-id-bunker-login, FR-id-bunker-persist, FR-id-create-new, FR-id-logout, FR-id-no-silent-override, FR-id-nsec-login, FR-id-optional-reentry, FR-id-out-of-band-honored, FR-id-persistence, FR-id-screen-when-no-identity, FR-id-show-new-nsec, FR-sr-bunker-signing, FR-sr-reviewer-identity, FR-srm-bunker-connect, FR-srm-bunker-sign-failure, FR-srm-event-sign, FR-srm-identity-indicator, FR-srm-identity-load, NFR-id-bunker-connect-latency, NFR-id-key-stays-local, NFR-id-key-validity, NFR-id-login-latency, NFR-id-no-plaintext-key]
---
# Identity — iOS Technical Spec

> Based on requirements in `../../product/identity.md`
> See also `../../product/ios/identity.md` for iOS-specific requirements.
> Based on design in `../../design/ios/identity.md`

## What We're Building

An iOS `IdentityFeature` (TCA) that presents the in-app login/create-identity sheet, backed by `IdentityClient`, `BunkerClient`, `NostrSigner`, and `Bech32` dependencies, with persistence in the iOS Keychain via a new `KeychainClient`. It supports two login forms — a local secret key (`nsec`) and a NIP-46 bunker URI — plus local-key creation. Because iOS has no out-of-band env/config sources, the Keychain-stored identity is the only identity source; the load precedence is simply Keychain → none. The feature reuses the existing `ReviewerIdentity` model and the identity indicator, so an in-app-adopted identity flows unchanged into the iOS patch-thread publishing path (`./shepherd-review.md`). Key generation reuses `swift-secp256k1` (`P256K`); the bunker path reuses `BunkerClient`'s NIP-46 handshake — no new third-party dependency.

## Technical Approach

The sheet is a standalone TCA reducer presented by `AppFeature` at launch when no identity resolves from Keychain, and reachable on demand. It does three things: validate/adopt a pasted `nsec`, generate a new keypair, and parse/connect a `bunker://` URI. The adopted secret key (local-key form) or bunker URI (bunker form) is persisted in the iOS Keychain (never plaintext on disk) via `KeychainClient`; `IdentityClient.loadIdentity` reads from Keychain as its sole source on iOS. Everything downstream (signing, indicator, publishing) is unchanged because it keys off the loaded `ReviewerIdentity` + cached secret, exactly as on macOS.

For v1 the iOS app target carries its own copies of `IdentityClient`, `BunkerClient`, `NostrSigner`, `Bech32`, and `ReviewerIdentity` under `engineering/apps/ios/Sources/` (see `./code-review-prompt.md` and `./shepherd-review.md` Open Question 1 — lifting these into a shared multiplatform target is a follow-up).

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Secure storage | iOS Keychain (`SecItem*`) | The native platform facility for secrets; never plaintext on disk. `NFR-id-no-plaintext-key`. |
| Identity load precedence | Keychain only (no env/config sources) | iOS exposes no env vars or dotfiles to the reviewer; the in-app screen is the only path. `FR-id-ios-screen-is-only-path`. |
| Key generation | `P256K` (already vendored for signing) | Uniform random scalar + validity check; no new dependency. `NFR-id-key-validity`. |
| Bunker path | Reuse `BunkerClient` NIP-46 handshake | Same connect/`get_public_key`/`sign_event` as macOS; the in-app login is the login-time entry into the same path the publishing half uses. |
| Storage format | 32-byte `Data` = secret key; otherwise UTF-8 `bunker://` URI | Unambiguous length-first rule (a 32-byte key is checked before any UTF-8 parse), matching macOS. |
| UI surface | SwiftUI sheet / full-screen form | iOS has no multi-window; the screen is a modal form over the empty state. |

## Data Model

The feature owns no new persistent domain model beyond the Keychain entry. It uses `ReviewerIdentity` as the result of a successful login.

- **Keychain entry**: account `shepherd-nostr-identity`, service `com.street-labs.shepherd` (or the app's keychain-access-group equivalent). Value: the 32-byte secret key (local-key form) or a UTF-8 `bunker://` URI string (bunker form), stored as `Data`. The public key, npub, and display name are derived in memory at load time — never stored separately.
- **IdentityFeature.State** (in-memory): the form-toggle selection, entered string, optional validation error, generated-nsec reveal string (backup-reveal state), whether the sheet is in on-demand (logged-in) mode, and the currently-active identity (for the logged-in variant).

## API / Interface Design

New dependency: `KeychainClient` (iOS), wrapping the three Keychain operations:

```swift
@DependencyClient
public struct KeychainClient: Sendable {
    /// Read stored identity material: 32 bytes of secret key (local-key form)
    /// or a UTF-8 bunker URI string (bunker form), or nil if none stored.
    public var readIdentity: @Sendable () -> Data?
    /// Store identity material (32-byte secret key or UTF-8 bunker URI as Data).
    /// Overwrites any existing entry. Returns true on success, false on a
    /// Keychain write failure so callers can refuse to adopt an un-persisted identity.
    public var writeIdentity: @Sendable (Data) -> Bool
    /// Delete the stored identity (logout). No-op if none stored.
    public var deleteIdentity: @Sendable () -> Void
}
```

`IdentityClient` (iOS copy) is extended with the login/create/logout methods (same `IdentityLoginError` enum and signatures as macOS — `loginWithKey`, `createNewIdentity`, `loginWithBunker`, `logout`), routing the local-key path through `KeychainClient` + `loadLocalKey` and the bunker path through `BunkerClient.connect`. `loadIdentity` reads Keychain only (no env/config sources on iOS).

## Component Architecture

- **`IdentityFeature`** (`engineering/apps/ios/Sources/IdentityFeature/` — new): reducer + view for the login/create sheet. `IdentityFeature.swift` (state, actions, validation/login/create/logout effects) and `IdentityView.swift` (the SwiftUI form from the design spec).
- **`KeychainClient`** (`engineering/apps/ios/Sources/Dependencies/KeychainClient.swift` — new): `SecItemAdd`/`SecItemCopyMatching`/`SecItemDelete` wrappers with `@DependencyClient` + `liveValue`.
- **`IdentityClient`** (iOS copy — extended): add `loginWithKey`, `createNewIdentity`, `loginWithBunker`, `logout`, and the Keychain source to `loadIdentity`. The cached `LoadedIdentity` is refreshed when a login/create/logout mutates the Keychain.
- **`AppFeature`** (iOS — extended): at launch, resolve identity from Keychain; if `nil`, present the Identity sheet. Add an action to reopen the sheet on demand (`FR-id-optional-reentry`).

## State Management

`IdentityFeature` owns its own state; it does not mutate `AppFeature` state directly. On a successful login/create, it sends a delegate action (`identityAdopted(ReviewerIdentity)`) back to `AppFeature`, which sets `state.reviewerIdentity` and dismisses the sheet. On logout, it sends `identityLoggedOut`, which sets `state.reviewerIdentity = nil` (and re-presents the login sheet or leaves publishing unavailable per the no-identity behavior in `./shepherd-review.md`).

## Error Handling

- **Invalid nsec**: `loginWithKey` returns `.failure(.invalidKey)` → inline "Not a valid nsec" error; stays on the input state.
- **Keychain write failure**: `.failure(.storageFailed)` → "Could not save identity — check Keychain access"; the identity is not adopted if it could not be persisted.
- **Bunker URI malformed / connect failure**: `.failure(.invalidURI)` (no connection) or `.failure(.connectFailed)` (unreachable/refused/timeout) → matching error, URI retained for retry; on `.connectFailed` the persisted URI is removed so no orphaned identity lingers.
- **Keychain read failure at launch**: `loadIdentity` falls through to none → the login sheet appears. No silent failure.

## Performance Considerations

Validation, key derivation, and Keychain writes are synchronous local operations (`NFR-id-login-latency`). Keychain access is the only potentially blocking call and is fast; it runs off the main thread via `.run` effects. The bunker login handshake is an async network round-trip bounded by a timeout (`NFR-id-bunker-connect-latency`).

## Security Considerations

- The secret key is stored in Keychain as data, never in a file, log, or `UserDefaults` (`NFR-id-no-plaintext-key`, `NFR-id-key-stays-local`).
- The nsec field is a `SecureField` (masked); the entered string is cleared from feature state as soon as it is adopted or the field is cleared.
- The backup-reveal `nsec` is held in feature state only while the reveal view is shown and cleared on dismiss.
- Key generation uses `P256K`'s randomness; the generated scalar is checked to be in the valid secp256k1 range.
- Logout deletes the Keychain entry and clears the in-memory cached identity so a subsequent sign attempt fails closed.

## Implementation Plan

1. **`KeychainClient` (iOS)** — add the dependency with `liveValue` (SecItem wrappers) and a test double. Stores either a 32-byte secret key or a UTF-8 bunker URI as `Data`. Unlocks persistence.
2. **Extend `IdentityClient` (iOS)** — add the Keychain-only `loadIdentity` source plus `loginWithKey`, `createNewIdentity`, `loginWithBunker`, `logout`. Reuse `loadLocalKey`, `Bech32`, and `BunkerClient.connect`/`BunkerConfig.parse`.
3. **`IdentityFeature` reducer** — state + actions for the form-toggle, input, error, connecting (bunker), backup-reveal, and logged-in variants; effects calling the `IdentityClient` methods; delegate actions to the parent.
4. **`IdentityView`** — the SwiftUI form from the design spec.
5. **Wire into `AppFeature`** — present the Identity sheet at launch when no identity resolves; reopen-on-demand action; handle `identityAdopted` / `identityLoggedOut` delegate actions; flow an adopted identity into the existing publishing path.
6. **Tests** — unit tests for `KeychainClient` (both formats), `IdentityClient.loginWithKey` (valid/invalid/overwrite), `createNewIdentity` (validity + persistence), `loginWithBunker` (valid URI → connect success, malformed URI, connect failure → URI removed), `logout`, and `IdentityFeature` reducer states (including Connecting). See QA plan.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-id-nsec-login | engineering/apps/ios/Sources/Dependencies/IdentityClient.swift; engineering/apps/ios/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-create-new | engineering/apps/ios/Sources/Dependencies/IdentityClient.swift; engineering/apps/ios/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-show-new-nsec | engineering/apps/ios/Sources/IdentityFeature/IdentityFeature.swift; engineering/apps/ios/Sources/IdentityFeature/IdentityView.swift | planned |
| FR-id-persistence | engineering/apps/ios/Sources/Dependencies/KeychainClient.swift; engineering/apps/ios/Sources/Dependencies/IdentityClient.swift | planned |
| FR-id-active-indicator | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-id-logout | engineering/apps/ios/Sources/Dependencies/IdentityClient.swift; engineering/apps/ios/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-bunker-login | engineering/apps/ios/Sources/Dependencies/IdentityClient.swift; engineering/apps/ios/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-bunker-persist | engineering/apps/ios/Sources/Dependencies/KeychainClient.swift; engineering/apps/ios/Sources/Dependencies/IdentityClient.swift | planned |
| FR-id-bunker-connect-failure | engineering/apps/ios/Sources/Dependencies/IdentityClient.swift; engineering/apps/ios/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-screen-when-no-identity | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift; engineering/apps/ios/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-optional-reentry | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift; engineering/apps/ios/Sources/IdentityFeature/IdentityFeature.swift | planned |
| FR-id-ios-keychain-storage | engineering/apps/ios/Sources/Dependencies/KeychainClient.swift | planned |
| FR-id-ios-screen-is-only-path | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |

Notes:
- `FR-id-out-of-band-honored` and `FR-id-no-silent-override` do not apply on iOS (no out-of-band sources) and are omitted from the Code Map; see `../../product/ios/identity.md`.
- The shared spec's `FR-srm-*` dependencies are realized on iOS by `FR-sri-*` (see `./shepherd-review.md`); the identity this screen produces flows into `FR-sri-event-sign` / `FR-sri-bunker-connect` / `FR-sri-identity-indicator`.

## Open Questions

1. **Shared deps** — as in `./code-review-prompt.md` Open Question 1: `IdentityClient`/`BunkerClient`/`NostrSigner`/`Bech32`/`ReviewerIdentity` are duplicated into the iOS target for v1; lifting to a shared multiplatform target is a follow-up.
2. **Keychain access group** — whether to use a keychain-access-group (for future iCloud Keychain sharing with the macOS app) is an engineering decision; v1 uses the app's default Keychain.
3. **`P256K` on iOS** — verify `swift-secp256k1` builds for the iOS app target at implementation time; it is already vendored for macOS signing.
