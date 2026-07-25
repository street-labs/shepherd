---
product-hash: 759a7eb8999156e9454875a44bb0df553a15e1756c8d20e8d5047df09b755718
product-slugs: [AC-id-active-shown, AC-id-bunker-can-publish, AC-id-bunker-connect-failure, AC-id-bunker-login-invalid-uri, AC-id-bunker-login-valid, AC-id-bunker-logout, AC-id-bunker-no-host-key, AC-id-bunker-persists, AC-id-create-new, AC-id-create-persists, AC-id-created-can-publish, AC-id-dismiss-read-only, AC-id-login-invalid, AC-id-login-valid, AC-id-logout, AC-id-no-plaintext, AC-id-out-of-band-skips, AC-id-switch, FR-id-active-indicator, FR-id-bunker-connect-failure, FR-id-bunker-login, FR-id-bunker-persist, FR-id-create-new, FR-id-logout, FR-id-no-silent-override, FR-id-nsec-login, FR-id-optional-reentry, FR-id-out-of-band-honored, FR-id-persistence, FR-id-screen-when-no-identity, FR-id-show-new-nsec, FR-sr-bunker-signing, FR-sr-reviewer-identity, FR-srm-bunker-connect, FR-srm-bunker-sign-failure, FR-srm-event-sign, FR-srm-identity-indicator, FR-srm-identity-load, NFR-id-bunker-connect-latency, NFR-id-key-stays-local, NFR-id-key-validity, NFR-id-login-latency, NFR-id-no-plaintext-key]
---
# Identity — iOS Design Spec

> Based on requirements in `../../product/identity.md`
> See also `../../product/ios/identity.md` for iOS-specific requirements.
> See `./shepherd-review.md` for the identity indicator and publishing path that consume the loaded identity.

## What We're Designing

The in-app Nostr identity screen for iPhone and iPad: a focused login/create surface where a reviewer pastes an existing `nsec`, pastes a NIP-46 `bunker://` URI, or generates a brand-new identity. On iOS this screen is the only identity configuration path (no env vars or config files), so it doubles as the first-run onboarding gate. It is presented as a sheet/full-screen form over the empty state, not a separate window (iOS has no multi-window). Once an identity is active, the existing reviewer-identity indicator (see `./shepherd-review.md`) surfaces it; this spec covers only the login surface itself.

## Screen Inventory

| Screen | Role |
|---|---|
| **Identity Sheet** | Self-service login / create-identity form, presented at launch when no identity is stored, and reachable on demand to switch or log out. Supports two login forms: a local secret key (`nsec`) and a NIP-46 bunker URI. |

## Screen Definitions

### Identity Sheet

A centered single-purpose form where the reviewer provides or creates a Nostr identity.

- **Entry points**:
  - Automatically at launch when no identity is available from the Keychain (`FR-id-screen-when-no-identity`).
  - On demand from the review surface when the reviewer chooses to switch or log out (`FR-id-optional-reentry`), via the identity indicator or a settings entry.
- **Layout**: A scrollable form centered on screen. Top-down regions:
  1. **Header** — the app glyph and a one-line title ("Sign in to publish review replies").
  2. **Form toggle** — a segmented control ("Secret Key" / "Bunker URI") selecting which login form the input expects. Defaults to "Secret Key". Switching clears the field and any error.
  3. **Identity input** — a `SecureField` for `nsec1…` (Secret Key form) or a plain `TextField` for `bunker://…` (Bunker URI form). Accepts paste. An inline error message appears directly below the field on validation/connect failure.
  4. **Primary action** — a "Sign In" button (accent-filled), disabled when the field is empty. For a bunker login it shows a "Connecting…" in-progress state while the NIP-46 handshake runs.
  5. **Create action** — a "Create New Identity" button beneath Sign In (local-key only; not shown when "Bunker URI" is active).
  6. **Secondary action** — a subtle "Skip for now" link at the bottom (dismisses to read-only / local-only mode).
  7. **Active-identity variant** — when opened on demand while logged in, the form instead shows the active identity (display name + truncated npub, with the bunker connection-state dot for a bunker identity) and "Log Out" / "Switch Identity" actions.
- **Components**:
  - **nsec SecureField** — masked, `nsec1…` placeholder; inline error on invalid key ("Not a valid nsec — check it starts with nsec1 and is complete."); error clears on any new keystroke.
  - **bunker URI TextField** — plain (not masked), `bunker://…` placeholder; inline error on malformed URI or connect failure.
  - **Sign In button** — submits the active form; disabled when empty; "Connecting…" for the bunker handshake.
  - **Create New Identity button** — secondary; triggers key generation and transitions to the backup-reveal state.
  - **Skip for now** — dismisses to read-only mode.
- **States**:
  - **Empty / initial** — field empty, Sign In disabled, Create and Skip visible.
  - **Error** — inline error under the field; Sign In re-enabled for correction.
  - **Backup reveal** (after Create) — the field is replaced by a read-only display of the generated `nsec1…` in full, a Copy button, a warning ("This is your only chance to save this key. If you lose it, you lose access to this identity."), and an "I've saved my key" confirmation button. The reviewer cannot dismiss without confirming.
  - **Connecting** (bunker only) — "Connecting to bunker…" with Sign In disabled; on success → logged-in variant, on failure → error with the URI retained.
  - **Logged-in / on-demand** — shows the active identity, "Log Out", and "Switch Identity" (which reveals the form toggle + input again).
