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
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-load-paste-happy`, `TC-crp-load-upload-happy`, `TC-crp-load-drag-drop-happy`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-paste-happy`, `TC-crp-macos-load-open-panel-single`, `TC-crp-macos-load-drag-drop-single`, `TC-crp-macos-binary-rejected-open-panel`

### `FR-crp-file-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edge-file-with-empty-lines`, `TC-crp-edge-file-with-very-long-lines`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-display-line-numbers`, `TC-crp-macos-file-display-preserves-whitespace`

### `FR-crp-syntax-highlight`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/lib/languageDetect.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-syntax-highlight-typescript`, `TC-crp-syntax-highlight-unknown-fallback`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-syntax-highlight-detected`, `TC-crp-macos-syntax-highlight-all-languages`, `TC-crp-macos-syntax-highlight-fallback`

### `FR-crp-line-comment-create`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-add-comment-single-line-happy`, `TC-crp-add-comment-line-range-happy`, `TC-crp-edge-multiple-comments-same-line`, `TC-crp-edge-very-long-comment-text`, `TC-crp-edge-rapid-successive-comments`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-single-line`, `TC-crp-macos-add-comment-gutter-indicator`

### `FR-crp-line-comment-edit`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edit-comment-happy`, `TC-crp-edit-comment-stays-on-line`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-edit-comment-happy`, `TC-crp-macos-edit-comment-stays-on-line`

### `FR-crp-line-comment-delete`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-delete-comment-happy`, `TC-crp-delete-comment-gutter-clears`, `TC-crp-delete-comment-count-decrements`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-delete-comment-happy`, `TC-crp-macos-delete-comment-gutter-clears`

### `FR-crp-comment-indicator`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-add-comment-gutter-indicator`, `TC-crp-add-comment-line-range-gutter-indicators`, `TC-crp-delete-comment-gutter-clears`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-gutter-indicator`, `TC-crp-macos-delete-comment-gutter-clears`

### `FR-crp-comment-count`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-add-comment-count-increments`, `TC-crp-delete-comment-count-decrements`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-comment-count-global`, `TC-crp-macos-comment-count-increments`

### `FR-crp-prompt-preamble`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-overall-comment-label`, `TC-crp-macos-overall-comment-in-prompt`

### `FR-crp-prompt-generate`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`, `engineering/apps/web/src/store/appStore.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-no-comments-disabled`, `TC-crp-edge-prompt-gen-performance`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-auto-regenerates`

### `FR-crp-prompt-preview`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-preview-matches-copy-exact`, `TC-crp-edge-stale-prompt-indicator`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-preview-live`, `TC-crp-macos-prompt-no-comments-placeholder`

### `FR-crp-prompt-copy`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/lib/clipboard.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-copy-clipboard-happy`, `TC-crp-copy-clipboard-toast`, `TC-crp-edge-clipboard-permission-denied`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-copy-clipboard-happy`, `TC-crp-macos-copy-toolbar-animation`

### `FR-crp-prompt-format`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`, `TC-crp-generate-prompt-structure-line-order`, `TC-crp-add-comment-line-range-prompt-format`, `TC-crp-edge-special-characters-in-comments`, `TC-crp-edge-untitled-file-prompt`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-structure-no-preamble`

### `FR-crp-clear-session`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-clear-confirmation-shows-dialog`, `TC-crp-clear-confirmation-cancel-preserves`, `TC-crp-clear-confirmation-confirm-clears`, `TC-crp-clear-no-confirm-empty-happy`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-clear-confirmation-dialog`, `TC-crp-macos-clear-no-confirm-empty`, `TC-crp-macos-multi-file-clear-all`

### `FR-crp-filename-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-load-paste-with-filename`, `TC-crp-load-upload-shows-filename`, `TC-crp-edge-untitled-file-prompt`

### `FR-crp-line-range-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-add-comment-line-range-happy`, `TC-crp-add-comment-line-range-gutter-indicators`, `TC-crp-add-comment-line-range-prompt-format`, `TC-crp-keyboard-range-select`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-line-range`, `TC-crp-macos-add-comment-line-range-gutter`

### `FR-crp-comment-navigation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-comment-navigation-next-happy`, `TC-crp-comment-navigation-prev-happy`, `TC-crp-comment-navigation-wrap-around`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-nav-next`, `TC-crp-macos-comment-nav-prev`, `TC-crp-macos-comment-nav-wrap`

### `NFR-crp-large-file-perf`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-large-file-scroll-no-jank`, `TC-crp-large-file-scroll-warning-banner`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-large-file-scroll-smooth`, `TC-crp-macos-large-file-load-time`

### `NFR-crp-render-time`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edge-initial-render-time`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-render-time-under-500ms`

### `NFR-crp-prompt-gen-time`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edge-prompt-gen-performance`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-gen-time-under-300ms`

### `NFR-crp-client-only`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edge-client-side-only`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-no-network-traffic`

### `NFR-crp-browser-support`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edge-cross-browser-clipboard`

### `NFR-crp-responsive-layout`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edge-responsive-below-1024`

### `NFR-crp-accessibility-keyboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-keyboard-add-comment-happy`, `TC-crp-keyboard-range-select`, `TC-crp-edge-focus-management-editor`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-keyboard-add-comment`, `TC-crp-macos-keyboard-open-file`, `TC-crp-macos-keyboard-copy-prompt`

### `NFR-crp-no-data-persistence`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edge-no-data-persistence`

### `AC-crp-load-paste`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-load-paste-happy`, `TC-crp-load-paste-with-filename`, `TC-crp-load-paste-empty-rejected`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-paste-happy`, `TC-crp-macos-load-paste-empty-clipboard`

### `AC-crp-load-upload`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-load-upload-happy`, `TC-crp-load-upload-shows-filename`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-open-panel-single`, `TC-crp-macos-load-open-panel-multi`

### `AC-crp-load-drag-drop`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-load-drag-drop-happy`, `TC-crp-load-drag-drop-hover-state`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-load-drag-drop-single`, `TC-crp-macos-load-drag-drop-multi`

### `AC-crp-syntax-highlight-detected`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-syntax-highlight-typescript`, `TC-crp-syntax-highlight-unknown-fallback`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-syntax-highlight-detected`, `TC-crp-macos-syntax-highlight-fallback`

### `AC-crp-add-comment-single-line`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-add-comment-single-line-happy`, `TC-crp-add-comment-gutter-indicator`, `TC-crp-add-comment-count-increments`, `TC-crp-edge-multiple-comments-same-line`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-single-line`, `TC-crp-macos-add-comment-gutter-indicator`

### `AC-crp-add-comment-line-range`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-add-comment-line-range-happy`, `TC-crp-add-comment-line-range-gutter-indicators`, `TC-crp-add-comment-line-range-prompt-format`, `TC-crp-keyboard-range-select`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-add-comment-line-range`, `TC-crp-macos-add-comment-line-range-gutter`

### `AC-crp-edit-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-edit-comment-happy`, `TC-crp-edit-comment-stays-on-line`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-edit-comment-happy`, `TC-crp-macos-edit-comment-stays-on-line`

### `AC-crp-delete-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-delete-comment-happy`, `TC-crp-delete-comment-gutter-clears`, `TC-crp-delete-comment-count-decrements`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-delete-comment-happy`, `TC-crp-macos-delete-comment-gutter-clears`

