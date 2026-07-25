---
product-hash: 79cd3657d1229c6903ee9652d107c23493af4ce8c70046a4724c05da34c4fc0c
product-slugs: [AC-crp-active-file-path-single-file, AC-crp-active-file-path-switches, AC-crp-active-file-path-visible, AC-crp-add-comment-line-range, AC-crp-add-comment-single-line, AC-crp-binary-file-rejected, AC-crp-clear-confirmation, AC-crp-clear-no-confirm-empty, AC-crp-comment-navigation-next, AC-crp-comment-summary-empty, AC-crp-comment-summary-realtime, AC-crp-comment-summary-shows-all, AC-crp-context-graceful-missing, AC-crp-context-neutral-vs-review, AC-crp-context-overall-visible, AC-crp-context-per-file-switches, AC-crp-context-per-file-visible, AC-crp-context-readonly, AC-crp-context-sidebar-collapse, AC-crp-copy-clipboard, AC-crp-delete-comment, AC-crp-done-auto-close, AC-crp-done-confirmation, AC-crp-done-disabled-no-comments, AC-crp-done-fallback-clipboard, AC-crp-done-sends-prompt, AC-crp-done-standalone-hidden, AC-crp-edit-comment, AC-crp-empty-state, AC-crp-file-mark-reviewed, AC-crp-file-path-display, AC-crp-file-path-single-dir, AC-crp-file-reviewed-clear-session, AC-crp-file-reviewed-grouping, AC-crp-file-reviewed-progress-count, AC-crp-file-reviewed-survives-tab-switch, AC-crp-file-reviewed-with-comments, AC-crp-file-tooltip-full-path, AC-crp-file-tooltip-reviewed, AC-crp-file-unmark-reviewed, AC-crp-generate-prompt-no-comments, AC-crp-generate-prompt-structure, AC-crp-keyboard-add-comment, AC-crp-large-file-scroll, AC-crp-line-wrap-comment-target, AC-crp-line-wrap-default-on, AC-crp-line-wrap-persists-session, AC-crp-line-wrap-preserves-line-numbers, AC-crp-line-wrap-toggle, AC-crp-load-drag-drop, AC-crp-load-paste, AC-crp-load-upload, AC-crp-multi-file-clear-all, AC-crp-multi-file-comment-count, AC-crp-multi-file-drop-multiple, AC-crp-multi-file-empty-after-remove-last, AC-crp-multi-file-load-adds, AC-crp-multi-file-nav-preserves-state, AC-crp-multi-file-prompt-omits-uncommented, AC-crp-multi-file-prompt-structure, AC-crp-multi-file-remove-no-comments, AC-crp-multi-file-remove-with-comments, AC-crp-overall-comment-in-prompt, AC-crp-overall-comment-label, AC-crp-panel-resize-bounds, AC-crp-panel-resize-double-click, AC-crp-panel-resize-drag, AC-crp-panel-resize-keyboard, AC-crp-panel-resize-persists, AC-crp-preview-matches-copy, AC-crp-syntax-highlight-detected, FR-crp-active-file-path, FR-crp-clear-session, FR-crp-comment-count, FR-crp-comment-indicator, FR-crp-comment-navigation, FR-crp-comment-summary, FR-crp-done-action, FR-crp-file-display, FR-crp-file-load, FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-persistence, FR-crp-file-reviewed-progress, FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual, FR-crp-file-tooltip, FR-crp-filename-display, FR-crp-line-comment-create, FR-crp-line-comment-delete, FR-crp-line-comment-edit, FR-crp-line-range-comment, FR-crp-line-wrap, FR-crp-multi-file-load, FR-crp-multi-file-nav, FR-crp-multi-file-prompt, FR-crp-multi-file-prompt-format, FR-crp-multi-file-remove, FR-crp-panel-resize, FR-crp-prompt-copy, FR-crp-prompt-format, FR-crp-prompt-generate, FR-crp-prompt-handoff, FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-review-context-collapsible, FR-crp-review-context-display, FR-crp-review-context-overall, FR-crp-review-context-per-file, FR-crp-review-context-receive, FR-crp-session-identity, FR-crp-syntax-highlight, FR-sc-file-api, FR-sc-session-id, NFR-crp-accessibility-keyboard, NFR-crp-browser-support, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-crp-no-data-persistence, NFR-crp-prompt-gen-time, NFR-crp-render-time, NFR-crp-responsive-layout]
---
# Code Review Prompt Generator — iOS Technical Spec

