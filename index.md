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
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-load-paste-happy`, `TC-crp-load-upload-happy`, `TC-crp-load-drag-drop-happy`

### `FR-crp-file-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edge-file-with-empty-lines`, `TC-crp-edge-file-with-very-long-lines`

### `FR-crp-syntax-highlight`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/lib/languageDetect.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-syntax-highlight-typescript`, `TC-crp-syntax-highlight-unknown-fallback`

### `FR-crp-line-comment-create`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-add-comment-single-line-happy`, `TC-crp-add-comment-line-range-happy`, `TC-crp-edge-multiple-comments-same-line`, `TC-crp-edge-very-long-comment-text`, `TC-crp-edge-rapid-successive-comments`

### `FR-crp-line-comment-edit`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-edit-comment-happy`, `TC-crp-edit-comment-stays-on-line`

### `FR-crp-line-comment-delete`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`
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
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`

### `FR-crp-prompt-generate`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-no-comments-disabled`, `TC-crp-edge-prompt-gen-performance`

### `FR-crp-prompt-preview`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-preview-matches-copy-exact`, `TC-crp-edge-stale-prompt-indicator`

### `FR-crp-prompt-copy`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/lib/clipboard.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-copy-clipboard-happy`, `TC-crp-copy-clipboard-toast`, `TC-crp-edge-clipboard-permission-denied`

### `FR-crp-prompt-format`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`, `TC-crp-generate-prompt-structure-line-order`, `TC-crp-add-comment-line-range-prompt-format`, `TC-crp-edge-special-characters-in-comments`, `TC-crp-edge-untitled-file-prompt`

### `FR-crp-clear-session`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`
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
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`
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
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`, `TC-crp-generate-prompt-structure-line-order`

### `AC-crp-generate-prompt-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-generate-prompt-no-comments-disabled`, `TC-crp-generate-prompt-no-comments-after-delete-all`

### `AC-crp-copy-clipboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/lib/clipboard.test.ts`
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
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/lib/binaryDetect.test.ts`
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
- **QA**: `qa/slash-command.md` -> `TC-sc-browser-open-url`, `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`, `TC-sc-edge-browser-open-fails`, `TC-sc-app-window-chrome`, `TC-sc-app-window-browser-fallback`

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

### `FR-sc-launcher-script`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: `engineering/slash-command.md` -> `scripts/shepherd-launch.sh`
- **QA**: `qa/slash-command.md` -> `TC-sc-launcher-warm-launch`, `TC-sc-launcher-cold-launch`, `TC-sc-single-tool-call`, `TC-sc-launcher-script-validation`, `TC-sc-launcher-server-start`

### `NFR-sc-launch-speed`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-launch-speed-cold`, `TC-sc-launch-speed-warm`, `TC-sc-launcher-warm-launch`, `TC-sc-launcher-cold-launch`

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

### `AC-sc-standalone-window`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-app-window-chrome`, `TC-sc-app-window-chromium-fallback`, `TC-sc-app-window-browser-fallback`, `TC-sc-app-window-subsequent`

### `AC-sc-warm-launch-2s`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: `engineering/slash-command.md` -> `scripts/shepherd-launch.sh`
- **QA**: `qa/slash-command.md` -> `TC-sc-launcher-warm-launch`

### `AC-sc-cold-launch-8s`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: `engineering/slash-command.md` -> `scripts/shepherd-launch.sh`
- **QA**: `qa/slash-command.md` -> `TC-sc-launcher-cold-launch`

### `AC-sc-single-tool-call`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`, `scripts/shepherd-launch.sh`
- **QA**: `qa/slash-command.md` -> `TC-sc-single-tool-call`


### `FR-diff-mode-toggle`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/diff-view.md` -> `TC-diff-toggle-to-diff-happy`, `TC-diff-toggle-to-diff-keyboard`, `TC-diff-toggle-to-file-happy`, `TC-diff-toggle-to-file-no-comments`, `TC-diff-switch-clears-comments-confirm`, `TC-diff-switch-clears-comments-cancel`, `TC-diff-switch-no-comments-no-dialog`, `TC-diff-keyboard-toggle-modes`

### `FR-diff-mode-availability`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-paste-disabled`, `TC-diff-upload-disabled`, `TC-diff-drag-drop-disabled`, `TC-diff-disabled-tooltip`

