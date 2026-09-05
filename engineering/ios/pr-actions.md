---
product-hash: eb5def0ee51a224812b9cafbb444a578042b2152cfa5d2f0d71c2cce5fcc23f0
product-slugs: [AC-pa-approval-tip, AC-pa-capabilities, AC-pa-comment-publishes, AC-pa-line-comment, AC-pa-live-replies, AC-pa-merge-gate, AC-pa-merge-publishes, AC-pa-stale, FR-pa-capabilities, FR-pa-comment, FR-pa-review, FR-pa-threads, NFR-pa-nostr-only, NFR-pa-publish-window]
---

# PR Actions — iOS Engineering

> Based on requirements in `../../product/pr-actions.md` and `../../product/ios/pr-actions.md`
> Based on design in `../../design/ios/pr-actions.md`

## What We're Building

PR actions are implemented in the shared SwiftPM package (`engineering/apps/macos/Sources/`) exactly as specified in `../../engineering/macos/pr-actions.md` — `EventBuilder`, the merge-gate function, verdict/merge effects in `AppFeature`, and comment publishing in `CommentFeature` are platform-clean and compile into the iOS target. The iOS work is presentational only: verdict sheet, merge control, and capability-gated controls rendered with iOS presentation, reusing the identity/signing stack the iOS app already uses for patch-thread replies (`FR-sri-event-sign`, `FR-sri-event-publish`).

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-pa-comment | engineering/apps/macos/Sources/CommentFeature/CommentFeature.swift; engineering/apps/ios/ShepherdiOSApp/iOSAppView.swift | implemented |
| FR-pa-review | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/ios/ShepherdiOSApp/iOSAppView.swift | implemented |
| FR-pa-threads | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| FR-pa-merge | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |
| FR-pa-capabilities | engineering/apps/macos/Sources/AppFeature/AppFeature.swift; engineering/apps/ios/ShepherdiOSApp/iOSAppView.swift | implemented |
| NFR-pa-publish-window | engineering/apps/macos/Sources/Dependencies/RelayClient.swift | implemented |
| NFR-pa-nostr-only | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | implemented |

(Shared-surface slugs ride the macOS implementation listed in `../../engineering/macos/pr-actions.md`; no iOS-only logic.)

## Tests

No new iOS unit tests: gate and builder logic is covered in the shared package. iOS verification is manual per `qa/ios/pr-actions.md`.
