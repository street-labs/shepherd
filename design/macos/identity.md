---
product-hash: a4ede6c56444cd114cece487d208c4b87772e3878443548e17071953dc34aca0
product-slugs: [AC-id-active-shown, AC-id-create-new, AC-id-create-persists, AC-id-created-can-publish, AC-id-dismiss-read-only, AC-id-login-invalid, AC-id-login-valid, AC-id-logout, AC-id-no-plaintext, AC-id-out-of-band-skips, AC-id-switch, FR-id-active-indicator, FR-id-create-new, FR-id-logout, FR-id-no-silent-override, FR-id-nsec-login, FR-id-optional-reentry, FR-id-out-of-band-honored, FR-id-persistence, FR-id-screen-when-no-identity, FR-id-show-new-nsec, FR-sr-reviewer-identity, FR-srm-event-sign, FR-srm-identity-indicator, FR-srm-identity-load, NFR-id-key-stays-local, NFR-id-key-validity, NFR-id-login-latency, NFR-id-no-plaintext-key]
---
# Identity — macOS Design Spec

> Based on requirements in `../../product/identity.md`
> See also `../../product/macos/shepherd-review.md` for the existing reviewer-identity model and indicator.

## What We're Designing

The in-app Nostr identity screen for the native macOS app: a single-window onboarding/login surface where a reviewer pastes an existing `nsec` to log in, or generates a brand-new identity with one click. It is the self-service replacement for the out-of-band env/config-file identity setup, and it gates into the existing review window only when no identity is available. The design reuses the existing reviewer-identity indicator (`IdentityIndicatorView`) to show the active identity once logged in, so this spec covers only the login surface itself.

## Screen Inventory

| Screen | Role |
|---|---|
| **Identity Window** | Self-service login / create-identity gate shown when no identity is available, and reachable on demand to switch or log out. |

## Screen Definitions

### Identity Window

A centered single-purpose window where the reviewer provides or creates a Nostr identity.

- **Entry points**:
  - Automatically at launch when no identity is available from any source (`FR-id-screen-when-no-identity`).
  - On demand from the review window when the reviewer chooses to switch or log out (`FR-id-optional-reentry`).
- **Layout**: A centered card on a plain background, vertically centered in the window. The card is narrow (roughly 420pt wide) so it reads as a focused dialog, not a full document. Top-down regions:
  1. **Header** — the app name/glyph and a one-line title ("Sign in to publish review replies").
  2. **Identity input** — a secure text field for pasting an `nsec1...`.
  3. **Primary actions** — "Sign In" button and a "Create New Identity" link/button beneath it.
  4. **Secondary action** — a subtle "Skip for now" link at the bottom.
  5. **Active-identity variant** — when opened on demand while logged in, the card instead shows the active identity and "Log Out" / "Switch Identity" actions (see States).
- **Components**:
  - **nsec field**: a `SecureField` (masked) with an `nsec1…` placeholder. Accepts paste. Shows an inline error message directly below the field when the submitted key is invalid (`AC-id-login-invalid`). The error is specific enough to act on: "Not a valid nsec — check it starts with nsec1 and is complete." Cleared on each new edit.
  - **Sign In button**: primary (accent-filled), disabled when the field is empty. Submits the key for validation (`FR-id-nsec-login`). Brief in-progress state is not needed (validation is synchronous and immediate, `NFR-id-login-latency`).
  - **Create New Identity button**: secondary (bordered, not filled). Triggers key generation (`FR-id-create-new`) and transitions the card to the backup-reveal state.
  - **Skip for now link**: subtle (plain link, no button chrome). Dismisses the window into read-only / local-only mode (`AC-id-dismiss-read-only`).
- **States**:
  - **Empty / initial**: field empty, Sign In disabled, Create and Skip visible. This is the state when no identity exists at launch.
  - **Error**: field contains input, an inline error string below the field names the problem; Sign In re-enabled so the reviewer can correct and resubmit.
  - **Backup reveal** (after Create New Identity): the field is replaced by a read-only display of the generated `nsec1…` in full, a Copy button, a warning line ("This is your only chance to save this key. If you lose it, you lose access to this identity."), and an "I've saved my key" confirmation button (`FR-id-show-new-nsec`). The reviewer cannot dismiss the backup reveal without confirming.
  - **Logged-in / on-demand**: when the window is opened while an identity is active, the card shows the active identity's display name and truncated npub (reusing the `IdentityIndicatorView` presentation), a "Log Out" button (`FR-id-logout`), and a "Switch Identity" button that reveals the nsec field + Create link again.