### `FR-diff-baseline-fetch`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-toggle-to-diff-happy`, `TC-diff-toggle-to-diff-loading-state`, `TC-diff-api-head-happy`, `TC-diff-api-head-untracked-404`, `TC-diff-api-head-not-git-repo`, `TC-diff-api-head-binary-415`, `TC-diff-api-head-missing-path`, `TC-diff-api-head-git-unavailable`, `TC-diff-api-routing-no-collision`, `TC-diff-error-network-failure`, `TC-diff-error-git-unavailable`, `TC-diff-error-file-outside-git`, `TC-diff-no-git-history-all-added`

### `FR-diff-compute`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`, `engineering/apps/web/src/lib/diffCompute.test.ts`
- **QA**: `qa/diff-view.md` -> `TC-diff-compute-correct-hunks`, `TC-diff-compute-empty-diff`, `TC-diff-compute-all-added`, `TC-diff-compute-all-removed`, `TC-diff-compute-every-line-changed`, `TC-diff-compute-no-newline-at-end`, `TC-diff-compute-performance-10k`

### `FR-diff-display`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-line-numbers-added`, `TC-diff-line-numbers-removed`, `TC-diff-line-numbers-context`, `TC-diff-syntax-highlight-happy`, `TC-diff-syntax-highlight-removed-lines`

### `FR-diff-collapse`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`, `engineering/apps/web/src/lib/diffCompute.test.ts`
- **QA**: `qa/diff-view.md` -> `TC-diff-collapse-default-happy`, `TC-diff-collapse-gap-boundary`, `TC-diff-collapse-leading-trailing`, `TC-diff-collapse-adjacent-hunks-small-gap`, `TC-diff-no-git-history-no-collapse`

### `FR-diff-expand`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`, `engineering/apps/web/src/lib/diffCompute.test.ts`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/diff-view.md` -> `TC-diff-expand-section-click`, `TC-diff-expand-section-keyboard`, `TC-diff-expand-section-no-recollapse`, `TC-diff-expand-then-comment-happy`, `TC-diff-keyboard-expand-section`

### `FR-diff-comment-create`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/diff-view.md` -> `TC-diff-comment-added-line-happy`, `TC-diff-comment-added-line-label`, `TC-diff-comment-removed-line-happy`, `TC-diff-comment-removed-line-label`, `TC-diff-comment-context-line-happy`, `TC-diff-comment-context-line-label`, `TC-diff-keyboard-add-comment`

### `FR-diff-comment-on-range`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-comment-range-same-type`, `TC-diff-comment-range-mixed-types`, `TC-diff-comment-range-blocked-by-collapsed`, `TC-diff-keyboard-range-select`

### `FR-diff-prompt-format`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`
- **QA**: `qa/diff-view.md` -> `TC-diff-prompt-includes-diff-happy`, `TC-diff-prompt-diff-notation`, `TC-diff-prompt-comment-labels`, `TC-diff-prompt-collapsed-markers`

### `FR-diff-empty-state`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-no-changes-empty-state`, `TC-diff-no-changes-switch-to-file`

### `FR-diff-refresh`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-refresh-happy`, `TC-diff-refresh-with-comments-confirm`, `TC-diff-refresh-with-comments-cancel`, `TC-diff-refresh-no-comments`, `TC-diff-error-file-deleted-refresh`

### `NFR-diff-compute-perf`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`, `engineering/apps/web/src/lib/diffCompute.test.ts`
- **QA**: `qa/diff-view.md` -> `TC-diff-compute-performance-10k`, `TC-diff-compute-perf-large-file`, `TC-diff-compute-every-line-changed`

### `NFR-diff-render-perf`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-render-perf-scroll`

### `NFR-diff-client-compute`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-compute-correct-hunks`, `TC-diff-compute-empty-diff`, `TC-diff-compute-all-added`

### `NFR-diff-baseline-fetch-speed`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-api-head-happy`

### `NFR-diff-accessibility`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-toggle-to-diff-keyboard`, `TC-diff-expand-section-keyboard`, `TC-diff-keyboard-toggle-modes`, `TC-diff-keyboard-navigate-lines`, `TC-diff-keyboard-add-comment`, `TC-diff-keyboard-range-select`, `TC-diff-keyboard-comment-navigation`, `TC-diff-keyboard-expand-section`

### `AC-diff-toggle-to-diff`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-toggle-to-diff-happy`, `TC-diff-toggle-to-diff-keyboard`, `TC-diff-toggle-to-diff-loading-state`, `TC-diff-keyboard-toggle-modes`

