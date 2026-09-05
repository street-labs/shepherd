# PR Actions

> Cross-platform shared spec. Per-platform presentation is specified in `design/<platform>/pr-actions.md`.

## Overview

Once a PR (NIP-34 kind `1618`) is open for review, the reviewer can act on it without leaving Shepherd: post comments and reviews, approve or reject the PR, and — for repo maintainers — merge it. All actions publish signed Nostr events to the PR's relays, so the record lives on Nostr where the merge service and other ngit clients see it, and replies from other participants stream into the open review live. The existing local commenting flow (file annotations exported into the review prompt) is unchanged; this spec adds the nostr-native path on top of it.

Event shapes follow `docs/approval-events.md`: approvals/rejections are kind `1620` bound to the PR's current tip commit; comments and reviews are threaded replies; merges are NIP-34 kind `1631` status transitions.

## User Stories

### US-PA-1: Comment on a PR
**As a** reviewer, **I want to** post a comment on the PR — on the PR as a whole or on a specific file/line — **so that** my feedback reaches the author and other reviewers on Nostr, not just my local session.

### US-PA-2: Submit a review
**As a** reviewer, **I want to** submit a review verdict (approve / request changes / comment) with a markdown summary, **so that** the PR's approval state is recorded as a signed Nostr event bound to the exact commit I reviewed.

### US-PA-3: See replies as they arrive
**As a** reviewer, **I want to** see other participants' comments and replies to my comments stream into the open review live, **so that** I can converse without re-opening the PR.

### US-PA-4: Merge a PR
**As a** repo maintainer, **I want to** merge an approved PR from the review surface, **so that** triage and landing happen in one place and the merged status is visible to every ngit client.

### US-PA-5: Know whether I can act
**As a** reviewer, **I want to** see which actions are available to me (comment / approve / merge) based on my identity and the repo's maintainers, **so that** I am never offered an action my key cannot back.

## Requirements

### Functional Requirements

#### `FR-pa-comment` — Post comments
The reviewer can write a comment (plain markdown) at PR level or attached to a specific file and line range. Publishing signs a threaded reply event (kind `1` with an `e` tag referencing the PR root event, `p` tags for the PR author and any reply-target author) with the reviewer's identity and publishes it to the PR's relays. A comment that fails to publish is kept locally with a clear failure state and can be retried. Publishing requires an unlocked identity; without one the comment stays local and the app explains why.

#### `FR-pa-review` — Approve / request changes
The reviewer can submit a review verdict with an optional markdown summary. Approval publishes a kind `1620` event per `docs/approval-events.md`: `e` tag on the PR root, `t` tag `approval` (or `rejection` to withdraw/decline), and a `c` tag carrying the PR tip commit the review was performed against (the `c` tag of the newest `1618`/`1619`). Requesting changes publishes `rejection`. The tip commit is captured at submit time; if the PR is updated afterwards, the verdict remains bound to the older commit and the UI shows it as stale.

#### `FR-pa-threads` — Live reply streaming
While a PR is open for review, an active subscription on the PR's relays streams incoming replies (comments by other participants, and replies to the reviewer's own comments) into the thread view as they arrive, deduplicating by event id and merging into the existing reply structure. Replies appear in thread order under their parent. The subscription lives for the duration of the review session and is cancelled when the PR is closed.

#### `FR-pa-merge` — Merge a PR
A reviewer whose pubkey is in the repo's maintainers (from the repo `30617` event's maintainers or the merge-service allowlist) can merge an open PR. The merge action publishes a kind `1631` Applied/Merged status event with the `merge-commit` / `applied-as-commits` tags per NIP-34, referencing the PR root via `e`. The action is gated on the PR having at least one current kind `1620` approval and zero current rejections (verdict resolution per `docs/approval-events.md`); a PR without a current approval shows the gate failure instead of publishing. How commits actually land in the repo (push by the merge service, or local push) is the merge service's job — Shepherd publishes the status event only.

> **Ceiling (`merge-commit` semantics).** Because Shepherd does not land commits itself, Shepherd publishes `merge-commit` = the PR's tip commit. This is only correct for fast-forward-style publication, where the landed commit is the tip. Non-FF landings (true merge commits, squash) produce a different landed commit and are the merge service's job; kind `1631` from Shepherd reads as "approved at tip, applied fast-forward". Tip-based `merge-commit` semantics apply as long as Shepherd publishes status only; a Shepherd-side landing path changes this.

#### `FR-pa-capabilities` — Action availability
The review surface shows each action only when the current identity can perform it: comment always (with identity), approve/reject when an identity exists, merge only for repo maintainers. A stale approval (PR tip moved since the `c` tag) is labeled stale and does not count toward the merge gate.

### Non-Functional Requirements

#### `NFR-pa-publish-window` — Bounded publish
Each publish completes or fails visibly within the existing relay publish timeout; no silent hangs. Success requires at least one accepting relay.

#### `NFR-pa-nostr-only` — No local-only review records
Verdicts and merges are never stored only in local files; the Nostr event is the record. Local persistence is limited to draft state for retry.

## Acceptance Criteria

- [ ] **PR comment publishes** `AC-pa-comment-publishes`: Given an unlocked identity and an open PR, when the reviewer posts a comment, then a signed threaded reply event is published to the PR's relays and appears in the thread.
- [ ] **Line-attached comment** `AC-pa-line-comment`: Given a comment attached to a file/line, then the published event carries the file/line reference and renders attached in the thread.
- [ ] **Approval bound to tip** `AC-pa-approval-tip`: Given a PR at tip commit X, when the reviewer approves, then the kind `1620` event carries `c` = X and counts as a current approval.
- [ ] **Stale approval flagged** `AC-pa-stale`: Given an approval for commit X and a newer `1619` PR update moving the tip to Y, then the approval is shown as stale and does not satisfy the merge gate.
- [ ] **Replies stream live** `AC-pa-live-replies`: Given another participant posts a reply while the PR is open, then it appears in the thread within the subscription window without a manual refresh.
- [ ] **Merge gated** `AC-pa-merge-gate`: Given a PR with zero current approvals, when a maintainer attempts to merge, then the merge is blocked with the gate reason shown and no kind `1631` is published.
- [ ] **Merge publishes status** `AC-pa-merge-publishes`: Given a PR with a current approval and no rejections, when a maintainer merges, then a kind `1631` event referencing the PR root is published and the PR shows merged.
- [ ] **Actions hidden without capability** `AC-pa-capabilities`: Given the current identity is not a maintainer, then no merge affordance is shown.

## Open Questions

- **Maintainers source**: read the maintainer list from the repo `30617` event, the merge service's allowlist (a nostr event? a grasp-server API?), or both, with which winning on conflict? For now: repo event tags, merge service later.
- **Local review upload**: Luke floated loading local macOS reviews into a temp ngit/grasp server so all comments live on Nostr. Deferred — publishing comments directly to the PR's relays (this spec) covers the nostr-native path; the temp-server bridge stays on the roadmap until the grasp server API shape is known.

## Dependencies

- Identity (existing `product/identity.md`) — signing requires an unlocked identity.
- PR Browse / open-PR flow (`product/pr-browse.md`) — actions hang off the open review surface.
- `docs/approval-events.md` — kind `1620` shape and merge-service verification rules.
