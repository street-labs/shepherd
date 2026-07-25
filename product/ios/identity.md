# Identity — iOS Platform

> iOS-specific requirements for Identity. See `../identity.md` for shared requirements.
> See also `./shepherd-review.md` for the iOS patch-thread publishing path that consumes the loaded identity.

The shared Identity spec describes an in-app login/create screen that coexists with out-of-band env/config-file identity sources. On iOS there are no environment variables or dotfiles available to the reviewer, so the in-app screen is the **only** identity configuration path. Everything else about the shared spec — nsec login, create-new, bunker login, persistence, logout, backup reveal, the no-plaintext security guarantees — applies unchanged.

## Shared Requirements — Applicability on iOS

### Apply as-is (no iOS-specific changes needed)

- `FR-id-nsec-login` — Login with nsec
- `FR-id-create-new` — Create new identity
- `FR-id-persistence` — Persist identity across launches (via the platform secure store — see `FR-id-ios-keychain-storage`)
- `FR-id-show-new-nsec` — Show created nsec for backup
- `FR-id-active-indicator` — Active identity indicator (realized by `FR-sri-identity-indicator`)
- `FR-id-logout` — Log out / forget identity
- `FR-id-bunker-login` — Login with bunker URI
- `FR-id-bunker-persist` — Persist bunker identity across launches
- `FR-id-bunker-connect-failure` — Bunker connect failure during login
- `FR-id-screen-when-no-identity` — Screen shown when no identity (at launch, when no stored identity exists)
- `FR-id-optional-reentry` — Optional re-entry (open the screen again to switch/log out)
- `NFR-id-no-plaintext-key` — Secret key never in plaintext
- `NFR-id-key-stays-local` — No key leaves the device
- `NFR-id-login-latency` — Login is immediate (local-key)
- `NFR-id-bunker-connect-latency` — Bunker login is bounded
- `NFR-id-key-validity` — New key is cryptographically valid

### Do not apply on iOS

- **`FR-id-out-of-band-honored`** — Does not apply. iOS has no environment-variable or config-file identity sources; the in-app screen (backed by the platform secure store) is the only source. There is no out-of-band identity to honor.
- **`FR-id-no-silent-override`** — Does not apply. With only one source (the in-app stored identity), there is no in-app-vs-out-of-band conflict to surface.
- **`AC-id-out-of-band-skips`** — Does not apply for the same reason.

## iOS-Specific Functional Requirements

### `FR-id-ios-keychain-storage` — Identity persists via the platform secure store
The in-app-stored identity (a 32-byte secret key for the local-key form, or the `bunker://` URI for the bunker form) is persisted in the iOS Keychain (the platform secure storage facility), never in plaintext on disk. This realizes `FR-id-persistence` and `FR-id-bunker-persist` on iOS. The stored material is the minimum needed to restore the identity on the next launch. If the Keychain cannot be read at launch (unavailable or corrupt), the login screen is presented again rather than failing silently. The specific Keychain service/account and any access-group are engineering decisions.

### `FR-id-ios-screen-is-only-path` — The in-app screen is the sole identity configuration path
Because iOS exposes no environment variables or config files to the reviewer, the in-app identity screen is the only way to configure, view, and change the reviewer's Nostr identity. The screen is presented at launch when no stored identity exists (`FR-id-screen-when-no-identity`) and is reachable on demand to switch or log out (`FR-id-optional-reentry`). There is no out-of-band alternative on iOS.

## iOS-Specific Non-Functional Requirements

(None beyond the shared NFRs. The shared `NFR-id-no-plaintext-key` is realized via Keychain on iOS.)

## iOS-Specific Acceptance Criteria

- [ ] **Identity stored in Keychain** `AC-id-ios-keychain-storage`: Given the reviewer logs in with an `nsec` in-app, when the reviewer relaunches the app, then the identity is still active (no login screen) and the raw `nsec` is not present in plaintext anywhere on disk (only in the Keychain). Given the reviewer logs in with a `bunker://` URI, when the reviewer relaunches, then the app reconnects using the stored URI and the URI is not in plaintext on disk.
- [ ] **Screen is the only path** `AC-id-ios-screen-is-only-path`: Given a fresh install with no stored identity, when the reviewer launches the app, then the in-app identity screen is presented and there is no env-var or config-file alternative; the reviewer either logs in, creates an identity, or skips to read-only mode.

## Open Questions

1. **Keychain access group / sharing**: whether the iOS app uses a keychain-access-group (for potential future shared-keychain scenarios with a macOS app via iCloud Keychain) is an engineering decision; v1 uses the app's default Keychain.
2. **Screen placement**: the shared spec leaves where the screen sits in the launch flow as a design decision (`product/identity.md` Open Question 2). On iOS it is a sheet/full-screen form presented over the empty state, not a separate window (iOS has no multi-window). See `../../design/ios/identity.md`.
3. **Confirm-backup enforcement strength**: inherited unchanged from the shared spec (Open Question 3). v1 uses a single "I've saved my key" confirmation.

## Dependencies

- Shared Identity requirements (`../identity.md`) — the login/create/persist/logout behavior this realizes.
- iOS shepherd-review (`./shepherd-review.md`) — the patch-thread publishing path (`FR-sri-event-sign`, `FR-sri-bunker-connect`, `FR-sri-identity-indicator`) that consumes the identity this screen produces. The shared spec's dependencies on `FR-srm-*` (macOS) are realized by `FR-sri-*` on iOS.
- Platform secure storage (iOS Keychain) — for `FR-id-ios-keychain-storage`.
