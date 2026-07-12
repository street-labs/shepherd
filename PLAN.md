# Markdown Rendered View Implementation Plan

Based on `engineering/macos/markdown-render.md`

## Phase 1: Foundation (Days 1-2) ✅ COMPLETE

### ✅ Task 1.1: Add swift-markdown dependency
- **File**: `engineering/apps/macos/Package.swift`
- **Action**: Add swift-markdown package dependency
- **Verification**: `swift build` succeeds
- **Implements**: Foundation for FR-mdr-render-commonmark
- **Completed**: commit c42b4cb

### ✅ Task 1.2: Build MarkdownParser
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/MarkdownParser.swift`
  - `engineering/apps/macos/Tests/MarkdownRenderFeatureTests/MarkdownParserTests.swift`
- **Action**: Parse markdown to AST, assign element IDs, map source ranges
- **Verification**: Unit tests with sample markdown files (basic, GFM, nested lists, code blocks)
- **Implements**: FR-mdr-render-commonmark, FR-mdr-element-id
- **Completed**: commit b57dc56 (10/10 tests passing)

### ✅ Task 1.3: Build GFMVisitor
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/GFMVisitor.swift`
  - `engineering/apps/macos/Tests/MarkdownRenderFeatureTests/GFMVisitorTests.swift`
- **Action**: Extend swift-markdown with GFM table/task list/strikethrough support
- **Verification**: Test with GFM samples
- **Implements**: FR-mdr-render-commonmark (GFM extensions)
- **Completed**: commit 525e69c (9/9 tests passing)

## Phase 2: Basic Rendering (Days 3-4) ✅ COMPLETE

### ✅ Task 2.1: Build RenderedMarkdownView (file mode)
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift`
  - `engineering/apps/macos/Tests/MarkdownRenderFeatureTests/RenderedMarkdownViewTests.swift`
- **Action**: Render AST as SwiftUI views. Start with basic elements (headings, paragraphs, lists), then add tables, code blocks, images
- **Verification**: Snapshot tests for rendering fidelity
- **Implements**: FR-mdr-render-commonmark, FR-mdr-render-styling
- **Completed**: commit a915ee0 (12/12 tests passing)

### ✅ Task 2.2: Wire up rendered view with toggle
- **Files**:
  - `engineering/apps/macos/Sources/AppFeature/AppFeature.swift`
  - `engineering/apps/macos/Sources/AppFeature/ToolbarView.swift`
  - `engineering/apps/macos/Sources/AppFeature/CodeViewerPanelView.swift`
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/MarkdownRenderMode.swift`
  - `engineering/apps/macos/Sources/SharedModels/FileNode.swift`
- **Action**: Add `renderMode: MarkdownRenderMode` to state, add segmented control to toolbar, wire up conditional rendering
- **Verification**: Integration tests for toggle switches view between raw and rendered
- **Implements**: FR-mdr-render-toggle, FR-mdr-detect-markdown
- **Completed**: commit 02bfd3e (all tests passing)

## Phase 3: Comment Interaction (Days 5-6)

### ✅ Task 3.1: Build comment interaction in rendered view
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift` (extend)
  - `engineering/apps/macos/Tests/MarkdownRenderFeatureTests/CommentInteractionTests.swift`
- **Action**: Add hover affordance, click-to-comment, element ID anchoring
- **Verification**: UI tests for comment creation/editing/deletion
- **Implements**: FR-mdr-rendered-comment-create

### ✅ Task 3.2: Store rendered comments
- **Files**:
  - `engineering/apps/macos/Sources/AppFeature/AppFeature.swift` (extend)
  - `engineering/apps/macos/Sources/SharedModels/RenderedComment.swift`
- **Action**: Add `renderedComments: [String: [RenderedComment]]` dict to state
- **Verification**: TCA TestStore validates comment state mutations
- **Implements**: FR-mdr-rendered-comment-create (storage)

### ✅ Task 3.3: Build prompt generation from rendered comments
- **Files**:
  - `engineering/apps/macos/Sources/PromptFeature/PromptBuilder.swift` (extend)
  - `engineering/apps/macos/Tests/PromptFeatureTests/RenderedPromptTests.swift`
- **Action**: Map element IDs to raw source line ranges, generate prompt format
- **Verification**: Unit tests verify prompt output matches design spec format
- **Implements**: FR-mdr-rendered-comment-prompt

### ✅ Task 3.4: Add mode-switch confirmation dialog
- **Files**:
  - `engineering/apps/macos/Sources/AppFeature/AppFeature.swift` (extend)
  - `engineering/apps/macos/Sources/AppFeature/ConfirmationDialogView.swift`
- **Action**: Show dialog if comments exist when switching modes
- **Verification**: Integration test for confirmation flow (cancel, clear+switch)
- **Implements**: FR-mdr-switch-comments

## Phase 4: Diff Rendering (Days 7-9)

### ✅ Task 4.1: Build MarkdownDiffer
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/MarkdownDiffer.swift`
  - `engineering/apps/macos/Tests/MarkdownRenderFeatureTests/MarkdownDifferTests.swift`
