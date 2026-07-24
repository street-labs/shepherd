---
product-hash: 73657271350feabccb5f4c4bd71c6f9b4b1619aa9145ca3c8443a98fc08618d9
product-slugs: [AC-id-active-shown, AC-id-bunker-can-publish, AC-id-bunker-connect-failure, AC-id-bunker-login-invalid-uri, AC-id-bunker-login-valid, AC-id-bunker-logout, AC-id-bunker-no-host-key, AC-id-bunker-persists, AC-id-create-new, AC-id-create-persists, AC-id-created-can-publish, AC-id-dismiss-read-only, AC-id-login-invalid, AC-id-login-valid, AC-id-logout, AC-id-no-plaintext, AC-id-out-of-band-skips, AC-id-switch, FR-id-active-indicator, FR-id-bunker-connect-failure, FR-id-bunker-login, FR-id-bunker-persist, FR-id-create-new, FR-id-logout, FR-id-no-silent-override, FR-id-nsec-login, FR-id-optional-reentry, FR-id-out-of-band-honored, FR-id-persistence, FR-id-screen-when-no-identity, FR-id-show-new-nsec, FR-sr-bunker-signing, FR-sr-reviewer-identity, FR-srm-bunker-connect, FR-srm-bunker-sign-failure, FR-srm-event-sign, FR-srm-identity-indicator, FR-srm-identity-load, NFR-id-bunker-connect-latency, NFR-id-key-stays-local, NFR-id-key-validity, NFR-id-login-latency, NFR-id-no-plaintext-key]
---
# Identity — macOS Test Plan

> Based on requirements in `../../product/identity.md`
> Based on design in `../../design/macos/identity.md`
> Based on technical spec in `../../engineering/macos/identity.md`

## What We're Testing

