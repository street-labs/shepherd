---
product-hash: 155691b3451808cebd8df33b45ff1932bf1520bf74c4026c77b8e5a519566195
product-slugs: [AC-pa-approval-tip, AC-pa-capabilities, AC-pa-comment-publishes, AC-pa-line-comment, AC-pa-live-replies, AC-pa-merge-gate, AC-pa-merge-publishes, AC-pa-stale, FR-pa-capabilities, FR-pa-comment, FR-pa-merge, FR-pa-review, FR-pa-threads, NFR-pa-nostr-only, NFR-pa-publish-window]
---

# PR Actions — iOS Design

> Based on requirements in `../../product/pr-actions.md` and `../../product/ios/pr-actions.md`
> Lives inside the existing iOS PR review flow; no new screens.

- **Verdicts** (`FR-pa-review`) — toolbar menu ("Review…") in the PR review screen opens a sheet: verdict segmented control (Approve / Request changes), optional markdown summary, read-only tip commit, Submit. Same binding and stale labeling as macOS.
- **Comments** (`FR-pa-comment`) — the existing reply composer publishes on submit; inline bubbles gain "Post to PR" with posted/failed indicators and retry, identical semantics to macOS.
- **Merge** (`FR-pa-merge`) — Merge button in the metadata section, enabled only when the gate passes; disabled state exposes the gate reason via a popover; confirm dialog before publishing kind `1631`.
- **Live replies** (`FR-pa-threads`) — same in-place thread updates as the existing iOS patch-thread loop; "N new replies" pill when scrolled up.
- **Capability gating** (`FR-pa-capabilities`) — identical to macOS: no identity disables review/post controls, non-maintainers see no Merge control.
- Touch targets meet the 44pt minimum; sheets use the platform sheet presentation.