- **Action**: LCS-based block diff, word-level diff for modified blocks
- **Verification**: Unit test with sample baseline/working pairs
- **Implements**: FR-mdr-rendered-diff-display (computation)

### ✅ Task 4.2: Build RenderedMarkdownView (diff mode)
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift` (extend)
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/DiffAnnotationView.swift`
- **Action**: Render working AST with diff annotations. Add DiffAnnotationView wrapper for visual treatments (green/red borders, strikethrough, word highlights)
- **Verification**: Snapshot tests for diff rendering
- **Implements**: FR-mdr-rendered-diff-display (rendering)

### ✅ Task 4.3: Add diff comment interaction
- **Files**:
  - `engineering/apps/macos/Sources/AppFeature/AppFeature.swift` (extend)
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift` (extend)
- **Action**: Support commenting on added/removed/modified elements. Store in `renderedDiffComments` dict
- **Verification**: UI tests for diff comment creation
- **Implements**: FR-mdr-rendered-diff-comment

### ✅ Task 4.4: Build prompt generation from rendered diff comments
- **Files**:
  - `engineering/apps/macos/Sources/PromptFeature/PromptBuilder.swift` (extend)
  - `engineering/apps/macos/Tests/PromptFeatureTests/RenderedDiffPromptTests.swift`
- **Action**: Include old/new source for modified elements
- **Verification**: Unit tests verify prompt format
- **Implements**: FR-mdr-rendered-diff-prompt

## Phase 5: Security & Edge Cases (Days 10-11)

### ✅ Task 5.1: Build MarkdownSanitizer
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/MarkdownSanitizer.swift`
  - `engineering/apps/macos/Tests/MarkdownRenderFeatureTests/SanitizerTests.swift`
- **Action**: Strip dangerous HTML (script tags, event handlers, javascript: URLs)
- **Verification**: Test with XSS payloads, verify script tags are removed
- **Implements**: NFR-mdr-xss-safety

### ✅ Task 5.2: Add fallback banner for heavily restructured diffs
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift` (extend)
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/DiffFallbackBanner.swift`
- **Action**: Detect > 80% changed blocks, show banner, provide switch-to-raw button
- **Verification**: Integration test with heavily edited files
- **Implements**: FR-mdr-rendered-diff-display (fallback)

## Phase 6: Polish & Performance (Days 12-14)

### ✅ Task 6.1: Keyboard navigation + accessibility
- **Files**:
  - `engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift` (extend)
- **Action**: Make elements focusable, add ARIA labels for diff annotations, test with VoiceOver
- **Verification**: Manual testing with VoiceOver, UI tests for keyboard navigation
- **Implements**: NFR-mdr-accessibility

### ✅ Task 6.2: Performance testing & optimization
- **Files**:
  - `engineering/apps/macos/Tests/MarkdownRenderFeatureTests/PerformanceTests.swift`
- **Action**: Measure parse/render/diff times with 5k, 10k line files. Optimize if exceeding budgets
- **Verification**: Performance tests pass within budgets
- **Implements**: NFR-mdr-render-perf, NFR-mdr-render-scroll-perf, NFR-mdr-rendered-diff-perf

### ✅ Task 6.3: Final integration testing
- **Files**:
  - `engineering/apps/macos/Tests/AppFeatureTests/MarkdownRenderIntegrationTests.swift`
- **Action**: End-to-end flows (load markdown → toggle to rendered → add comment → verify prompt, diff computation → render → comment)
- **Verification**: All integration tests pass
- **Implements**: All requirements end-to-end

## Definition of Done

- [ ] All 12 functional requirements have `// Implements:` markers in code
- [ ] Code Map in `engineering/macos/markdown-render.md` updated with Status `implemented`
- [ ] All unit tests pass (`swift test`)
- [ ] All snapshot tests pass (rendering fidelity verified)
- [ ] Performance budgets met (200ms render for 5k lines, 1s diff for 5k lines)
- [ ] XSS sanitization verified (script tags stripped)
- [ ] Accessibility verified (keyboard navigation, VoiceOver announcements)
- [ ] QA test plan executed (40+ test cases from `qa/macos/markdown-render.md`)
- [ ] Traceability audit passes (`./scripts/audit-traceability.sh`)
- [ ] All specs updated to reflect implementation reality

## Estimated Timeline

- **Phase 1 (Foundation):** 2 days
- **Phase 2 (Basic Rendering):** 2 days
- **Phase 3 (Comment Interaction):** 2 days
- **Phase 4 (Diff Rendering):** 3 days
- **Phase 5 (Security & Edge Cases):** 2 days
- **Phase 6 (Polish & Performance):** 3 days
- **Total:** ~14 days (2 weeks)

## Current Status

- ✅ Specs complete (design, engineering, QA)
- ✅ Traceability index updated
- ✅ PR #17 open for review
- 🚧 Ready to start Phase 1

## Next Immediate Step

Start with **Task 1.1**: Add swift-markdown dependency to `Package.swift`
