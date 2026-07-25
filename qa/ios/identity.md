---
product-hash: 759a7eb8999156e9454875a44bb0df553a15e1756c8d20e8d5047df09b755718
product-slugs: [AC-id-active-shown, AC-id-bunker-can-publish, AC-id-bunker-connect-failure, AC-id-bunker-login-invalid-uri, AC-id-bunker-login-valid, AC-id-bunker-logout, AC-id-bunker-no-host-key, AC-id-bunker-persists, AC-id-create-new, AC-id-create-persists, AC-id-created-can-publish, AC-id-dismiss-read-only, AC-id-login-invalid, AC-id-login-valid, AC-id-logout, AC-id-no-plaintext, AC-id-out-of-band-skips, AC-id-switch, FR-id-active-indicator, FR-id-bunker-connect-failure, FR-id-bunker-login, FR-id-bunker-persist, FR-id-create-new, FR-id-logout, FR-id-no-silent-override, FR-id-nsec-login, FR-id-optional-reentry, FR-id-out-of-band-honored, FR-id-persistence, FR-id-screen-when-no-identity, FR-id-show-new-nsec, FR-sr-bunker-signing, FR-sr-reviewer-identity, FR-srm-bunker-connect, FR-srm-bunker-sign-failure, FR-srm-event-sign, FR-srm-identity-indicator, FR-srm-identity-load, NFR-id-bunker-connect-latency, NFR-id-key-stays-local, NFR-id-key-validity, NFR-id-login-latency, NFR-id-no-plaintext-key]
---
# Identity — iOS Test Plan

> Based on requirements in `../../product/identity.md`
> See also `../../product/ios/identity.md` for iOS-specific requirements.
> Based on design in `../../design/ios/identity.md`
> Based on technical spec in `../../engineering/ios/identity.md`

## What We're Testing

The in-app Nostr identity login and creation flow for iPhone and iPad: pasting an existing `nsec` to log in, generating a new identity, logging in with a NIP-46 bunker URI, persistence across launches via the iOS Keychain, logout, switching, and the guarantee that the secret key is never written to disk in plaintext. On iOS the in-app screen is the only identity path (no out-of-band sources), so the out-of-band coexistence criteria are out of scope. Risk areas: secret-key handling (security), Keychain integration (platform-specific, can fail locked/empty), and the bunker handshake (network).

## Test Approach

