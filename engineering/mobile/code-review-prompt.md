---
product-hash: 323b3b866d3f9c84f30fca9b3c045f8e898d2504e3bc4a91e659530e8f11be78
product-slugs: [AC-crp-active-file-path-single-file, AC-crp-active-file-path-switches, AC-crp-active-file-path-visible, AC-crp-add-comment-line-range, AC-crp-add-comment-single-line, AC-crp-binary-file-rejected, AC-crp-clear-confirmation, AC-crp-clear-no-confirm-empty, AC-crp-comment-navigation-next, AC-crp-comment-summary-empty, AC-crp-comment-summary-realtime, AC-crp-comment-summary-shows-all, AC-crp-context-graceful-missing, AC-crp-context-neutral-vs-review, AC-crp-context-overall-visible, AC-crp-context-per-file-switches, AC-crp-context-per-file-visible, AC-crp-context-readonly, AC-crp-context-sidebar-collapse, AC-crp-copy-clipboard, AC-crp-delete-comment, AC-crp-done-auto-close, AC-crp-done-confirmation, AC-crp-done-disabled-no-comments, AC-crp-done-fallback-clipboard, AC-crp-done-sends-prompt, AC-crp-done-standalone-hidden, AC-crp-edit-comment, AC-crp-empty-state, AC-crp-file-mark-reviewed, AC-crp-file-path-display, AC-crp-file-path-single-dir, AC-crp-file-reviewed-clear-session, AC-crp-file-reviewed-grouping, AC-crp-file-reviewed-progress-count, AC-crp-file-reviewed-survives-tab-switch, AC-crp-file-reviewed-with-comments, AC-crp-file-tooltip-full-path, AC-crp-file-tooltip-reviewed, AC-crp-file-unmark-reviewed, AC-crp-generate-prompt-no-comments, AC-crp-generate-prompt-structure, AC-crp-keyboard-add-comment, AC-crp-large-file-scroll, AC-crp-line-wrap-comment-target, AC-crp-line-wrap-default-on, AC-crp-line-wrap-persists-session, AC-crp-line-wrap-preserves-line-numbers, AC-crp-line-wrap-toggle, AC-crp-load-drag-drop, AC-crp-load-paste, AC-crp-load-upload, AC-crp-multi-file-clear-all, AC-crp-multi-file-comment-count, AC-crp-multi-file-drop-multiple, AC-crp-multi-file-empty-after-remove-last, AC-crp-multi-file-load-adds, AC-crp-multi-file-nav-preserves-state, AC-crp-multi-file-prompt-omits-uncommented, AC-crp-multi-file-prompt-structure, AC-crp-multi-file-remove-no-comments, AC-crp-multi-file-remove-with-comments, AC-crp-overall-comment-in-prompt, AC-crp-overall-comment-label, AC-crp-panel-resize-bounds, AC-crp-panel-resize-double-click, AC-crp-panel-resize-drag, AC-crp-panel-resize-keyboard, AC-crp-panel-resize-persists, AC-crp-preview-matches-copy, AC-crp-syntax-highlight-detected, AC-crpm-context-collapse, AC-crpm-deeplink-load, AC-crpm-deeplink-send, AC-crpm-first-file-speed, AC-crpm-fullscreen-chrome, AC-crpm-offline-clipboard, AC-crpm-pinch-zoom, AC-crpm-session-persist, AC-crpm-swipe-nav, AC-crpm-voice-capture, FR-crp-active-file-path, FR-crp-clear-session, FR-crp-comment-count, FR-crp-comment-indicator, FR-crp-comment-navigation, FR-crp-comment-summary, FR-crp-done-action, FR-crp-file-display, FR-crp-file-load, FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-persistence, FR-crp-file-reviewed-progress, FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-visual, FR-crp-file-tooltip, FR-crp-filename-display, FR-crp-line-comment-create, FR-crp-line-comment-delete, FR-crp-line-comment-edit, FR-crp-line-range-comment, FR-crp-line-wrap, FR-crp-multi-file-load, FR-crp-multi-file-nav, FR-crp-multi-file-prompt, FR-crp-multi-file-prompt-format, FR-crp-multi-file-remove, FR-crp-panel-resize, FR-crp-prompt-copy, FR-crp-prompt-format, FR-crp-prompt-generate, FR-crp-prompt-handoff, FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-review-context-collapsible, FR-crp-review-context-display, FR-crp-review-context-overall, FR-crp-review-context-per-file, FR-crp-review-context-receive, FR-crp-session-identity, FR-crp-syntax-highlight, FR-crpm-deeplink-handoff, FR-crpm-deeplink-launch, FR-crpm-fullscreen, FR-crpm-gesture-nav, FR-crpm-mobile-context, FR-crpm-mobile-tabs, FR-crpm-offline-persist, FR-crpm-offline-sync, FR-crpm-pinch-zoom, FR-crpm-touch-select, FR-crpm-voice-input, FR-sc-file-api, FR-sc-session-id, NFR-crp-accessibility-keyboard, NFR-crp-browser-support, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-crp-no-data-persistence, NFR-crp-prompt-gen-time, NFR-crp-render-time, NFR-crp-responsive-layout, NFR-crpm-mobile-input-lag, NFR-crpm-mobile-lazy]
---

# Code Review Prompt Generator — Mobile Engineering Spec

> Based on requirements in `../../product/code-review-prompt.md`  
> See also `../../product/mobile/code-review-prompt.md` for mobile-specific requirements.  
> Based on design in `../../design/mobile/code-review-prompt.md`

## What We're Building