- **Actions**:
  - Submit a pasted key → validate → adopt or show error.
  - Submit a bunker URI → parse → connect → adopt or show error (Connecting state in between).
  - Create new → generate → backup reveal → confirm → adopt (local-key only).
  - Skip → dismiss to read-only mode.
  - Log out (logged-in variant) → forget stored identity → return to empty state.
  - Switch identity (logged-in variant) → reveal input → log in with a different key or URI.
- **Requirements satisfied**: `FR-id-nsec-login`, `FR-id-create-new`, `FR-id-show-new-nsec`, `FR-id-screen-when-no-identity`, `FR-id-optional-reentry`, `FR-id-logout`, `FR-id-active-indicator`, `FR-id-bunker-login`, `FR-id-bunker-persist`, `FR-id-bunker-connect-failure`, `FR-id-ios-screen-is-only-path`, `AC-id-login-valid`, `AC-id-login-invalid`, `AC-id-create-new`, `AC-id-logout`, `AC-id-dismiss-read-only`, `AC-id-switch`, `AC-id-bunker-login-valid`, `AC-id-bunker-login-invalid-uri`, `AC-id-bunker-connect-failure`, `AC-id-bunker-persists`, `AC-id-bunker-logout`, `AC-id-ios-screen-is-only-path`.

## Interaction Flows

### First-time login with an existing nsec

A reviewer who already has a Nostr identity and just installed Shepherd.

1. Reviewer launches the app with no stored identity → the Identity Sheet appears in its empty/initial state.
2. Reviewer pastes their `nsec1…` into the secure field → Sign In enables.
3. Reviewer taps Sign In → the app validates the key. On success the sheet dismisses and the empty state (or review surface) appears with the active identity indicator showing the reviewer's identity. On failure, an inline error appears and the reviewer corrects and resubmits.

### Create a new identity

A reviewer new to Nostr who has no key.

1. Launch with no identity → Identity Sheet appears.
2. Reviewer taps "Create New Identity" → the form transitions to the backup-reveal state showing the generated `nsec1…`, a Copy button, and the backup warning.
3. Reviewer copies the `nsec`, saves it, taps "I've saved my key" → the sheet dismisses with the new identity active. On the next launch, no identity sheet appears.

### Skip and publish later

1. Identity Sheet appears → reviewer taps "Skip for now" → the sheet dismisses into read-only / local-only mode.
2. The reviewer opens a patch review and tries to submit an inline comment → publishing is unavailable with a clear indication (reusing the no-identity indicator behavior, `./shepherd-review.md`), and the comment is saved locally.

### Log out and switch

1. From the review surface, the reviewer opens the Identity Sheet on demand (logged-in variant) → sees the active identity.
2. Taps "Log Out" → the stored identity is forgotten and the form returns to its empty state.
3. Pastes a new `nsec` and signs in → the new identity becomes active and the indicator updates.

### Login with a bunker (no raw key on device)

1. Launch with no identity → Identity Sheet appears.
2. Reviewer switches the form toggle to "Bunker URI" and pastes their `bunker://…` connection string.
3. Taps Sign In → the form enters the Connecting state while the app runs the NIP-46 handshake. On success the sheet dismisses with the active identity indicator showing the bunker identity as connected. On failure (unreachable signer, bad secret, timeout) an inline error names the bunker as the cause, the URI is retained, and the reviewer can retry.
4. On the next launch, the app reconnects to the bunker using the stored URI and no login sheet appears.

## Component Specs

### nsec SecureField

A masked single-line input for a Nostr secret key.

- **Variants**: empty, populated (masked), error.
- **Inputs**: the entered string; an optional error string.
- **States**: disabled-submit when empty; error styling (red tint + inline message) when an error is present.
- **Behavior**: accepts paste; clears the error on any new keystroke; submits on the keyboard's primary action as well as button tap.

### Backup Reveal

A read-only display of a freshly generated `nsec` with a backup confirmation gate.

- **Variants**: revealed (default after generation).
- **Inputs**: the generated `nsec1…` string.
- **States**: copy-not-copied (Copy button toggles to a brief "Copied" confirmation).
- **Behavior**: the "I've saved my key" button is the only way out of this state; it is always enabled (single confirmation is the v1 choice, per shared Open Question 3).

## Responsive Behavior

The Identity Sheet is a single-column form and presents identically on iPhone and iPad (sized to the screen, centered on iPad with a form-sheet width). There is no multi-column layout to adapt.

## Accessibility

- The nsec field is a secure field; its accessibility label is "Nostr secret key" with the placeholder as a hint.
- Sign In, Create New Identity, Skip, and Log Out are reachable and operable via VoiceOver and an attached keyboard; the field submits on the primary keyboard action.
- The backup-reveal warning is announced as an accessibility alert so VoiceOver users hear the "only chance to save" message.
- The active identity in the logged-in variant uses the same accessibility label contract as the identity indicator (display name + npub).
- Color is never the only signal for the error state: the inline error message carries the text, not just a red border.

## Open Questions

1. **Sheet vs. full-screen cover on compact**: a sheet (form-sheet) vs. a full-screen cover for the first-run gate. A full-screen cover reads as a more deliberate onboarding gate; a sheet is lighter. Deferred to a visual prototype.
2. **Where the on-demand entry lives**: the identity indicator tap vs. a Settings entry vs. both. The indicator tap is the most discoverable; deferred to prototype.