### `AC-crp-generate-prompt-structure`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-generate-prompt-structure-happy`, `TC-crp-generate-prompt-structure-no-preamble`, `TC-crp-generate-prompt-structure-line-order`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-structure-happy`, `TC-crp-macos-prompt-structure-no-preamble`

### `AC-crp-generate-prompt-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-generate-prompt-no-comments-disabled`, `TC-crp-generate-prompt-no-comments-after-delete-all`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-prompt-no-comments-placeholder`, `TC-crp-macos-prompt-clears-after-delete-all`

### `AC-crp-copy-clipboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/lib/clipboard.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-copy-clipboard-happy`, `TC-crp-copy-clipboard-toast`, `TC-crp-edge-clipboard-permission-denied`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-copy-clipboard-happy`, `TC-crp-macos-copy-toolbar-animation`

### `AC-crp-preview-matches-copy`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-preview-matches-copy-exact`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-preview-matches-copy`

### `AC-crp-clear-confirmation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-clear-confirmation-shows-dialog`, `TC-crp-clear-confirmation-cancel-preserves`, `TC-crp-clear-confirmation-confirm-clears`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-clear-confirmation-dialog`, `TC-crp-macos-clear-cancel-preserves`

### `AC-crp-clear-no-confirm-empty`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-clear-no-confirm-empty-happy`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-clear-no-confirm-empty`

### `AC-crp-empty-state`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-empty-state-instructions`, `TC-crp-empty-state-buttons-disabled`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-empty-state-instructions`, `TC-crp-macos-empty-state-buttons-disabled`

### `AC-crp-large-file-scroll`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-large-file-scroll-no-jank`, `TC-crp-large-file-scroll-warning-banner`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-large-file-scroll-smooth`

### `AC-crp-comment-navigation-next`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-comment-navigation-next-happy`, `TC-crp-comment-navigation-prev-happy`, `TC-crp-comment-navigation-wrap-around`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-nav-next`, `TC-crp-macos-comment-nav-prev`, `TC-crp-macos-comment-nav-wrap`

### `AC-crp-keyboard-add-comment`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-keyboard-add-comment-happy`, `TC-crp-keyboard-range-select`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-keyboard-add-comment`

### `AC-crp-binary-file-rejected`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/lib/binaryDetect.test.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-binary-file-rejected-upload`, `TC-crp-binary-file-rejected-drag-drop`, `TC-crp-binary-file-rejected-no-crash`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-binary-rejected-open-panel`, `TC-crp-macos-binary-rejected-drag-drop`

### `FR-sc-invoke-command`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launch-happy-inrepo`, `TC-sc-launch-happy-standalone`, `TC-sc-no-args-usage`, `TC-sc-help-flag`, `TC-sc-install-claude-code-command`, `TC-sc-edge-exit-codes`

### `FR-sc-file-resolution`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-absolute-path-inrepo`, `TC-sc-absolute-path-standalone`, `TC-sc-resolve-relative-path`, `TC-sc-resolve-symlink`, `TC-sc-edge-spaces-in-path`, `TC-sc-edge-unicode-filename`, `TC-sc-edge-very-long-path`, `TC-sc-path-handling-windows`

### `FR-sc-file-validation`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`, `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-file-not-found-cli`, `TC-sc-binary-rejected-cli`, `TC-sc-permission-denied-cli`, `TC-sc-directory-rejected-cli`, `TC-sc-large-file-warning-cli`, `TC-sc-output-errors-stderr`, `TC-sc-edge-empty-file`, `TC-sc-edge-file-with-only-null-bytes`, `TC-sc-edge-symlink-to-directory`, `TC-sc-edge-file-deleted-after-validation`, `TC-sc-edge-exit-codes`

### `FR-sc-app-serve`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launch-happy-standalone`, `TC-sc-server-starts-available-port`, `TC-sc-server-serves-static-assets`, `TC-sc-server-reuse-lockfile`, `TC-sc-edge-port-in-use`

### `FR-sc-browser-open`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-browser-open-url`, `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`, `TC-sc-edge-browser-open-fails`, `TC-sc-app-window-chrome`, `TC-sc-app-window-browser-fallback`

### `FR-sc-auto-load-file`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/hooks/useFileFromUrl.ts`, `engineering/apps/web/src/App.tsx`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launch-happy-inrepo`, `TC-sc-auto-load-from-url-param`, `TC-sc-auto-load-clears-url-param`, `TC-sc-auto-load-error-state`, `TC-sc-auto-load-no-param`, `TC-sc-session-clear-on-new-file`

### `FR-sc-file-api`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-api-200-valid-file`, `TC-sc-api-400-missing-param`, `TC-sc-api-403-permission`, `TC-sc-api-403-non-localhost`, `TC-sc-api-404-not-found`, `TC-sc-api-404-directory`, `TC-sc-api-415-binary`, `TC-sc-api-headers`, `TC-sc-api-path-traversal`, `TC-sc-edge-api-concurrent-requests`

### `FR-sc-install`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`, `scripts/install-command.sh`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-install-global`, `TC-sc-install-binary-on-path`, `TC-sc-install-claude-code-command`

### `FR-sc-server-shutdown`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-lockfile-write`, `TC-sc-lockfile-stale-cleanup`, `TC-sc-idle-shutdown-fires`, `TC-sc-idle-shutdown-resets`, `TC-sc-explicit-stop-running`, `TC-sc-explicit-stop-not-running`, `TC-sc-signal-handler-cleanup`, `TC-sc-server-reuse-lockfile`, `TC-sc-edge-concurrent-invocations`, `TC-sc-edge-lockfile-directory-missing`

### `FR-sc-output-feedback`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launch-happy-standalone`, `TC-sc-no-args-usage`, `TC-sc-output-success-format`, `TC-sc-output-reuse-note`, `TC-sc-output-errors-stderr`

### `FR-sc-launcher-script`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: `engineering/web/slash-command.md` -> `scripts/shepherd-launch.sh`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launcher-warm-launch`, `TC-sc-launcher-cold-launch`, `TC-sc-single-tool-call`, `TC-sc-launcher-script-validation`, `TC-sc-launcher-server-start`

### `NFR-sc-launch-speed`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launch-speed-cold`, `TC-sc-launch-speed-warm`, `TC-sc-launcher-warm-launch`, `TC-sc-launcher-cold-launch`

### `NFR-sc-no-global-deps`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-install-global`

### `NFR-sc-cross-platform`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`, `TC-sc-path-handling-windows`

### `NFR-sc-localhost-only`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-server-binds-localhost`, `TC-sc-api-403-non-localhost`, `TC-sc-api-path-traversal`

### `NFR-sc-no-telemetry`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-no-outbound-network`

### `NFR-sc-minimal-footprint`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-package-size`, `TC-sc-server-memory`

### `AC-sc-launch-happy-path`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/hooks/useFileFromUrl.ts`, `engineering/apps/web/src/App.tsx`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launch-happy-inrepo`, `TC-sc-launch-happy-standalone`, `TC-sc-auto-load-from-url-param`, `TC-sc-api-200-valid-file`, `TC-sc-output-success-format`

### `AC-sc-absolute-path`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/hooks/useFileFromUrl.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-absolute-path-inrepo`, `TC-sc-absolute-path-standalone`

### `AC-sc-file-not-found`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-file-not-found-cli`, `TC-sc-file-not-found-api`, `TC-sc-api-404-not-found`

### `AC-sc-binary-file-rejected`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-binary-rejected-cli`, `TC-sc-binary-rejected-api`, `TC-sc-api-415-binary`