The in-app Nostr identity login and creation flow for the native macOS app: pasting an existing `nsec` to log in, generating a new identity, persistence across launches via Keychain, logout, coexistence with out-of-band identity sources, and the guarantee that the secret key is never written to disk in plaintext. Risk areas: secret-key handling (security), Keychain integration (platform-specific, can fail locked/empty), and precedence interaction with the existing out-of-band identity-load path.

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-id-login-valid` | `TC-id-login-valid`, `TC-id-login-persists` | Not started |
| `AC-id-login-invalid` | `TC-id-login-invalid-format`, `TC-id-login-invalid-checksum`, `TC-id-login-invalid-length` | Not started |
| `AC-id-create-new` | `TC-id-create-new`, `TC-id-create-shows-nsec`, `TC-id-create-confirm-required` | Not started |
| `AC-id-create-persists` | `TC-id-create-persists` | Not started |
| `AC-id-created-can-publish` | `TC-id-created-publishes` | Not started |
| `AC-id-logout` | `TC-id-logout`, `TC-id-logout-then-relaunch` | Not started |
| `AC-id-out-of-band-skips` | `TC-id-out-of-band-skips` | Not started |
| `AC-id-dismiss-read-only` | `TC-id-skip-read-only` | Not started |
| `AC-id-active-shown` | `TC-id-active-indicator` | Not started |
| `AC-id-no-plaintext` | `TC-id-no-plaintext-disk` | Not started |
| `AC-id-switch` | `TC-id-switch-identity` | Not started |
| `AC-id-bunker-login-valid` | `TC-id-bunker-login-valid` | Not started |
| `AC-id-bunker-login-invalid-uri` | `TC-id-bunker-login-invalid-uri` | Not started |
| `AC-id-bunker-connect-failure` | `TC-id-bunker-connect-failure` | Not started |
| `AC-id-bunker-persists` | `TC-id-bunker-persists` | Not started |
| `AC-id-bunker-can-publish` | `TC-id-bunker-can-publish` | Not started |
| `AC-id-bunker-logout` | `TC-id-bunker-logout` | Not started |
| `AC-id-bunker-no-host-key` | `TC-id-bunker-no-host-key` | Not started |
| `NFR-id-key-validity` | `TC-id-generated-key-valid` | Not started |
| `NFR-id-login-latency` | `TC-id-login-latency` | Not started |
| `NFR-id-bunker-connect-latency` | `TC-id-bunker-connect-latency` | Not started |

## Test Cases

### Login (existing nsec)

The happy and error paths for adopting an existing secret key in-app.

#### Login with a valid nsec `TC-id-login-valid`
- **Type**: Integration
- **Covers**: `AC-id-login-valid`, `FR-id-nsec-login`
- **Preconditions**: Keychain has no stored identity; no out-of-band identity configured.
- **Steps**:
  1. Launch the app — the Identity Window appears.
  2. Paste a known-valid `nsec1…` into the secure field.
  3. Click Sign In.
- **Expected Result**: The window dismisses, the main review window appears, and the active identity indicator shows the public key matching the pasted nsec.

#### Login persists across relaunch `TC-id-login-persists`
- **Type**: Integration (manual — relaunch)
- **Covers**: `AC-id-login-valid`, `FR-id-persistence`
- **Preconditions**: A successful login just completed.
- **Steps**:
  1. Quit and relaunch the app.
- **Expected Result**: The Identity Window does not appear; the same identity is active (indicator shows the same public key).

#### Reject malformed format `TC-id-login-invalid-format`
- **Type**: Unit (reducer) + Integration (UI)
- **Covers**: `AC-id-login-invalid`, `FR-id-nsec-login`
- **Preconditions**: Identity Window shown.
- **Steps**:
  1. Enter a string that is not bech32 (e.g. `hello world`).
  2. Click Sign In.
- **Expected Result**: An inline error names the problem; no identity is adopted; the window stays open.

#### Reject bad checksum `TC-id-login-invalid-checksum`
- **Type**: Unit
- **Covers**: `AC-id-login-invalid`, `FR-id-nsec-login`
- **Preconditions**: Identity Window shown.
- **Steps**:
  1. Paste an `nsec1…` string with a corrupted last character (valid format, invalid bech32 checksum).
  2. Click Sign In.
- **Expected Result**: Inline error; no identity adopted.

#### Reject wrong-length key `TC-id-login-invalid-length`
- **Type**: Unit
- **Covers**: `AC-id-login-invalid`, `FR-id-nsec-login`
- **Preconditions**: Identity Window shown.
- **Steps**:
  1. Paste a bech32-decodable value whose data is not 32 bytes (e.g. a truncated nsec).
  2. Click Sign In.
- **Expected Result**: Inline error; no identity adopted.

### Create new identity

Generating a fresh identity in-app.

#### Create new identity `TC-id-create-new`
- **Type**: Integration
- **Covers**: `AC-id-create-new`, `FR-id-create-new`
- **Preconditions**: Keychain empty; no out-of-band identity.
- **Steps**:
  1. Launch — Identity Window appears.
  2. Click "Create New Identity".
- **Expected Result**: The card transitions to the backup-reveal state showing a generated `nsec1…`, a Copy button, and the backup warning. A new identity is adopted (indicator shows its public key after confirmation).

#### Backup reveal shows the nsec `TC-id-create-shows-nsec`
- **Type**: Integration
- **Covers**: `FR-id-show-new-nsec`
- **Preconditions**: Create New Identity just clicked.
- **Steps**:
  1. Observe the reveal state; click Copy.
- **Expected Result**: The full `nsec1…` is visible and copies to the clipboard; the warning states this is the only chance to save it.

#### Confirm required before dismiss `TC-id-create-confirm-required`
- **Type**: Integration
- **Covers**: `FR-id-show-new-nsec`
- **Preconditions**: Backup-reveal state shown.
- **Steps**:
  1. Attempt to dismiss the window without clicking "I've saved my key".
- **Expected Result**: The reveal state cannot be bypassed without confirmation (no Skip/dismiss in this state).

#### Created identity persists `TC-id-create-persists`
- **Type**: Integration (manual — relaunch)
- **Covers**: `AC-id-create-persists`, `FR-id-persistence`
- **Preconditions**: A new identity was created and confirmed.
- **Steps**:
  1. Quit and relaunch the app.
- **Expected Result**: No Identity Window; the created identity is still active with the same public key.

#### Created identity can publish `TC-id-created-publishes`
- **Type**: Integration (manual — patch review)
- **Covers**: `AC-id-created-can-publish`, `FR-srm-event-sign`
- **Preconditions**: A new identity is active; a patch review (`--patch`) is opened.
- **Steps**:
  1. Add an inline comment anchored to a line range and submit it.
- **Expected Result**: The reply is signed under the created identity's public key and published; it appears in the patch-thread section attributed to that identity.

### Logout and switch

#### Logout forgets identity `TC-id-logout`
- **Type**: Integration
- **Covers**: `AC-id-logout`, `FR-id-logout`
- **Preconditions**: A reviewer is logged in via the in-app screen.
- **Steps**:
  1. Open the Identity Window on demand.
  2. Click Log Out.
- **Expected Result**: The stored secret key is removed (Keychain entry deleted), publishing becomes unavailable, and the card returns to the empty/initial state.

#### Logout then relaunch shows screen `TC-id-logout-then-relaunch`
- **Type**: Integration (manual — relaunch)
- **Covers**: `AC-id-logout`, `FR-id-screen-when-no-identity`
- **Preconditions**: Logout just completed; no out-of-band identity.
- **Steps**:
  1. Quit and relaunch the app.
- **Expected Result**: The Identity Window appears again (no stored identity).

#### Switch identity `TC-id-switch-identity`
- **Type**: Integration
- **Covers**: `AC-id-switch`, `FR-id-optional-reentry`
- **Preconditions**: Logged in with identity A.
- **Steps**:
  1. Open the Identity Window on demand.
  2. Click Switch Identity, paste a different valid `nsec` B, and sign in.
- **Expected Result**: Identity B becomes active; the indicator reflects B; the previously stored key for A is replaced (a relaunch keeps B, not A).

### Bunker login (NIP-46 remote signer)

Logging in by pasting a `bunker://` URI instead of a raw `nsec`, so the secret key stays off-host.

