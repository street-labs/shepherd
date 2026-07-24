# Traceability Index

This file maps every requirement slug to all the places it's referenced across the project. When a requirement changes, look it up here to find everything that needs updating.

**Every agent must keep this file up to date when creating or referencing requirement slugs.**

## How to Read This Index

Each entry lists a requirement slug and every artifact that references it:

- **Defined in**: The product spec where the requirement lives
- **Design**: Design spec(s) that address it
- **Engineering**: Engineering spec(s) and code file(s) that implement it
- **QA**: Test case(s) that cover it

## Index

### `FR-crp-file-load`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-paste-happy`, `TC-crp-macos-load-open-panel-single`, `TC-crp-macos-load-drag-drop-single`, `TC-crp-macos-binary-rejected-open-panel`

### `FR-crp-file-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-display-line-numbers`, `TC-crp-macos-file-display-preserves-whitespace`

### `FR-crp-syntax-highlight`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-syntax-highlight-detected`, `TC-crp-macos-syntax-highlight-all-languages`, `TC-crp-macos-syntax-highlight-fallback`

### `FR-crp-line-comment-create`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-single-line`, `TC-crp-macos-add-comment-gutter-indicator`

### `FR-crp-line-comment-edit`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-edit-comment-happy`, `TC-crp-macos-edit-comment-stays-on-line`

### `FR-crp-line-comment-delete`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-delete-comment-happy`, `TC-crp-macos-delete-comment-gutter-clears`

### `FR-crp-comment-indicator`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-gutter-indicator`, `TC-crp-macos-delete-comment-gutter-clears`

### `FR-crp-comment-count`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-comment-count-global`, `TC-crp-macos-comment-count-increments`

### `FR-crp-prompt-preamble`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-overall-comment-label`, `TC-crp-macos-overall-comment-in-prompt`

### `FR-crp-prompt-generate`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-auto-regenerates`

### `FR-crp-prompt-preview`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-preview-live`, `TC-crp-macos-prompt-no-comments-placeholder`

### `FR-crp-prompt-copy`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-copy-clipboard-happy`, `TC-crp-macos-copy-toolbar-animation`

### `FR-crp-prompt-format`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-structure-no-preamble`

### `FR-crp-clear-session`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-clear-confirmation-dialog`, `TC-crp-macos-clear-no-confirm-empty`, `TC-crp-macos-multi-file-clear-all`

### `FR-crp-filename-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: —

### `FR-crp-line-range-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-line-range`, `TC-crp-macos-add-comment-line-range-gutter`

### `FR-crp-comment-navigation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-nav-next`, `TC-crp-macos-comment-nav-prev`, `TC-crp-macos-comment-nav-wrap`

### `NFR-crp-large-file-perf`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-large-file-scroll-smooth`, `TC-crp-macos-large-file-load-time`

### `NFR-crp-render-time`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-render-time-under-500ms`

### `NFR-crp-prompt-gen-time`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-gen-time-under-300ms`

### `NFR-crp-client-only`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-no-network-traffic`

### `NFR-crp-browser-support`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-crp-responsive-layout`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-crp-accessibility-keyboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-keyboard-add-comment`, `TC-crp-macos-keyboard-open-file`, `TC-crp-macos-keyboard-copy-prompt`

### `NFR-crp-no-data-persistence`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: —

### `AC-crp-load-paste`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-paste-happy`, `TC-crp-macos-load-paste-empty-clipboard`

### `AC-crp-load-upload`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-open-panel-single`, `TC-crp-macos-load-open-panel-multi`

### `AC-crp-load-drag-drop`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-drag-drop-single`, `TC-crp-macos-load-drag-drop-multi`

### `AC-crp-syntax-highlight-detected`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-syntax-highlight-detected`, `TC-crp-macos-syntax-highlight-fallback`

### `AC-crp-add-comment-single-line`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-single-line`, `TC-crp-macos-add-comment-gutter-indicator`

### `AC-crp-add-comment-line-range`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-line-range`, `TC-crp-macos-add-comment-line-range-gutter`

### `AC-crp-edit-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-edit-comment-happy`, `TC-crp-macos-edit-comment-stays-on-line`

### `AC-crp-delete-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-delete-comment-happy`, `TC-crp-macos-delete-comment-gutter-clears`

### `AC-crp-generate-prompt-structure`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-structure-no-preamble`

### `AC-crp-generate-prompt-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-no-comments-placeholder`, `TC-crp-macos-prompt-clears-after-delete-all`

### `AC-crp-copy-clipboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-copy-clipboard-happy`, `TC-crp-macos-copy-toolbar-animation`

### `AC-crp-preview-matches-copy`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-preview-matches-copy`

### `AC-crp-clear-confirmation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-clear-confirmation-dialog`, `TC-crp-macos-clear-cancel-preserves`

### `AC-crp-clear-no-confirm-empty`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-clear-no-confirm-empty`

### `AC-crp-empty-state`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-empty-state-instructions`, `TC-crp-macos-empty-state-buttons-disabled`

### `AC-crp-large-file-scroll`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-large-file-scroll-smooth`