### `AC-diff-toggle-to-file`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-toggle-to-file-happy`, `TC-diff-toggle-to-file-no-comments`, `TC-diff-keyboard-toggle-modes`

### `AC-diff-collapse-default`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-collapse-default-happy`, `TC-diff-collapse-gap-boundary`, `TC-diff-collapse-leading-trailing`, `TC-diff-collapse-adjacent-hunks-small-gap`

### `AC-diff-expand-section`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-expand-section-click`, `TC-diff-expand-section-keyboard`, `TC-diff-expand-section-no-recollapse`, `TC-diff-keyboard-expand-section`

### `AC-diff-comment-added-line`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-comment-added-line-happy`, `TC-diff-comment-added-line-label`

### `AC-diff-comment-removed-line`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-comment-removed-line-happy`, `TC-diff-comment-removed-line-label`

### `AC-diff-comment-context-line`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-comment-context-line-happy`, `TC-diff-comment-context-line-label`

### `AC-diff-prompt-includes-diff`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`
- **QA**: `qa/diff-view.md` -> `TC-diff-prompt-includes-diff-happy`, `TC-diff-prompt-diff-notation`, `TC-diff-prompt-comment-labels`, `TC-diff-prompt-collapsed-markers`

### `AC-diff-no-git-history`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-no-git-history-all-added`, `TC-diff-no-git-history-no-collapse`

### `AC-diff-no-changes`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-no-changes-empty-state`, `TC-diff-no-changes-switch-to-file`

### `AC-diff-paste-upload-disabled`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-paste-disabled`, `TC-diff-upload-disabled`, `TC-diff-drag-drop-disabled`, `TC-diff-disabled-tooltip`

### `AC-diff-line-numbers`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-line-numbers-added`, `TC-diff-line-numbers-removed`, `TC-diff-line-numbers-context`, `TC-diff-compute-correct-hunks`

### `AC-diff-syntax-highlight`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-syntax-highlight-happy`, `TC-diff-syntax-highlight-removed-lines`

### `AC-diff-refresh-updates`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-refresh-happy`, `TC-diff-refresh-with-comments-confirm`, `TC-diff-refresh-with-comments-cancel`, `TC-diff-refresh-no-comments`

### `AC-diff-switch-clears-comments`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-switch-clears-comments-confirm`, `TC-diff-switch-clears-comments-cancel`, `TC-diff-switch-no-comments-no-dialog`, `TC-diff-toggle-to-file-no-comments`

### `AC-diff-comment-range`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-comment-range-same-type`, `TC-diff-comment-range-mixed-types`, `TC-diff-comment-range-blocked-by-collapsed`

### `AC-diff-expand-then-comment`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/diff-view.md`
- **Engineering**: `engineering/diff-view.md`
- **QA**: `qa/diff-view.md` -> `TC-diff-expand-then-comment-happy`, `TC-diff-expand-then-comment-gutter-hover`

### `FR-sr-changeset-detection`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-happy-path-full-loop`, `TC-sr-no-changes-on-main`, `TC-sr-no-changes-no-divergence`, `TC-sr-changeset-merge-base`, `TC-sr-renamed-files`

### `FR-sr-file-filtering`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-filters-lockfiles`, `TC-sr-filters-generated-dirs`, `TC-sr-filters-generated-extensions`, `TC-sr-filters-binary`, `TC-sr-filters-ide-files`, `TC-sr-filters-snapshot-files`, `TC-sr-includes-config-files`, `TC-sr-unknown-file-included`

### `FR-sr-file-list-display`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-file-list-format`, `TC-sr-sorted-file-list`, `TC-sr-file-list-exclusion-count`

### `FR-sr-iteration-loop`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-happy-path-full-loop`, `TC-sr-skip-file`, `TC-sr-quit-early`, `TC-sr-list-command-mid-review`, `TC-sr-user-input-synonyms`, `TC-sr-unrecognized-input`

### `FR-sr-completion-summary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-completion-summary-full`, `TC-sr-completion-summary-quit-early`, `TC-sr-completion-summary-all-skipped`

### `FR-sr-command-file`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-command-file-exists`

### `FR-sr-install`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `scripts/install-command.sh`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-install-global-symlink`

### `FR-sr-no-args`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-happy-path-full-loop`

### `FR-sr-git-required`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-not-git-repo`

### `NFR-sr-startup-speed`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-startup-speed`

### `NFR-sr-no-dependencies`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-no-external-dependencies`

### `NFR-sr-agent-native`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-happy-path-full-loop`

