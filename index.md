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

<!--
Entry template -- copy this when adding a new slug:

### `FR-feature-slug`
- **Defined in**: `product/feature.md`
- **Design**: `design/feature.md`
- **Engineering**: `engineering/feature.md`, `engineering/src/path/to/file.ext`
- **QA**: `qa/feature.md` -> `TC-feature-slug`
-->