### `AC-crp-comment-navigation-next`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-nav-next`, `TC-crp-macos-comment-nav-prev`, `TC-crp-macos-comment-nav-wrap`

### `AC-crp-keyboard-add-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-keyboard-add-comment`

### `AC-crp-binary-file-rejected`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-binary-rejected-open-panel`, `TC-crp-macos-binary-rejected-drag-drop`

### `FR-sc-invoke-command`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-file-resolution`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-file-validation`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-app-serve`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-browser-open`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-auto-load-file`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-file-api`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-install`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: `scripts/install-command.sh`
- **QA**: —

### `FR-sc-server-shutdown`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-output-feedback`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-launcher-script`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: —
- **QA**: —

### `NFR-sc-launch-speed`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-sc-no-global-deps`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-sc-cross-platform`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-sc-localhost-only`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-sc-no-telemetry`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-sc-minimal-footprint`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-launch-happy-path`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-absolute-path`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-file-not-found`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-binary-file-rejected`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-permission-denied`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-directory-rejected`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-no-args-usage`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-large-file-warning`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-server-reuse`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-server-manual-stop`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-install-global`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: `scripts/install-command.sh`
- **QA**: —

### `AC-sc-install-symlink`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-session-clear-on-new-file`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-cross-platform-open`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-standalone-window`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-warm-launch-2s`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: —
- **QA**: —

### `AC-sc-cold-launch-8s`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: —
- **QA**: —

### `AC-sc-single-tool-call`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: —
- **QA**: —

### `FR-sc-mac-invoke-command`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A (reuses existing macOS CRPG window)
- **Engineering**: `engineering/macos/slash-command.md` -> `.claude/commands/shepherd.md`, `.config/opencode/skills/shepherd/SKILL.md`
- **QA**: TBD

### `FR-sc-mac-launch`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `scripts/shepherd-launch.sh`, `engineering/apps/macos/ShepherdApp/ShepherdApp.swift`
- **QA**: TBD

### `FR-sc-mac-session-handoff`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `scripts/shepherd-launch.sh`, `engineering/apps/macos/Sources/Dependencies/SessionClient.swift`
- **QA**: TBD

### `FR-sc-mac-prebuild`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `scripts/install-command.sh`
- **QA**: TBD

### `AC-sc-mac-launches-app`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `scripts/shepherd-launch.sh`
- **QA**: TBD

### `AC-sc-mac-no-server`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `scripts/shepherd-launch.sh`
- **QA**: TBD

### `AC-sc-mac-prompt-roundtrip`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `engineering/apps/macos/Sources/Dependencies/SessionClient.swift`, `.claude/commands/shepherd.md`
- **QA**: TBD

### `AC-sc-mac-coexists`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `scripts/install-command.sh`, `.claude/commands/shepherd.md`
- **QA**: TBD

### `AC-sc-mac-prebuild-fast`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `scripts/install-command.sh`
- **QA**: TBD

### `AC-sc-mac-prebuild`
- **Defined in**: `product/macos/slash-command.md`
- **Design**: N/A
- **Engineering**: `engineering/macos/slash-command.md` -> `scripts/install-command.sh`
- **QA**: TBD


### `FR-diff-mode-toggle`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-mode-availability`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-baseline-fetch`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-compute`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-display`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-collapse`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-expand`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-comment-create`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-comment-on-range`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-prompt-format`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-empty-state`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-diff-refresh`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-diff-compute-perf`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-diff-render-perf`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-diff-client-compute`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-diff-baseline-fetch-speed`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-diff-accessibility`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-toggle-to-diff`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-toggle-to-file`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-collapse-default`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-expand-section`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-comment-added-line`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-comment-removed-line`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-comment-context-line`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-prompt-includes-diff`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-no-git-history`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-no-changes`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-paste-upload-disabled`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-line-numbers`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-syntax-highlight`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-refresh-updates`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-switch-clears-comments`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-comment-range`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-diff-expand-then-comment`
- **Defined in**: `product/diff-view.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sr-changeset-detection`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `FR-sr-file-filtering`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `FR-sr-file-list-display`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `FR-sr-iteration-loop`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`, `TC-srm-interactive-prompt-options`

### `FR-sr-completion-summary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `FR-sr-command-file`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-coexistence`, `TC-srm-install-symlink`

### `FR-sr-install`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-install-symlink`, `TC-srm-install-degraded-no-swift`, `TC-srm-install-git-pull`

### `FR-sr-scope-argument`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `FR-sr-multi-file-launch`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`, `TC-srm-launcher-context-flag`

### `FR-sr-per-file-context`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-context-in-app`, `TC-srm-context-tab-switch`

### `FR-sr-changeset-overview`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-context-in-app`

### `FR-sr-priority-ordering`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-priority-tab-order`

### `FR-sr-feedback-collection`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`, `TC-srm-interactive-prompt-options`

### `FR-sr-git-required`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-not-git-repo`

### `NFR-sr-startup-speed`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `NFR-sr-no-dependencies`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: —

### `NFR-sr-agent-native`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `NFR-sr-cross-platform`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: —