A native mobile application for iOS and Android that brings the Code Review Prompt Generator to phones and tablets. This spec chooses **separate native apps** (Swift/SwiftUI for iOS, Kotlin/Jetpack Compose for Android) over cross-platform frameworks because the CRPG is fundamentally a text-heavy, interaction-rich app where platform-native text rendering, gesture handling, and keyboard integration are critical for quality. The app is launched via deep links from Buzz Mobile, persists sessions locally to survive network interruptions, and uses platform speech APIs for voice comment input.

## Technical Approach

### Tech Stack Decision

**Decision: Separate native apps, not cross-platform.**

We choose Swift/SwiftUI for iOS and Kotlin/Jetpack Compose for Android rather than React Native, Flutter, or other cross-platform solutions. Rationale:

1. **Text rendering performance**: The CRPG displays thousands of lines of code with syntax highlighting and must scroll smoothly. Native text layout engines (TextKit on iOS, TextView on Android) are highly optimized for exactly this use case. Cross-platform text rendering introduces a layer of abstraction that complicates performance tuning.

2. **Gesture fidelity**: The design requires precise pinch-zoom, swipe navigation, and long-press interactions. Native gesture recognizers provide the best fidelity and least latency. Cross-platform gesture systems often feel "off" compared to platform-native patterns.

3. **Keyboard integration**: Comment input is a core feature, and native keyboard toolbars (iOS inputAccessoryView, Android input extras) are essential for voice input buttons and smooth transitions. Cross-platform keyboard handling is notoriously fragile.

4. **Shared logic is minimal**: The CRPG's business logic (prompt generation, comment management) is straightforward — most complexity lives in UI rendering and interaction, which can't be shared across platforms anyway. A shared codebase would save little while introducing dependency and build complexity.

5. **No web parity requirement**: Unlike a consumer app that must maintain visual consistency with a web version, the CRPG mobile app has no web counterpart to match (the macOS app is native). Each platform can optimize for its own conventions without breaking visual parity.

**Stack details:**

- **iOS**: Swift 5.9+, SwiftUI, iOS 15+ deployment target
- **Android**: Kotlin 1.9+, Jetpack Compose, Android API 26+ (8.0 Oreo)
- **Shared**: No shared code between platforms. Each platform implements from the same product/design specs.

### Platform Versions Supported

- **iOS**: 15.0+ (covers ~95% of active iOS devices as of 2024)
- **Android**: API 26+ / Android 8.0+ (covers ~90% of active Android devices as of 2024)

These minimums balance modern API access (SwiftUI/Compose stability, Speech APIs) with device coverage.

## Data Model

Session state is the only persistent data the CRPG owns. Everything else (file content, review context) is passed in via deep link and lives only in memory during the session. Session state is serialized to local storage for offline persistence and restored when the app returns to foreground.

### Session State Structure

```swift
// iOS Swift representation
struct ReviewSession: Codable {
    let sessionID: String              // from deep link, used for callback
    var files: [ReviewFile]            // all loaded files
    var overallComment: String         // "preamble" / global instruction
    var activeFileIndex: Int           // which file is currently displayed
    var reviewContext: ReviewContext?  // overall + per-file context from agent
}

struct ReviewFile: Codable, Identifiable {
    let id: UUID                       // stable identifier
    let path: String                   // full file path (e.g., "src/utils.ts")
    let content: String                // decoded file text
    let language: String               // detected language for syntax highlighting
    var comments: [LineComment]        // inline comments
    var zoomLevel: Float               // pinch zoom level (0.5...2.0)
    var isReviewed: Bool               // manual review toggle
    let diffData: String?              // optional diff text (future)
    let fileContext: FileContext?      // per-file neutral + review feedback
}

struct LineComment: Codable, Identifiable {
    let id: UUID
    let lineRange: ClosedRange<Int>    // single line or range
    var text: String
    let timestamp: Date
}

struct ReviewContext: Codable {
    let overallNeutral: String
    let overallFeedback: String
}

struct FileContext: Codable {
    let neutral: String
    let feedback: String
}
```

Android Kotlin structure is analogous using data classes and kotlinx.serialization.

### Persistence Strategy

**iOS**: `UserDefaults` for session state, falling back to file-based storage if size exceeds 1MB (UserDefaults limit). Location: `UserDefaults.standard` with key `shepherd.reviewSession.{sessionID}`. Fallback file location: `FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]/reviewSessions/{sessionID}.json`.

**Android**: `SharedPreferences` for small sessions (<100KB), file-based for larger. Location: `getSharedPreferences("shepherd_sessions", Context.MODE_PRIVATE)` with key `session_{sessionID}`. Fallback file: `context.filesDir/reviewSessions/{sessionID}.json`.

**Serialization format**: JSON via Swift `Codable` (iOS) and kotlinx.serialization (Android). JSON is human-readable for debugging and forward-compatible (unknown keys are ignored on deserialize).

**Session lifecycle**:
1. Deep link launches app with encoded session data → decode and initialize in-memory session
2. Every comment add/edit/delete triggers save to local storage (debounced 500ms to reduce write churn)
3. App backgrounded → immediate save
4. App foregrounded → restore from local storage if in-memory state is lost
5. Prompt sent via Done action → delete local session file (success) or queue for retry (failure)

**Storage size limit**: 10MB per session (enforced at decode time — files larger than 10MB are rejected with error message). Prevents unbounded memory growth and ensures save performance.

## Deep Link Protocol

The CRPG is launched from Buzz Mobile via a custom URL scheme. The deep link encodes session ID, file data, and optional review context.

### Deep Link Format

**Scheme**: `shepherd://review`

**Query parameters**:
- `sessionId` (required): UUID string identifying this session for callback
- `files` (required): Base64-encoded JSON array of file objects
- `context` (optional): Base64-encoded JSON object with overall context
- `callback` (required): Deep link URL for sending prompt back to Buzz Mobile

