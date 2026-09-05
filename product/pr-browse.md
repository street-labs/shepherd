# PR Browse

> Cross-platform shared spec. macOS presentation is specified in `design/macos/pr-browse.md` and `product/macos/shepherd-review.md` (the in-app open flow this feature feeds).

## Overview

Shepherd's in-app patch/PR open today requires the reviewer to already know an event id. PR Browse adds discovery: the reviewer maintains a short list of NIP-34 repositories to watch, then browses the pull requests (kind `1618`) filed against any of them, and can also browse the pull requests in which a given Nostr pubkey is tagged. Picking a PR from either list opens it for review through the existing in-app patch/PR open load path — there is no second review surface.

A NIP-34 repository is identified by its coordinate `30617:<owner-pubkey>:<d-identifier>`. A pull request event (kind `1618`) references its repository with an `a` tag carrying that coordinate and may tag reviewers/participants with `p` tags carrying pubkeys.

## User Stories

### US-PB-1: Watch the repos I care about
**As a** reviewer, **I want to** add and remove NIP-34 repository coordinates in a persisted watchlist, **so that** I can get to the PRs of the repositories I maintain without re-entering their coordinates.

### US-PB-2: See the PRs filed against a watched repo
**As a** reviewer, **I want to** pick a watched repository and see its pull requests (subject, author, age) fetched from my configured relays, **so that** I can triage incoming PRs without leaving Shepherd or copying event ids out of another Nostr client.

### US-PB-3: See the PRs I'm tagged in
**As a** reviewer, **I want to** enter a Nostr pubkey (npub or hex) and see the pull requests that tag it, **so that** I can find the PRs where I'm a reviewer or requested participant.

### US-PB-5: Browse is the first thing I see
**As a** reviewer, **I want to** open Shepherd and land directly in PR browsing (watchlist and PR lists), **so that** the common case — open app, find a PR, review it — has no extra step, with opening a patch or PR by id available as an action from within that state.

### US-PB-6: See real PR status
**As a** reviewer, **I want to** see each PR's actual status (open / merged / closed / draft) with a badge and have only open PRs shown by default, **so that** I triage against truth instead of guessing from recency.

### US-PB-7: Browse PRs on private grasp servers
**As a** reviewer, **I want to** browse PRs of repositories hosted on relays that are not publicly readable, **so that** ngit repos on private grasp servers are first-class citizens.

### US-PB-4: Open a browsed PR for review
**As a** reviewer, **I want to** select a PR from either list and have it open for review, **so that** browsing flows straight into the existing review workflow.

## Requirements

### Functional Requirements

#### `FR-pb-watchlist-manage` — Manage the watched-repo list
The user can add a repository to the watchlist by entering its coordinate (`30617:<pubkey>:<d>`), and remove entries. The list is persisted locally and restored on launch. Duplicate coordinates are rejected. A malformed coordinate is rejected with a clear error and is not added. The watchlist has no fixed size limit.

#### `FR-pb-repo-list` — List pull requests for a watched repo
Selecting a watched repository fetches kind `1618` events whose `a` tag equals the repository coordinate. The fetch targets the repository's own announcement relays (the `relays` tag of the repo's `30617` event), falling back to the configured relays when the repo event or its relay list is unavailable — PRs on private grasp servers live on the repo's relays, not necessarily on the reviewer's. Relays that require it are answered via NIP-42 AUTH using the user's identity; an unauthenticated relay that rejects the request is skipped, not fatal. The list shows each PR's subject (from the `subject` tag, or the first line of the content), author (event pubkey), age, and status badge (see `FR-pb-status`), newest first, and deduplicates events by id across relays. Fetching has a bounded wait window; PRs that do not arrive in time are simply not shown (partial lists are valid). The user can re-trigger the fetch (refresh).

NIP-34 PR status is conveyed by separate status events (kinds `1630`–`1633`), not by the PR event.