### `AC-sr-happy-path`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-filters-lockfiles`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-filters-generated`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-filters-binary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-includes-config`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-excludes-deleted`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-skip-file`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-skip-file`

### `AC-sr-quit-early`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-quit-early`

### `AC-sr-no-changes`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-no-changes`

### `AC-sr-all-filtered`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-all-filtered`

### `AC-sr-not-git-repo`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-not-git-repo`

### `AC-sr-invokes-shepherd`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-list-command`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-context-in-app`

### `AC-sr-completion-summary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-sorted-file-list`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-priority-tab-order`

### `AC-sr-batch-open`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`, `TC-srm-priority-tab-order`

### `AC-sr-unified-prompt`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`, `TC-srm-skip-file`

### `AC-sr-install-global`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-install-symlink`

### `FR-crp-done-action`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-sends-prompt`, `TC-crp-macos-done-auto-close-reliable`, `TC-crp-macos-done-disabled-no-comments`, `TC-crp-macos-done-hidden-standalone`

### `FR-crp-prompt-handoff`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-sends-prompt`, `TC-crp-macos-done-fallback-clipboard`

### `AC-crp-done-sends-prompt`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-sends-prompt`

### `AC-crp-done-confirmation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-sends-prompt`

### `AC-crp-done-auto-close`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-auto-close-reliable`

### `AC-crp-done-fallback-clipboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-fallback-clipboard`

### `AC-crp-done-disabled-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-disabled-no-comments`

### `AC-crp-done-standalone-hidden`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-hidden-standalone`

### `FR-sc-prompt-receive`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-prompt-output-api`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-prompt-cleanup`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-sc-watcher-low-overhead`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-prompt-received`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-prompt-watcher-timeout`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-prompt-cleanup-stale`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-prompt-output-api-success`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-prompt-output-api-localhost-only`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-detect-markdown`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-render-toggle`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-render-commonmark`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-render-styling`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-element-id`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-rendered-comment-create`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-rendered-comment-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-switch-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-raw-diff-unchanged`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-rendered-diff-display`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-rendered-diff-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-mdr-rendered-diff-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-mdr-render-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-mdr-render-scroll-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-mdr-rendered-diff-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-mdr-xss-safety`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-mdr-client-only`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-mdr-accessibility`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-toggle-appears`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-toggle-hidden-non-md`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-render-basic`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-render-gfm`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-render-code-blocks`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-raw-unchanged`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-comment-rendered-element`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-comment-heading`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-comment-prompt-format`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-switch-clears-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-switch-no-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-rendered-diff-additions`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-rendered-diff-removals`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-rendered-diff-modifications`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-rendered-diff-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-rendered-diff-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-html-sanitized`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-large-file-renders`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-keyboard-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-mdr-diff-fallback`
- **Defined in**: `product/markdown-render.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-dm-system-preference`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-dm-manual-toggle`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-dm-persistence`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-dm-realtime-tracking`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-dm-full-surface-coverage`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-dm-css-custom-properties`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-dm-no-fouc`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-dm-smooth-transition`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-dm-syntax-highlight-both-themes`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-dm-contrast-ratios`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `NFR-dm-no-performance-impact`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-default-respects-system`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-default-light-system`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-toggle-to-dark`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-toggle-to-light`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-toggle-to-system`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-persistence-survives-reload`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-persistence-system-survives-reload`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-realtime-os-change`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-manual-ignores-os`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-syntax-highlight-dark`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-syntax-highlight-light`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-all-surfaces-themed`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-diff-view-themed`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-drop-zone-themed`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-dialog-themed`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-no-fouc`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-localstorage-unavailable`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-dm-keyboard-toggle`
- **Defined in**: `product/dark-mode.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-crp-multi-file-load`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-load-adds`, `TC-crp-macos-multi-file-drop-multiple`

### `FR-crp-multi-file-nav`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-switch-preserves`, `TC-crp-macos-file-tree-disambiguates-same-name`, `TC-crp-macos-file-tree-collapse-expand`

### `FR-crp-multi-file-remove`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-remove-with-comments`, `TC-crp-macos-multi-file-remove-no-comments`, `TC-crp-macos-multi-file-remove-last-empty`

### `FR-crp-multi-file-prompt`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-prompt-structure`

### `FR-crp-multi-file-prompt-format`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-prompt-structure`, `TC-crp-macos-multi-file-prompt-omits-uncommented`

### `AC-crp-multi-file-load-adds`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-load-adds`

### `AC-crp-multi-file-drop-multiple`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-drop-multiple`

### `AC-crp-multi-file-nav-preserves-state`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-switch-preserves`

### `AC-crp-multi-file-remove-with-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-remove-with-comments`

### `AC-crp-multi-file-remove-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-remove-no-comments`

### `AC-crp-multi-file-prompt-structure`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-prompt-structure`

### `AC-crp-multi-file-prompt-omits-uncommented`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-prompt-omits-uncommented`

### `AC-crp-multi-file-comment-count`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-comment-count-global`

### `AC-crp-multi-file-clear-all`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-clear-all`