- **Automated (Swift Testing + TCA `TestStore`)**: `IdentityFeature` reducer — form-toggle, nsec validation (valid/invalid), create-new → backup-reveal → confirm, bunker login (valid URI → connecting → adopted; malformed URI → error; connect failure → error + URI retained), logout, switch. `IdentityClient` — `loginWithKey`/`createNewIdentity`/`loginWithBunker`/`logout` with stubbed `KeychainClient` and `BunkerClient`. `KeychainClient` — read/write/delete both formats (test double + an integration test against the real Keychain on a device/simulator).
- **Manual (iPhone + iPad, iOS 17+)**: first-run sheet presentation, paste login, create + backup reveal, bunker login against a test signer, persistence across relaunch, logout, read-only skip, VoiceOver, no-plaintext on-disk inspection.

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-id-login-valid` | `TC-id-ios-login-valid`, `TC-id-ios-login-persists` | Not started |
| `AC-id-login-invalid` | `TC-id-ios-login-invalid-format`, `TC-id-ios-login-invalid-checksum`, `TC-id-ios-login-invalid-length` | Not started |
| `AC-id-create-new` | `TC-id-ios-create-new`, `TC-id-ios-create-shows-nsec`, `TC-id-ios-create-confirm-required` | Not started |
| `AC-id-create-persists` | `TC-id-ios-create-persists` | Not started |
| `AC-id-created-can-publish` | `TC-id-ios-created-publishes` | Not started |
| `AC-id-logout` | `TC-id-ios-logout`, `TC-id-ios-logout-then-relaunch` | Not started |
| `AC-id-dismiss-read-only` | `TC-id-ios-skip-read-only` | Not started |
| `AC-id-active-shown` | `TC-id-ios-active-indicator` | Not started |
| `AC-id-no-plaintext` | `TC-id-ios-no-plaintext-disk` | Not started |
| `AC-id-switch` | `TC-id-ios-switch-identity` | Not started |
| `AC-id-bunker-login-valid` | `TC-id-ios-bunker-login-valid` | Not started |
| `AC-id-bunker-login-invalid-uri` | `TC-id-ios-bunker-login-invalid-uri` | Not started |
| `AC-id-bunker-connect-failure` | `TC-id-ios-bunker-connect-failure` | Not started |
| `AC-id-bunker-persists` | `TC-id-ios-bunker-persists` | Not started |
| `AC-id-bunker-can-publish` | `TC-id-ios-bunker-can-publish` | Not started |
| `AC-id-bunker-logout` | `TC-id-ios-bunker-logout` | Not started |
| `AC-id-bunker-no-host-key` | `TC-id-ios-bunker-no-host-key` | Not started |
| `AC-id-ios-keychain-storage` | `TC-id-ios-keychain-storage`, `TC-id-ios-no-plaintext-disk` | Not started |
| `AC-id-ios-screen-is-only-path` | `TC-id-ios-screen-only-path` | Not started |

## Test Cases

### Local-key login

#### `TC-id-ios-login-valid` — Login with valid nsec (Automated + Manual)
1. Launch with no stored identity → the Identity Sheet appears.
2. Paste a valid `nsec1…` → tap Sign In.
- **Expected**: The app adopts the identity, derives the public key, surfaces the active identity indicator, and dismisses the sheet. (`AC-id-login-valid`)

#### `TC-id-ios-login-persists` — Login persists across relaunch (Manual)
1. Login with a valid `nsec`; relaunch the app.
- **Expected**: No login sheet appears; the identity is still active. (`AC-id-login-valid`, `AC-id-create-persists` analogue)

#### `TC-id-ios-login-invalid-format` / `-checksum` / `-length` — Invalid key rejected (Automated + Manual)
1. Submit a malformed string (not `nsec1…`, bad checksum, or not a 32-byte key).
- **Expected**: A clear inline error; no identity adopted; the sheet stays open. (`AC-id-login-invalid`)

### Create new identity

#### `TC-id-ios-create-new` — Create a new identity (Automated + Manual)
1. On the Identity Sheet, tap "Create New Identity".
- **Expected**: A fresh key is generated, adopted, and the backup-reveal state shows the `nsec1…` in full with a Copy button and the backup warning. (`AC-id-create-new`)

#### `TC-id-ios-create-shows-nsec` — nsec shown for backup (Manual)
1. After create, observe the reveal.
- **Expected**: The full `nsec1…` is displayed with a warning that this is the only chance to save it. (`FR-id-show-new-nsec`)

#### `TC-id-ios-create-confirm-required` — Confirm required to dismiss (Manual)
1. In the backup-reveal state, attempt to dismiss without confirming.
- **Expected**: The "I've saved my key" confirmation is the only way out. (`AC-id-create-new`)

#### `TC-id-ios-create-persists` — Created identity persists (Manual)
1. Create an identity, confirm backup, relaunch.
- **Expected**: The identity is still active (no sheet). (`AC-id-create-persists`)

#### `TC-id-ios-created-publishes` — Created identity can publish (Manual)
1. Create an identity, open a patch review, submit an inline comment.
- **Expected**: The reply is signed under the created identity's public key and published. (`AC-id-created-can-publish`)

### Logout, switch, read-only

#### `TC-id-ios-logout` — Logout forgets identity (Automated + Manual)
1. While logged in, open the Identity Sheet (on-demand variant) → tap "Log Out".
- **Expected**: The stored secret key is removed; publishing becomes unavailable; the form returns to empty. (`AC-id-logout`)

#### `TC-id-ios-logout-then-relaunch` — Logout persists across relaunch (Manual)
1. Log out, relaunch.
- **Expected**: The login sheet appears (no stored identity). (`AC-id-logout`)

#### `TC-id-ios-switch-identity` — Switch identity (Automated + Manual)
1. While logged in with identity A, open the sheet, tap "Switch Identity", paste a different `nsec` B, sign in.
- **Expected**: Identity B becomes active; the indicator reflects B; A's stored key is replaced. (`AC-id-switch`)

#### `TC-id-ios-skip-read-only` — Skip to read-only (Manual)
1. On the first-run sheet, tap "Skip for now".
- **Expected**: The sheet dismisses into read-only / local-only mode; publishing is unavailable with a clear indication; comments save locally. (`AC-id-dismiss-read-only`)

#### `TC-id-ios-active-indicator` — Active identity shown (Manual)
1. After login, observe the identity indicator.
- **Expected**: The indicator shows the identity's display name or npub. (`AC-id-active-shown`)

### Bunker login

#### `TC-id-ios-bunker-login-valid` — Login with valid bunker URI (Automated + Manual)
1. Switch the form toggle to "Bunker URI"; paste a valid `bunker://` URI pointing at a reachable signer; tap Sign In.
- **Expected**: The Connecting state runs, the app connects, obtains the pubkey, adopts the bunker identity, surfaces the indicator as connected, and dismisses the sheet. (`AC-id-bunker-login-valid`)