### `NFR-sr-cross-platform`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-cross-platform-git-commands`

### `AC-sr-happy-path`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-happy-path-full-loop`

### `AC-sr-filters-lockfiles`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-filters-lockfiles`

### `AC-sr-filters-generated`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-filters-generated-dirs`, `TC-sr-filters-generated-extensions`

### `AC-sr-filters-binary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-filters-binary`

### `AC-sr-includes-config`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-includes-config-files`

### `AC-sr-excludes-deleted`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-excludes-deleted-files`

### `AC-sr-skip-file`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-skip-file`

### `AC-sr-quit-early`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-quit-early`

### `AC-sr-no-changes`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-no-changes-on-main`, `TC-sr-no-changes-no-divergence`

### `AC-sr-all-filtered`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-all-filtered`

### `AC-sr-not-git-repo`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-not-git-repo`

### `AC-sr-invokes-shepherd`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-invokes-shepherd-per-file`

### `AC-sr-list-command`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-list-command-mid-review`

### `AC-sr-completion-summary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-completion-summary-full`, `TC-sr-completion-summary-quit-early`

### `AC-sr-sorted-file-list`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-sorted-file-list`

### `AC-sr-install-global`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/shepherd-review.md`
- **Engineering**: `engineering/shepherd-review.md`
- **QA**: `qa/shepherd-review.md` -> `TC-sr-install-global-symlink`

### `FR-crp-done-action`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/components/Toolbar.tsx`, `engineering/apps/web/src/hooks/useFileFromUrl.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-done-happy`, `TC-crp-done-keyboard-shortcut`, `TC-crp-done-reset-on-comment-add`, `TC-crp-done-reset-on-comment-edit`, `TC-crp-done-reset-on-comment-delete`, `TC-crp-done-reset-on-preamble-change`, `TC-crp-done-resend-after-failure`, `TC-crp-done-rapid-double-click`, `TC-crp-done-copy-still-works`, `TC-crp-done-auto-close-app-mode`

### `FR-crp-prompt-handoff`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/slash-command.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-done-happy`

### `AC-crp-done-sends-prompt`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/components/Toolbar.tsx`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-done-happy`, `TC-crp-done-keyboard-shortcut`, `TC-crp-done-clipboard-parallel`, `TC-crp-done-auto-close-clipboard`

### `AC-crp-done-confirmation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/components/Toolbar.tsx`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-done-happy`, `TC-crp-done-auto-close-fallback`

### `AC-crp-done-auto-close`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-done-auto-close-app-mode`, `TC-crp-done-auto-close-fallback`, `TC-crp-done-auto-close-clipboard`

### `AC-crp-done-fallback-clipboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/lib/clipboard.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-done-fallback-clipboard`, `TC-crp-done-resend-after-failure`

### `AC-crp-done-disabled-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/components/Toolbar.tsx`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-done-disabled-no-comments`

### `AC-crp-done-standalone-hidden`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/code-review-prompt.md`
- **Engineering**: `engineering/code-review-prompt.md`, `engineering/apps/web/src/components/Toolbar.tsx`, `engineering/apps/web/src/store/appStore.ts`
- **QA**: `qa/code-review-prompt.md` -> `TC-crp-done-hidden-standalone`, `TC-crp-done-hidden-after-clear`

### `FR-sc-prompt-receive`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-watcher-detects-file`, `TC-sc-watcher-deletes-after-read`, `TC-sc-feedback-loop-e2e`, `TC-sc-feedback-loop-resend`

### `FR-sc-prompt-output-api`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-prompt-api-write-happy`, `TC-sc-prompt-api-creates-dir`, `TC-sc-prompt-api-overwrites`, `TC-sc-prompt-api-localhost-only`, `TC-sc-prompt-api-method-check`, `TC-sc-prompt-api-no-collision`, `TC-sc-feedback-loop-e2e`

### `FR-sc-prompt-cleanup`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-watcher-cleanup-stale`

### `NFR-sc-watcher-low-overhead`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-watcher-timeout`

### `AC-sc-prompt-received`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-watcher-detects-file`, `TC-sc-feedback-loop-e2e`

### `AC-sc-prompt-watcher-timeout`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-watcher-timeout`

### `AC-sc-prompt-cleanup-stale`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/slash-command.md` -> `TC-sc-watcher-cleanup-stale`

### `AC-sc-prompt-output-api-success`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-prompt-api-write-happy`