### `AC-sc-permission-denied`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-permission-denied-cli`, `TC-sc-permission-denied-api`, `TC-sc-api-403-permission`

### `AC-sc-directory-rejected`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-directory-rejected-cli`, `TC-sc-directory-rejected-api`, `TC-sc-api-404-directory`

### `AC-sc-no-args-usage`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-no-args-usage`, `TC-sc-help-flag`

### `AC-sc-large-file-warning`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-large-file-warning-cli`, `TC-sc-large-file-warning-e2e`

### `AC-sc-server-reuse`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-server-reuse-lockfile`, `TC-sc-server-reuse-output`, `TC-sc-output-reuse-note`, `TC-sc-edge-concurrent-invocations`, `TC-sc-server-reuse-same-worktree`

### `AC-sc-server-manual-stop`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-explicit-stop-running`, `TC-sc-explicit-stop-not-running`

### `AC-sc-install-global`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`, `scripts/install-command.sh`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-install-global`, `TC-sc-install-binary-on-path`

### `AC-sc-session-clear-on-new-file`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/hooks/useFileFromUrl.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-session-clear-on-new-file`

### `AC-sc-cross-platform-open`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-cross-platform-macos`, `TC-sc-cross-platform-linux`, `TC-sc-cross-platform-windows`

### `AC-sc-standalone-window`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-app-window-chrome`, `TC-sc-app-window-chromium-fallback`, `TC-sc-app-window-browser-fallback`, `TC-sc-app-window-subsequent`

### `AC-sc-warm-launch-2s`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: `engineering/web/slash-command.md` -> `scripts/shepherd-launch.sh`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launcher-warm-launch`

### `AC-sc-cold-launch-8s`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: `engineering/web/slash-command.md` -> `scripts/shepherd-launch.sh`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-launcher-cold-launch`

### `AC-sc-single-tool-call`
- **Defined in**: `product/slash-command.md`
- **Design**: N/A (no visual changes)
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`, `scripts/shepherd-launch.sh`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-single-tool-call`


### `FR-diff-mode-toggle`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-toggle-to-diff-happy`, `TC-diff-toggle-to-diff-keyboard`, `TC-diff-toggle-to-file-happy`, `TC-diff-toggle-to-file-no-comments`, `TC-diff-switch-clears-comments-confirm`, `TC-diff-switch-clears-comments-cancel`, `TC-diff-switch-no-comments-no-dialog`, `TC-diff-keyboard-toggle-modes`

### `FR-diff-mode-availability`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-paste-disabled`, `TC-diff-upload-disabled`, `TC-diff-drag-drop-disabled`, `TC-diff-disabled-tooltip`

### `FR-diff-baseline-fetch`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-toggle-to-diff-happy`, `TC-diff-toggle-to-diff-loading-state`, `TC-diff-api-head-happy`, `TC-diff-api-head-untracked-404`, `TC-diff-api-head-not-git-repo`, `TC-diff-api-head-binary-415`, `TC-diff-api-head-missing-path`, `TC-diff-api-head-git-unavailable`, `TC-diff-api-routing-no-collision`, `TC-diff-error-network-failure`, `TC-diff-error-git-unavailable`, `TC-diff-error-file-outside-git`, `TC-diff-no-git-history-all-added`

### `FR-diff-compute`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`, `engineering/apps/web/src/lib/diffCompute.test.ts`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-compute-correct-hunks`, `TC-diff-compute-empty-diff`, `TC-diff-compute-all-added`, `TC-diff-compute-all-removed`, `TC-diff-compute-every-line-changed`, `TC-diff-compute-no-newline-at-end`, `TC-diff-compute-performance-10k`

### `FR-diff-display`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-line-numbers-added`, `TC-diff-line-numbers-removed`, `TC-diff-line-numbers-context`, `TC-diff-syntax-highlight-happy`, `TC-diff-syntax-highlight-removed-lines`

### `FR-diff-collapse`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`, `engineering/apps/web/src/lib/diffCompute.test.ts`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-collapse-default-happy`, `TC-diff-collapse-gap-boundary`, `TC-diff-collapse-leading-trailing`, `TC-diff-collapse-adjacent-hunks-small-gap`, `TC-diff-no-git-history-no-collapse`

### `FR-diff-expand`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`, `engineering/apps/web/src/lib/diffCompute.test.ts`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-expand-section-click`, `TC-diff-expand-section-keyboard`, `TC-diff-expand-section-no-recollapse`, `TC-diff-expand-then-comment-happy`, `TC-diff-keyboard-expand-section`

### `FR-diff-comment-create`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`, `engineering/apps/web/src/store/appStore.test.ts`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-comment-added-line-happy`, `TC-diff-comment-added-line-label`, `TC-diff-comment-removed-line-happy`, `TC-diff-comment-removed-line-label`, `TC-diff-comment-context-line-happy`, `TC-diff-comment-context-line-label`, `TC-diff-keyboard-add-comment`

### `FR-diff-comment-on-range`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-comment-range-same-type`, `TC-diff-comment-range-mixed-types`, `TC-diff-comment-range-blocked-by-collapsed`, `TC-diff-keyboard-range-select`

### `FR-diff-prompt-format`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-prompt-includes-diff-happy`, `TC-diff-prompt-diff-notation`, `TC-diff-prompt-comment-labels`, `TC-diff-prompt-collapsed-markers`

### `FR-diff-empty-state`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-no-changes-empty-state`, `TC-diff-no-changes-switch-to-file`

### `FR-diff-refresh`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-refresh-happy`, `TC-diff-refresh-with-comments-confirm`, `TC-diff-refresh-with-comments-cancel`, `TC-diff-refresh-no-comments`, `TC-diff-error-file-deleted-refresh`

### `NFR-diff-compute-perf`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`, `engineering/apps/web/src/lib/diffCompute.test.ts`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-compute-performance-10k`, `TC-diff-compute-perf-large-file`, `TC-diff-compute-every-line-changed`

### `NFR-diff-render-perf`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-render-perf-scroll`

### `NFR-diff-client-compute`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-compute-correct-hunks`, `TC-diff-compute-empty-diff`, `TC-diff-compute-all-added`

### `NFR-diff-baseline-fetch-speed`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-api-head-happy`

### `NFR-diff-accessibility`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-toggle-to-diff-keyboard`, `TC-diff-expand-section-keyboard`, `TC-diff-keyboard-toggle-modes`, `TC-diff-keyboard-navigate-lines`, `TC-diff-keyboard-add-comment`, `TC-diff-keyboard-range-select`, `TC-diff-keyboard-comment-navigation`, `TC-diff-keyboard-expand-section`

### `AC-diff-toggle-to-diff`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-toggle-to-diff-happy`, `TC-diff-toggle-to-diff-keyboard`, `TC-diff-toggle-to-diff-loading-state`, `TC-diff-keyboard-toggle-modes`

### `AC-diff-toggle-to-file`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-toggle-to-file-happy`, `TC-diff-toggle-to-file-no-comments`, `TC-diff-keyboard-toggle-modes`

### `AC-diff-collapse-default`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-collapse-default-happy`, `TC-diff-collapse-gap-boundary`, `TC-diff-collapse-leading-trailing`, `TC-diff-collapse-adjacent-hunks-small-gap`

### `AC-diff-expand-section`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-expand-section-click`, `TC-diff-expand-section-keyboard`, `TC-diff-expand-section-no-recollapse`, `TC-diff-keyboard-expand-section`