### `AC-crp-multi-file-empty-after-remove-last`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-remove-last-empty`

### `AC-crp-file-path-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tree-disambiguates-same-name`

### `AC-crp-file-path-single-dir`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tree-single-dir`

### `FR-sr-context-handoff`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-launcher-context-flag`, `TC-srm-launcher-no-context-flag`, `TC-srm-context-in-app`

### `AC-sr-context-in-crpg`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-context-in-app`, `TC-srm-context-tab-switch`, `TC-srm-context-graceful-missing`

### `AC-sr-auto-open`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-sr-interactive-prompt`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-interactive-prompt-options`

### `FR-crp-review-context-receive`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-graceful-missing`

### `FR-crp-review-context-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-per-file-visible`, `TC-crp-macos-context-neutral-vs-review`

### `FR-crp-review-context-overall`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-sidebar-collapse`

### `FR-crp-review-context-per-file`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-per-file-visible`, `TC-crp-macos-context-per-file-initial`, `TC-crp-macos-context-per-file-switches`

### `AC-crp-context-overall-visible`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-overall-visible`

### `AC-crp-context-per-file-visible`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-per-file-visible`

### `AC-crp-context-per-file-switches`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-per-file-switches`

### `AC-crp-context-neutral-vs-review`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-neutral-vs-review`

### `AC-crp-context-graceful-missing`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-graceful-missing`

### `AC-crp-context-readonly`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-readonly`

### `FR-crp-file-reviewed-toggle`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-mark-reviewed-happy`, `TC-crp-macos-unmark-reviewed-happy`

### `FR-crp-file-reviewed-visual`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-mark-reviewed-happy`, `TC-crp-macos-unmark-reviewed-happy`

### `FR-crp-file-reviewed-grouping`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-grouping-tree`

### `FR-crp-file-reviewed-progress`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-progress-count`

### `FR-crp-file-reviewed-persistence`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-survives-tab-switch`, `TC-crp-macos-reviewed-clear-session-resets`

### `AC-crp-file-mark-reviewed`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-mark-reviewed-happy`

### `AC-crp-file-unmark-reviewed`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-unmark-reviewed-happy`

### `AC-crp-file-reviewed-grouping`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-grouping-tree`

### `AC-crp-file-reviewed-progress-count`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-progress-count`

### `AC-crp-file-reviewed-survives-tab-switch`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-survives-tab-switch`

### `AC-crp-file-reviewed-with-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-independent-of-comments`

### `AC-crp-file-reviewed-clear-session`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-clear-session-resets`

### `FR-crp-review-context-collapsible`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-sidebar-collapse`

### `AC-crp-context-sidebar-collapse`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-sidebar-collapse`

### `AC-crp-overall-comment-label`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-overall-comment-label`

### `AC-crp-overall-comment-in-prompt`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-overall-comment-in-prompt`

### `FR-crp-comment-summary`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-summary-shows-all`, `TC-crp-macos-comment-summary-realtime`, `TC-crp-macos-comment-summary-empty`

### `AC-crp-comment-summary-shows-all`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-summary-shows-all`

### `AC-crp-comment-summary-realtime`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-summary-realtime`

### `AC-crp-comment-summary-empty`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-summary-empty`

### `FR-crp-line-wrap`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-toggle-on`, `TC-crp-macos-line-wrap-toggle-off`, `TC-crp-macos-line-wrap-default-on`, `TC-crp-macos-line-wrap-persists-session`

### `AC-crp-line-wrap-toggle`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-toggle-on`, `TC-crp-macos-line-wrap-toggle-off`

### `AC-crp-line-wrap-preserves-line-numbers`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-preserves-line-numbers`

### `AC-crp-line-wrap-comment-target`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-comment-target`

### `AC-crp-line-wrap-default-on`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-default-on`

### `AC-crp-line-wrap-persists-session`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-persists-session`

### `FR-sc-session-id`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-dynamic-port`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-session-scoped-output`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-concurrent-windows`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-sc-session-cleanup`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-crp-session-identity`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-session-identity-title`, `TC-crp-macos-session-identity-standalone`

### `AC-sc-concurrent-sessions`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `AC-sc-session-output-isolation`
- **Defined in**: `product/slash-command.md`
- **Design**: —
- **Engineering**: —
- **QA**: —

### `FR-crp-panel-resize`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-drag`, `TC-crp-macos-panel-resize-min-max`, `TC-crp-macos-panel-resize-double-click-reset`

### `FR-crp-active-file-path`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-active-file-path-visible`, `TC-crp-macos-active-file-path-switches`, `TC-crp-macos-active-file-path-hidden-single`

### `FR-crp-file-tooltip`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tooltip-full-path`, `TC-crp-macos-file-tooltip-reviewed-status`

### `AC-crp-panel-resize-drag`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-drag`

### `AC-crp-panel-resize-bounds`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-min-max`

### `AC-crp-panel-resize-double-click`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-double-click-reset`

### `AC-crp-panel-resize-persists`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-persists-file-switch`