#### `TC-id-ios-bunker-login-invalid-uri` — Malformed URI rejected (Automated + Manual)
1. Submit a malformed `bunker://` URI (missing relay, unparseable pubkey).
- **Expected**: A clear inline error; no connection attempted; no identity adopted; the sheet stays open. (`AC-id-bunker-login-invalid-uri`)

#### `TC-id-ios-bunker-connect-failure` — Connect failure during login (Automated + Manual)
1. Submit a well-formed URI but the signer is unreachable/refuses/times out.
- **Expected**: An error names the bunker as the cause; the URI is retained for correction; no identity adopted; the reviewer can retry. (`AC-id-bunker-connect-failure`)

#### `TC-id-ios-bunker-persists` — Bunker identity persists (Manual)
1. Login with a bunker URI, relaunch.
- **Expected**: The app reconnects using the stored URI; the identity is active (no sheet); the indicator shows connected. (`AC-id-bunker-persists`)

#### `TC-id-ios-bunker-can-publish` — Bunker identity can publish (Manual)
1. With a bunker identity, submit an inline comment in a patch review.
- **Expected**: The reply is signed by the remote bunker under the reviewer's pubkey and published, without the secret key ever on the device. (`AC-id-bunker-can-publish`)

#### `TC-id-ios-bunker-logout` — Bunker logout forgets URI (Automated + Manual)
1. While logged in via a bunker, log out.
- **Expected**: The stored URI is removed; publishing becomes unavailable; the next launch shows the login sheet. (`AC-id-bunker-logout`)

#### `TC-id-ios-bunker-no-host-key` — No host key on device (Manual)
1. After a bunker login, inspect the app's on-disk footprint and memory.
- **Expected**: The reviewer's secret key is not present anywhere (only the bunker URI in Keychain and an ephemeral control-channel keypair); the URI is not in plaintext on disk. (`AC-id-bunker-no-host-key`)

### iOS-specific

#### `TC-id-ios-keychain-storage` — Identity stored in Keychain (Manual)
1. Login with an `nsec`; inspect the app's on-disk footprint.
- **Expected**: The raw `nsec` is not in plaintext anywhere on disk; it is in the Keychain. On relaunch the identity is restored. (`AC-id-ios-keychain-storage`)

#### `TC-id-ios-no-plaintext-disk` — No plaintext on disk (Manual)
1. After login (local-key and, separately, bunker), inspect application support, preferences, and logs.
- **Expected**: The raw `nsec` / secret-key bytes do not appear in plaintext anywhere on disk; only Keychain holds the identity material. (`AC-id-no-plaintext`, `AC-id-ios-keychain-storage`)

#### `TC-id-ios-screen-only-path` — Screen is the only path (Manual)
1. On a fresh install, launch the app.
- **Expected**: The in-app Identity Sheet is presented; there is no env-var or config-file alternative; the reviewer either logs in, creates, or skips to read-only. (`AC-id-ios-screen-is-only-path`)

## Out of Scope

- `AC-id-out-of-band-skips`: no out-of-band identity sources on iOS (no env vars / config files). See `../../product/ios/identity.md`.
- macOS-only identity concerns (separate window, macOS Keychain-access-group specifics, env/config precedence): `qa/macos/identity.md`.
- The publishing path itself (signing, relay publish, bunker sign-failure mid-review): `./shepherd-review.md`.