#### `FR-pb-npub-list` — List pull requests tagging a pubkey
The user can enter a Nostr pubkey (`npub1…` or 64-char hex) and fetch kind `1618` events with a `p` tag equal to that pubkey. Presentation is identical to `FR-pb-repo-list` (same fields, ordering, dedupe, wait window, refresh). An invalid npub/hex input is rejected with a clear error. This lookup uses the same relay set and presentation as the repo list. This lookup is not persisted.

#### `FR-pb-default-state` — PR Browse is the app's default empty state
When no files are loaded, the app's main window shows the PR Browse surface (watchlist + PR list, per `design/macos/pr-browse.md`) inline as the default state — not as a sheet the user must summon. The empty state's existing entry points ("Open Files…", "Paste from Clipboard", and the "Open Patch or PR…" affordance of `FR-srm-patch-open-entry`) remain available as actions from within this state, and dragging files onto the window still loads them. Once files are loaded the browse surface is replaced by the review layout. This default state is the base for future browse views (e.g. "my open PRs", per-repo, "needs review"); those views are not in v1.

#### `FR-pb-open-pr` — Open a browsed PR for review
Selecting a PR from either list opens it for review by its event id through the existing in-app patch/PR open load path (fetch by id, kind dispatch, PR diff acquisition, metadata, review surface). The browse surface is replaced by the review layout when the PR begins loading, and restored when the review session is cleared. A PR that fails to load surfaces the same errors the in-app open path already produces.

### Non-Functional Requirements

#### `FR-pb-status` — Status badges and open-only filter
For each listed PR the app fetches the newest status event (kinds `1630` Open, `1631` Applied/Merged, `1632` Closed, `1633` Draft, resolved by `created_at` from the PR author or a repo maintainer) that references the PR via an `e` tag, and renders its status as a badge on the list row. The list defaults to showing open PRs; the user can toggle to show all statuses. A PR with no status event is shown as open.

#### `NFR-pb-fetch-window` — Bounded fetch
Each list fetch waits no longer than the platform's existing single-event fetch window (8 seconds) before presenting whatever arrived.

## Acceptance Criteria

- [ ] **Watchlist persists** `AC-pb-watchlist-persists`: Given a repo coordinate is added, when the app relaunches, then the coordinate is still in the watchlist.
- [ ] **Bad coordinate rejected** `AC-pb-watchlist-invalid`: Given input that is not a `30617:<pubkey>:<d>` coordinate, when the user tries to add it, then a clear error is shown and the watchlist is unchanged.
- [ ] **Repo list populates** `AC-pb-repo-list`: Given a watched repo with PRs on the user's relays, when it is selected, then its kind `1618` PRs are listed newest first with subject, author, and age.
- [ ] **Npub list populates** `AC-pb-npub-list`: Given a valid npub, when it is entered, then PRs tagging that pubkey are listed newest first.
- [ ] **Browse is the default state** `AC-pb-default-state`: Given the app launches with no files loaded, then the main window shows the PR Browse surface (watchlist + PR list) inline, with "Open Patch or PR…" available as an action from within it.
- [ ] **Status badge renders** `AC-pb-status-badge`: Given a PR with a kind `1631` merged status event, when its repo list is shown, then the PR row shows a merged badge and is hidden from the default open-only view.
- [ ] **Private repo browsable** `AC-pb-private-relays`: Given a watched repo whose `30617` announcement lists a relay the user is not currently connected to and that requires NIP-42 AUTH, when it is selected, then its PRs are fetched from that relay after auth and listed normally.
- [ ] **PR opens for review** `AC-pb-open-pr`: Given a PR is listed, when it is selected, then the existing in-app PR review flow loads it (same surface as opening by id).

## Out of Scope

- Patch events (kind `1617`) in the browse lists — the roadmap fast-follow extends the repo list to patches.
- Background watching / notifications — lists are fetched on demand.
- Entering repos by `naddr1…` or git URL — coordinate string only in v1.
- Additional browse views ("my open PRs", per-repo, "needs review") — `FR-pb-default-state` is the base they hang off; see `roadmap/patch-watcher.md`.
- Deep link directly into a PR — already served by the existing `shepherd://pr/<ref>` deeplink entry; pasting a link or event id into a text field is served by the Open Patch or PR dialog reached from within the browse state.