### `AC-crp-panel-resize-keyboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: —
- **Engineering**: —
- **QA**: _coverage TBD_

### `AC-crp-active-file-path-visible`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-active-file-path-visible`

### `AC-crp-active-file-path-switches`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-active-file-path-switches`

### `AC-crp-active-file-path-single-file`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-active-file-path-hidden-single`

### `AC-crp-file-tooltip-full-path`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tooltip-full-path`

### `AC-crp-file-tooltip-reviewed`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tooltip-reviewed-status`
### `FR-crp-macos-window-management`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-window-multi-session`, `TC-crp-macos-window-restore-geometry`, `TC-crp-macos-window-min-size`, `TC-crp-macos-window-fits-screen`, `TC-crp-macos-close-last-window-keeps-running`

### `FR-crp-macos-menu-bar`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-menu-copy-disabled`, `TC-crp-macos-menu-shortcuts-displayed`, `TC-crp-macos-menu-standard-items`

### `FR-crp-macos-keyboard-shortcuts`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-keyboard-open-file`, `TC-crp-macos-keyboard-copy-prompt`, `TC-crp-macos-keyboard-close-window`, `TC-crp-macos-keyboard-undo-redo`

### `FR-crp-macos-file-open-panel`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-open-panel-single`, `TC-crp-macos-load-open-panel-multi`

### `FR-crp-macos-drag-drop-finder`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-drag-drop-single`, `TC-crp-macos-load-drag-drop-multi`, `TC-crp-macos-drag-drop-finder-path`

### `FR-crp-macos-clipboard`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-copy-clipboard-happy`

### `FR-crp-macos-system-appearance`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-appearance-follows-system`, `TC-crp-macos-no-appearance-toggle`

### `FR-crp-macos-auto-close`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-auto-close-reliable`

### `FR-crp-macos-slash-command-launch`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-slash-command-launch-session`, `TC-crp-macos-window-deduplicate`

### `FR-crp-macos-standalone-mode`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-hidden-standalone`, `TC-crp-macos-standalone-open-panel`

### `FR-crp-macos-sandboxed-file-access`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-permission-error`

### `FR-crp-macos-distribution`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-signed-notarized`

### `NFR-crp-macos-launch-time`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-launch-cold-time`

### `NFR-crp-macos-memory`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-memory-typical-session`, `TC-crp-macos-memory-idle`

### `NFR-crp-macos-min-version`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-min-version-enforced`

### `AC-crp-macos-window-open`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-window-multi-session`

### `AC-crp-macos-window-restore`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-window-restore-geometry`

### `AC-crp-macos-window-deduplicate`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-window-deduplicate`

### `AC-crp-macos-menu-copy-disabled`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-menu-copy-disabled`

### `AC-crp-macos-menu-shortcuts`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-menu-shortcuts-displayed`

### `AC-crp-macos-open-panel-multi`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-open-panel-multi`

### `AC-crp-macos-drag-drop-finder-path`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-drag-drop-finder-path`

### `AC-crp-macos-appearance-follows-system`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-appearance-follows-system`

### `AC-crp-macos-no-appearance-toggle`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-no-appearance-toggle`

### `AC-crp-macos-auto-close-reliable`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-auto-close-reliable`

### `AC-crp-macos-slash-command-launch-session`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-slash-command-launch-session`

### `AC-crp-macos-standalone-no-done`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-hidden-standalone`

### `AC-crp-macos-standalone-open-panel`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-standalone-open-panel`

### `AC-crp-macos-file-permission-error`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-permission-error`

### `AC-crp-macos-signed-notarized`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-signed-notarized`

### `AC-crp-macos-launch-cold`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-launch-cold-time`

### `AC-crp-macos-memory-typical`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-memory-typical-session`

### `AC-crp-macos-min-version-enforced`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-min-version-enforced`

### `AC-crp-macos-multi-window-independent`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-window-independent`

### `AC-crp-macos-close-last-window`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-close-last-window-keeps-running`

### `FR-srm-coexists`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `scripts/install-command.sh`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-coexistence`

### `FR-srm-command-file`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `.claude/commands/shepherd-review.md`, `.config/opencode/skills/shepherd-review/SKILL.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-coexistence`, `TC-srm-install-symlink`

### `FR-srm-multi-file-launch`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `scripts/shepherd-launch.sh`, `.claude/commands/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`, `TC-srm-launcher-context-flag`

### `FR-srm-context-handoff`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `scripts/shepherd-launch.sh`, `.claude/commands/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-launcher-context-flag`, `TC-srm-launcher-no-context-flag`, `TC-srm-context-in-app`

### `FR-srm-install`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `scripts/install-command.sh`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-install-symlink`, `TC-srm-install-degraded-no-swift`, `TC-srm-install-git-pull`

### `NFR-srm-launch-budget`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `NFR-srm-no-server`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-no-server`

### `NFR-srm-platform-restriction`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-binary-missing-error`, `TC-srm-install-degraded-no-swift`

### `AC-srm-coexists`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-coexistence`

### `AC-srm-batch-open-native`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`, `TC-srm-priority-tab-order`

### `AC-srm-no-server`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-no-server`

