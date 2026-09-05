# PR Actions — macOS Engineering

> Based on requirements in `../../product/pr-actions.md`
> Based on design in `../../design/macos/pr-actions.md`

## Architecture

No new feature module. Actions extend the existing review surface (`AppFeature` + `CommentFeature`) and the Nostr dependency layer. All event shapes follow `docs/approval-events.md`.

```
NostrSigner / RelayClient.publish  (existing signing + publish path)
EventBuilder (new, ShepherdDependencies)
  -> threadedReply(rootID, authorPubkey, content, fileRef?) -> kind 1
  -> verdict(prEventID, repoCoordinate, tipCommit, verdict, summary?) -> kind 1620
  -> mergeStatus(prEventID, repoCoordinate, mergeCommit)            -> kind 1631
AppFeature
  verdict sheet state, merge gate evaluation, publish effects
  (reuses the existing live-reply subscription for FR-pa-threads)
CommentFeature
  "Post to PR" publish path with posted/failed/retry bubble state
```

## Components

- **`EventBuilder`** (`Sources/Dependencies/`, new): pure constructors producing unsigned `NostrEvent`s; `NostrSigner` signs, `RelayClient.publish` sends. Kind `1620`: tags `e` (PR root, root marker), `p` (PR author), `a` (repo coordinate), `t` (`approval`/`rejection`), `c` (tip commit), optional `merge-base`. Kind `1631`: `e` (PR root), `a`, `merge-commit` / `applied-as-commits`. V1 ceiling per the product spec: Shepherd publishes `merge-commit` = the PR tip commit (fast-forward-style publication only); non-FF landing is the merge service's job.
- **Publish target set** (`FR-pa-comment`/`FR-pa-review`): the PR's relays — the repo-announcement relay set resolved by the browse/open path, falling back to configured relays. `NFR-pa-publish-window` uses the existing publish timeout; success = ≥1 OK.
- **Merge gate** (`FR-pa-merge`): pure function over (all fetched `1620` events for the PR, current tip commit, maintainer list from the repo `30617` tags). Verdict resolution per `docs/approval-events.md`: newest-per-(pubkey, PR) wins, stale `c` never counts. Exposed as a testable static; `AppFeature` renders enabled/disabled Merge with the gate reason.
- **Live replies** (`FR-pa-threads`): `AppFeature` already runs a live kind-1 subscription that merges incoming replies into the open thread (the patch-thread loop); PR open routes the same subscription at the PR root id — no new machinery, only the subscription's root parameter.
- **Comment publishing** (`FR-pa-comment`): `CommentFeature` gains a publish effect reusing the patch-reply publish path (`PatchReplyMapper`-compatible tags, plus the file/line reference for line-attached comments). Local bubble state: posting → posted(relayCount) / failed(retry).

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| `FR-pa-comment` | engineering/apps/macos/Sources/CommentFeature/CommentFeature.swift; engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/Dependencies/EventBuilder.swift | implemented |
| `FR-pa-review` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/Dependencies/EventBuilder.swift | implemented |
| `FR-pa-threads` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| `FR-pa-merge` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/Dependencies/EventBuilder.swift | implemented |
| `FR-pa-capabilities` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/macos/Sources/ReviewContextFeature/PatchMetadataSectionView.swift | implemented |
| `NFR-pa-publish-window` | engineering/apps/macos/Sources/Dependencies/RelayClient.swift | implemented |
| `NFR-pa-nostr-only` | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |

## Tests

`EventBuilder` tag/JSON truth tables (1620 with/without summary, 1631). Merge-gate truth table: approval+rejection mixes, stale `c`, ordering. Publish failure → retry state. Capability gating given identity/maintainer fixtures.