### `AC-diff-comment-added-line`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-comment-added-line-happy`, `TC-diff-comment-added-line-label`

### `AC-diff-comment-removed-line`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-comment-removed-line-happy`, `TC-diff-comment-removed-line-label`

### `AC-diff-comment-context-line`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-comment-context-line-happy`, `TC-diff-comment-context-line-label`

### `AC-diff-prompt-includes-diff`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`, `engineering/apps/web/src/lib/promptBuilder.test.ts`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-prompt-includes-diff-happy`, `TC-diff-prompt-diff-notation`, `TC-diff-prompt-comment-labels`, `TC-diff-prompt-collapsed-markers`

### `AC-diff-no-git-history`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-no-git-history-all-added`, `TC-diff-no-git-history-no-collapse`

### `AC-diff-no-changes`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-no-changes-empty-state`, `TC-diff-no-changes-switch-to-file`

### `AC-diff-paste-upload-disabled`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-paste-disabled`, `TC-diff-upload-disabled`, `TC-diff-drag-drop-disabled`, `TC-diff-disabled-tooltip`

### `AC-diff-line-numbers`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-line-numbers-added`, `TC-diff-line-numbers-removed`, `TC-diff-line-numbers-context`, `TC-diff-compute-correct-hunks`

### `AC-diff-syntax-highlight`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-syntax-highlight-happy`, `TC-diff-syntax-highlight-removed-lines`

### `AC-diff-refresh-updates`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-refresh-happy`, `TC-diff-refresh-with-comments-confirm`, `TC-diff-refresh-with-comments-cancel`, `TC-diff-refresh-no-comments`

### `AC-diff-switch-clears-comments`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-switch-clears-comments-confirm`, `TC-diff-switch-clears-comments-cancel`, `TC-diff-switch-no-comments-no-dialog`, `TC-diff-toggle-to-file-no-comments`

### `AC-diff-comment-range`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-comment-range-same-type`, `TC-diff-comment-range-mixed-types`, `TC-diff-comment-range-blocked-by-collapsed`

### `AC-diff-expand-then-comment`
- **Defined in**: `product/diff-view.md`
- **Design**: `design/web/diff-view.md`
- **Engineering**: `engineering/web/diff-view.md`
- **QA**: `qa/web/diff-view.md` -> `TC-diff-expand-then-comment-happy`, `TC-diff-expand-then-comment-gutter-hover`

### `FR-sr-changeset-detection`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-happy-path-batch-open`, `TC-sr-no-changes-on-main`, `TC-sr-no-changes-no-divergence`, `TC-sr-changeset-merge-base`, `TC-sr-renamed-files`

### `FR-sr-file-filtering`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-filters-lockfiles`, `TC-sr-filters-generated-dirs`, `TC-sr-filters-generated-extensions`, `TC-sr-filters-binary`, `TC-sr-filters-ide-files`, `TC-sr-filters-snapshot-files`, `TC-sr-includes-config-files`, `TC-sr-unknown-file-included`

### `FR-sr-file-list-display`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-file-list-format`, `TC-sr-sorted-file-list`, `TC-sr-file-list-exclusion-count`

### `FR-sr-iteration-loop`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-happy-path-batch-open`, `TC-sr-batch-open-all-tabs`, `TC-sr-tab-order-matches-priority`, `TC-sr-implicit-skip`, `TC-sr-done-at-any-point`, `TC-sr-unified-prompt-return`, `TC-sr-no-comments-done`, `TC-sr-interactive-prompt-options`

### `FR-sr-completion-summary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-completion-summary-full`, `TC-sr-completion-summary-no-feedback`, `TC-sr-feedback-action-apply`, `TC-sr-feedback-action-save`

### `FR-sr-command-file`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-command-file-exists`

### `FR-sr-install`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `scripts/install-command.sh`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-install-global-symlink`

### `FR-sr-scope-argument`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-scope-staged`, `TC-sr-scope-unstaged`, `TC-sr-scope-invalid`

### `FR-sr-multi-file-launch`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `scripts/shepherd-launch.sh`, `engineering/apps/web/src/hooks/useFileFromUrl.ts`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-batch-launch-all-files`, `TC-sr-batch-open-all-tabs`, `TC-sr-multi-file-url-params`

### `FR-sr-per-file-context`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-changeset-overview-with-context`

### `FR-sr-changeset-overview`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-changeset-overview-with-context`

### `FR-sr-priority-ordering`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-sorted-file-list`, `TC-sr-tab-order-matches-priority`

### `FR-sr-feedback-collection`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-unified-prompt-return`, `TC-sr-feedback-action-apply`, `TC-sr-feedback-action-save`, `TC-sr-interactive-prompt-options`, `TC-sr-interactive-prompt-cancel`

### `FR-sr-git-required`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md` -> `.claude/commands/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-not-git-repo`

### `NFR-sr-startup-speed`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-startup-speed`

### `NFR-sr-no-dependencies`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-no-external-dependencies`

### `NFR-sr-agent-native`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-happy-path-batch-open`

### `NFR-sr-cross-platform`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-cross-platform-git-commands`

### `AC-sr-happy-path`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-happy-path-batch-open`

### `AC-sr-filters-lockfiles`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-filters-lockfiles`

### `AC-sr-filters-generated`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-filters-generated-dirs`, `TC-sr-filters-generated-extensions`

### `AC-sr-filters-binary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-filters-binary`

### `AC-sr-includes-config`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-includes-config-files`

### `AC-sr-excludes-deleted`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-excludes-deleted-files`

### `AC-sr-skip-file`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-implicit-skip`

### `AC-sr-quit-early`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-done-at-any-point`, `TC-sr-interactive-prompt-cancel`

### `AC-sr-no-changes`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-no-changes-on-main`, `TC-sr-no-changes-no-divergence`

### `AC-sr-all-filtered`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-all-filtered`

### `AC-sr-not-git-repo`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-not-git-repo`

### `AC-sr-invokes-shepherd`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-batch-launch-all-files`

### `AC-sr-list-command`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-changeset-overview-with-context`

### `AC-sr-completion-summary`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-completion-summary-full`, `TC-sr-completion-summary-no-feedback`

### `AC-sr-sorted-file-list`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-sorted-file-list`, `TC-sr-tab-order-matches-priority`

### `AC-sr-batch-open`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-batch-open-all-tabs`, `TC-sr-batch-launch-all-files`

### `AC-sr-unified-prompt`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-unified-prompt-return`

### `AC-sr-install-global`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-install-global-symlink`

### `FR-crp-done-action`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/components/Toolbar.tsx`, `engineering/apps/web/src/hooks/useFileFromUrl.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-done-happy`, `TC-crp-done-keyboard-shortcut`, `TC-crp-done-reset-on-comment-add`, `TC-crp-done-reset-on-comment-edit`, `TC-crp-done-reset-on-comment-delete`, `TC-crp-done-reset-on-preamble-change`, `TC-crp-done-resend-after-failure`, `TC-crp-done-rapid-double-click`, `TC-crp-done-copy-still-works`, `TC-crp-done-auto-close-app-mode`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-sends-prompt`, `TC-crp-macos-done-auto-close-reliable`, `TC-crp-macos-done-disabled-no-comments`, `TC-crp-macos-done-hidden-standalone`