### `AC-srm-context-in-app`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`, `TC-srm-context-in-app`, `TC-srm-context-tab-switch`, `TC-srm-context-graceful-missing`

### `AC-srm-session-isolation`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-session-isolation`

### `AC-srm-prompt-roundtrip`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-happy-path`

### `AC-srm-cancel`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-cancel-keeps-window`, `TC-srm-interactive-prompt-options`

### `AC-srm-install-symlink`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-install-symlink`

### `AC-srm-install-degraded`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-install-degraded-no-swift`

### `AC-srm-install-git-pull`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-install-git-pull`

### `FR-srm-scope-modes`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `.claude/commands/shepherd-review.md`, `.config/opencode/skills/shepherd-review/SKILL.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-default-scope`, `TC-srm-scope-invalid`, `TC-srm-branch-scope`, `TC-srm-commit-scope`, `TC-srm-range-scope`

### `FR-srm-branch-scope`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `.claude/commands/shepherd-review.md`, `.config/opencode/skills/shepherd-review/SKILL.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-branch-scope`

### `FR-srm-commit-scope`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `.claude/commands/shepherd-review.md`, `.config/opencode/skills/shepherd-review/SKILL.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-commit-scope`

### `FR-srm-range-scope`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `.claude/commands/shepherd-review.md`, `.config/opencode/skills/shepherd-review/SKILL.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-range-scope`

### `FR-srm-commit-mode-no-untracked`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `.claude/commands/shepherd-review.md`, `.config/opencode/skills/shepherd-review/SKILL.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-branch-scope`, `TC-srm-commit-scope`, `TC-srm-range-scope`

### `FR-srm-no-blank-window`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`, `.claude/commands/shepherd-review.md`, `.config/opencode/skills/shepherd-review/SKILL.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-empty-no-launch`, `TC-srm-no-changes`

### `AC-srm-default-scope`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-default-scope`

### `AC-srm-branch-scope`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-branch-scope`

### `AC-srm-commit-scope`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-commit-scope`

### `AC-srm-range-scope`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-range-scope`

### `AC-srm-commit-excludes-untracked`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-branch-scope`, `TC-srm-commit-scope`, `TC-srm-range-scope`

### `AC-srm-empty-no-launch`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-empty-no-launch`, `TC-srm-no-changes`

### `FR-srm-identity-load`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-identity-load`, `TC-srm-identity-no-key`, `TC-srm-bunker-uri-malformed`

### `FR-srm-event-sign`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-comment-publish`, `TC-srm-signer-unit`, `TC-srm-bunker-sign`

### `FR-srm-event-publish`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-comment-publish`, `TC-srm-publish-relay-failure`

### `FR-srm-comment-publish-on-submit`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-comment-publish`, `TC-srm-comment-publish-no-identity`

### `FR-srm-reply-to-reply`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-reply-to-reply`, `TC-sr-patch-reply-respond`

### `FR-srm-identity-indicator`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-identity-indicator`, `TC-srm-identity-no-key`, `TC-srm-bunker-identity-indicator`

### `AC-srm-identity-load`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-identity-load`, `TC-srm-identity-no-key`

### `AC-srm-comment-publish`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-comment-publish`, `TC-srm-comment-publish-no-identity`

### `AC-srm-reply-to-reply`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-reply-to-reply`

### `AC-srm-publish-no-dup`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-publish-no-dup`

### `AC-srm-publish-relay-failure`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-publish-relay-failure`

### `FR-srm-bunker-connect`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-bunker-connect`, `TC-srm-bunker-uri-malformed`, `TC-srm-nip44-unit`

### `FR-srm-bunker-sign-failure`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-bunker-sign-failure`

### `AC-srm-bunker-connect`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-bunker-connect`, `TC-srm-bunker-uri-malformed`

### `AC-srm-bunker-sign`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-bunker-sign`

### `AC-srm-bunker-sign-failure`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-bunker-sign-failure`

### `FR-srm-patch-open-entry`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`; `engineering/apps/macos/Sources/AppFeature/FileDropZoneView.swift`, `engineering/apps/macos/Sources/OpenPatchFeature/OpenPatchView.swift` (planned)
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-happy`

### `FR-srm-patch-open-input`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`; `engineering/apps/macos/Sources/OpenPatchFeature/OpenPatchFeature.swift`, `engineering/apps/macos/Sources/Dependencies/NIP19Decode.swift` (planned)
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-nevent`, `TC-srm-patch-open-invalid-id`

### `FR-srm-patch-open-fetch`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`; `engineering/apps/macos/Sources/OpenPatchFeature/OpenPatchFeature.swift`, `engineering/apps/macos/Sources/Dependencies/RelayClient.swift` (planned)
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-not-found`, `TC-srm-patch-open-wrong-kind`, `TC-srm-patch-open-bad-diff`, `TC-srm-patch-open-no-relays`

### `FR-srm-patch-open-load`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`; `engineering/apps/macos/Sources/AppFeature/AppFeature.swift`, `engineering/apps/macos/Sources/SharedModels/PatchDiffSplitter.swift`, `engineering/apps/macos/Sources/SharedModels/FileNode.swift` (planned)
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-happy`, `TC-srm-patch-open-splitter-unit`

### `AC-srm-patch-open-happy`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-happy`, `TC-srm-patch-open-splitter-unit`