> Based on requirements in `../../product/code-review-prompt.md`
> See also `../../product/ios/code-review-prompt.md` for iOS-specific requirements.
> Based on design in `../../design/ios/code-review-prompt.md`

## What We're Building

A native iOS app (iPhone + iPad) that presents the CRPG review surface for an in-app opened NIP-34 patch. It reuses the macOS app's cross-platform SPM feature modules (SwiftUI + TCA) for the code viewer, comments, file browser, and inspector, and adds an iOS-specific app shell that drives the layout by horizontal size class and presents the patch-open entry (see `./shepherd-review.md`). There is no local file loading, no slash command, no local server, and no session-directory I/O; content arrives as a parsed patch and comments are published to the Nostr patch thread or copied to the clipboard.

## Technical Approach

The macOS app is already structured as an SPM workspace of feature-module packages (`engineering/apps/macos/Sources/*`) built on SwiftUI + TCA, with `@ObservableState`, `@Dependency`-injected effects, enum-based navigation, `IdentifiedArray`, and TreeSitter highlighting. Most of these modules are platform-agnostic Swift that compile for iOS unchanged. The iOS app is a new app target under `engineering/apps/ios/` that depends on those shared feature modules and supplies an iOS-specific root (`AppFeature`/`AppView`), an adaptive layout reducer, and iOS-only entry/identity/Nostr dependencies.

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| UI framework | SwiftUI (iOS) | Native iOS framework; `NavigationSplitView` adapts to size class automatically; sheets/alerts match iOS conventions. |
| Architecture | TCA | Same as macOS — unidirectional flow, `TestStore` exhaustiveness, `@Dependency` effects. Reuses the reducer/feature design language. |
| Module reuse | Depend on existing macOS feature SPM targets | `SharedModels`, `CodeViewerFeature`, `CommentFeature`, `FileBrowserFeature`, `InspectorFeature`, and `PromptBuilder` are platform-agnostic; reusing them avoids forking the review logic. |
| Adaptive layout | `NavigationSplitView` with `horizontalSizeClass` selection | SwiftUI picks compact (stack) vs expanded (columns) automatically; one view tree reflows both. `FR-crp-ios-adaptive-layout`. |
| Code viewer | Reuse the macOS `CodeViewerFeature` (LazyVStack + TreeSitter) | Already virtualized for 10k-line files and handles wrapping. iOS `ScrollView` performance is adequate for patch diffs (typically far smaller than 10k lines). |
| Clipboard | `UIPasteboard` | iOS system clipboard for Copy. `FR-crp-ios-clipboard`. |
| Persistence | Session data (files/comments/preamble) is not persisted (`NFR-crp-no-data-persistence`); the reviewer identity persists in Keychain via `./identity.md`. Backgrounding handled by keeping the scene alive | `scenePhase` transitions preserve in-memory state across background→resume (`FR-crp-ios-background-handoff`). No session-data disk persistence in v1; identity persistence is specified in `./identity.md`. |
| Identity/Nostr | iOS copies of `RelayClient`, `NostrSigner`, `Bech32`, `PatchReplyMapper`, `NostrEvent` under `engineering/apps/ios/Sources/Dependencies/` | These live under `engineering/apps/macos/` today; duplicating into the iOS target keeps this kickoff from modifying the macOS app. A future refactor can lift them into a shared multiplatform target (see Open Questions). |
| Build system | Xcode + SPM, iOS app target | New `ShepherdiOS` app target in a new `engineering/apps/ios/` Xcode project, depending on the shared SPM feature packages. |
| Minimum target | iOS 17 | Required for modern SwiftUI (`NavigationSplitView` column visibility, `@Observable`, inspector-style layouts). `NFR-crp-ios-min-version`. |
| Language mode | Swift 6, strict concurrency | Matches the macOS package; effect closures capture dependencies explicitly; relay WebSocket callbacks accumulate through a `LockIsolated` box. |