### `FR-crp-prompt-handoff`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/web/slash-command.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-done-happy`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-sends-prompt`, `TC-crp-macos-done-fallback-clipboard`

### `AC-crp-done-sends-prompt`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/components/Toolbar.tsx`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-done-happy`, `TC-crp-done-keyboard-shortcut`, `TC-crp-done-clipboard-parallel`, `TC-crp-done-auto-close-clipboard`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-sends-prompt`

### `AC-crp-done-confirmation`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/components/Toolbar.tsx`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-done-happy`, `TC-crp-done-auto-close-fallback`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-sends-prompt`

### `AC-crp-done-auto-close`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-done-auto-close-app-mode`, `TC-crp-done-auto-close-fallback`, `TC-crp-done-auto-close-clipboard`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-auto-close-reliable`

### `AC-crp-done-fallback-clipboard`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/store/appStore.ts`, `engineering/apps/web/src/lib/clipboard.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-done-fallback-clipboard`, `TC-crp-done-resend-after-failure`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-fallback-clipboard`

### `AC-crp-done-disabled-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/components/Toolbar.tsx`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-done-disabled-no-comments`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-disabled-no-comments`

### `AC-crp-done-standalone-hidden`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/components/Toolbar.tsx`, `engineering/apps/web/src/store/appStore.ts`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-done-hidden-standalone`, `TC-crp-done-hidden-after-clear`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-done-hidden-standalone`

### `FR-sc-prompt-receive`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-watcher-detects-file`, `TC-sc-watcher-deletes-after-read`, `TC-sc-feedback-loop-e2e`, `TC-sc-feedback-loop-resend`

### `FR-sc-prompt-output-api`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-prompt-api-write-happy`, `TC-sc-prompt-api-creates-dir`, `TC-sc-prompt-api-overwrites`, `TC-sc-prompt-api-localhost-only`, `TC-sc-prompt-api-method-check`, `TC-sc-prompt-api-no-collision`, `TC-sc-feedback-loop-e2e`

### `FR-sc-prompt-cleanup`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-watcher-cleanup-stale`

### `NFR-sc-watcher-low-overhead`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-watcher-timeout`

### `AC-sc-prompt-received`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-watcher-detects-file`, `TC-sc-feedback-loop-e2e`

### `AC-sc-prompt-watcher-timeout`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-watcher-timeout`

### `AC-sc-prompt-cleanup-stale`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `.claude/commands/shepherd.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-watcher-cleanup-stale`

### `AC-sc-prompt-output-api-success`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-prompt-api-write-happy`

### `AC-sc-prompt-output-api-localhost-only`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md` -> `engineering/apps/web/src/vite-plugins/fileApiPlugin.ts`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-prompt-api-localhost-only`

### `FR-mdr-detect-markdown`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-detect-md-ext`, `TC-mdr-detect-mdx-ext`, `TC-mdr-detect-markdown-ext`, `TC-mdr-detect-mdown-ext`, `TC-mdr-detect-mkdn-ext`, `TC-mdr-detect-mkd-ext`, `TC-mdr-detect-uppercase-ext`, `TC-mdr-detect-non-md-hidden`, `TC-mdr-detect-no-extension`, `TC-mdr-detect-md-in-directory`

### `FR-mdr-render-toggle`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-toggle-click-rendered`, `TC-mdr-toggle-click-raw`, `TC-mdr-toggle-keyboard`, `TC-mdr-toggle-default-raw`, `TC-mdr-toggle-persists-session`, `TC-mdr-toggle-resets-new-file`, `TC-mdr-toggle-independent-file-diff`

### `FR-mdr-render-commonmark`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-render-headings`, `TC-mdr-render-paragraphs-bold-italic`, `TC-mdr-render-links`, `TC-mdr-render-unordered-lists`, `TC-mdr-render-ordered-lists`, `TC-mdr-render-nested-lists`, `TC-mdr-render-blockquotes`, `TC-mdr-render-horizontal-rules`, `TC-mdr-render-images`, `TC-mdr-render-images-broken`, `TC-mdr-render-inline-code`, `TC-mdr-render-html-blocks-safe`, `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough`, `TC-mdr-render-gfm-autolinks`, `TC-mdr-render-code-blocks-highlighted`, `TC-mdr-render-code-blocks-no-lang`

### `FR-mdr-render-styling`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-style-body-typography`, `TC-mdr-style-heading-hierarchy`, `TC-mdr-style-code-block-theme`, `TC-mdr-style-table-styling`, `TC-mdr-style-max-width`, `TC-mdr-style-blockquote`, `TC-mdr-style-links`

### `FR-mdr-element-id`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-element-id-deterministic`, `TC-mdr-element-id-positional`, `TC-mdr-element-id-all-block-types`

### `FR-mdr-rendered-comment-create`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-comment-paragraph`, `TC-mdr-comment-heading`, `TC-mdr-comment-list-item`, `TC-mdr-comment-code-block`, `TC-mdr-comment-table`, `TC-mdr-comment-blockquote`, `TC-mdr-comment-multiple-same-element`, `TC-mdr-comment-hover-affordance`, `TC-mdr-comment-cmd-click`, `TC-mdr-comment-bubble-label`, `TC-mdr-comment-count-increments`

### `FR-mdr-rendered-comment-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-prompt-raw-source-lines`, `TC-mdr-prompt-element-type`, `TC-mdr-prompt-format-structure`, `TC-mdr-prompt-multiple-comments-order`, `TC-mdr-prompt-no-preamble`, `TC-mdr-prompt-with-preamble`

### `FR-mdr-switch-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-switch-with-comments-confirm`, `TC-mdr-switch-with-comments-cancel`, `TC-mdr-switch-no-comments-immediate`, `TC-mdr-switch-preamble-preserved`, `TC-mdr-switch-raw-to-rendered`, `TC-mdr-switch-rendered-to-raw`, `TC-mdr-switch-rendered-file-to-rendered-diff`, `TC-mdr-switch-rendered-diff-to-rendered-file`

### `FR-mdr-raw-diff-unchanged`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-raw-file-identical`, `TC-mdr-raw-diff-identical`

### `FR-mdr-rendered-diff-display`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-added-block`, `TC-mdr-rdiff-removed-block`, `TC-mdr-rdiff-modified-block-word-diff`, `TC-mdr-rdiff-unchanged-block`, `TC-mdr-rdiff-no-changes`, `TC-mdr-rdiff-fallback-banner`, `TC-mdr-rdiff-fallback-switch-link`, `TC-mdr-rdiff-fallback-dismiss`, `TC-mdr-rdiff-loading-spinner`, `TC-mdr-rdiff-timeout-fallback`

### `FR-mdr-rendered-diff-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-comment-added`, `TC-mdr-rdiff-comment-removed`, `TC-mdr-rdiff-comment-modified`, `TC-mdr-rdiff-comment-unchanged`, `TC-mdr-rdiff-comment-anchor-qualifier`

### `FR-mdr-rendered-diff-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-prompt-modified-old-new`, `TC-mdr-rdiff-prompt-added-new-only`, `TC-mdr-rdiff-prompt-removed-old-only`, `TC-mdr-rdiff-prompt-heading-format`, `TC-mdr-rdiff-prompt-document-order`

### `NFR-mdr-render-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-perf-render-5k`, `TC-mdr-perf-render-10k`, `TC-mdr-perf-render-ui-block`

### `NFR-mdr-render-scroll-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-perf-scroll-smooth`, `TC-mdr-perf-scroll-content-visibility`