#### Login with a valid bunker URI `TC-id-bunker-login-valid`
- **Type**: Integration (mock bunker or live signer)
- **Covers**: `AC-id-bunker-login-valid`, `FR-id-bunker-login`
- **Preconditions**: Keychain has no stored identity; no out-of-band identity; a reachable NIP-46 bunker is available (or a mock `BunkerClient` returning a pubkey).
- **Steps**:
  1. Launch the app — the Identity Window appears.
  2. Switch the form toggle to "Bunker URI" and paste a valid `bunker://…` URI.
  3. Click Sign In.
- **Expected Result**: The card enters a Connecting state, the app connects to the signer, obtains the reviewer's public key, adopts the bunker identity, the window dismisses, and the indicator shows the bunker identity as connected.

#### Reject malformed bunker URI `TC-id-bunker-login-invalid-uri`
- **Type**: Unit (reducer) + Integration (UI)
- **Covers**: `AC-id-bunker-login-invalid-uri`, `FR-id-bunker-login`
- **Preconditions**: Identity Window shown, "Bunker URI" form active.
- **Steps**:
  1. Enter a malformed string (not `bunker://`, missing `relay=`, unparseable pubkey).
  2. Click Sign In.
- **Expected Result**: An inline error names the problem; no connection is attempted; no identity is adopted; the window stays open.

#### Bunker connect failure during login `TC-id-bunker-connect-failure`
- **Type**: Integration (mock bunker that refuses / times out)
- **Covers**: `AC-id-bunker-connect-failure`, `FR-id-bunker-connect-failure`
- **Preconditions**: "Bunker URI" form active; a well-formed URI pointing at an unreachable signer.
- **Steps**:
  1. Paste the well-formed `bunker://` URI and click Sign In.
- **Expected Result**: After the connect timeout, an error names the bunker as the cause, the entered URI is retained for correction, no identity is adopted, and the reviewer can retry. The Keychain does not retain a URI for a failed connect.

#### Bunker identity persists across relaunch `TC-id-bunker-persists`
- **Type**: Integration (manual — relaunch; mock bunker reconnect)
- **Covers**: `AC-id-bunker-persists`, `FR-id-bunker-persist`
- **Preconditions**: A successful bunker login just completed.
- **Steps**:
  1. Quit and relaunch the app.
