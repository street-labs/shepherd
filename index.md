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
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-load-paste-happy`, `TC-crp-load-upload-happy`, `TC-crp-load-drag-drop-happy`

### `FR-crp-file-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edge-file-with-empty-lines`, `TC-crp-edge-file-with-very-long-lines`

### `FR-crp-syntax-highlight`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-syntax-highlight-typescript`, `TC-crp-syntax-highlight-unknown-fallback`

### `FR-crp-line-comment-create`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-add-comment-single-line-happy`, `TC-crp-add-comment-line-range-happy`, `TC-crp-edge-multiple-comments-same-line`, `TC-crp-edge-very-long-comment-text`, `TC-crp-edge-rapid-successive-comments`

### `FR-crp-line-comment-edit`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edit-comment-happy`, `TC-crp-edit-comment-stays-on-line`

### `FR-crp-line-comment-delete`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-delete-comment-happy`, `TC-crp-delete-comment-gutter-clears`, `TC-crp-delete-comment-count-decrements`

### `FR-crp-comment-indicator`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-add-comment-gutter-indicator`, `TC-crp-add-comment-line-range-gutter-indicators`, `TC-crp-delete-comment-gutter-clears`

### `FR-crp-comment-count`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-add-comment-count-increments`, `TC-crp-delete-comment-count-decrements`

### `FR-crp-prompt-preamble`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`

### `FR-crp-prompt-generate`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-no-comments-disabled`, `TC-crp-edge-prompt-gen-performance`

### `FR-crp-prompt-preview`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-preview-matches-copy-exact`, `TC-crp-edge-stale-prompt-indicator`

### `FR-crp-prompt-copy`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-copy-clipboard-happy`, `TC-crp-copy-clipboard-toast`, `TC-crp-edge-clipboard-permission-denied`

### `FR-crp-prompt-format`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`, `TC-crp-generate-prompt-structure-line-order`, `TC-crp-add-comment-line-range-prompt-format`, `TC-crp-edge-special-characters-in-comments`, `TC-crp-edge-untitled-file-prompt`

### `FR-crp-clear-session`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-clear-confirmation-shows-dialog`, `TC-crp-clear-confirmation-cancel-preserves`, `TC-crp-clear-confirmation-confirm-clears`, `TC-crp-clear-no-confirm-empty-happy`

### `FR-crp-filename-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-load-paste-with-filename`, `TC-crp-load-upload-shows-filename`, `TC-crp-edge-untitled-file-prompt`

### `FR-crp-line-range-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-add-comment-line-range-happy`, `TC-crp-add-comment-line-range-gutter-indicators`, `TC-crp-add-comment-line-range-prompt-format`, `TC-crp-keyboard-range-select`

### `FR-crp-comment-navigation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-comment-navigation-next-happy`, `TC-crp-comment-navigation-prev-happy`, `TC-crp-comment-navigation-wrap-around`

### `NFR-crp-large-file-perf`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-large-file-scroll-no-jank`, `TC-crp-large-file-scroll-warning-banner`

### `NFR-crp-render-time`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edge-initial-render-time`

### `NFR-crp-prompt-gen-time`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edge-prompt-gen-performance`

### `NFR-crp-client-only`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edge-client-side-only`

### `NFR-crp-browser-support`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edge-cross-browser-clipboard`

### `NFR-crp-responsive-layout`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edge-responsive-below-1024`

### `NFR-crp-accessibility-keyboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-keyboard-add-comment-happy`, `TC-crp-keyboard-range-select`, `TC-crp-edge-focus-management-editor`

### `NFR-crp-no-data-persistence`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edge-no-data-persistence`

### `AC-crp-load-paste`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-load-paste-happy`, `TC-crp-load-paste-with-filename`, `TC-crp-load-paste-empty-rejected`

### `AC-crp-load-upload`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-load-upload-happy`, `TC-crp-load-upload-shows-filename`

### `AC-crp-load-drag-drop`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-load-drag-drop-happy`, `TC-crp-load-drag-drop-hover-state`

### `AC-crp-syntax-highlight-detected`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-syntax-highlight-typescript`, `TC-crp-syntax-highlight-unknown-fallback`