### `AC-sc-prompt-output-api-localhost-only`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/slash-command.md`
- **Engineering**: `engineering/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/slash-command.md` -> `TC-sc-prompt-api-localhost-only`

### `FR-mdr-detect-markdown`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-detect-md-ext`, `TC-mdr-detect-mdx-ext`, `TC-mdr-detect-markdown-ext`, `TC-mdr-detect-mdown-ext`, `TC-mdr-detect-mkdn-ext`, `TC-mdr-detect-mkd-ext`, `TC-mdr-detect-uppercase-ext`, `TC-mdr-detect-non-md-hidden`, `TC-mdr-detect-no-extension`, `TC-mdr-detect-md-in-directory`

### `FR-mdr-render-toggle`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-toggle-click-rendered`, `TC-mdr-toggle-click-raw`, `TC-mdr-toggle-keyboard`, `TC-mdr-toggle-default-raw`, `TC-mdr-toggle-persists-session`, `TC-mdr-toggle-resets-new-file`, `TC-mdr-toggle-independent-file-diff`

### `FR-mdr-render-commonmark`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-render-headings`, `TC-mdr-render-paragraphs-bold-italic`, `TC-mdr-render-links`, `TC-mdr-render-unordered-lists`, `TC-mdr-render-ordered-lists`, `TC-mdr-render-nested-lists`, `TC-mdr-render-blockquotes`, `TC-mdr-render-horizontal-rules`, `TC-mdr-render-images`, `TC-mdr-render-images-broken`, `TC-mdr-render-inline-code`, `TC-mdr-render-html-blocks-safe`, `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough`, `TC-mdr-render-gfm-autolinks`, `TC-mdr-render-code-blocks-highlighted`, `TC-mdr-render-code-blocks-no-lang`

### `FR-mdr-render-styling`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-style-body-typography`, `TC-mdr-style-heading-hierarchy`, `TC-mdr-style-code-block-theme`, `TC-mdr-style-table-styling`, `TC-mdr-style-max-width`, `TC-mdr-style-blockquote`, `TC-mdr-style-links`

### `FR-mdr-element-id`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-element-id-deterministic`, `TC-mdr-element-id-positional`, `TC-mdr-element-id-all-block-types`

### `FR-mdr-rendered-comment-create`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-comment-paragraph`, `TC-mdr-comment-heading`, `TC-mdr-comment-list-item`, `TC-mdr-comment-code-block`, `TC-mdr-comment-table`, `TC-mdr-comment-blockquote`, `TC-mdr-comment-multiple-same-element`, `TC-mdr-comment-hover-affordance`, `TC-mdr-comment-cmd-click`, `TC-mdr-comment-bubble-label`, `TC-mdr-comment-count-increments`

### `FR-mdr-rendered-comment-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-prompt-raw-source-lines`, `TC-mdr-prompt-element-type`, `TC-mdr-prompt-format-structure`, `TC-mdr-prompt-multiple-comments-order`, `TC-mdr-prompt-no-preamble`, `TC-mdr-prompt-with-preamble`

### `FR-mdr-switch-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-switch-with-comments-confirm`, `TC-mdr-switch-with-comments-cancel`, `TC-mdr-switch-no-comments-immediate`, `TC-mdr-switch-preamble-preserved`, `TC-mdr-switch-raw-to-rendered`, `TC-mdr-switch-rendered-to-raw`, `TC-mdr-switch-rendered-file-to-rendered-diff`, `TC-mdr-switch-rendered-diff-to-rendered-file`

### `FR-mdr-raw-diff-unchanged`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-raw-file-identical`, `TC-mdr-raw-diff-identical`

### `FR-mdr-rendered-diff-display`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-added-block`, `TC-mdr-rdiff-removed-block`, `TC-mdr-rdiff-modified-block-word-diff`, `TC-mdr-rdiff-unchanged-block`, `TC-mdr-rdiff-no-changes`, `TC-mdr-rdiff-fallback-banner`, `TC-mdr-rdiff-fallback-switch-link`, `TC-mdr-rdiff-fallback-dismiss`, `TC-mdr-rdiff-loading-spinner`, `TC-mdr-rdiff-timeout-fallback`

### `FR-mdr-rendered-diff-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-comment-added`, `TC-mdr-rdiff-comment-removed`, `TC-mdr-rdiff-comment-modified`, `TC-mdr-rdiff-comment-unchanged`, `TC-mdr-rdiff-comment-anchor-qualifier`