- **Expected Result**: The app reconnects to the bunker using the stored URI, the Identity Window does not appear, and the indicator shows the bunker identity as connected again.

#### Bunker identity can publish `TC-id-bunker-can-publish`
- **Type**: Integration (manual — patch review; mock bunker signer)
- **Covers**: `AC-id-bunker-can-publish`, `FR-sr-bunker-signing`, `FR-srm-event-sign`
- **Preconditions**: A bunker identity is active; a patch review (`--patch`) is opened.
- **Steps**:
  1. Add an inline comment anchored to a line range and submit it.
- **Expected Result**: The reply is signed by the remote bunker under the reviewer's public key and published; it appears in the patch-thread section attributed to that identity; the reviewer's secret key was never present on the host.

#### Bunker logout forgets URI `TC-id-bunker-logout`
- **Type**: Integration
- **Covers**: `AC-id-bunker-logout`, `FR-id-logout`
- **Preconditions**: A reviewer is logged in via a bunker URI.
- **Steps**:
  1. Open the Identity Window on demand.
  2. Click Log Out.
- **Expected Result**: The stored bunker URI is removed (Keychain entry deleted), the bunker control channel closes, publishing becomes unavailable, and the card returns to the empty/initial state. On next launch (with no out-of-band identity) the login screen appears.

#### Bunker secret never on host `TC-id-bunker-no-host-key`
- **Type**: Manual
- **Covers**: `AC-id-bunker-no-host-key`, `NFR-id-key-stays-local`, `NFR-id-no-plaintext-key`
- **Preconditions**: A reviewer logged in via a bunker URI.
- **Steps**:
  1. Inspect `~/Library/Application Support/Shepherd`, `~/Library/Preferences/…plist`, logs, and the Keychain for the reviewer's Nostr secret key.
  2. Confirm the Keychain holds only the bunker URI (queryable via `security find-generic-password …`), not a 32-byte secret key.
- **Expected Result**: The reviewer's Nostr secret key is not present anywhere on the host; only the bunker URI is in Keychain (not in plaintext on disk) and an ephemeral control-channel keypair in memory.

#### Bunker connect is bounded by a timeout `TC-id-bunker-connect-latency`
- **Type**: Unit (timing / mock)
- **Covers**: `NFR-id-bunker-connect-latency`, `FR-id-bunker-connect-failure`
- **Preconditions**: A mock bunker that never responds.
- **Steps**:
  1. Initiate a bunker login with a URI pointing at the non-responding signer.
- **Expected Result**: The connect attempt times out within the bounded window (not hanging indefinitely) and is treated as a connect failure with a clear error.

### Coexistence with out-of-band identity

#### Out-of-band identity skips the screen `TC-id-out-of-band-skips`
- **Type**: Integration (manual — env setup)
- **Covers**: `AC-id-out-of-band-skips`, `FR-id-out-of-band-honored`
- **Preconditions**: `SHEPHERD_NSEC` env var (or `~/.config/nostr/identity`) set to a valid key; Keychain empty.
- **Steps**:
  1. Launch the app.
- **Expected Result**: The app uses the out-of-band identity; the Identity Window does not appear; the indicator shows the out-of-band identity.

### Skip / read-only mode

#### Skip proceeds to read-only `TC-id-skip-read-only`
- **Type**: Integration (manual — patch review)
- **Covers**: `AC-id-dismiss-read-only`, `FR-id-screen-when-no-identity`
- **Preconditions**: No identity available; Identity Window shown.
- **Steps**:
  1. Click "Skip for now".
  2. Open a patch review and submit an inline comment.
- **Expected Result**: The window dismisses into read-only mode; submitting a comment records it locally and publishing is unavailable with a clear indication (no identity).

### Active identity indicator

#### Active identity shown after login `TC-id-active-indicator`
- **Type**: Integration
- **Covers**: `AC-id-active-shown`, `FR-id-active-indicator`, `FR-srm-identity-indicator`
- **Preconditions**: Logged in (in-app or out-of-band).
- **Steps**:
  1. Open a patch review and inspect the identity indicator.