**File object schema** (before base64 encoding):
```json
{
  "path": "src/utils.ts",
  "content": "import { validate } from './validators';\n...",
  "language": "typescript",
  "diffData": null,
  "context": {
    "neutral": "This file: Modified process() to validate inputs...",
    "feedback": "Consider edge case handling for empty arrays."
  }
}
```

**Context object schema**:
```json
{
  "neutral": "What changed: Added validation logic...",
  "feedback": "Consider edge case handling..."
}
```

**Example deep link**:
```
shepherd://review?sessionId=abc-123&files=eyJwYXRoIjoi...&context=eyJuZXV0cmFsIjoi...&callback=buzzmobile://prompt-received
```

### Deep Link Parsing (`FR-crpm-deeplink-launch`)

**iOS**: `UIApplicationDelegate.application(_:open:options:)` or SwiftUI `.onOpenURL`. Parse URL components with `URLComponents`, decode base64 with `Data(base64Encoded:)`, deserialize JSON with `JSONDecoder`.

**Android**: Intent filter in manifest for `shepherd://review` scheme. Parse with `Uri.parse()`, decode base64 with `Base64.decode()`, deserialize JSON with kotlinx.serialization.

**Error handling**: If deep link parsing fails (malformed URL, invalid base64, JSON parse error), show user-friendly error: "Could not load review session. Please try again from Buzz Mobile." Log error details for debugging.

**Binary file rejection** (`FR-crp-file-load`): Scan first 8KB of each file's decoded content for null bytes (`0x00`). If found, reject file with error: "Binary files are not supported." This heuristic may reject rare text files with embedded nulls, but prevents garbled binary display.

### Deep Link Callback (`FR-crpm-deeplink-handoff`)

When user taps Done, send generated prompt back to Buzz Mobile via the callback URL provided in the launch deep link.

**Callback URL format**: `{callback}?sessionId={sessionId}&prompt={base64EncodedPrompt}`

**iOS**: Use `UIApplication.shared.open(callbackURL)` to trigger Buzz Mobile deep link.

**Android**: Use `Intent(Intent.ACTION_VIEW, Uri.parse(callbackURL))` and `startActivity()`.

**Timeout**: If callback URL open fails (Buzz Mobile not installed or not responding), fall back to clipboard copy and show error message: "Could not send to Buzz Mobile. Prompt copied to clipboard." (`AC-crpm-offline-clipboard`)

**Offline queue** (`FR-crpm-offline-sync`): If callback fails due to network unavailability (detected via reachability check), queue the prompt locally. Store in `queuedPrompts` array in UserDefaults/SharedPreferences. On app launch or network restore, attempt to send all queued prompts. User can view queued prompts in a "Pending" screen (accessed from toolbar menu) and manually retry or delete them.

## Syntax Highlighting

The CRPG must syntax highlight 13 languages: JavaScript, TypeScript, Python, Go, Rust, Java, C, C++, HTML, CSS, JSON, YAML, Markdown (`FR-crp-syntax-highlight`).

### Syntax Highlighting Library Choice

**Decision: Highlightr for iOS, CodeView-Android for Android.**