## Project Structure

```
engineering/apps/ios/
├── ShepherdiOS.xcodeproj/          # Xcode project (iOS app target)
├── ShepherdiOSApp/                 # Main app target
│   ├── ShepherdiOSApp.swift        # @main entry, AppFeature store, scene-phase handling
│   ├── AppFeature/
│   │   ├── AppFeature.swift        # Root reducer (iOS shell)
│   │   └── AppView.swift           # Adaptive root view (NavigationSplitView)
│   └── Resources/
│       ├── Assets.xcassets          # App icon, accent color
│       └── ShepherdiOS.entitlements
├── Sources/                        # iOS-only packages
│   ├── Dependencies/
│   │   ├── RelayClient.swift        # in-process Nostr relay client (URLSessionWebSocketTask)
│   │   ├── NostrSigner.swift        # async sign: local Schnorr | NIP-46 bunker
│   │   ├── Bech32.swift             # nsec/npub/nevent1 decode
│   │   ├── PatchReplyMapper.swift   # [NostrEvent] -> [PatchReply]
│   │   ├── PatchParser.swift        # unified diff -> per-file blocks -> tabs
│   │   └── NostrEvent.swift         # NIP-01 event model
│   └── PatchOpenFeature/
│       ├── PatchOpenFeature.swift   # open-patch reducer (fetch, validate, load)
│       └── PatchOpenView.swift      # Open Patch sheet
└── Tests/
    └── …                           # Swift Testing + TCA TestStore
```