### `NFR-mdr-rendered-diff-perf`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-perf-rdiff-5k`, `TC-mdr-perf-rdiff-10k`, `TC-mdr-perf-rdiff-timeout`

### `NFR-mdr-xss-safety`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-xss-script-tag`, `TC-mdr-xss-event-handler`, `TC-mdr-xss-javascript-url`, `TC-mdr-xss-iframe`, `TC-mdr-xss-svg-script`, `TC-mdr-xss-data-url`, `TC-mdr-xss-safe-html-preserved`

### `NFR-mdr-client-only`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-client-only-no-requests`

### `NFR-mdr-accessibility`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-a11y-keyboard-nav`, `TC-mdr-a11y-keyboard-comment`, `TC-mdr-a11y-screen-reader-elements`, `TC-mdr-a11y-screen-reader-diff`, `TC-mdr-a11y-focus-on-mode-switch`, `TC-mdr-a11y-aria-toggle`, `TC-mdr-a11y-aria-rendered-content`, `TC-mdr-a11y-aria-diff-annotations`

### `AC-mdr-toggle-appears`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-toggle-click-rendered`, `TC-mdr-toggle-default-raw`, `TC-mdr-detect-md-ext`

### `AC-mdr-toggle-hidden-non-md`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-detect-non-md-hidden`

### `AC-mdr-render-basic`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-render-headings`, `TC-mdr-render-paragraphs-bold-italic`, `TC-mdr-render-links`, `TC-mdr-render-unordered-lists`

### `AC-mdr-render-gfm`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-render-gfm-tables`, `TC-mdr-render-gfm-task-lists`, `TC-mdr-render-gfm-strikethrough`

### `AC-mdr-render-code-blocks`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-render-code-blocks-highlighted`

### `AC-mdr-raw-unchanged`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-raw-file-identical`, `TC-mdr-raw-diff-identical`

### `AC-mdr-comment-rendered-element`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-comment-paragraph`, `TC-mdr-comment-hover-affordance`, `TC-mdr-comment-bubble-label`

### `AC-mdr-comment-heading`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-comment-heading`, `TC-mdr-prompt-raw-source-lines`

### `AC-mdr-comment-prompt-format`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-prompt-raw-source-lines`, `TC-mdr-prompt-format-structure`

### `AC-mdr-switch-clears-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-switch-with-comments-confirm`, `TC-mdr-switch-with-comments-cancel`

### `AC-mdr-switch-no-comments`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-switch-no-comments-immediate`

### `AC-mdr-rendered-diff-additions`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-added-block`

### `AC-mdr-rendered-diff-removals`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-removed-block`

### `AC-mdr-rendered-diff-modifications`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-modified-block-word-diff`

### `AC-mdr-rendered-diff-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-comment-added`, `TC-mdr-rdiff-comment-modified`

### `AC-mdr-rendered-diff-prompt`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-prompt-modified-old-new`, `TC-mdr-rdiff-prompt-added-new-only`, `TC-mdr-rdiff-prompt-removed-old-only`

### `AC-mdr-html-sanitized`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-xss-script-tag`, `TC-mdr-xss-event-handler`, `TC-mdr-xss-javascript-url`, `TC-mdr-xss-iframe`, `TC-mdr-xss-svg-script`

### `AC-mdr-large-file-renders`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-perf-render-5k`, `TC-mdr-perf-scroll-smooth`

### `AC-mdr-keyboard-comment`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-a11y-keyboard-comment`

### `AC-mdr-diff-fallback`
- **Defined in**: `product/markdown-render.md`
- **Design**: `design/web/markdown-render.md`
- **Engineering**: `engineering/web/markdown-render.md`
- **QA**: `qa/web/markdown-render.md` -> `TC-mdr-rdiff-fallback-banner`, `TC-mdr-rdiff-fallback-switch-link`, `TC-mdr-rdiff-timeout-fallback`

### `FR-dm-system-preference`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-system-dark-default`, `TC-dm-system-light-default`, `TC-dm-system-no-preference`

### `FR-dm-manual-toggle`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-toggle-to-dark`, `TC-dm-toggle-to-light`, `TC-dm-toggle-to-system`, `TC-dm-toggle-keyboard`

### `FR-dm-persistence`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-persist-dark-reload`, `TC-dm-persist-system-reload`, `TC-dm-persist-no-localstorage`, `TC-dm-persist-corrupt-value`

### `FR-dm-realtime-tracking`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-realtime-os-dark-to-light`, `TC-dm-realtime-manual-ignores-os`

### `FR-dm-full-surface-coverage`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-surface-toolbar`, `TC-dm-surface-code-viewer`, `TC-dm-surface-comments`, `TC-dm-surface-sidebar`, `TC-dm-surface-drop-zone`, `TC-dm-surface-diff-view`, `TC-dm-surface-dialogs`, `TC-dm-surface-toasts`

### `FR-dm-css-custom-properties`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-surface-toolbar`, `TC-dm-surface-code-viewer`, `TC-dm-surface-comments`, `TC-dm-surface-sidebar`

### `NFR-dm-no-fouc`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-no-fouc-dark`, `TC-dm-no-fouc-system`

### `NFR-dm-smooth-transition`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-transition-smooth`, `TC-dm-transition-no-initial`

### `NFR-dm-syntax-highlight-both-themes`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-syntax-dark-readable`, `TC-dm-syntax-light-readable`, `TC-dm-syntax-no-reparse`

### `NFR-dm-contrast-ratios`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-a11y-contrast-light`, `TC-dm-a11y-contrast-dark`

### `NFR-dm-no-performance-impact`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-perf-no-regression`

### `AC-dm-default-respects-system`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-system-dark-default`, `TC-dm-no-fouc-dark`

### `AC-dm-default-light-system`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-system-light-default`, `TC-dm-system-no-preference`

### `AC-dm-toggle-to-dark`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-toggle-to-dark`, `TC-dm-transition-smooth`

### `AC-dm-toggle-to-light`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-toggle-to-light`, `TC-dm-transition-smooth`

### `AC-dm-toggle-to-system`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-toggle-to-system`

### `AC-dm-persistence-survives-reload`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-persist-dark-reload`

### `AC-dm-persistence-system-survives-reload`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-persist-system-reload`

### `AC-dm-realtime-os-change`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-realtime-os-dark-to-light`

### `AC-dm-manual-ignores-os`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-realtime-manual-ignores-os`

### `AC-dm-syntax-highlight-dark`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-syntax-dark-readable`

### `AC-dm-syntax-highlight-light`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-syntax-light-readable`

### `AC-dm-all-surfaces-themed`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-surface-toolbar`, `TC-dm-surface-code-viewer`, `TC-dm-surface-comments`, `TC-dm-surface-sidebar`, `TC-dm-surface-drop-zone`, `TC-dm-surface-diff-view`, `TC-dm-surface-dialogs`, `TC-dm-surface-toasts`

### `AC-dm-diff-view-themed`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-surface-diff-view`

### `AC-dm-drop-zone-themed`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-surface-drop-zone`

### `AC-dm-dialog-themed`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-surface-dialogs`

### `AC-dm-no-fouc`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-no-fouc-dark`, `TC-dm-no-fouc-system`

### `AC-dm-localstorage-unavailable`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-persist-no-localstorage`