**iOS**: Use [Highlightr](https://github.com/raspu/Highlightr), a Swift wrapper around highlight.js. Supports all 13 required languages, renders to `NSAttributedString` for native text display, and is actively maintained. Alternative considered: [Splash](https://github.com/JohnSundell/Splash) — Swift-native but supports fewer languages and no Markdown.

**Android**: Use [CodeView-Android](https://github.com/amrdeveloper/CodeView) or similar Compose-compatible syntax highlighter. If no mature Compose library exists, fall back to [highlight.js via WebView](https://highlightjs.org/) wrapped in a Compose `AndroidView`. WebView is a performance compromise but guarantees language coverage and visual consistency with iOS.

### Language Detection

Detect language from file extension using a static mapping:

```swift
// iOS
func detectLanguage(path: String) -> String {
    let ext = (path as NSString).pathExtension.lowercased()
    let languageMap: [String: String] = [
        "js": "javascript", "jsx": "javascript", "mjs": "javascript", "cjs": "javascript",
        "ts": "typescript", "tsx": "typescript",
        "py": "python",
        "go": "go",
        "rs": "rust",
        "java": "java",
        "c": "c", "h": "c",
        "cpp": "cpp", "cc": "cpp", "cxx": "cpp", "hpp": "cpp",
        "html": "html", "htm": "html",
        "css": "css", "scss": "css",
        "json": "json",
        "yaml": "yaml", "yml": "yaml",
        "md": "markdown", "markdown": "markdown"
    ]
    return languageMap[ext] ?? "plaintext"
}
```

If language is `plaintext`, no highlighting is applied (raw text display).

### Rendering Performance (`NFR-crp-render-time`, `NFR-crp-large-file-perf`)

**Lazy rendering for large files**: For files >2000 lines, render only visible lines + small buffer (50 lines above/below viewport). Use iOS `UITextView` with custom `NSLayoutManager` or Android `LazyColumn` with windowing. This keeps memory footprint low and scroll smooth even for 10,000-line files.

**Highlight caching**: Cache `NSAttributedString` (iOS) or `AnnotatedString` (Android) per file after first highlight. Invalidate cache only if file content changes (never happens in CRPG, since files are immutable once loaded).

**Progressive highlighting** (`NFR-crp-render-time`): On initial load, show plain text immediately (< 100ms), then apply syntax highlighting in background thread. Highlighting must complete within 500ms for <1000 lines. For larger files, highlight only visible portion first, then background-highlight the rest.

## Touch Interaction

Mobile has no hover, no mouse, and requires larger tap targets. All interactions are touch-based.

### Tap Targets (`FR-crpm-touch-select`)

**Line number tap target size**: Minimum 44pt (iOS) / 48dp (Android) in height per platform accessibility guidelines. Line numbers are rendered in a gutter column with width 60pt/60dp (enough for 4-digit line numbers). Tapping anywhere in the gutter row opens the comment input box for that line.

**Comment indicator tap target**: Same 44pt/48dp minimum. Indicators are drawn as colored dots (8pt/8dp diameter) but tap target extends to full gutter height.

**Implementation**: iOS uses `UITapGestureRecognizer` on gutter view. Android uses `Modifier.clickable` on gutter composable. Both map tap coordinates to line number via layout math.

### Gesture Navigation (`FR-crpm-gesture-nav`)

**Swipe left/right to navigate files**: Use platform gesture recognizers.

**iOS**: `UISwipeGestureRecognizer` with `.left` and `.right` directions on code content area. Swipe triggers `switchToNextFile()` / `switchToPreviousFile()` with wrap-around (last file → first file). Animate transition with `UIView.transition(with:duration:options:animations:)` using `.transitionFlipFromLeft` or `.transitionFlipFromRight` for visual feedback.

**Android**: `Modifier.pointerInput` with `detectHorizontalDragGestures()` on code content composable. Detect swipe via velocity threshold (> 1000 dp/s). Animate transition with `AnimatedContent` and `slideInHorizontally/slideOutHorizontally`.

**Swipe gesture conflict** (`FR-crp-line-wrap`): When line wrap is OFF, horizontal scrolling is enabled. Swipe gestures for file navigation could conflict with horizontal scroll. **Resolution**: Require faster swipe velocity for file nav (> 1500 dp/s) vs. normal scroll velocity. Slower horizontal drag scrolls code; fast swipe switches files. Alternatively, use two-finger swipe for file nav (but less discoverable).

### Pinch Zoom (`FR-crpm-pinch-zoom`)

**iOS**: `UIPinchGestureRecognizer` on code content view. Scale factor maps to text size multiplier (0.5x to 2.0x). Update `UIFont.pointSize` on pinch end. Store zoom level in `ReviewFile.zoomLevel` (persists per-file within session).

**Android**: `Modifier.pointerInput` with `detectTransformGestures()` for pinch detection. Scale factor updates `TextStyle.fontSize` on composable. Store zoom level in file state.

**Line number alignment**: Line numbers must scale proportionally with code text to maintain alignment. Both use same zoom multiplier. Gutter width remains fixed (60pt/60dp) but font size scales.

**Zoom bounds**: Minimum 0.5x (12pt/12sp base font → 6pt/6sp), maximum 2.0x (24pt/24sp). Clamp scale factor on gesture end.

### Voice Input (`FR-crpm-voice-input`)

**iOS**: Use `SFSpeechRecognizer` (Speech framework). Check `SFSpeechRecognizer.authorizationStatus()` on app launch. If authorized, show microphone button in comment input toolbar. Tap mic → start recognition with `SFSpeechAudioBufferRecognitionRequest`, stream results to comment text field. Stop on tap end or silence timeout (3 seconds).

**Android**: Use `SpeechRecognizer` with `RecognizerIntent.ACTION_RECOGNIZE_SPEECH`. Check `SpeechRecognizer.isRecognitionAvailable()` on app launch. Tap mic → launch recognizer, receive results in `onResults()` callback, append to comment text.

**Permissions**: Request microphone permission on first mic button tap. If denied, hide mic button and show toast: "Microphone permission required for voice input."

**Fallback**: If speech recognition is unavailable (device lacks mic, API unsupported), hide mic button entirely. Keyboard input is always available.

## State Management

### Architecture Pattern

**Decision: MVVM (Model-View-ViewModel) for both platforms.**

MVVM is the idiomatic pattern for SwiftUI and Jetpack Compose. Both frameworks are declarative and reactive, making MVVM a natural fit.

**iOS**: Use `ObservableObject` and `@Published` properties in ViewModels. SwiftUI views observe ViewModels and re-render on state change. Example:

```swift
class ReviewSessionViewModel: ObservableObject {
    @Published var session: ReviewSession
    @Published var generatedPrompt: String = ""
    
    func addComment(fileID: UUID, lineRange: ClosedRange<Int>, text: String) {
        // mutate session.files[fileID].comments
        // trigger prompt regeneration
        // save session to local storage
    }
}
```

**Android**: Use `ViewModel` and `StateFlow`/`MutableStateFlow` for reactive state. Composables collect flows and recompose on state change. Example:

```kotlin
class ReviewSessionViewModel : ViewModel() {
    private val _session = MutableStateFlow<ReviewSession?>(null)
    val session: StateFlow<ReviewSession?> = _session.asStateFlow()
    
    private val _generatedPrompt = MutableStateFlow("")
    val generatedPrompt: StateFlow<String> = _generatedPrompt.asStateFlow()
    
    fun addComment(fileID: String, lineRange: IntRange, text: String) {
        // mutate _session.value
        // trigger prompt regeneration
        // save session to local storage
    }
}
```

### Prompt Generation Reactivity (`FR-crp-prompt-generate`)

Prompt is automatically regenerated whenever:
- A comment is added, edited, or deleted
- The overall comment (preamble) is changed

**Implementation**: Use Combine (iOS) or Kotlin Flow (Android) to observe session state changes and trigger regeneration.

**iOS**:
```swift
cancellables.append(
    $session
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] session in
            self?.regeneratePrompt(session)
        }
)
```

**Android**:
```kotlin
viewModelScope.launch {
    _session
        .debounce(300)
        .collectLatest { session ->
            _generatedPrompt.value = regeneratePrompt(session)
        }
}
```

**Debounce 300ms**: Prevents excessive regeneration during rapid typing or multi-comment edits. Satisfies `NFR-crp-prompt-gen-time` (< 300ms latency feels instant).

### Session Persistence Trigger

Save session to local storage on every state mutation. Debounce saves by 500ms to reduce write churn.

**iOS**:
```swift
cancellables.append(
    $session
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { session in
            SessionStorage.save(session)
        }
)
```

**Android**:
```kotlin
viewModelScope.launch {
    _session
        .debounce(500)
        .collectLatest { session ->
            SessionStorage.save(context, session)
        }
}
```

Also save immediately on app background (iOS `sceneDidEnterBackground`, Android `onPause`).

## Prompt Generation Algorithm

The prompt format is defined by `FR-crp-prompt-format` and `FR-crp-multi-file-prompt-format`. Generation is a pure function: `(ReviewSession) -> String`.

### Algorithm

```swift
func generatePrompt(session: ReviewSession) -> String {
    var prompt = ""
    
    // 1. Instructions section (overall comment / preamble)
    if !session.overallComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        prompt += "# Instructions\n\n"
        prompt += session.overallComment.trimmingCharacters(in: .whitespacesAndNewlines)
        prompt += "\n\n"
    }
    
    // 2. File sections (only files with comments)
    let filesWithComments = session.files.filter { !$0.comments.isEmpty }
    for file in filesWithComments {
        prompt += "## File: \(file.path) (\(file.language))\n\n"
        prompt += "### Requested Changes\n\n"
        
        // Sort comments by line number
        let sortedComments = file.comments.sorted { $0.lineRange.lowerBound < $1.lineRange.lowerBound }
        
        for comment in sortedComments {
            // Extract code snippet for this line range
            let snippet = extractSnippet(file.content, lineRange: comment.lineRange)
            prompt += "```\(file.language)\n"
            prompt += snippet
            prompt += "\n```\n"
            prompt += comment.text
            prompt += "\n\n"
        }
    }
    
    return prompt.trimmingCharacters(in: .whitespacesAndNewlines)
}