### `AC-srm-patch-open-nevent`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-nevent`

### `AC-srm-patch-open-invalid-id`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-invalid-id`

### `AC-srm-patch-open-not-found`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-not-found`

### `AC-srm-patch-open-wrong-kind`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-wrong-kind`

### `AC-srm-patch-open-bad-diff`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-bad-diff`

### `AC-srm-patch-open-no-relays`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-no-relays`

### `AC-srm-patch-open-activates-thread`
- **Defined in**: `product/macos/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-patch-open-activates-thread`

### `FR-mdr-detect-markdown`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-toggle-appears-markdown`, `TC-mdr-toggle-hidden-typescript`

### `FR-mdr-render-toggle`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-toggle-appears-markdown`, `TC-mdr-switch-no-comments-immediate`

### `FR-mdr-render-commonmark`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-render-basic-commonmark`, `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough`, `TC-mdr-render-code-blocks-syntax`

### `FR-mdr-render-styling`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-render-basic-commonmark`, `TC-mdr-render-code-blocks-syntax`

### `FR-mdr-element-id`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-comment-heading-anchors-line`

### `FR-mdr-rendered-comment-create`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-comment-paragraph-hover`, `TC-mdr-comment-paragraph-submit`

### `FR-mdr-rendered-comment-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-comment-heading-anchors-line`, `TC-mdr-comment-prompt-raw-source`

### `FR-mdr-switch-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-switch-rendered-to-raw-confirm`, `TC-mdr-switch-no-comments-immediate`

### `FR-mdr-raw-diff-unchanged`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-raw-unchanged-syntax-highlight`

### `FR-mdr-rendered-diff-display`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-added-paragraph-green`, `TC-mdr-diff-removed-paragraph-strikethrough`, `TC-mdr-diff-modified-word-level`, `TC-mdr-diff-fallback-80-percent-changed`

### `FR-mdr-rendered-diff-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-comment-modified-element`

### `FR-mdr-rendered-diff-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-prompt-old-new-source`

### `NFR-mdr-render-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-perf-5k-lines-render`

### `NFR-mdr-render-scroll-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-perf-scroll-smooth`

### `NFR-mdr-rendered-diff-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-perf-diff-5k`

### `NFR-mdr-xss-safety`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-xss-script-stripped`, `TC-mdr-xss-onerror-stripped`

### `NFR-mdr-client-only`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: —

### `NFR-mdr-accessibility`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-keyboard-tab-focus`, `TC-mdr-keyboard-enter-comment`, `TC-mdr-voiceover-diff-annotations`

### `AC-mdr-toggle-appears`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-toggle-appears-markdown`

### `AC-mdr-toggle-hidden-non-md`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-toggle-hidden-typescript`

### `AC-mdr-render-basic`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-render-basic-commonmark`

### `AC-mdr-render-gfm`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough`

### `AC-mdr-render-code-blocks`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-render-code-blocks-syntax`

### `AC-mdr-raw-unchanged`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-raw-unchanged-syntax-highlight`

### `AC-mdr-comment-rendered-element`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-comment-paragraph-hover`, `TC-mdr-comment-paragraph-submit`

### `AC-mdr-comment-heading`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-comment-heading-anchors-line`

### `AC-mdr-comment-prompt-format`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-comment-prompt-raw-source`

### `AC-mdr-switch-clears-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-switch-raw-to-rendered-confirm`, `TC-mdr-switch-rendered-to-raw-confirm`

### `AC-mdr-switch-no-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-switch-no-comments-immediate`

### `AC-mdr-rendered-diff-additions`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-added-paragraph-green`

### `AC-mdr-rendered-diff-removals`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-removed-paragraph-strikethrough`

### `AC-mdr-rendered-diff-modifications`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-modified-word-level`

### `AC-mdr-rendered-diff-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-comment-modified-element`

### `AC-mdr-rendered-diff-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-prompt-old-new-source`

### `AC-mdr-html-sanitized`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-xss-script-stripped`, `TC-mdr-xss-onerror-stripped`

### `AC-mdr-large-file-renders`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-perf-5k-lines-render`, `TC-mdr-perf-scroll-smooth`

### `AC-mdr-keyboard-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-keyboard-tab-focus`, `TC-mdr-keyboard-enter-comment`

### `AC-mdr-diff-fallback`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/macos/markdown-render.md`
- **Engineering**: `engineering/macos/markdown-render.md`
- **QA**: `qa/macos/markdown-render.md` -> `TC-mdr-diff-fallback-80-percent-changed`

### `FR-sr-patch-source`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-happy-path`, `TC-sr-patch-event-not-found`

### `FR-sr-patch-fetch`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-happy-path`, `TC-sr-patch-event-not-found`

### `FR-sr-patch-validation`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-invalid-diff`, `TC-sr-patch-invalid-event-id`

