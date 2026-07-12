---
product-hash: 69829a16ab804671ab7c7469445cb1a699d3b2681aaf502ea3fececb4cf858bd
product-slugs: [AC-mdr-comment-heading, AC-mdr-comment-prompt-format, AC-mdr-comment-rendered-element, AC-mdr-diff-fallback, AC-mdr-html-sanitized, AC-mdr-keyboard-comment, AC-mdr-large-file-renders, AC-mdr-raw-unchanged, AC-mdr-render-basic, AC-mdr-render-code-blocks, AC-mdr-render-gfm, AC-mdr-rendered-diff-additions, AC-mdr-rendered-diff-comment, AC-mdr-rendered-diff-modifications, AC-mdr-rendered-diff-prompt, AC-mdr-rendered-diff-removals, AC-mdr-switch-clears-comments, AC-mdr-switch-no-comments, AC-mdr-toggle-appears, AC-mdr-toggle-hidden-non-md, FR-mdr-detect-markdown, FR-mdr-element-id, FR-mdr-raw-diff-unchanged, FR-mdr-render-commonmark, FR-mdr-render-styling, FR-mdr-render-toggle, FR-mdr-rendered-comment-create, FR-mdr-rendered-comment-prompt, FR-mdr-rendered-diff-comment, FR-mdr-rendered-diff-display, FR-mdr-rendered-diff-prompt, FR-mdr-switch-comments, NFR-mdr-accessibility, NFR-mdr-client-only, NFR-mdr-render-perf, NFR-mdr-render-scroll-perf, NFR-mdr-rendered-diff-perf, NFR-mdr-xss-safety]
---
# Markdown Rendered View — macOS Technical Spec

> Based on requirements in `../../product/markdown-render.md`
> Based on design in `../../design/macos/markdown-render.md`

## What We're Building

A SwiftUI-based rendered markdown view that parses markdown to an AST, renders it as native views with syntax-highlighted code blocks, supports element-level comment anchoring, and displays visual diffs with word-level change annotations. We're using swift-markdown (Apple's CommonMark parser) for parsing, extending it with GitHub Flavored Markdown support via a custom visitor, and building a tree-diffing algorithm for rendered diffs. The architecture integrates cleanly with the existing TCA-based app structure, adding a new render mode to the existing view/diff mode matrix.

## Technical Approach

**Parsing:** Use Apple's `swift-markdown` library to parse markdown into an AST. Extend it with a custom `MarkdownVisitor` to handle GFM extensions (tables, task lists, strikethrough, autolinks). Each AST node is assigned a stable identifier based on its position in the tree (e.g., `paragraph-3`, `list-1-item-2`).

**Rendering:** Build a `RenderedMarkdownView` SwiftUI component that traverses the AST and produces native views. Paragraphs become `Text`, headings become styled `Text`, lists become `VStack`/`HStack` compositions, code blocks use the existing `SyntaxHighlighter` dependency. Images use `AsyncImage`.

**Comment Anchoring:** Store rendered-mode comments in a separate dictionary keyed by element ID (analogous to the existing `comments` dict for line-based comments and `diffComments` dict for diff-line comments). The prompt builder maps element IDs back to raw source line ranges via the AST node's `SourceLocation`.

**Diff Rendering:** Parse both HEAD and working copy into ASTs, run a tree diff algorithm (LCS-based block matching), classify each block as added/removed/modified/unchanged, then render with visual annotations. Modified blocks get word-level diff via a simple word-splitter + LCS. Fallback banner appears if > 80% of blocks changed.

**Security:** Sanitize HTML blocks embedded in markdown using a whitelist-based sanitizer (strip `<script>`, event handlers, `javascript:` URLs). This happens post-parsing, pre-rendering.

**Performance:** Rendering is synchronous but budgeted per `NFR-mdr-render-perf` (200ms for 5k lines). If a file exceeds budget, show a spinner. Diff computation is async with a 5-second timeout fallback.

## Data Model

### MarkdownRenderMode (Enum)

```swift
enum MarkdownRenderMode: Equatable {
    case raw
    case rendered
}
```

Added to `AppFeature.State`. Defaults to `.raw`. Only visible when a markdown file is loaded.

### MarkdownAST (Struct)