- **Expected Result**: The indicator shows the identity's display name or truncated npub so the reviewer can confirm whose key replies will be attributed to.

### Security

#### Secret key not in plaintext on disk `TC-id-no-plaintext-disk`
- **Type**: Manual
- **Covers**: `AC-id-no-plaintext`, `NFR-id-no-plaintext-key`, `NFR-id-key-stays-local`
- **Preconditions**: A reviewer has logged in via the in-app screen.
- **Steps**:
  1. Inspect `~/Library/Application Support/Shepherd`, `~/Library/Preferences/com.street-labs.shepherd.plist`, and the app's log output for the raw `nsec` / 32-byte secret.
  2. Confirm the Keychain holds the key (`security find-generic-password -s com.street-labs.shepherd -a shepherd-nostr-identity` prompts for access, does not print the secret without authorization).
- **Expected Result**: The raw `nsec` and secret-key bytes appear nowhere in plaintext on disk or logs; only Keychain holds the secret.

### Non-functional

#### Generated key is cryptographically valid `TC-id-generated-key-valid`
- **Type**: Unit
- **Covers**: `NFR-id-key-validity`, `FR-id-create-new`
- **Preconditions**: None.
- **Steps**:
  1. Call `createNewIdentity` (or the underlying generator) N times (e.g. 100).
  2. For each, decode the nsec to 32 bytes, derive the public key, and verify the scalar is in the valid secp256k1 range and the pubkey is a valid x-only key.
- **Expected Result**: Every generated key is a valid 32-byte scalar in range with a derivable valid pubkey.

#### Login is immediate `TC-id-login-latency`
- **Type**: Unit (timing)
- **Covers**: `NFR-id-login-latency`
- **Preconditions**: None.
- **Steps**:
  1. Time `loginWithKey` with a valid nsec (validation + pubkey derivation + Keychain write).
- **Expected Result**: Completes with no network round-trip; well under any user-perceptible threshold (target: < 100ms locally).

## Edge Cases & Error Scenarios

### Keychain unavailable at write time
- **Trigger**: Keychain is locked or the system denies access when `loginWithKey`/`createNewIdentity` tries to write.
- **Expected behavior**: The operation returns nil with a "Could not save identity" error; the identity is not adopted (so it does not silently vanish on next launch).
- **Test case**: `TC-id-keychain-write-failure` (manual / injected via test double)

### Keychain read returns corrupt data
- **Trigger**: The stored Keychain entry is not 32 bytes or fails pubkey derivation.
- **Expected behavior**: `loadIdentity` treats it as no stored identity and falls through to out-of-band sources; if none, the login window appears.
- **Test case**: `TC-id-keychain-corrupt` (unit — inject a bad data blob via the test double)

### Both in-app and out-of-band identity present
- **Trigger**: A key is stored in Keychain AND `SHEPHERD_NSEC` is set to a different key.
- **Expected behavior**: The Keychain (in-app) identity wins per the engineering precedence (Decision 1); the indicator shows the in-app identity; no silent override surprise because the in-app key was the reviewer's most recent explicit action.
- **Test case**: `TC-id-precedence-inapp-over-env` (integration)

## Regression Considerations

- **Existing patch-review publishing**: an identity adopted in-app must flow through the unchanged `reviewerIdentityLoaded` → `patchReviewPublishEffect` path. Verify a patch review still publishes after an in-app login (covered by `TC-id-created-publishes`).
- **Existing out-of-band users**: adding the Keychain source as highest precedence must not break a user who logs in in-app and then later sets an env var expecting it to take over — this is the precedence open question (Decision 1). The chosen precedence (in-app wins) is documented; if it surprises users, revisit.
- **`IdentityIndicatorView`**: the indicator must render an in-app-adopted identity identically to an out-of-band one (same `ReviewerIdentity` model), so no indicator regression is expected.
- **Bunker path**: unaffected — the Keychain source only stores local keys; a configured bunker still loads via its existing precedence slot below Keychain.