### `FR-mdr-rendered-diff-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-prompt-modified-old-new`, `TC-mdr-rdiff-prompt-added-new-only`, `TC-mdr-rdiff-prompt-removed-old-only`, `TC-mdr-rdiff-prompt-heading-format`, `TC-mdr-rdiff-prompt-document-order`

### `NFR-mdr-render-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-perf-render-5k`, `TC-mdr-perf-render-10k`, `TC-mdr-perf-render-ui-block`

### `NFR-mdr-render-scroll-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-perf-scroll-smooth`, `TC-mdr-perf-scroll-content-visibility`

### `NFR-mdr-rendered-diff-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-perf-rdiff-5k`, `TC-mdr-perf-rdiff-10k`, `TC-mdr-perf-rdiff-timeout`

### `NFR-mdr-xss-safety`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-xss-script-tag`, `TC-mdr-xss-event-handler`, `TC-mdr-xss-javascript-url`, `TC-mdr-xss-iframe`, `TC-mdr-xss-svg-script`, `TC-mdr-xss-data-url`, `TC-mdr-xss-safe-html-preserved`

### `NFR-mdr-client-only`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-client-only-no-requests`

### `NFR-mdr-accessibility`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-a11y-keyboard-nav`, `TC-mdr-a11y-keyboard-comment`, `TC-mdr-a11y-screen-reader-elements`, `TC-mdr-a11y-screen-reader-diff`, `TC-mdr-a11y-focus-on-mode-switch`, `TC-mdr-a11y-aria-toggle`, `TC-mdr-a11y-aria-rendered-content`, `TC-mdr-a11y-aria-diff-annotations`

### `AC-mdr-toggle-appears`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-toggle-click-rendered`, `TC-mdr-toggle-default-raw`, `TC-mdr-detect-md-ext`

### `AC-mdr-toggle-hidden-non-md`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-detect-non-md-hidden`

### `AC-mdr-render-basic`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-render-headings`, `TC-mdr-render-paragraphs-bold-italic`, `TC-mdr-render-links`, `TC-mdr-render-unordered-lists`

### `AC-mdr-render-gfm`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough`

### `AC-mdr-render-code-blocks`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-render-code-blocks-highlighted`

### `AC-mdr-raw-unchanged`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-raw-file-identical`, `TC-mdr-raw-diff-identical`

### `AC-mdr-comment-rendered-element`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-comment-paragraph`, `TC-mdr-comment-hover-affordance`, `TC-mdr-comment-bubble-label`

### `AC-mdr-comment-heading`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-comment-heading`, `TC-mdr-prompt-raw-source-lines`

### `AC-mdr-comment-prompt-format`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-prompt-raw-source-lines`, `TC-mdr-prompt-format-structure`

### `AC-mdr-switch-clears-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-switch-with-comments-confirm`, `TC-mdr-switch-with-comments-cancel`

### `AC-mdr-switch-no-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-switch-no-comments-immediate`

### `AC-mdr-rendered-diff-additions`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-added-block`

### `AC-mdr-rendered-diff-removals`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-removed-block`

### `AC-mdr-rendered-diff-modifications`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-modified-block-word-diff`

### `AC-mdr-rendered-diff-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-comment-added`, `TC-mdr-rdiff-comment-modified`

### `AC-mdr-rendered-diff-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-prompt-modified-old-new`, `TC-mdr-rdiff-prompt-added-new-only`, `TC-mdr-rdiff-prompt-removed-old-only`

### `AC-mdr-html-sanitized`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-xss-script-tag`, `TC-mdr-xss-event-handler`, `TC-mdr-xss-javascript-url`, `TC-mdr-xss-iframe`, `TC-mdr-xss-svg-script`

### `AC-mdr-large-file-renders`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-perf-render-5k`, `TC-mdr-perf-scroll-smooth`

### `AC-mdr-keyboard-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-a11y-keyboard-comment`

### `AC-mdr-diff-fallback`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/markdown-render.md`
- **Engineering**: `engineering/markdown-render.md`
- **QA**: `qa/markdown-render.md` -> `TC-mdr-rdiff-fallback-banner`, `TC-mdr-rdiff-fallback-switch-link`, `TC-mdr-rdiff-timeout-fallback`

<!--
Entry template -- copy this when adding a new slug:

### `FR-feature-slug`
- **Defined in**: `product/feature.md`
- **Design**: `design/feature.md`
- **Engineering**: `engineering/feature.md`, `engineering/src/path/to/file.ext`
- **QA**: `qa/feature.md` -> `TC-feature-slug`
-->