### `AC-crp-add-comment-single-line`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-add-comment-single-line-happy`, `TC-crp-add-comment-gutter-indicator`, `TC-crp-add-comment-count-increments`, `TC-crp-edge-multiple-comments-same-line`

### `AC-crp-add-comment-line-range`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-add-comment-line-range-happy`, `TC-crp-add-comment-line-range-gutter-indicators`, `TC-crp-add-comment-line-range-prompt-format`, `TC-crp-keyboard-range-select`

### `AC-crp-edit-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edit-comment-happy`, `TC-crp-edit-comment-stays-on-line`

### `AC-crp-delete-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-delete-comment-happy`, `TC-crp-delete-comment-gutter-clears`, `TC-crp-delete-comment-count-decrements`

### `AC-crp-generate-prompt-structure`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`, `TC-crp-generate-prompt-structure-line-order`

### `AC-crp-generate-prompt-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-no-comments-disabled`, `TC-crp-generate-prompt-no-comments-after-delete-all`

### `AC-crp-copy-clipboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-copy-clipboard-happy`, `TC-crp-copy-clipboard-toast`, `TC-crp-edge-clipboard-permission-denied`

### `AC-crp-preview-matches-copy`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-preview-matches-copy-exact`

### `AC-crp-clear-confirmation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-clear-confirmation-shows-dialog`, `TC-crp-clear-confirmation-cancel-preserves`, `TC-crp-clear-confirmation-confirm-clears`

### `AC-crp-clear-no-confirm-empty`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-clear-no-confirm-empty-happy`

### `AC-crp-empty-state`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-empty-state-instructions`, `TC-crp-empty-state-buttons-disabled`

### `AC-crp-large-file-scroll`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-large-file-scroll-no-jank`, `TC-crp-large-file-scroll-warning-banner`

### `AC-crp-comment-navigation-next`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-comment-navigation-next-happy`, `TC-crp-comment-navigation-prev-happy`, `TC-crp-comment-navigation-wrap-around`

### `AC-crp-keyboard-add-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-keyboard-add-comment-happy`, `TC-crp-keyboard-range-select`

### `AC-crp-binary-file-rejected`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-binary-file-rejected-upload`, `TC-crp-binary-file-rejected-drag-drop`, `TC-crp-binary-file-rejected-no-crash`

### `FR-sc-invoke-command`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-launch-happy-inrepo`, `TC-sc-launch-happy-standalone`, `TC-sc-no-args-usage`, `TC-sc-help-flag`, `TC-sc-install-claude-code-command`, `TC-sc-edge-exit-codes`

### `FR-sc-file-resolution`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-absolute-path-inrepo`, `TC-sc-absolute-path-standalone`, `TC-sc-resolve-relative-path`, `TC-sc-resolve-symlink`, `TC-sc-edge-spaces-in-path`, `TC-sc-edge-unicode-filename`, `TC-sc-edge-very-long-path`, `TC-sc-path-handling-windows`

### `FR-sc-file-validation`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`, `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-file-not-found-cli`, `TC-sc-binary-rejected-cli`, `TC-sc-permission-denied-cli`, `TC-sc-directory-rejected-cli`, `TC-sc-large-file-warning-cli`, `TC-sc-output-errors-stderr`, `TC-sc-edge-empty-file`, `TC-sc-edge-file-with-only-null-bytes`, `TC-sc-edge-symlink-to-directory`, `TC-sc-edge-file-deleted-after-validation`, `TC-sc-edge-exit-codes`

### `FR-sc-app-serve`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-launch-happy-standalone`, `TC-sc-server-starts-available-port`, `TC-sc-server-serves-static-assets`, `TC-sc-server-reuse-lockfile`, `TC-sc-edge-port-in-use`

### `FR-sc-browser-open`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-browser-open-url`, `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`, `TC-sc-edge-browser-open-fails`

### `FR-sc-auto-load-file`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/hooks/useFileFromUrl.ts`, `engineering/apps/web/src/App.tsx`
- **QA**: `qa/slash-command.md` -> `TC-sc-launch-happy-inrepo`, `TC-sc-auto-load-from-url-param`, `TC-sc-auto-load-clears-url-param`, `TC-sc-auto-load-error-state`, `TC-sc-auto-load-no-param`, `TC-sc-session-clear-on-new-file`

