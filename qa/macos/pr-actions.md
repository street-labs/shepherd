# PR Actions — macOS Test Plan

> Based on requirements in `../../product/pr-actions.md`
> Based on design in `../../design/macos/pr-actions.md`
> Based on technical spec in `../../engineering/macos/pr-actions.md`

## What We're Testing

Comment publishing, review verdicts (kind `1620`), live reply streaming, the merge gate and merge publish (kind `1631`), and capability gating — unit-tested against stubbed signer/relay clients, plus manual verification of the surfaces.

## Coverage Matrix

| Requirement | Test Cases |
|---|---|
| `FR-pa-comment` | `TC-pa-comment-publish`, `TC-pa-line-ref`, `TC-pa-comment-retry` |
| `FR-pa-review` | `TC-pa-approval-bind`, `TC-pa-rejection` |
| `FR-pa-threads` | `TC-pa-live-reply`, `TC-pa-dedupe` |
| `FR-pa-merge` | `TC-pa-merge-gate`, `TC-pa-merge-publish`, `TC-pa-stale-approval` |
| `FR-pa-capabilities` | `TC-pa-capabilities` |
| `NFR-pa-publish-window` | `TC-pa-comment-retry` |
| `NFR-pa-nostr-only` | `TC-pa-merge-gate` (gate reads only nostr events) |

## Test Cases

### Comments

#### `TC-pa-comment-publish` — Comment publishes as threaded reply
Given an unlocked identity, when a PR-level comment is submitted, then a signed kind `1` event with `e` (PR root) and `p` tags is published to the PR's relay set and the bubble flips to posted. (`AC-pa-comment-publishes`)

#### `TC-pa-line-ref` — Line-attached comment carries the reference
Given a comment attached to file F lines 3–7, then the published event carries that reference and the thread renders it attached. (`AC-pa-line-comment`)

#### `TC-pa-comment-retry` — Failed publish retains content
Given a relay stub that rejects all publishes, when a comment is submitted, then within the publish window the bubble shows failed with retry; retrying against an accepting stub publishes the identical event. (`AC-pa-comment-publishes`)

### Verdicts

#### `TC-pa-approval-bind` — Approval binds to tip commit
Given a PR whose newest `1618`/`1619` has `c` = X, when the reviewer approves, then the kind `1620` event carries `t: approval` and `c: X`. (`AC-pa-approval-tip`)

#### `TC-pa-rejection` — Request-changes publishes rejection
Same path with `t: rejection`; and a later rejection by the same pubkey supersedes their earlier approval (newest-per-pubkey resolution). (`AC-pa-approval-tip`)

### Live replies

#### `TC-pa-live-reply` — Incoming reply appears without refresh
Given the PR open and a stub relay emitting a participant reply mid-session, then the thread shows it under its parent within the window. (`AC-pa-live-replies`)

#### `TC-pa-dedupe` — Duplicate event ids merge
Same reply delivered by two relays renders once.

### Merge

#### `TC-pa-merge-gate` — Gate blocks without approval
Given zero current approvals (or one current rejection), when a maintainer clicks Merge, then no event publishes and the gate reason is shown. (`AC-pa-merge-gate`)

#### `TC-pa-merge-publishes` — Merge publishes 1631
Given one current approval and zero rejections, when a maintainer merges, then a kind `1631` referencing the PR root is published and status shows merged. (`AC-pa-merge-publishes`)

#### `TC-pa-stale-approval` — Stale approval excluded from gate
Given an approval with `c` = X and a newer PR update with tip Y, then the approval is labeled stale and the gate fails. (`AC-pa-stale`)

### Capabilities

#### `TC-pa-capabilities` — Controls per identity/role
No identity → review/post disabled with explanation; identity but not maintainer → no Merge control; maintainer → Merge visible. (`AC-pa-capabilities`)