### `AC-dm-keyboard-toggle`
- **Defined in**: `product/dark-mode.md`
- **Design**: `design/web/dark-mode.md`
- **Engineering**: `engineering/web/dark-mode.md`
- **QA**: `qa/web/dark-mode.md` -> `TC-dm-toggle-keyboard`, `TC-dm-a11y-toggle-aria`

### `FR-crp-multi-file-load`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-load-second`, `TC-crp-multi-file-load-paste-adds`, `TC-crp-multi-file-drop-multiple-happy`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-load-adds`, `TC-crp-macos-multi-file-drop-multiple`

### `FR-crp-multi-file-nav`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-switch-preserves-comments`, `TC-crp-multi-file-tab-shows-info`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-switch-preserves`, `TC-crp-macos-file-tree-disambiguates-same-name`, `TC-crp-macos-file-tree-collapse-expand`

### `FR-crp-multi-file-remove`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-remove-with-comments-confirm`, `TC-crp-multi-file-remove-no-comments-immediate`, `TC-crp-multi-file-remove-active-switches`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-remove-with-comments`, `TC-crp-macos-multi-file-remove-no-comments`, `TC-crp-macos-multi-file-remove-last-empty`

### `FR-crp-multi-file-prompt`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-prompt-structure-happy`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-prompt-structure`

### `FR-crp-multi-file-prompt-format`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-prompt-structure-happy`, `TC-crp-multi-file-prompt-order`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-prompt-structure`, `TC-crp-macos-multi-file-prompt-omits-uncommented`

### `AC-crp-multi-file-load-adds`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-load-second`, `TC-crp-multi-file-load-paste-adds`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-load-adds`

### `AC-crp-multi-file-drop-multiple`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-drop-multiple-happy`, `TC-crp-multi-file-drop-mixed-binary`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-drop-multiple`

### `AC-crp-multi-file-nav-preserves-state`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-switch-preserves-comments`, `TC-crp-multi-file-switch-preserves-scroll`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-switch-preserves`

### `AC-crp-multi-file-remove-with-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-remove-with-comments-confirm`, `TC-crp-multi-file-remove-with-comments-cancel`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-remove-with-comments`

### `AC-crp-multi-file-remove-no-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-remove-no-comments-immediate`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-remove-no-comments`

### `AC-crp-multi-file-prompt-structure`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-prompt-structure-happy`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-prompt-structure`

### `AC-crp-multi-file-prompt-omits-uncommented`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-prompt-omits-uncommented`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-prompt-omits-uncommented`

### `AC-crp-multi-file-comment-count`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-comment-count-global`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-comment-count-global`

### `AC-crp-multi-file-clear-all`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-clear-all-confirm`, `TC-crp-multi-file-clear-all-resets`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-clear-all`

### `AC-crp-multi-file-empty-after-remove-last`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-multi-file-remove-last-empty-state`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-multi-file-remove-last-empty`

### `AC-crp-file-path-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tree-disambiguates-same-name`

### `AC-crp-file-path-single-dir`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tree-single-dir`

### `FR-sr-context-handoff`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-context-handoff`

### `AC-sr-context-in-crpg`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-context-in-crpg`

### `AC-sr-auto-open`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-auto-open`

### `AC-sr-interactive-prompt`
- **Defined in**: `product/shepherd-review.md`
- **Design**: `design/web/shepherd-review.md`
- **Engineering**: `engineering/web/shepherd-review.md`
- **QA**: `qa/web/shepherd-review.md` -> `TC-sr-interactive-prompt-options`, `TC-sr-interactive-prompt-cancel`

### `FR-crp-review-context-receive`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-graceful-missing`, `TC-crp-context-overall-visible`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-graceful-missing`

### `FR-crp-review-context-display`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-overall-visible`, `TC-crp-context-per-file-visible`, `TC-crp-context-neutral-vs-review`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-per-file-visible`, `TC-crp-macos-context-neutral-vs-review`

### `FR-crp-review-context-overall`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-overall-visible`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-overall-visible`, `TC-crp-macos-context-sidebar-collapse`

### `FR-crp-review-context-per-file`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-per-file-visible`, `TC-crp-context-per-file-switches`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-per-file-visible`, `TC-crp-macos-context-per-file-switches`

### `AC-crp-context-overall-visible`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-overall-visible`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-overall-visible`

### `AC-crp-context-per-file-visible`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-per-file-visible`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-per-file-visible`

### `AC-crp-context-per-file-switches`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-per-file-switches`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-per-file-switches`

### `AC-crp-context-neutral-vs-review`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-neutral-vs-review`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-neutral-vs-review`

### `AC-crp-context-graceful-missing`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-graceful-missing`, `TC-crp-context-sidebar-hidden`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-graceful-missing`

### `AC-crp-context-readonly`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-readonly`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-readonly`

### `FR-crp-file-reviewed-toggle`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-mark-reviewed-happy`, `TC-crp-unmark-reviewed-happy`, `TC-crp-mark-reviewed-via-tab`, `TC-crp-mark-reviewed-keyboard`, `TC-crp-reviewed-edge-rapid-toggle`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-mark-reviewed-happy`, `TC-crp-macos-unmark-reviewed-happy`

### `FR-crp-file-reviewed-visual`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-mark-reviewed-happy`, `TC-crp-unmark-reviewed-happy`, `TC-crp-reviewed-visual-tab-states`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-mark-reviewed-happy`, `TC-crp-macos-unmark-reviewed-happy`

### `FR-crp-file-reviewed-grouping`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-reviewed-grouping-display`, `TC-crp-reviewed-grouping-all-reviewed`, `TC-crp-reviewed-grouping-none-reviewed`, `TC-crp-reviewed-new-file-unreviewed`, `TC-crp-reviewed-edge-single-file-reviewed`, `TC-crp-reviewed-edge-add-after-all-reviewed`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-grouping-tree`

### `FR-crp-file-reviewed-progress`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-reviewed-progress-display`, `TC-crp-reviewed-progress-updates`, `TC-crp-reviewed-progress-hidden-single`, `TC-crp-reviewed-remove-file-discards`, `TC-crp-reviewed-edge-add-after-all-reviewed`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-progress-count`

### `FR-crp-file-reviewed-persistence`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-reviewed-survives-tab-switch`, `TC-crp-reviewed-clear-session-resets`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-survives-tab-switch`, `TC-crp-macos-reviewed-clear-session-resets`

### `AC-crp-file-mark-reviewed`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-mark-reviewed-happy`, `TC-crp-mark-reviewed-via-tab`, `TC-crp-mark-reviewed-keyboard`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-mark-reviewed-happy`

### `AC-crp-file-unmark-reviewed`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-unmark-reviewed-happy`, `TC-crp-mark-reviewed-keyboard`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-unmark-reviewed-happy`

### `AC-crp-file-reviewed-grouping`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-reviewed-grouping-display`, `TC-crp-reviewed-grouping-all-reviewed`, `TC-crp-reviewed-grouping-none-reviewed`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-grouping-tree`

### `AC-crp-file-reviewed-progress-count`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-reviewed-progress-display`, `TC-crp-reviewed-progress-updates`, `TC-crp-reviewed-progress-hidden-single`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-progress-count`

### `AC-crp-file-reviewed-survives-tab-switch`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-reviewed-survives-tab-switch`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-survives-tab-switch`

### `AC-crp-file-reviewed-with-comments`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-reviewed-independent-of-comments`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-independent-of-comments`

### `AC-crp-file-reviewed-clear-session`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-reviewed-clear-session-resets`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-reviewed-clear-session-resets`