### `FR-sc-file-api`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-api-200-valid-file`, `TC-sc-api-400-missing-param`, `TC-sc-api-403-permission`, `TC-sc-api-403-non-localhost`, `TC-sc-api-404-not-found`, `TC-sc-api-404-directory`, `TC-sc-api-415-binary`, `TC-sc-api-headers`, `TC-sc-api-path-traversal`, `TC-sc-edge-api-concurrent-requests`

### `FR-sc-install`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`, `scripts/install-command.sh`
- **QA**: `qa/slash-command.md` -> `TC-sc-install-global`, `TC-sc-install-binary-on-path`, `TC-sc-install-claude-code-command`

### `FR-sc-server-shutdown`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-lockfile-write`, `TC-sc-lockfile-stale-cleanup`, `TC-sc-idle-shutdown-fires`, `TC-sc-idle-shutdown-resets`, `TC-sc-explicit-stop-running`, `TC-sc-explicit-stop-not-running`, `TC-sc-signal-handler-cleanup`, `TC-sc-server-reuse-lockfile`, `TC-sc-edge-concurrent-invocations`, `TC-sc-edge-lockfile-directory-missing`

### `FR-sc-output-feedback`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-launch-happy-standalone`, `TC-sc-no-args-usage`, `TC-sc-output-success-format`, `TC-sc-output-reuse-note`, `TC-sc-output-errors-stderr`

### `NFR-sc-launch-speed`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-launch-speed-cold`, `TC-sc-launch-speed-warm`

### `NFR-sc-no-global-deps`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-install-global`

### `NFR-sc-cross-platform`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`, `TC-sc-path-handling-windows`

### `NFR-sc-localhost-only`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-server-binds-localhost`, `TC-sc-api-403-non-localhost`, `TC-sc-api-path-traversal`

### `NFR-sc-no-telemetry`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-no-outbound-network`

### `NFR-sc-minimal-footprint`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-package-size`, `TC-sc-server-memory`

### `AC-sc-launch-happy-path`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/hooks/useFileFromUrl.ts`, `engineering/apps/web/src/App.tsx`
- **QA**: `qa/slash-command.md` -> `TC-sc-launch-happy-inrepo`, `TC-sc-launch-happy-standalone`, `TC-sc-auto-load-from-url-param`, `TC-sc-api-200-valid-file`, `TC-sc-output-success-format`

### `AC-sc-absolute-path`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/hooks/useFileFromUrl.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-absolute-path-inrepo`, `TC-sc-absolute-path-standalone`

### `AC-sc-file-not-found`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-file-not-found-cli`, `TC-sc-file-not-found-api`, `TC-sc-api-404-not-found`

### `AC-sc-binary-file-rejected`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-binary-rejected-cli`, `TC-sc-binary-rejected-api`, `TC-sc-api-415-binary`

### `AC-sc-permission-denied`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-permission-denied-cli`, `TC-sc-permission-denied-api`, `TC-sc-api-403-permission`

### `AC-sc-directory-rejected`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-directory-rejected-cli`, `TC-sc-directory-rejected-api`, `TC-sc-api-404-directory`

### `AC-sc-no-args-usage`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-no-args-usage`, `TC-sc-help-flag`

### `AC-sc-large-file-warning`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-large-file-warning-cli`, `TC-sc-large-file-warning-e2e`

### `AC-sc-server-reuse`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-server-reuse-lockfile`, `TC-sc-server-reuse-output`, `TC-sc-output-reuse-note`, `TC-sc-edge-concurrent-invocations`

### `AC-sc-server-manual-stop`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-explicit-stop-running`, `TC-sc-explicit-stop-not-running`

### `AC-sc-install-global`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`, `scripts/install-command.sh`
- **QA**: `qa/slash-command.md` -> `TC-sc-install-global`, `TC-sc-install-binary-on-path`

### `AC-sc-session-clear-on-new-file`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/hooks/useFileFromUrl.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-session-clear-on-new-file`

### `AC-sc-cross-platform-open`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`

<!--
Entry template -- copy this when adding a new slug:

### `FR-feature-slug`
- **Defined in**: `product/feature.md`
- **Design**: `design/feature.md`
- **Engineering**: `engineering/feature.md`, `engineering/src/path/to/file.ext`
- **QA**: `qa/feature.md` -> `TC-feature-slug`
-->