```swift
struct MarkdownAST {
    let document: Document // swift-markdown's root node
    let elementMap: [String: MarkdownElement] // stable ID -> AST node mapping
}

struct MarkdownElement {
    let id: String // e.g., "paragraph-3"
    let node: Markup // swift-markdown AST node
    let sourceRange: SourceRange // line range in raw source
}
```

Computed once per file load, cached in state.

### RenderedComment (Struct)

```swift
struct RenderedComment: Equatable, Identifiable {
    let id: UUID
    let elementID: String // e.g., "paragraph-3" or "modified:heading-2"
    let text: String
    let timestamp: Date
}
```

Stored in `AppFeature.State.renderedComments: [String: [RenderedComment]]` (keyed by element ID).

Similarly, `AppFeature.State.renderedDiffComments: [String: [RenderedComment]]` for diff mode.

### DiffAnnotation (Struct)

```swift
struct DiffAnnotation {
    let elementID: String
    let changeType: DiffChangeType
    let wordLevelChanges: [WordLevelDiff]? // for modified blocks
}

enum DiffChangeType {
    case added
    case removed
    case modified
    case unchanged
}

struct WordLevelDiff {
    let text: String
    let type: DiffChangeType // .added or .removed
}
```

Computed by the diff engine, stored in state for rendering.

## Component Architecture

### New Feature Modules

**`MarkdownRenderFeature/`**
- `MarkdownRenderMode.swift` — enum definition
- `MarkdownParser.swift` — parses markdown to AST, assigns element IDs
- `GFMVisitor.swift` — extends swift-markdown with GFM support
- `MarkdownSanitizer.swift` — HTML sanitization
- `MarkdownDiffer.swift` — AST-level diff computation
- `RenderedMarkdownView.swift` — SwiftUI view that renders AST
- `DiffAnnotationView.swift` — SwiftUI wrapper for diff visual annotations
- `ElementIdentifier.swift` — stable ID generation logic

### Modified Existing Modules

**`AppFeature/AppFeature.swift`**
- Add `renderMode: MarkdownRenderMode` to `State`
- Add `renderedComments: [String: [RenderedComment]]` to `State`
- Add `renderedDiffComments: [String: [RenderedComment]]` to `State`
- Add `Action.renderModeChanged(MarkdownRenderMode)`
- Add `Action.renderedCommentAdded(elementID: String, text: String)`
- Add reducer logic for mode switching (with confirmation if comments exist)

**`AppFeature/ToolbarView.swift`**
- Add rendered/raw segmented control (only visible when `state.file.isMarkdownFile`)
- Bind to `renderMode` state

**`CodeViewerFeature/CodeViewerView.swift`**
- Conditional rendering: if `renderMode == .rendered`, show `RenderedMarkdownView`; else show existing `LineView` list

**`PromptFeature/PromptBuilder.swift`**
- Add `buildRenderedPrompt()` method that maps element IDs to raw source line ranges
- Add `buildRenderedDiffPrompt()` method that includes old/new source for modified elements

### Dependency on swift-markdown

Add `swift-markdown` to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
    // ... existing dependencies
]
```

No external network calls (satisfies `NFR-mdr-client-only`). All parsing and rendering happens locally.

## State Management (TCA)

### State Flow

1. **File Load:** When a file is loaded, `AppFeature` checks if it's markdown (via file extension). If yes:
   - Parse to AST via `MarkdownParser.parse(file.content)`
   - Store `ast: MarkdownAST?` in state
   - Set `renderMode = .raw` (default)

2. **Toggle to Rendered:**
   - User clicks Rendered segment → `Action.renderModeChanged(.rendered)` dispatched
   - Reducer checks if comments exist in current mode
   - If yes, show confirmation dialog; if no, switch immediately
   - On confirmation, clear current-mode comments, set `renderMode = .rendered`

3. **Rendered Comment Creation:**
   - User clicks element → `Action.renderedCommentAdded(elementID, text)` dispatched
   - Reducer appends comment to `renderedComments[elementID]`
   - Prompt builder recomputes preview

4. **Diff Mode:**
   - When `viewMode == .diff && renderMode == .rendered`:
     - Fetch baseline (HEAD) via existing `DiffClient`
     - Parse baseline to AST
     - Run `MarkdownDiffer.diff(baseline: AST, working: AST)` → `[DiffAnnotation]`
     - Store `diffAnnotations: [DiffAnnotation]?` in state
     - `RenderedMarkdownView` renders working copy AST with annotations

### Effects

**Async Diff Computation (`NFR-mdr-rendered-diff-perf`):**

```swift
case .viewModeChanged(.diff) where state.renderMode == .rendered:
    return .run { send in
        let baseline = try await diffClient.fetchBaseline()
        let baselineAST = MarkdownParser.parse(baseline)
        let workingAST = state.ast!
        
        let annotations = try await Task {
            try await MarkdownDiffer.diff(baseline: baselineAST, working: workingAST)
        }.value
        
        await send(.diffAnnotationsComputed(annotations))
    }
    .cancellable(id: DiffComputeID.self, cancelInFlight: true)