func extractSnippet(_ content: String, lineRange: ClosedRange<Int>) -> String {
    let lines = content.components(separatedBy: .newlines)
    let start = max(0, lineRange.lowerBound - 1) // 0-indexed
    let end = min(lines.count - 1, lineRange.upperBound - 1)
    return lines[start...end].joined(separator: "\n")
}
```

**Performance** (`NFR-crp-prompt-gen-time`): This algorithm is O(n) where n = number of comments. For 200 comments across 10,000-line files, expect < 50ms execution time (string concatenation is fast on modern devices). Well under 300ms requirement.

## UI Layout

### File Tab Strip (`FR-crpm-mobile-tabs`)

Horizontal scrollable row of file tabs at top of screen. Each tab shows file name (truncated if > 15 chars) and comment count badge.

**iOS**: Use `ScrollView(.horizontal)` with `HStack` of tab buttons. Buttons use `.frame(minWidth: 80)` to prevent excessive shrinking. Active tab has `.background(Color.blue)` and `.foregroundColor(.white)`. Inactive tabs have `.background(Color.clear)` and `.foregroundColor(.primary)`.

**Android**: Use `LazyRow` with `items(files)` and custom `FileTab` composable. Active tab has `backgroundColor = MaterialTheme.colorScheme.primary`. Inactive tabs have `backgroundColor = Color.Transparent`.

**Comment count badge**: Displayed as "(3)" after file name if count > 0. Rendered with smaller font (12pt/12sp) vs. file name (14pt/14sp).

**Scroll behavior**: Tabs scroll horizontally if total width exceeds screen width. When user switches to a file not currently visible, scroll the tab strip to reveal it (animate scroll with 300ms duration).

### Code Content Area (`FR-crp-file-display`)

Main scrollable view displaying code with line numbers, syntax highlighting, and inline comments.

**iOS**: Use `UITextView` (for syntax highlighting with NSAttributedString) inside a `UIScrollView`. Line numbers rendered in a separate `UIView` pinned to left edge (gutter). Gutter scrolls vertically with code but not horizontally. Implement horizontal scrolling manually with `UIPanGestureRecognizer` when line wrap is OFF.

**Android**: Use `LazyColumn` with custom line item composables. Each line item has a gutter cell (line number) and code cell (text). Gutter has fixed width (60dp). Code cell has flexible width. Horizontal scrolling enabled with `Modifier.horizontalScroll()` when line wrap is OFF.

**Line wrapping** (`FR-crp-line-wrap`): Default ON. Toggle via button in toolbar. When ON, code text view uses word wrap (iOS `.lineBreakMode = .byWordWrapping`, Android `softWrap = true`). When OFF, disable wrap and enable horizontal scroll.

**Line number alignment for wrapped lines**: When line wraps to multiple visual rows, line number appears only once, aligned to first row. Gutter cell height matches first row height. Implementation: line number view has `.top` vertical alignment.

### Bottom Toolbar

Fixed toolbar at bottom with three elements: Context button (left), Comment count (center), Done button (right).

**iOS**: Use `HStack` in `.toolbar` with `.bottomBar` placement. Buttons use `.frame(width: 80, height: 44)` for tap targets.

**Android**: Use `BottomAppBar` with `Row` layout. Buttons use `Modifier.size(width = 80.dp, height = 48.dp)`.

**Done button state**: Enabled only when session.files contains at least one file with at least one comment. Disabled state has 50% opacity and ignores taps.

### Review Context Drawer (`FR-crpm-mobile-context`)

Bottom sheet that slides up from bottom edge. Shows overall context and per-file context.

**iOS**: Use [sheet modifier](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:)) or custom bottom sheet (e.g., [BottomSheet library](https://github.com/weitieda/bottom-sheet)). Drawer has drag handle at top (horizontal pill shape, 36pt wide, 5pt tall). Swipe up to expand, swipe down to collapse. Collapsed height: 60pt (just header). Expanded height: 50% of screen height.

**Android**: Use [ModalBottomSheet](https://developer.android.com/reference/kotlin/androidx/compose/material3/package-summary#ModalBottomSheet(kotlin.Function0,androidx.compose.ui.Modifier,androidx.compose.material3.SheetState,kotlin.Float,androidx.compose.ui.graphics.Shape,androidx.compose.ui.graphics.Color,androidx.compose.ui.graphics.Color,androidx.compose.ui.unit.Dp,androidx.compose.ui.graphics.Color,kotlin.Function0,kotlin.Function1)) from Material3. Drag handle is built-in. Collapsed state shows `sheetPeekHeight = 60.dp`. Expanded state shows `sheetState.expand()`.

**Context sections**: Three collapsible sections inside drawer: Overall Context (neutral), Review Feedback, and File Context. Each section has a header with chevron icon (▶ collapsed, ▼ expanded). Tap header to toggle. Sections are independent (collapsing one doesn't collapse others).

**Scroll within drawer**: When expanded, drawer content scrolls vertically if taller than drawer height. Use `ScrollView` (iOS) or `Column(Modifier.verticalScroll())` (Android).

## Performance Optimization

### Lazy File Loading (`NFR-crpm-mobile-lazy`)

When session is launched with 10+ files, decode and render only the first file immediately. Other files are decoded on-demand when user navigates to them.

**Implementation**:
- Deep link parsing decodes only `files[0].content` base64 initially. Other files remain base64-encoded in memory.
- When user switches to file N, check if `files[N].content` is base64 or decoded. If base64, decode it and cache decoded result.
- Benefit: First file visible within 2 seconds even for 20-file sessions (`AC-crpm-first-file-speed`). Background decode other files during idle time.

### Comment Input Responsiveness (`NFR-crpm-mobile-input-lag`)

Tapping a line number must open the comment input box and show keyboard within 200ms, even on older devices.

**Optimization**: Pre-allocate comment input view on screen load (hidden, zero height). On tap, animate height expansion and focus input. This avoids view instantiation cost on tap. Keyboard show is platform-controlled (iOS/Android both optimize this).

**Defer heavy work**: Regenerating the prompt can take 50-100ms for large sessions. Debounce prompt regeneration by 300ms after comment input changes. Don't block keyboard show for prompt updates.

### Memory Management

**Large file handling**: Files > 10,000 lines trigger a warning on load: "Large file — performance may be affected." Still loadable, but user is warned. If device memory is low (iOS `didReceiveMemoryWarning`, Android `onLowMemory`), clear syntax highlighting cache and revert to plain text rendering for all files.

**Session size limit**: Enforce 10MB limit on session decode. If deep link payload exceeds 10MB after base64 decode, reject with error: "Session too large. Please reduce the number of files or file size."

## Error Handling

### Deep Link Errors

**Malformed URL**: "Invalid review link. Please try again from Buzz Mobile."

**Base64 decode failure**: "Could not decode session data. Please try again."

**JSON parse failure**: "Invalid session format. Please update Buzz Mobile and try again."

**File too large** (single file > 1MB): "File {path} is too large to load. Maximum file size: 1MB."

**Session too large** (total > 10MB): "Session too large. Please reduce the number of files."

### Prompt Callback Errors

**Callback URL invalid**: "Could not send prompt to Buzz Mobile. Prompt copied to clipboard."

**Buzz Mobile not installed**: "Buzz Mobile not found. Prompt copied to clipboard. Paste into Buzz manually."

**Network unavailable** (`FR-crpm-offline-sync`): "No network connection. Prompt saved and will be sent when connection is restored."

### Local Storage Errors

**Save failure** (disk full, permissions issue): "Could not save session. Your comments may be lost if the app closes." Show warning banner.

**Restore failure** (corrupted session file): "Could not restore previous session. Starting fresh." Delete corrupted file and start with empty session.

## Security Considerations

### Data Privacy

All file content and comments remain on-device. No data is uploaded to external servers. Deep link communication is between Buzz Mobile and Shepherd Mobile only, both local apps on the same device.

**Base64 encoding in deep links**: Deep links containing file content are visible in system logs and could be intercepted by malicious apps with log access. This is acceptable because: (1) the user has already granted Buzz Mobile access to these files, (2) deep links are ephemeral (used once and discarded), (3) session data is immediately persisted locally and cleared from deep link on load.

**Local storage encryption**: iOS UserDefaults and FileManager use system-level encryption (Data Protection when device is locked). Android SharedPreferences and filesDir are app-sandboxed. No additional encryption is applied. If user requires higher security, they can enable device-level encryption (iOS: on by default, Android: enabled on modern devices).

### Permissions

**Microphone permission**: Required for voice input. Requested on first mic button tap. If denied, mic button is hidden but app remains functional.

**No other permissions required**: App does not access camera, contacts, location, or other sensitive data.

## Implementation Plan

1. **Deep link parsing and session restoration** — Implement URL scheme handling, base64 decoding, JSON deserialization, session state model, and local storage save/restore. This is the foundation for all other features. Rationale: Without session loading, no other features can be tested.

2. **Code display and syntax highlighting** — Integrate Highlightr (iOS) / CodeView-Android (Android), implement lazy text rendering, line number gutter, and basic vertical scrolling. Rationale: Code display is the core UI; must be solid before adding interactions.

3. **Touch interactions and comment input** — Implement line number tap targets, comment input box, keyboard toolbar, and comment save to session state. Rationale: This completes the basic comment workflow (tap line → type comment → save).

4. **Prompt generation** — Implement prompt generation algorithm, reactive regeneration on comment changes, and prompt preview screen. Rationale: Prompt generation is the output; now we can test end-to-end (load file → comment → generate → preview).

5. **File navigation and multi-file support** — Implement file tab strip, swipe gestures for file switching, and multi-file prompt format. Rationale: Multi-file is a major feature but builds on single-file foundation.

6. **Review context drawer** — Implement bottom sheet UI, collapsible sections, neutral vs. review feedback styling, and per-file context switching. Rationale: Context display is independent of core commenting; can be layered on after basic features work.

7. **Voice input integration** — Integrate Speech framework (iOS) / SpeechRecognizer (Android), mic button in comment input toolbar, and permissions handling. Rationale: Voice input is a nice-to-have that enhances comment input; implement after manual input is solid.

8. **Pinch zoom** — Implement pinch gesture recognizers, text size scaling, line number alignment, and per-file zoom persistence. Rationale: Zoom improves readability but isn't essential for core workflow; can be added after basic interactions work.

9. **Prompt callback and offline queue** — Implement deep link callback to Buzz Mobile, Done button logic, offline queue for failed sends, and retry mechanism. Rationale: Callback is the final step in the workflow; test after all input features are complete.

10. **Advanced UI features** — Implement file reviewed toggle, progress indicator, All Comments screen, fullscreen mode, and line wrapping toggle. Rationale: These are polish features that improve UX but aren't blocking for MVP.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-crp-file-load | ios: App/Models/ReviewSession.swift:40-80; android: app/src/main/java/com/shepherd/mobile/models/ReviewSession.kt:40-80 | planned |
| FR-crp-file-display | ios: App/Views/CodeViewer.swift; android: app/src/main/java/com/shepherd/mobile/ui/CodeViewer.kt | planned |
| FR-crp-syntax-highlight | ios: App/Utilities/SyntaxHighlighter.swift; android: app/src/main/java/com/shepherd/mobile/ui/SyntaxHighlighter.kt | planned |
| FR-crp-line-comment-create | ios: App/ViewModels/ReviewSessionViewModel.swift:120-150; android: app/src/main/java/com/shepherd/mobile/viewmodels/ReviewSessionViewModel.kt:120-150 | planned |
| FR-crp-line-comment-edit | ios: App/ViewModels/ReviewSessionViewModel.swift:160-180; android: app/src/main/java/com/shepherd/mobile/viewmodels/ReviewSessionViewModel.kt:160-180 | planned |
| FR-crp-line-comment-delete | ios: App/ViewModels/ReviewSessionViewModel.swift:190-210; android: app/src/main/java/com/shepherd/mobile/viewmodels/ReviewSessionViewModel.kt:190-210 | planned |
| FR-crp-comment-indicator | ios: App/Views/LineNumberGutter.swift:60-80; android: app/src/main/java/com/shepherd/mobile/ui/LineNumberGutter.kt:60-80 | planned |
| FR-crp-comment-count | ios: App/Views/BottomToolbar.swift:40-60; android: app/src/main/java/com/shepherd/mobile/ui/BottomToolbar.kt:40-60 | planned |
| FR-crp-prompt-preamble | ios: App/Views/OverallCommentInput.swift; android: app/src/main/java/com/shepherd/mobile/ui/OverallCommentInput.kt | planned |
| FR-crp-prompt-generate | ios: App/Utilities/PromptGenerator.swift; android: app/src/main/java/com/shepherd/mobile/utilities/PromptGenerator.kt | planned |
| FR-crp-prompt-preview | ios: App/Views/PromptPreviewScreen.swift; android: app/src/main/java/com/shepherd/mobile/ui/PromptPreviewScreen.kt | planned |
| FR-crp-prompt-copy | ios: App/Views/PromptPreviewScreen.swift:80-100; android: app/src/main/java/com/shepherd/mobile/ui/PromptPreviewScreen.kt:80-100 | planned |
| FR-crp-prompt-format | ios: App/Utilities/PromptGenerator.swift:20-120; android: app/src/main/java/com/shepherd/mobile/utilities/PromptGenerator.kt:20-120 | planned |
| FR-crp-done-action | ios: App/Views/BottomToolbar.swift:80-120; android: app/src/main/java/com/shepherd/mobile/ui/BottomToolbar.kt:80-120 | planned |
| FR-crp-prompt-handoff | ios: App/Utilities/DeepLinkHandler.swift:150-200; android: app/src/main/java/com/shepherd/mobile/utilities/DeepLinkHandler.kt:150-200 | planned |
| FR-crp-session-identity | ios: App/Views/ContentView.swift:30-50; android: app/src/main/java/com/shepherd/mobile/MainActivity.kt:40-60 | planned |
| FR-crp-clear-session | ios: App/ViewModels/ReviewSessionViewModel.swift:220-250; android: app/src/main/java/com/shepherd/mobile/viewmodels/ReviewSessionViewModel.kt:220-250 | planned |
| FR-crp-filename-display | ios: App/Views/FileTabStrip.swift:40-60; android: app/src/main/java/com/shepherd/mobile/ui/FileTabStrip.kt:40-60 | planned |
| FR-crp-line-range-comment | ios: App/Models/LineComment.swift:10-30; android: app/src/main/java/com/shepherd/mobile/models/LineComment.kt:10-30 | planned |
| FR-crp-comment-navigation | ios: App/Views/CodeViewer.swift:180-220; android: app/src/main/java/com/shepherd/mobile/ui/CodeViewer.kt:180-220 | planned |
| FR-crp-multi-file-load | ios: App/ViewModels/ReviewSessionViewModel.swift:40-70; android: app/src/main/java/com/shepherd/mobile/viewmodels/ReviewSessionViewModel.kt:40-70 | planned |
| FR-crp-multi-file-nav | ios: App/Views/FileTabStrip.swift; android: app/src/main/java/com/shepherd/mobile/ui/FileTabStrip.kt | planned |
| FR-crp-multi-file-remove | ios: App/ViewModels/ReviewSessionViewModel.swift:260-290; android: app/src/main/java/com/shepherd/mobile/viewmodels/ReviewSessionViewModel.kt:260-290 | planned |
| FR-crp-multi-file-prompt | ios: App/Utilities/PromptGenerator.swift:130-180; android: app/src/main/java/com/shepherd/mobile/utilities/PromptGenerator.kt:130-180 | planned |
| FR-crp-multi-file-prompt-format | ios: App/Utilities/PromptGenerator.swift:130-180; android: app/src/main/java/com/shepherd/mobile/utilities/PromptGenerator.kt:130-180 | planned |
| FR-crp-review-context-receive | ios: App/Utilities/DeepLinkHandler.swift:60-100; android: app/src/main/java/com/shepherd/mobile/utilities/DeepLinkHandler.kt:60-100 | planned |
| FR-crp-review-context-display | ios: App/Views/ReviewContextDrawer.swift; android: app/src/main/java/com/shepherd/mobile/ui/ReviewContextDrawer.kt | planned |
| FR-crp-review-context-overall | ios: App/Views/ReviewContextDrawer.swift:40-80; android: app/src/main/java/com/shepherd/mobile/ui/ReviewContextDrawer.kt:40-80 | planned |
| FR-crp-review-context-per-file | ios: App/Views/ReviewContextDrawer.swift:90-130; android: app/src/main/java/com/shepherd/mobile/ui/ReviewContextDrawer.kt:90-130 | planned |
| FR-crp-review-context-collapsible | ios: App/Views/ReviewContextDrawer.swift:140-180; android: app/src/main/java/com/shepherd/mobile/ui/ReviewContextDrawer.kt:140-180 | planned |
| FR-crp-comment-summary | ios: App/Views/AllCommentsScreen.swift; android: app/src/main/java/com/shepherd/mobile/ui/AllCommentsScreen.kt | planned |
| FR-crp-file-reviewed-toggle | ios: App/ViewModels/ReviewSessionViewModel.swift:300-320; android: app/src/main/java/com/shepherd/mobile/viewmodels/ReviewSessionViewModel.kt:300-320 | planned |
| FR-crp-file-reviewed-visual | ios: App/Views/FileTabStrip.swift:70-90; android: app/src/main/java/com/shepherd/mobile/ui/FileTabStrip.kt:70-90 | planned |
| FR-crp-file-reviewed-grouping | ios: App/Views/FileTabStrip.swift:100-140; android: app/src/main/java/com/shepherd/mobile/ui/FileTabStrip.kt:100-140 | planned |
| FR-crp-file-reviewed-progress | ios: App/Views/BottomToolbar.swift:120-140; android: app/src/main/java/com/shepherd/mobile/ui/BottomToolbar.kt:120-140 | planned |
| FR-crp-file-reviewed-persistence | ios: App/Models/ReviewFile.swift:40-50; android: app/src/main/java/com/shepherd/mobile/models/ReviewFile.kt:40-50 | planned |
| FR-crp-panel-resize | — | unimplemented |
| FR-crp-active-file-path | ios: App/Views/CodeViewer.swift:20-40; android: app/src/main/java/com/shepherd/mobile/ui/CodeViewer.kt:20-40 | planned |
| FR-crp-file-tooltip | ios: App/Views/FileTabStrip.swift:150-180; android: app/src/main/java/com/shepherd/mobile/ui/FileTabStrip.kt:150-180 | planned |
| FR-crp-line-wrap | ios: App/Views/CodeViewer.swift:100-130; android: app/src/main/java/com/shepherd/mobile/ui/CodeViewer.kt:100-130 | planned |
| FR-crpm-deeplink-launch | ios: App/Utilities/DeepLinkHandler.swift:20-60; android: app/src/main/java/com/shepherd/mobile/utilities/DeepLinkHandler.kt:20-60 | planned |
| FR-crpm-deeplink-handoff | ios: App/Utilities/DeepLinkHandler.swift:150-200; android: app/src/main/java/com/shepherd/mobile/utilities/DeepLinkHandler.kt:150-200 | planned |
| FR-crpm-offline-persist | ios: App/Utilities/SessionStorage.swift; android: app/src/main/java/com/shepherd/mobile/utilities/SessionStorage.kt | planned |
| FR-crpm-offline-sync | ios: App/Utilities/OfflineQueue.swift; android: app/src/main/java/com/shepherd/mobile/utilities/OfflineQueue.kt | planned |
| FR-crpm-touch-select | ios: App/Views/LineNumberGutter.swift:20-50; android: app/src/main/java/com/shepherd/mobile/ui/LineNumberGutter.kt:20-50 | planned |
| FR-crpm-gesture-nav | ios: App/Views/CodeViewer.swift:140-170; android: app/src/main/java/com/shepherd/mobile/ui/CodeViewer.kt:140-170 | planned |
| FR-crpm-pinch-zoom | ios: App/Views/CodeViewer.swift:230-270; android: app/src/main/java/com/shepherd/mobile/ui/CodeViewer.kt:230-270 | planned |
| FR-crpm-voice-input | ios: App/Utilities/VoiceInputManager.swift; android: app/src/main/java/com/shepherd/mobile/utilities/VoiceInputManager.kt | planned |
| FR-crpm-mobile-context | ios: App/Views/ReviewContextDrawer.swift; android: app/src/main/java/com/shepherd/mobile/ui/ReviewContextDrawer.kt | planned |
| FR-crpm-fullscreen | ios: App/Views/CodeViewer.swift:280-310; android: app/src/main/java/com/shepherd/mobile/ui/CodeViewer.kt:280-310 | planned |
| FR-crpm-mobile-tabs | ios: App/Views/FileTabStrip.swift; android: app/src/main/java/com/shepherd/mobile/ui/FileTabStrip.kt | planned |