- **Actions**:
  - Submit a pasted key → validate → adopt or show error.
  - Create new → generate → show backup reveal → confirm → adopt.
  - Skip → dismiss to read-only mode.
  - Log out (logged-in variant) → forget stored identity → return to empty state.
  - Switch identity (logged-in variant) → reveal input → log in with a different key (`AC-id-switch`).
- **Requirements satisfied**: `FR-id-nsec-login`, `FR-id-create-new`, `FR-id-show-new-nsec`, `FR-id-screen-when-no-identity`, `FR-id-optional-reentry`, `FR-id-logout`, `FR-id-active-indicator`, `AC-id-login-valid`, `AC-id-login-invalid`, `AC-id-create-new`, `AC-id-logout`, `AC-id-dismiss-read-only`, `AC-id-switch`.

## Interaction Flows

### First-time login with an existing nsec

A reviewer who already has a Nostr identity and just installed Shepherd.

1. Reviewer launches the app with no configured identity → the Identity Window appears in its empty/initial state.
2. Reviewer pastes their `nsec1…` into the secure field → the Sign In button enables.
3. Reviewer clicks Sign In → the app validates the key. On success the window dismisses and the main review window appears with the active identity indicator showing the reviewer's identity. On failure, an inline error appears under the field and the reviewer corrects and resubmits.

### Create a new identity

A reviewer new to Nostr who has no key.

1. Reviewer launches the app with no identity → Identity Window appears.
2. Reviewer clicks "Create New Identity" → the card transitions to the backup-reveal state showing the generated `nsec1…`, a Copy button, and the backup warning.
3. Reviewer copies the `nsec`, saves it somewhere safe, then clicks "I've saved my key" → the window dismisses and the main review window appears with the new identity active. On the next launch, no identity screen appears (`AC-id-create-persists`).

### Skip and publish later

A reviewer who wants to read a patch now and set up identity later.

1. Identity Window appears → reviewer clicks "Skip for now" → the window dismisses into read-only / local-only mode.
2. The reviewer opens a patch review and tries to submit an inline comment → publishing is unavailable with a clear indication (reusing the existing no-identity indicator behavior from `FR-srm-identity-indicator`), and the comment is saved locally.

### Log out and switch

A reviewer who wants to rotate keys.

1. From the review window, the reviewer opens the Identity Window on demand (logged-in variant) → sees the active identity.
2. Reviewer clicks "Log Out" → the stored identity is forgotten and the card returns to its empty/initial state.
3. Reviewer pastes a new `nsec` and signs in → the new identity becomes active and the indicator updates (`AC-id-switch`).

## Component Specs

### nsec SecureField

A masked single-line input for a Nostr secret key.

- **Variants**: empty, populated (masked), error.
- **Inputs**: the entered string; an optional error string.
- **States**: disabled-submit when empty; error styling (red tint on the field border + inline message) when an error is present.
- **Behavior**: accepts paste; clears the error on any new keystroke; submits on Return as well as button click.

### Backup Reveal

A read-only display of a freshly generated `nsec` with a backup confirmation gate.

- **Variants**: revealed (default after generation).
- **Inputs**: the generated `nsec1…` string.
- **States**: copy-not-copied (Copy button toggles to a brief "Copied" confirmation, reusing the existing copy-confirmation pattern from the toolbar).
- **Behavior**: the "I've saved my key" button is the only way out of this state; it is always enabled (the app cannot verify the reviewer actually saved the key, per open question 3 — a single confirmation is the v1 choice).

## Responsive Behavior

The Identity Window is a fixed-aspect centered card and does not meaningfully resize. On the smallest supported macOS window size it remains centered and scrollable if needed. There is no sidebar, split, or multi-column layout to adapt.

## Accessibility

- The nsec field is a secure field; its accessibility label is "Nostr secret key" and the placeholder is exposed as a hint.
- The Sign In, Create New Identity, Skip, and Log Out controls are keyboard-reachable and operable with Return/Space; the field submits on Return.
- The backup-reveal warning is announced as an accessibility alert so VoiceOver users hear the "only chance to save" message.
- The active identity shown in the logged-in variant uses the same accessibility label contract as `IdentityIndicatorView` (display name + npub).
- Color is never the only signal for the error state: the inline error message carries the text, not just a red border.