### `FR-crp-review-context-collapsible`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-sidebar-collapse`

### `AC-crp-context-sidebar-collapse`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-context-sidebar-collapse`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-context-sidebar-collapse`

### `AC-crp-overall-comment-label`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-overall-comment-label`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-overall-comment-label`

### `AC-crp-overall-comment-in-prompt`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-overall-comment-in-prompt`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-overall-comment-in-prompt`

### `FR-crp-comment-summary`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-comment-summary-shows-all`, `TC-crp-comment-summary-realtime`, `TC-crp-comment-summary-empty`, `TC-crp-comment-summary-click-navigates`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-summary-shows-all`, `TC-crp-macos-comment-summary-realtime`, `TC-crp-macos-comment-summary-empty`

### `AC-crp-comment-summary-shows-all`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-comment-summary-shows-all`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-summary-shows-all`

### `AC-crp-comment-summary-realtime`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-comment-summary-realtime`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-summary-realtime`

### `AC-crp-comment-summary-empty`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-comment-summary-empty`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-comment-summary-empty`

### `FR-crp-line-wrap`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-line-wrap-toggle-on`, `TC-crp-line-wrap-toggle-off`, `TC-crp-line-wrap-keyboard-shortcut`, `TC-crp-line-wrap-gutter-alignment`, `TC-crp-line-wrap-range-selection`, `TC-crp-line-wrap-comment-navigation`, `TC-crp-line-wrap-toggle-disabled-empty`, `TC-crp-line-wrap-toggle-performance`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-toggle-on`, `TC-crp-macos-line-wrap-toggle-off`, `TC-crp-macos-line-wrap-default-on`, `TC-crp-macos-line-wrap-persists-session`

### `AC-crp-line-wrap-toggle`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-line-wrap-toggle-on`, `TC-crp-line-wrap-toggle-off`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-toggle-on`, `TC-crp-macos-line-wrap-toggle-off`

### `AC-crp-line-wrap-preserves-line-numbers`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-line-wrap-line-numbers`, `TC-crp-line-wrap-gutter-alignment`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-preserves-line-numbers`

### `AC-crp-line-wrap-comment-target`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-line-wrap-comment-click`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-comment-target`

### `AC-crp-line-wrap-default-on`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-line-wrap-default-on`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-default-on`

### `AC-crp-line-wrap-persists-session`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-line-wrap-persists-file-switch`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-line-wrap-persists-session`

### `FR-sc-session-id`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`, `engineering/web/code-review-prompt.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-session-id-generated`, `TC-sc-session-id-deterministic`

### `FR-sc-dynamic-port`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-dynamic-port`, `TC-sc-separate-servers-different-worktrees`

### `FR-sc-session-scoped-output`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`, `engineering/web/shepherd-review.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-session-scoped-output-path`; `qa/web/shepherd-review.md` -> `TC-sr-concurrent-review-sessions`

### `FR-sc-concurrent-windows`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-concurrent-sessions-happy`

### `FR-sc-session-cleanup`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-session-cleanup-after-read`

### `FR-crp-session-identity`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/web/slash-command.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/slash-command.md`, `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-session-identity-window-title`, `TC-crp-session-identity-standalone`; `qa/web/slash-command.md` -> `TC-sc-window-title-shows-project`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-session-identity-title`, `TC-crp-macos-session-identity-standalone`

### `AC-sc-concurrent-sessions`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-concurrent-sessions-happy`; `qa/web/shepherd-review.md` -> `TC-sr-concurrent-review-sessions`

### `AC-sc-session-output-isolation`
- **Defined in**: `product/slash-command.md`
- **Design**: `design/web/slash-command.md`
- **Engineering**: `engineering/web/slash-command.md`
- **QA**: `qa/web/slash-command.md` -> `TC-sc-session-output-isolation`

### `FR-crp-panel-resize`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-panel-resize-drag`, `TC-crp-panel-resize-min-bound`, `TC-crp-panel-resize-max-bound`, `TC-crp-panel-resize-double-click-reset`, `TC-crp-panel-resize-persists-file-switch`, `TC-crp-panel-resize-keyboard`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-drag`, `TC-crp-macos-panel-resize-min-max`, `TC-crp-macos-panel-resize-double-click-reset`

### `FR-crp-active-file-path`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-active-file-path-visible`, `TC-crp-active-file-path-switches`, `TC-crp-active-file-path-hidden-single`, `TC-crp-active-file-path-pasted-file`, `TC-crp-active-file-path-transition`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-active-file-path-visible`, `TC-crp-macos-active-file-path-switches`, `TC-crp-macos-active-file-path-hidden-single`

### `FR-crp-file-tooltip`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/components/FileBrowser.tsx`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-file-tooltip-shows-path`, `TC-crp-file-tooltip-reviewed-status`, `TC-crp-file-tooltip-pasted-file`, `TC-crp-file-tooltip-truncated-name`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tooltip-full-path`, `TC-crp-macos-file-tooltip-reviewed-status`

### `AC-crp-panel-resize-drag`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-panel-resize-drag`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-drag`

### `AC-crp-panel-resize-bounds`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-panel-resize-min-bound`, `TC-crp-panel-resize-max-bound`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-min-max`

### `AC-crp-panel-resize-double-click`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-panel-resize-double-click-reset`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-double-click-reset`

### `AC-crp-panel-resize-persists`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-panel-resize-persists-file-switch`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-panel-resize-persists-file-switch`

### `AC-crp-active-file-path-visible`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-active-file-path-visible`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-active-file-path-visible`

### `AC-crp-active-file-path-switches`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-active-file-path-switches`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-active-file-path-switches`

### `AC-crp-active-file-path-single-file`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-active-file-path-hidden-single`, `TC-crp-active-file-path-transition`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-active-file-path-hidden-single`

### `AC-crp-file-tooltip-full-path`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/components/FileBrowser.tsx`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-file-tooltip-shows-path`, `TC-crp-file-tooltip-pasted-file`, `TC-crp-file-tooltip-truncated-name`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tooltip-full-path`

### `AC-crp-file-tooltip-reviewed`
- **Defined in**: `product/code-review-prompt.md`
- **Design**: `design/web/code-review-prompt.md`, `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/web/code-review-prompt.md`, `engineering/apps/web/src/components/FileBrowser.tsx`, `engineering/macos/code-review-prompt.md`
- **QA**: `qa/web/code-review-prompt.md` -> `TC-crp-file-tooltip-reviewed-status`; `qa/macos/code-review-prompt.md` -> `TC-crp-macos-file-tooltip-reviewed-status`
### `FR-crp-macos-window-management`
- **Defined in**: `product/macos/code-review-prompt.md`
- **Design**: `design/macos/code-review-prompt.md`
- **Engineering**: `engineering/macos/code-review-prompt.md`
- **QA**: `qa/macos/code-review-prompt.md` -> `TC-crp-macos-window-multi-session`, `TC-crp-macos-window-restore-geometry`, `TC-crp-macos-window-min-size`, `TC-crp-macos-close-last-window-keeps-running`

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

<!--
Entry template -- copy this when adding a new slug:

### `FR-feature-slug`
- **Defined in**: `product/feature.md`
- **Design**: `design/web/feature.md`
- **Engineering**: `engineering/web/feature.md`, `engineering/apps/web/src/path/to/file.ext`
- **QA**: `qa/web/feature.md` -> `TC-feature-slug`
-->