The shared feature modules are referenced from `engineering/apps/macos/Sources/` as local SPM dependencies (read-only from the iOS target's perspective).

## Data Model

The iOS app reuses `SharedModels` (`FileNode`, `Comment`, `ReviewContext`, `SyntaxLanguage`, `PromptBuilder`, `SessionData`) unchanged. A patch review session is built in-memory from a parsed patch event, not loaded from `session.json`:

- `PatchReviewSession` — the in-memory session: the parsed per-file diff blocks (each a `FileNode` with diff content), the patch metadata, and the live patch-thread replies. Built by `PatchOpenFeature` on a successful open.
- `PatchMetadata` — full/short event id, author pubkey + resolved display name, commit message, parent short hash, repo coordinate, status (`open` in v1).
- `PatchReply` — reused from the macOS mapper model (author, bot/human, content, timestamp, optional line anchor).

## Component Architecture

- `AppFeature` (iOS) — root reducer. Holds the optional `PatchReviewSession` and the identity state. Presents `EmptyState` or composes `FileBrowserFeature` + `CodeViewerFeature` + `InspectorFeature` (all reused) over the adaptive layout. Drives `PatchOpenFeature` as a sheet.
- `PatchOpenFeature` — owns the Open Patch sheet state (input, fetch/error state), runs the fetch+validate+parse effect, and emits a `sessionLoaded(PatchReviewSession)` action on success.
- Adaptive layout — `AppView` uses `NavigationSplitView` with `.automatic` column visibility; compact width collapses to the stack form, expanded width shows all three columns. Inspector surfaces map to the detail column (expanded) or pushed detail screens (compact) via enum destinations.
- Identity/publish path — see `./shepherd-review.md`.

## State Management

TCA, as macOS. The session is held in `AppFeature.State`; switching files, adding/editing/deleting comments, marking reviewed, and editing the preamble flow through the reused feature reducers. `generatePrompt()` runs as a TCA effect on every comment/preamble mutation (`FR-crp-prompt-generate`). Backgrounding is observed via `@Environment(\.scenePhase)`; on `.background` the state is retained (no discard); on `.active` it is unchanged. A full termination (process death) discards state per `NFR-crp-no-data-persistence`.

## Error Handling

- Patch open: all fetch/validation failures map to a typed `PatchOpenError` rendered as the sheet's inline message (`AC-sri-patch-open-*`). No crash on malformed input.
- Publish: bunker sign failure / no-relay-accepts degrade per `FR-sri-bunker-sign-failure` / `AC-sri-publish-relay-failure`; the local comment is always retained.
- Clipboard: a failed copy surfaces a transient error; non-fatal.

## Performance Considerations

- Patch diffs are typically small (well under 10k lines); the reused virtualized `CodeViewerFeature` is more than adequate. `NFR-crp-large-file-perf` and `NFR-crp-render-time` are inherited; if a pathological patch exceeds thresholds, a warning is shown but the file still loads (matching macOS).
- Relay subscriptions are cancelled as soon as the first event arrives (`FR-sri-patch-open-fetch`) and the live thread subscription is torn down when the review window closes, to avoid lingering WebSocket connections.
- `NFR-crp-ios-memory` and `NFR-crp-ios-launch-time` budgets apply.

## Security Considerations

- A local secret key (`nsec`) is held in memory for the session and never written to unprotected storage; it persists across launches in the iOS Keychain via the Identity feature (`FR-id-ios-keychain-storage`, see `./identity.md`), never in plaintext on disk. The secret key never leaves the device (`NFR-id-key-stays-local`).
- Nostr relay traffic is the only network egress; it carries published replies and subscription reads. No file content leaves the device except as published patch-thread replies (`NFR-crp-client-only`).
- Relay URLs and identity are configured in-app; input is validated before use (bunker URI parse, relay URL scheme).

## Implementation Plan

1. **iOS app target + adaptive shell** — create `engineering/apps/ios/`, the `ShepherdiOS` app target, `AppFeature`/`AppView` with `NavigationSplitView` size-class adaptation, and the Empty State. Wire shared feature modules as SPM dependencies. Unlocks rendering the review surface.
2. **Patch parsing + `PatchOpenFeature`** — `PatchParser` (unified diff → per-file blocks), the Open Patch sheet, fetch/validate effects, `sessionLoaded`. Unlocks opening a patch.
3. **Review composition** — compose `FileBrowserFeature` + `CodeViewerFeature` + `InspectorFeature` over the loaded session; wire prompt generation, copy, comments summary, reviewed tracking, clear. Unlocks the full CRPG surface.
4. **Identity + Nostr dependencies + publishing** — `IdentityFeature` + `KeychainClient` (see `./identity.md`), `RelayClient`, `NostrSigner`, `Bech32`, `PatchReplyMapper`, `PatchOpenFeature` bunker path; patch-thread live subscription and reply publishing (cross-ref `./shepherd-review.md`). Unlocks identity login/create/persist and bidirectional review.
5. **Backgrounding + accessibility + polish** — `scenePhase` preservation, VoiceOver labels, Dynamic Type, keyboard shortcuts, system appearance. Unlocks NFR/AC coverage.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-crp-file-display | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-crp-line-wrap | engineering/apps/macos/Sources/CodeViewerFeature/CodeViewerView.swift | planned |
| FR-crp-syntax-highlight | engineering/apps/macos/Sources/CodeViewerFeature/CodeViewerView.swift | planned |
| FR-crp-line-comment-create | engineering/apps/macos/Sources/CommentFeature/CommentFeature.swift | planned |
| FR-crp-line-comment-edit | engineering/apps/macos/Sources/CommentFeature/CommentFeature.swift | planned |
| FR-crp-line-comment-delete | engineering/apps/macos/Sources/CommentFeature/CommentFeature.swift | planned |
| FR-crp-comment-indicator | engineering/apps/macos/Sources/CommentFeature/CommentBubbleView.swift | planned |
| FR-crp-comment-count | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-crp-prompt-preamble | engineering/apps/macos/Sources/InspectorFeature/InspectorView.swift | planned |
| FR-crp-prompt-generate | engineering/apps/macos/Sources/SharedModels/PromptBuilder.swift | planned |
| FR-crp-prompt-preview | engineering/apps/macos/Sources/InspectorFeature/InspectorView.swift | planned |
| FR-crp-prompt-copy | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-crp-prompt-format | engineering/apps/macos/Sources/SharedModels/PromptBuilder.swift | planned |
| FR-crp-clear-session | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-crp-filename-display | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-crp-line-range-comment | engineering/apps/macos/Sources/CommentFeature/CommentFeature.swift | planned |
| FR-crp-comment-navigation | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-crp-multi-file-nav | engineering/apps/macos/Sources/FileBrowserFeature/FileBrowserFeature.swift | planned |
| FR-crp-multi-file-remove | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-crp-multi-file-prompt | engineering/apps/macos/Sources/SharedModels/PromptBuilder.swift | planned |
| FR-crp-multi-file-prompt-format | engineering/apps/macos/Sources/SharedModels/PromptBuilder.swift | planned |
| FR-crp-review-context-receive | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | unimplemented |
| FR-crp-review-context-display | engineering/apps/macos/Sources/InspectorFeature/InspectorView.swift | planned |
| FR-crp-review-context-overall | engineering/apps/macos/Sources/InspectorFeature/InspectorView.swift | planned |
| FR-crp-review-context-per-file | engineering/apps/macos/Sources/InspectorFeature/InspectorView.swift | planned |
| FR-crp-review-context-collapsible | engineering/apps/macos/Sources/InspectorFeature/InspectorView.swift | planned |
| FR-crp-comment-summary | engineering/apps/macos/Sources/InspectorFeature/InspectorView.swift | planned |
| FR-crp-active-file-path | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-crp-file-tooltip | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-crp-file-reviewed-toggle | engineering/apps/macos/Sources/FileBrowserFeature/FileBrowserFeature.swift | planned |
| FR-crp-file-reviewed-visual | engineering/apps/macos/Sources/FileBrowserFeature/FileBrowserView.swift | planned |
| FR-crp-file-reviewed-grouping | engineering/apps/macos/Sources/FileBrowserFeature/FileBrowserFeature.swift | planned |
| FR-crp-file-reviewed-progress | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-crp-file-reviewed-persistence | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-crp-ios-patch-only-entry | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-crp-ios-adaptive-layout | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-crp-ios-system-appearance | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppView.swift | planned |
| FR-crp-ios-clipboard | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |
| FR-crp-ios-background-handoff | engineering/apps/ios/ShepherdiOSApp/AppFeature/AppFeature.swift | planned |

Notes:
- `FR-crp-file-load`, `FR-crp-done-action`, `FR-crp-prompt-handoff`, `FR-crp-session-identity`, `FR-crp-panel-resize`, `FR-sc-file-api`, `FR-sc-session-id` do not apply on iOS (see `../../product/ios/code-review-prompt.md`); they are omitted from the Code Map intentionally.
- `FR-crp-review-context-receive` is marked `unimplemented` because an in-app-opened patch has no agent context to receive; the graceful-missing behavior of the reused inspector covers it. It remains in the shared spec.
- `FR-crp-multi-file-load` is realized by the patch-open load path (`FR-sri-patch-open-load`), not a user-initiated load; see `./shepherd-review.md`.

## Open Questions

1. **Shared Nostr dependencies**: `RelayClient`/`NostrSigner`/`Bech32`/`PatchReplyMapper`/`NostrEvent` currently live under `engineering/apps/macos/`. Duplicating them into `engineering/apps/ios/` for v1 avoids touching the macOS app in this kickoff, but diverges the two copies. A follow-up refactor should lift them into a shared multiplatform SPM target depended on by both apps. Deferred — out of scope for this kickoff.
2. **Feature-module iOS compatibility**: the assumption that `CodeViewerFeature`, `CommentFeature`, `FileBrowserFeature`, and `InspectorFeature` compile for iOS unchanged needs verification at implementation time. Any macOS-only imports (e.g. `AppKit`, `NSWindow`) discovered are isolated behind `#if os(macOS)` / `#if os(iOS)` guards or moved to the app shell. Flagged for the first build.
3. **TreeSitter on iOS**: `swift-tree-sitter` runs on iOS, but the grammar-bundle packaging may differ from macOS. Verify the 13-language bundle builds for an iOS app target. Flagged for the first build.