```

Timeout fallback: if computation exceeds 5 seconds, show fallback banner per `AC-mdr-diff-fallback`.

## API / Interface Design

### MarkdownParser

```swift
struct MarkdownParser {
    static func parse(_ source: String) -> MarkdownAST
}
```

**Internals:**
- Use `Document(parsing: source)` from swift-markdown
- Walk the AST, assign stable IDs to block-level nodes (paragraphs, headings, lists, code blocks, tables, blockquotes, images)
- Build `elementMap: [String: MarkdownElement]`
- Return `MarkdownAST(document: doc, elementMap: map)`

### MarkdownDiffer

```swift
struct MarkdownDiffer {
    static func diff(baseline: MarkdownAST, working: MarkdownAST) async throws -> [DiffAnnotation]
}
```

**Algorithm:**
1. Extract block-level elements from both ASTs (paragraphs, headings, lists, etc.)
2. Run LCS (Longest Common Subsequence) on the block lists (matched by content hash or structural similarity)
3. Classify blocks as added/removed/modified/unchanged
4. For modified blocks, run word-level LCS on text content
5. Return annotations

**Fallback heuristic:**
If > 80% of blocks are classified as modified/added/removed, mark as "too many changes" and return a flag.

### MarkdownSanitizer

```swift
struct MarkdownSanitizer {
    static func sanitize(_ html: String) -> String
}
```

**Implementation:**
- Use a whitelist-based approach: allow specific HTML tags (`<p>`, `<h1>-<h6>`, `<ul>`, `<ol>`, `<li>`, `<code>`, `<pre>`, `<a>`, `<img>`, `<strong>`, `<em>`, `<table>`, `<tr>`, `<td>`, `<th>`, `<blockquote>`, `<hr>`)
- Strip all `<script>` tags, event handler attributes (`onclick`, `onerror`, etc.), `javascript:` URLs
- Use a library like SwiftSoup or build a simple regex-based stripper
- Apply after rendering but before inserting into SwiftUI view

## Error Handling

**Parsing Errors:**
- If `swift-markdown` fails to parse (malformed markdown), fall back to raw view and show an error banner: "Unable to render this file. Showing raw view."

**Diff Computation Timeout:**
- If diff computation exceeds 5 seconds, cancel the task and show fallback banner: "Too many structural changes for rendered diff. [Switch to Raw Diff]"

**Image Load Failures:**
- Embedded images use `AsyncImage`. If an image fails to load, show alt text in its place (handled automatically by SwiftUI).

**Sanitization:**
- Sanitization is defensive — it silently strips dangerous content. No user-facing error.

## Performance Considerations

**Parsing Budget (`NFR-mdr-render-perf`):**
- Target: 200ms for 5k-line files, 500ms for 5k-10k lines
- Measured via `ContinuousClock` around `MarkdownParser.parse()`
- If parsing exceeds budget, show a spinner during parse
- For very large files (> 10k lines), consider showing a banner recommending raw view

**Rendering Budget:**
- SwiftUI rendering is synchronous. For large ASTs, this may block the main thread.
- Optimization: use `LazyVStack` for rendered elements to defer off-screen rendering
- If scroll performance degrades (per `NFR-mdr-render-scroll-perf`), investigate virtualization or chunking

**Diff Computation Budget (`NFR-mdr-rendered-diff-perf`):**
- Target: 1 second for 5k-line files, 3 seconds for 5k-10k lines
- Run diff computation in a background `Task`
- Show loading spinner while computing
- 5-second timeout fallback

**Memory:**
- Caching: Store parsed AST in state to avoid re-parsing on every render
- Clear AST when file is unloaded or session ends

## Security Considerations

**XSS Prevention (`NFR-mdr-xss-safety`):**
- All HTML embedded in markdown must be sanitized before rendering
- Use `MarkdownSanitizer.sanitize()` on any HTML blocks extracted from the AST
- Test with malicious payloads: `<script>alert('xss')</script>`, `<img src=x onerror="alert('xss')">`

**Client-Side Only (`NFR-mdr-client-only`):**
- No markdown content leaves the local machine
- All parsing, rendering, diffing happens in-process
- No external services or APIs called

## Implementation Plan

1. **Add swift-markdown dependency** — Update `Package.swift`, verify it builds.

2. **Build MarkdownParser** — Parse markdown to AST, assign element IDs, map source ranges. Unit test with sample markdown files (basic, GFM, nested lists, code blocks).

3. **Build GFMVisitor** — Extend swift-markdown with GFM table/task list/strikethrough support. Test with GFM samples.

4. **Build RenderedMarkdownView (file mode)** — Render AST as SwiftUI views. Start with basic elements (headings, paragraphs, lists), then add tables, code blocks (using existing SyntaxHighlighter), images. Test rendering fidelity against a known-good markdown file.

5. **Add renderMode state + toolbar toggle** — Add state to `AppFeature`, add segmented control to toolbar, wire up actions. Test toggle switches view between raw and rendered.

6. **Build comment interaction in rendered view** — Add hover affordance, click-to-comment, element ID anchoring. Store in `renderedComments` dict. Test comment creation/editing/deletion.

7. **Build prompt generation from rendered comments** — Map element IDs to raw source line ranges, generate prompt format. Test prompt output matches design spec.

8. **Add mode-switch confirmation dialog** — Show dialog if comments exist when switching modes. Test confirmation flow (cancel, clear+switch).

9. **Build MarkdownDiffer** — LCS-based block diff, word-level diff for modified blocks. Unit test with sample baseline/working pairs.

10. **Build RenderedMarkdownView (diff mode)** — Render working AST with diff annotations. Add DiffAnnotationView wrapper for visual treatments (green/red borders, strikethrough, word highlights). Test diff rendering matches design.

11. **Add diff comment interaction** — Support commenting on added/removed/modified elements. Store in `renderedDiffComments` dict. Test comment anchoring.

12. **Build prompt generation from rendered diff comments** — Include old/new source for modified elements. Test prompt format.

13. **Build MarkdownSanitizer** — Strip dangerous HTML. Test with XSS payloads, verify script tags are removed.

14. **Add fallback banner for heavily restructured diffs** — Detect > 80% changed blocks, show banner, provide switch-to-raw button. Test with heavily edited files.

15. **Keyboard navigation + accessibility** — Make elements focusable, add ARIA labels for diff annotations, test with VoiceOver. Implements `NFR-mdr-accessibility`.

16. **Performance testing** — Measure parse/render/diff times with 5k, 10k line files. Optimize if exceeding budgets. Implements `NFR-mdr-render-perf`, `NFR-mdr-render-scroll-perf`, `NFR-mdr-rendered-diff-perf`.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-mdr-detect-markdown | engineering/apps/macos/Sources/SharedModels/SyntaxLanguage.swift | planned |
| FR-mdr-render-toggle | engineering/apps/macos/Sources/AppFeature/ToolbarView.swift | planned |
| FR-mdr-render-commonmark | engineering/apps/macos/Sources/MarkdownRenderFeature/MarkdownParser.swift | planned |
| FR-mdr-render-styling | engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift | planned |
| FR-mdr-element-id | engineering/apps/macos/Sources/MarkdownRenderFeature/ElementIdentifier.swift | planned |
| FR-mdr-rendered-comment-create | engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift | planned |
| FR-mdr-rendered-comment-prompt | engineering/apps/macos/Sources/PromptFeature/PromptBuilder.swift | planned |
| FR-mdr-switch-comments | engineering/apps/macos/Sources/AppFeature/AppFeature.swift | planned |
| FR-mdr-raw-diff-unchanged | engineering/apps/macos/Sources/DiffViewerFeature/DiffViewerView.swift | planned |
| FR-mdr-rendered-diff-display | engineering/apps/macos/Sources/MarkdownRenderFeature/MarkdownDiffer.swift | planned |
| FR-mdr-rendered-diff-comment | engineering/apps/macos/Sources/MarkdownRenderFeature/RenderedMarkdownView.swift | planned |
| FR-mdr-rendered-diff-prompt | engineering/apps/macos/Sources/PromptFeature/PromptBuilder.swift | planned |