### `FR-sr-patch-application`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-application-conflicts`

### `FR-sr-patch-metadata-display`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-metadata-displayed`

### `FR-sr-patch-replies-display`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-replies-displayed`, `TC-sr-patch-replies-empty`

### `FR-sr-patch-replies-live`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-replies-live`, `TC-sr-patch-replies-live-no-relays`

### `FR-sr-relay-client`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-replies-live`, `TC-sr-patch-replies-live-no-relays`

### `FR-sr-patch-reply-publish`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-reply-publish`, `TC-srm-comment-publish`

### `FR-sr-reviewer-identity`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-identity-load`, `TC-srm-identity-indicator`, `TC-srm-bunker-connect`

### `FR-sr-bunker-signing`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-bunker-sign`, `TC-srm-bunker-sign-failure`

### `FR-sr-patch-reply-respond`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-reply-respond`, `TC-srm-reply-to-reply`

### `AC-sr-patch-happy-path`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-happy-path`

### `AC-sr-patch-event-not-found`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-event-not-found`

### `AC-sr-patch-invalid-diff`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-invalid-diff`

### `AC-sr-patch-application-conflicts`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-application-conflicts`

### `AC-sr-patch-metadata-displayed`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-metadata-displayed`

### `AC-sr-patch-invalid-event-id`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-invalid-event-id`

### `AC-sr-patch-conflicting-args`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-conflicting-args`

### `AC-sr-patch-reply-publish`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-reply-publish`, `TC-srm-comment-publish`

### `AC-sr-patch-reply-respond`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-sr-patch-reply-respond`, `TC-srm-reply-to-reply`

### `AC-sr-reviewer-identity`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-identity-load`, `TC-srm-identity-no-key`, `TC-srm-identity-indicator`

### `AC-sr-bunker-signing`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/macos/shepherd-review.md`
- **Engineering**: `engineering/macos/shepherd-review.md`
- **QA**: `qa/macos/shepherd-review.md` -> `TC-srm-bunker-sign`, `TC-srm-bunker-sign-failure`

### `FR-id-nsec-login`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-login-valid`, `TC-id-login-persists`, `TC-id-login-invalid-format`, `TC-id-login-invalid-checksum`, `TC-id-login-invalid-length`

### `FR-id-create-new`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-create-new`, `TC-id-create-shows-nsec`, `TC-id-create-confirm-required`, `TC-id-generated-key-valid`

### `FR-id-persistence`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-login-persists`, `TC-id-create-persists`

### `FR-id-show-new-nsec`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-create-shows-nsec`, `TC-id-create-confirm-required`

### `FR-id-active-indicator`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-active-indicator`

### `FR-id-logout`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-logout`, `TC-id-logout-then-relaunch`

### `FR-id-out-of-band-honored`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-out-of-band-skips`

### `FR-id-no-silent-override`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-precedence-inapp-over-env`

### `FR-id-screen-when-no-identity`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-skip-read-only`, `TC-id-logout-then-relaunch`

### `FR-id-optional-reentry`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-switch-identity`

### `NFR-id-no-plaintext-key`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-no-plaintext-disk`

### `NFR-id-key-stays-local`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-no-plaintext-disk`

### `NFR-id-login-latency`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-login-latency`

### `NFR-id-key-validity`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-generated-key-valid`

### `AC-id-login-valid`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-login-valid`, `TC-id-login-persists`

### `AC-id-login-invalid`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-login-invalid-format`, `TC-id-login-invalid-checksum`, `TC-id-login-invalid-length`

### `AC-id-create-new`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-create-new`, `TC-id-create-shows-nsec`, `TC-id-create-confirm-required`

### `AC-id-create-persists`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-create-persists`

### `AC-id-created-can-publish`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-created-publishes`

### `AC-id-logout`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-logout`, `TC-id-logout-then-relaunch`

### `AC-id-out-of-band-skips`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-out-of-band-skips`

### `AC-id-dismiss-read-only`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-skip-read-only`

### `AC-id-active-shown`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-active-indicator`

### `AC-id-no-plaintext`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-no-plaintext-disk`

### `AC-id-switch`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-switch-identity`

### `FR-id-bunker-login`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-login-valid`

### `FR-id-bunker-persist`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-persists`

### `FR-id-bunker-connect-failure`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-connect-failure`, `TC-id-bunker-connect-latency`

### `NFR-id-bunker-connect-latency`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-connect-latency`

### `AC-id-bunker-login-valid`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-login-valid`

### `AC-id-bunker-login-invalid-uri`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-login-invalid-uri`

### `AC-id-bunker-connect-failure`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-connect-failure`

### `AC-id-bunker-persists`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-persists`

### `AC-id-bunker-can-publish`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-can-publish`

### `AC-id-bunker-logout`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-logout`

### `AC-id-bunker-no-host-key`
- **Defined in**: `product/identity.md`
- **Design**: `design/macos/identity.md`
- **Engineering**: `engineering/macos/identity.md`
- **QA**: `qa/macos/identity.md` -> `TC-id-bunker-no-host-key`
