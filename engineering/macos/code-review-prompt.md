# Code Review Prompt Generator -- macOS Technical Spec

> Based on requirements in `../../product/code-review-prompt.md`
> See also `../../product/macos/code-review-prompt.md` for macOS-specific requirements.
> Based on design in `../../design/macos/code-review-prompt.md`

## Technical Approach

This is a native macOS application built with **SwiftUI** and **The Composable Architecture (TCA)** (`NFR-crp-client-only`). There is no backend, no database, and no network calls beyond local file system operations. All file content and user annotations remain in-process for the lifetime of the session (`NFR-crp-no-data-persistence`).

The application uses **Swift Package Manager (SPM)** for dependency management and modular build targets. Each functional area of the UI is a separate Swift package target (feature module), enabling independent testing and clear boundaries. The root app target composes these feature modules into the final application.

The core architectural idea mirrors the web version: the user loads one or more files, each parsed into an array of lines held in TCA state keyed by a stable ID, the user attaches comments to line numbers on any loaded file, and a pure function assembles those inputs into a structured prompt string. The prompt is generated reactively -- every comment or preamble mutation triggers `generatePrompt()` via a TCA effect, aggregating comments across all files so the displayed prompt is always current. All processing runs locally within the application process with no side effects beyond clipboard writes and session directory I/O.

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| UI framework | SwiftUI | Native macOS UI framework. First-class support for toolbars, split views, menus, system appearance, and accessibility. Required for modern macOS app development. |
| Architecture | TCA (The Composable Architecture) | Unidirectional data flow, exhaustive testability via `TestStore`, controlled side effects via `@Dependency`, composable reducer tree. Prevents ad-hoc state management and makes every state transition explicit. |
| State management | `@ObservableState` structs | TCA's modern observation system. Eliminates `ViewStore`/`WithViewStore` boilerplate. Views observe state directly via `@Bindable` and `store.state`. |
| Side effects | `@Dependency` + async effects | All I/O (file system, clipboard, syntax highlighting) is injected via `@Dependency`, enabling deterministic testing with no mocks. Effects use Swift concurrency (`async`/`await`). |
| Navigation | Enum-based destinations (Swift Navigation) | `@CasePathable` enums for alerts, sheets, and modal presentations. Compile-time exhaustive handling of all navigation states. |
| Syntax highlighting | TreeSitter (swift-tree-sitter) | Native syntax highlighting engine. Supports all 13 required languages. Runs on a background thread. No WASM overhead. Produces token ranges that map directly to SwiftUI `AttributedString`. |
| Virtualized code viewer | Custom `LazyVStack` + scroll proxy | SwiftUI's `LazyVStack` with `ScrollViewReader` for programmatic scrolling. For 10,000+ line files, only visible lines (plus overscan) are rendered. Custom line measurement for wrapped lines. |
| Collections | `IdentifiedArray` (swift-identified-collections) | O(1) lookup by ID for files, comments, and tree nodes. Type-safe alternative to `[ID: Value]` dictionaries that preserves order. |
| Persistence | `NSWindow.setFrameAutosaveName` for window geometry | Window position/size persisted via the native `setFrameAutosaveName(_:)` API, which automatically saves and restores per-window geometry keyed by a unique name. Each session window uses its session ID (or a default key for standalone mode) as the autosave name, supporting multi-window geometry persistence. Session data is NOT persisted, consistent with `NFR-crp-no-data-persistence`. |
| Testing | Swift Testing + TCA `TestStore` | `TestStore` for exhaustive reducer testing. `expectNoDifference` / `expectDifference` for state assertions. Snapshot tests for key views. Dependency injection for all side effects. |
| Build system | Xcode + SPM | Xcode project with SPM package dependencies. Feature modules as local packages for modularity. |
| Distribution | Signed `.app` bundle + Homebrew cask | Developer ID signing + notarization via `notarytool`. Homebrew cask formula for `brew install --cask shepherd`. |
| Minimum target | macOS 14 (Sonoma) | Required for modern SwiftUI APIs (`@Observable`, improved `NavigationSplitView`, `Inspector`). `NFR-crp-macos-min-version` |
| Package manager | SPM (Swift Package Manager) | Native to the Swift ecosystem. No external tool dependencies. Supports local packages for feature modules. |
| Language mode | Swift 6 (complete strict concurrency) | The package builds under `swift-tools-version: 6.0`, so every target uses the Swift 6 language mode with complete data-race checking. TCA effects capture their dependencies explicitly (`.run { [dependency] send in … }`) so the `@Sendable` effect closure never captures the non-Sendable reducer `self`. |

---

## Project Structure

```
engineering/apps/macos/
├── Shepherd.xcodeproj/            # Xcode project
├── ShepherdApp/                   # Main app target
│   ├── ShepherdApp.swift          # @main entry point, AppFeature store
│   ├── AppFeature/
│   │   ├── AppFeature.swift       # Root reducer
│   │   └── AppView.swift          # Root view
│   └── Resources/
│       ├── Assets.xcassets         # App icon, accent color
│       └── Shepherd.entitlements   # Sandbox entitlements
├── Sources/                        # Feature module packages
│   ├── SharedModels/
│   │   ├── FileNode.swift
│   │   ├── Comment.swift
│   │   ├── ReviewContext.swift
│   │   ├── SessionData.swift
│   │   ├── SyntaxLanguage.swift
│   │   └── PromptBuilder.swift
│   ├── FileBrowserFeature/
│   │   ├── FileBrowserFeature.swift
│   │   └── FileBrowserView.swift
│   ├── CodeViewerFeature/
│   │   ├── CodeViewerFeature.swift
│   │   ├── CodeViewerView.swift
│   │   └── LineView.swift
│   ├── CommentFeature/
│   │   ├── CommentFeature.swift
│   │   ├── CommentBubbleView.swift
│   │   └── InlineCommentEditorView.swift
│   ├── InspectorFeature/
│   │   ├── InspectorFeature.swift
│   │   └── InspectorView.swift
│   ├── PromptFeature/
│   │   ├── PromptFeature.swift
│   │   ├── PromptPreviewView.swift
│   │   └── CommentSummaryView.swift
│   ├── ReviewContextFeature/
│   │   ├── ReviewContextFeature.swift
│   │   ├── ReviewContextPanelView.swift
│   │   └── ReviewContextSectionView.swift
│   ├── SessionFeature/
│   │   ├── SessionFeature.swift
│   │   └── SessionClient.swift
│   └── Dependencies/
│       ├── FileClient.swift
│       ├── ClipboardClient.swift
│       ├── SyntaxHighlightClient.swift
│       ├── PromptGeneratorClient.swift
│       ├── SessionClient.swift
│       └── WindowClient.swift
├── Tests/
│   ├── AppFeatureTests/
│   │   └── AppFeatureTests.swift
│   ├── FileBrowserFeatureTests/
│   │   └── FileBrowserFeatureTests.swift
│   ├── CodeViewerFeatureTests/
│   │   └── CodeViewerFeatureTests.swift
│   ├── CommentFeatureTests/
│   │   └── CommentFeatureTests.swift
│   ├── InspectorFeatureTests/
│   │   └── InspectorFeatureTests.swift
│   ├── PromptFeatureTests/
│   │   └── PromptFeatureTests.swift
│   ├── SharedModelsTests/
│   │   ├── PromptBuilderTests.swift
│   │   └── FileTreeBuilderTests.swift
│   └── SnapshotTests/
│       └── ViewSnapshotTests.swift
└── Package.swift                   # SPM manifest for local packages
```

### SPM Dependencies

```swift
// Package.swift (root)
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.0"),
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.9.0"),
    // TreeSitter language grammars
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-javascript", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-typescript", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-python", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-go", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-rust", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-java", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-c", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-cpp", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-html", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-css", from: "0.23.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-json", from: "0.24.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-yaml", from: "0.7.0"),
    .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-markdown", from: "0.4.0"),
]
```

---

## Architecture Overview

### Reducer Tree

The application's state is managed by a tree of TCA reducers. The root `AppFeature` reducer composes child feature reducers using `Scope`. Each feature owns its own slice of state and handles its own actions.

```
AppFeature (root)
├── SessionFeature              # Session lifecycle, slash command mode, window identity
├── FileBrowserFeature          # File tree, active file selection, review status
│   └── forEach FileNode        # Per-file state (reviewed, comment count)
├── CodeViewerFeature           # Active file display, line selection, scroll position
│   └── CommentFeature          # Inline comments (create, edit, delete)
├── InspectorFeature            # Right sidebar
│   ├── ReviewContextFeature    # Overall changeset context (collapsible)
│   └── PromptFeature           # Prompt preview, comment summary, overall comment
└── Alerts/Sheets               # Confirmation dialogs via @Presents
```

### Data Flow

```
User Action (View)
    │
    ▼
Action Enum (sent to Store)
    │
    ▼
Reducer Body (pure state mutation + effect returns)
    │
    ├──► State Mutation (synchronous, in-place)
    │
    └──► Effect (async side effect via @Dependency)
         │
         ▼
    Dependency Client (FileClient, ClipboardClient, etc.)
         │
         ▼
    Effect Result Action (fed back into reducer)
         │
         ▼
    State Mutation (from result)
         │
         ▼
    View Update (automatic via @ObservableState observation)
```

---

## Data Models

All data is defined as Swift structs conforming to `Equatable` and `Identifiable` where appropriate. These live in the `SharedModels` package.

```swift
import IdentifiedCollections
import Foundation

// MARK: - Core Models

/// A loaded file in the review session.
/// Implements: FR-crp-file-load, FR-crp-file-display, FR-crp-multi-file-load
struct FileNode: Identifiable, Equatable {
    let id: UUID
    /// File name, or "Untitled" if pasted without a name.
    var name: String
    /// Full file path from the file system. Nil for pasted content.
    var filePath: String?
    /// Detected programming language.
    var language: SyntaxLanguage
    /// The raw file content as a single string.
    let content: String
    /// The content split into individual lines. Derived from `content`.
    let lines: [String]
    /// Whether the user has marked this file as reviewed.
    /// Implements: FR-crp-file-reviewed-toggle, FR-crp-file-reviewed-persistence
    var isReviewed: Bool = false
    /// Cached scroll position (line index) for restoring on file switch.
    var scrollOffset: Int = 0
}

/// A single inline comment attached to one or more lines of a specific file.
/// Implements: FR-crp-line-comment-create, FR-crp-line-range-comment
struct Comment: Identifiable, Equatable {
    let id: UUID
    /// The file this comment belongs to.
    let fileID: FileNode.ID
    /// First line of the commented range (1-indexed).
    let startLine: Int
    /// Last line of the commented range (1-indexed). Same as startLine for single-line comments.
    let endLine: Int
    /// The user's comment text.
    var text: String
    /// Timestamp of creation. Used for stable ordering when line numbers are equal.
    let createdAt: Date
}

/// Structured review context data passed from the shepherd-review command.
/// Implements: FR-crp-review-context-receive
struct ReviewContext: Equatable, Codable {
    /// Overall changeset context (neutral description + agent's review feedback).
    var overall: ContextPair
    /// Per-file context, keyed by file path.
    var files: [String: ContextPair]

    struct ContextPair: Equatable, Codable {
        /// Factual description of what changed.
        var neutral: String
        /// The AI agent's assessment and opinions.
        var review: String
    }
}

/// Session data loaded from ~/.shepherd/sessions/<session-id>/
/// Implements: FR-crp-macos-slash-command-launch
struct SessionData: Equatable, Codable {
    let sessionID: String
    let workingDirectory: String?
    let projectName: String?
    let files: [SessionFile]
    let reviewContext: ReviewContext?

    struct SessionFile: Equatable, Codable {
        let path: String
        let content: String
    }
}

/// Supported syntax highlighting languages.
/// Implements: FR-crp-syntax-highlight
enum SyntaxLanguage: String, CaseIterable, Equatable, Codable {
    case javascript
    case typescript
    case python
    case go
    case rust
    case java
    case c
    case cpp
    case html
    case css
    case json
    case yaml
    case markdown
    case plaintext

    /// Maps file extensions to languages.
    static func detect(from fileName: String) -> SyntaxLanguage {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "js", "jsx", "mjs", "cjs": return .javascript
        case "ts", "tsx": return .typescript
        case "py": return .python
        case "go": return .go
        case "rs": return .rust
        case "java": return .java
        case "c", "h": return .c
        case "cpp", "cc", "cxx", "hpp": return .cpp
        case "html", "htm": return .html
        case "css": return .css
        case "json": return .json
        case "yaml", "yml": return .yaml
        case "md", "markdown": return .markdown
        default: return .plaintext
        }
    }
}

/// A node in the file browser directory tree.
/// Implements: FR-crp-multi-file-nav, FR-crp-file-reviewed-grouping
enum FileTreeNode: Identifiable, Equatable {
    case directory(DirectoryNode)
    case file(FileLeaf)

    var id: String {
        switch self {
        case .directory(let node): return "dir:\(node.path)"
        case .file(let leaf): return "file:\(leaf.fileID)"
        }
    }

    struct DirectoryNode: Equatable {
        let name: String
        let path: String
        var children: [FileTreeNode]
        /// True when all descendant files are reviewed.
        var isFullyReviewed: Bool
    }

    struct FileLeaf: Equatable {
        let fileID: FileNode.ID
        let name: String
    }
}

/// State of the inline comment editor.
/// Implements: FR-crp-line-comment-create, FR-crp-line-comment-edit
@CasePathable
enum EditorState: Equatable {
    case creating(anchorLine: Int, endLine: Int)
    case editing(commentID: Comment.ID)
}

/// Active tab in the inspector sidebar.
enum InspectorTab: Equatable {
    case preview
    case allComments
}
```

### Derived Data

Several values are computed from state rather than stored directly:

- **Comment count (global)**: `state.allComments.count` -- total across all files. Used by the toolbar (`FR-crp-comment-count`).
- **Comments per file**: Computed by grouping `allComments` by `fileID`. Used by FileBrowser for per-file comment count badges.
- **Lines with comments (active file)**: A `[Int: [Comment.ID]]` mapping each line number to comments covering that line, filtered to the active file. Computed by iterating comments where `fileID == activeFileID` and expanding each `[startLine...endLine]` range.
- **File tree**: `buildFileTree(files:reviewedFiles:)` utility that parses file paths into a nested `[FileTreeNode]` hierarchy. Unreviewed files sort before reviewed files within each directory (`FR-crp-file-reviewed-grouping`).
- **Active file path**: Derived from `files[activeFileID]?.filePath ?? files[activeFileID]?.name`. Used by ActiveFilePath view (`FR-crp-active-file-path`).
- **Review progress**: `(reviewedCount, totalCount)` tuple for the "N/M reviewed" display (`FR-crp-file-reviewed-progress`).
- **Per-file review context**: Derived from `reviewContext?.files[activeFilePath]`. Used by ReviewContextPanel (`FR-crp-review-context-per-file`).

---

## Feature Modules (Reducer Definitions)

### AppFeature (Root)

The root reducer composes all child features and handles application-level concerns.

```swift
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        // Child feature states
        var session = SessionFeature.State()
        var fileBrowser = FileBrowserFeature.State()
        var codeViewer = CodeViewerFeature.State()
        var inspector = InspectorFeature.State()

        // Shared state (accessible by multiple children)
        var files: IdentifiedArrayOf<FileNode> = []
        var allComments: IdentifiedArrayOf<Comment> = []
        var activeFileID: FileNode.ID?
        var overallComment: String = ""
        var generatedPrompt: String?
        var lineWrapEnabled: Bool = true
        var fileBrowserWidth: CGFloat = 220

        // Window state — geometry persistence handled by NSWindow.setFrameAutosaveName,
        // not stored in TCA state. Each window's position/size is keyed by session ID
        // (or "standalone" for non-session windows), supporting multi-window restoration.

        // Navigation / alerts
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var destination: Destination.State?

        // Derived
        var isMultiFile: Bool { files.count >= 2 }
        var hasComments: Bool { !allComments.isEmpty }
        var activeFile: FileNode? { activeFileID.flatMap { files[id: $0] } }
        var commentCount: Int { allComments.count }
    }

    @CasePathable
    enum Action: Equatable {
        // Child feature actions
        case session(SessionFeature.Action)
        case fileBrowser(FileBrowserFeature.Action)
        case codeViewer(CodeViewerFeature.Action)
        case inspector(InspectorFeature.Action)

        // File loading
        case filesDropped([URL])
        case fileOpenPanelRequested
        case fileOpened(Result<[(String, String, URL?)], Error>)
        case pasteFileFromClipboard

        // Session management
        case clearSessionRequested
        case clearSessionConfirmed
        case removeFileRequested(FileNode.ID)
        case removeFileConfirmed(FileNode.ID)

        // Prompt lifecycle
        case promptRegenerated(String?)
        case copyPrompt
        case promptCopied
        case doneRequested
        case promptHandoffSucceeded
        case promptHandoffFailed(String)

        // Window lifecycle
        case windowAppeared
        case windowClosed

        // Alerts / destinations
        case alert(PresentationAction<Alert>)
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        enum Alert: Equatable {
            case clearConfirmed
            case removeFileConfirmed(FileNode.ID)
        }
    }

    @Dependency(\.fileClient) var fileClient
    @Dependency(\.clipboardClient) var clipboardClient
    @Dependency(\.promptGenerator) var promptGenerator
    @Dependency(\.sessionClient) var sessionClient

    var body: some ReducerOf<Self> {
        Scope(state: \.session, action: \.session) {
            SessionFeature()
        }
        Scope(state: \.fileBrowser, action: \.fileBrowser) {
            FileBrowserFeature()
        }
        Scope(state: \.codeViewer, action: \.codeViewer) {
            CodeViewerFeature()
        }

        // Upstream Reduce for comment submission. Must run BEFORE the comment
        // Scope: child clears editorState/editorText on submit, so parent must
        // read them first to build the new Comment.
        Reduce { state, action in
            guard case .comment(.submitComment) = action,
                  let editor = state.comment.editorState else { return .none }
            let trimmed = state.comment.editorText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .none }
            switch editor {
            case let .creating(anchorLine, endLine):
                guard let fileID = state.activeFileID else { return .none }
                state.allComments.append(
                    Comment(
                        id: uuid(),
                        fileID: fileID,
                        startLine: min(anchorLine, endLine),
                        endLine: max(anchorLine, endLine),
                        text: trimmed
                    )
                )
            case let .editing(commentID):
                state.allComments[id: commentID]?.text = trimmed
            }
            return .merge(.send(.regeneratePrompt), .send(.rebuildFileTree))
        }

        Scope(state: \.comment, action: \.comment) {
            CommentFeature()
        }
        Scope(state: \.inspector, action: \.inspector) {
            InspectorFeature()
        }
        Reduce { state, action in
            switch action {
            // ... action handling (see implementation plan)
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }
}
```

### FileBrowserFeature

Manages the file tree sidebar, file selection, review status, and resize behavior.

**Sidebar rendering.** The tree is rendered as a **flat list of visible rows** (each row carries its indentation depth; descendants of a collapsed directory are omitted), not as recursive `DisclosureGroup`s nested inside the `List`. Nested disclosures in a macOS `List` miscalculate row frames (rows overlap / labels ghost), and arbitrary-depth recursion in the row builder forces `AnyView`, which erases the view identity `List` needs for correct row reuse. Directory rows own a manual chevron and drive collapse via `directoryExpandedChanged`; collapse keys are the directory's **full path from the tree root**, so same-named directories at different depths never collide.

```swift
/// Implements: FR-crp-multi-file-nav, FR-crp-panel-resize, FR-crp-file-reviewed-toggle,
/// FR-crp-file-reviewed-visual, FR-crp-file-reviewed-grouping, FR-crp-file-reviewed-progress,
/// FR-crp-file-tooltip, FR-crp-active-file-path
@Reducer
struct FileBrowserFeature {
    @ObservableState
    struct State: Equatable {
        /// Set of collapsed directory paths.
        var collapsedDirs: Set<String> = []
        /// The computed file tree (rebuilt when files or review status changes).
        var fileTree: [FileTreeNode] = []
    }

    @CasePathable
    enum Action: Equatable {
        case fileSelected(FileNode.ID)
        case directoryExpandedChanged(path: String, isExpanded: Bool)
        case toggleFileReviewed(FileNode.ID)
        case removeFileRequested(FileNode.ID)
        case fileTreeRebuilt([FileTreeNode])
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fileSelected:
                // Handled by parent (AppFeature) to update activeFileID
                return .none
            // Directory rows use a DisclosureGroup whose isExpanded binding must write the
            // exact requested value. A value-ignoring toggle makes the binding getter
            // disagree with SwiftUI's write and drives an infinite re-layout loop (row
            // ghosting / flicker) — the same class of bug as the review-context panels.
            case let .directoryExpandedChanged(dirPath, isExpanded):
                if isExpanded {
                    state.collapsedDirs.remove(dirPath)
                } else {
                    state.collapsedDirs.insert(dirPath)
                }
                return .none
            case .toggleFileReviewed:
                // Handled by parent to update file's isReviewed
                return .none
            case .removeFileRequested:
                // Handled by parent (confirmation flow)
                return .none
            case let .fileTreeRebuilt(tree):
                state.fileTree = tree
                return .none
            }
        }
    }
}
```

### CodeViewerFeature

Manages the active file display, line selection, scroll position, and keyboard navigation.

```swift
/// Implements: FR-crp-file-display, FR-crp-syntax-highlight, FR-crp-comment-indicator,
/// FR-crp-line-wrap, FR-crp-line-range-comment, NFR-crp-large-file-perf
@Reducer
struct CodeViewerFeature {
    @ObservableState
    struct State: Equatable {
        /// Syntax tokens for the active file (produced by SyntaxHighlightClient).
        var syntaxTokens: [SyntaxToken] = []
        /// The currently focused line (keyboard navigation).
        var focusedLine: Int?
        /// The currently selected line range for range-commenting.
        var selectedRange: ClosedRange<Int>?
        /// Whether a large file warning banner is visible.
        var showLargeFileWarning: Bool = false
    }

    @CasePathable
    enum Action: Equatable {
        case lineClicked(Int)
        case lineRangeSelected(ClosedRange<Int>)
        case scrolledToLine(Int)
        case focusedLineChanged(Int?)
        case syntaxHighlightingCompleted([SyntaxToken])
        case largeBannerDismissed
        case openCommentEditor(anchorLine: Int, endLine: Int)
    }

    @Dependency(\.syntaxHighlightClient) var syntaxHighlighter

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .lineClicked(line):
                state.selectedRange = nil
                return .send(.openCommentEditor(anchorLine: line, endLine: line))

            case let .lineRangeSelected(range):
                state.selectedRange = range
                return .none

            case let .scrolledToLine(line):
                // Parent persists this in the active FileNode.scrollOffset
                return .none

            case let .focusedLineChanged(line):
                state.focusedLine = line
                return .none

            case let .syntaxHighlightingCompleted(tokens):
                state.syntaxTokens = tokens
                state.showLargeFileWarning = false
                return .none

            case .largeBannerDismissed:
                state.showLargeFileWarning = false
                return .none

            case .openCommentEditor:
                // Handled by parent (CommentFeature)
                return .none
            }
        }
    }
}

/// A syntax token produced by TreeSitter.
struct SyntaxToken: Equatable {
    let range: Range<String.Index>
    let type: TokenType

    enum TokenType: String, Equatable {
        case keyword, string, comment, number, type, function
        case property, variable, `operator`, punctuation, plain
    }
}
```

### CommentFeature

Manages the lifecycle of inline comments -- create, edit, delete, and navigation.

```swift
/// Implements: FR-crp-line-comment-create, FR-crp-line-comment-edit,
/// FR-crp-line-comment-delete, FR-crp-comment-navigation
@Reducer
struct CommentFeature {
    @ObservableState
    struct State: Equatable {
        /// Current editor state (creating or editing a comment).
        var editorState: EditorState?
        /// The text currently in the editor.
        var editorText: String = ""
        /// The ID of the focused comment (via next/prev navigation).
        var focusedCommentID: Comment.ID?
    }

    @CasePathable
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case openEditor(EditorState)
        case submitComment
        case cancelEditor
        case editComment(Comment.ID)
        case deleteComment(Comment.ID)
        case navigateComment(Direction)
        case setFocusedComment(Comment.ID?)

        enum Direction: Equatable {
            case next, previous
        }
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .openEditor(editorState):
                state.editorState = editorState
                state.editorText = ""
                if case let .editing(commentID) = editorState {
                    // Parent will provide existing text
                    _ = commentID
                }
                return .none

            case .submitComment:
                guard !state.editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return .none
                }
                // Parent reducer (AppFeature) creates/updates the comment in
                // `allComments` BEFORE this child runs (see AppFeature.body —
                // the upstream `.comment(.submitComment)` Reduce is placed
                // before `Scope(state: \.comment, ...)`). After parent persists
                // the comment, this child clears editor state.
                state.editorState = nil
                state.editorText = ""
                return .none

            case .cancelEditor:
                state.editorState = nil
                state.editorText = ""
                return .none

            case .editComment:
                // Handled by parent
                return .none

            case .deleteComment:
                // Handled by parent
                return .none

            case .navigateComment:
                // Handled by parent (needs access to allComments)
                return .none

            case let .setFocusedComment(id):
                state.focusedCommentID = id
                return .none
            }
        }
    }
}
```

### InspectorFeature

Manages the right sidebar: review context, overall comment editor, and the preview/all-comments tab control.

```swift
/// Implements: FR-crp-prompt-preamble, FR-crp-prompt-preview, FR-crp-comment-summary,
/// FR-crp-review-context-overall, FR-crp-review-context-collapsible
@Reducer
struct InspectorFeature {
    @ObservableState
    struct State: Equatable {
        /// Active tab: preview or all comments.
        var activeTab: InspectorTab = .preview
        /// Whether the overall review context section is collapsed.
        var isReviewContextCollapsed: Bool = false
    }

    @CasePathable
    enum Action: Equatable {
        case tabChanged(InspectorTab)
        case reviewContextExpandedChanged(Bool)
        case commentSummaryCommentTapped(Comment.ID)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .tabChanged(tab):
                state.activeTab = tab
                return .none

            // Write the exact requested value — never toggle. The DisclosureGroup
            // isExpanded binding must round-trip its value; a value-ignoring toggle
            // makes the getter disagree with SwiftUI's requested value, which drives
            // an infinite re-layout loop (flicker + compositor thrash).
            case let .reviewContextExpandedChanged(isExpanded):
                state.isReviewContextCollapsed = !isExpanded
                return .none

            case .commentSummaryCommentTapped:
                // Handled by parent (navigate to file + comment)
                return .none
            }
        }
    }
}
```

### PromptFeature

Handles prompt generation and the generated prompt text.

```swift
/// Implements: FR-crp-prompt-generate, FR-crp-prompt-format, FR-crp-multi-file-prompt,
/// FR-crp-multi-file-prompt-format, NFR-crp-prompt-gen-time
@Reducer
struct PromptFeature {
    @ObservableState
    struct State: Equatable {
        var generatedPrompt: String?
        var isGenerating: Bool = false
    }

    @CasePathable
    enum Action: Equatable {
        case regenerateRequested(
            files: IdentifiedArrayOf<FileNode>,
            comments: IdentifiedArrayOf<Comment>,
            overallComment: String
        )
        case promptGenerated(String?)
    }

    @Dependency(\.promptGenerator) var promptGenerator

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .regenerateRequested(files, comments, overallComment):
                state.isGenerating = true
                return .run { send in
                    let prompt = await promptGenerator.generate(files, comments, overallComment)
                    await send(.promptGenerated(prompt))
                }

            case let .promptGenerated(prompt):
                state.generatedPrompt = prompt
                state.isGenerating = false
                return .none
            }
        }
    }
}
```

### SessionFeature

Manages session lifecycle, slash command mode, and window identity.

```swift
/// Implements: FR-crp-macos-slash-command-launch, FR-crp-macos-standalone-mode,
/// FR-crp-session-identity, FR-crp-done-action, FR-crp-prompt-handoff,
/// FR-crp-macos-auto-close
@Reducer
struct SessionFeature {
    @ObservableState
    struct State: Equatable {
        /// The session ID (nil in standalone mode).
        var sessionID: String?
        /// Whether the app was launched via slash command with a session.
        var isSlashCommandMode: Bool = false
        /// The project name or working directory for the window title.
        var projectName: String?
        /// Done button state.
        var doneState: DoneState = .idle

        enum DoneState: Equatable {
            case idle, sending, sent
        }

        /// The window title derived from session context.
        /// Implements: FR-crp-session-identity
        var windowTitle: String {
            if let name = projectName {
                return "Shepherd -- \(name)"
            }
            return "Shepherd"
        }
    }

    @CasePathable
    enum Action: Equatable {
        case launched(sessionID: String?)
        case sessionDataLoaded(SessionData)
        case sessionDataLoadFailed(String)
    }

    @Dependency(\.sessionClient) var sessionClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .launched(sessionID):
                state.sessionID = sessionID
                state.isSlashCommandMode = sessionID != nil
                guard let sessionID else { return .none }
                return .run { send in
                    let data = try await sessionClient.loadSession(sessionID)
                    await send(.sessionDataLoaded(data))
                } catch: { error, send in
                    await send(.sessionDataLoadFailed(error.localizedDescription))
                }

            case let .sessionDataLoaded(data):
                state.projectName = data.projectName ?? data.workingDirectory
                // Parent handles loading files and review context from data
                return .none

            case .sessionDataLoadFailed:
                // Parent may show an alert
                return .none
            }
        }
    }
}
```

### ReviewContextFeature

Manages the per-file review context display state.

**Collapse binding contract.** Both the per-file panel and the overall inspector
section render their collapsible container with a SwiftUI `DisclosureGroup` bound to
an `isExpanded` binding derived from `!isCollapsed`. The collapse action is
**value-carrying** (`expandedChanged(Bool)`) and the reducer writes the exact value
(`isCollapsed = !isExpanded`). It must never be a value-ignoring toggle: a toggle makes
the binding getter disagree with the value SwiftUI just wrote, so SwiftUI re-writes to
reconcile, which toggles again — an infinite layout-invalidation loop that flickers and
starves scrolling. This surfaces only in the review flow because these panels render
only when review-context data is present.

```swift
/// Implements: FR-crp-review-context-display, FR-crp-review-context-per-file,
/// FR-crp-review-context-collapsible
@Reducer
struct ReviewContextFeature {
    @ObservableState
    struct State: Equatable {
        /// Whether the per-file context panel is collapsed.
        var isCollapsed: Bool = false
        /// The active file's per-file context (nil if no context for this file).
        var activeFileContext: ReviewContext.ContextPair?
    }

    @CasePathable
    enum Action: Equatable {
        case expandedChanged(Bool)
        case activeFileContextUpdated(ReviewContext.ContextPair?)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // Write the exact requested value — never toggle (see Collapse binding contract).
            case let .expandedChanged(isExpanded):
                state.isCollapsed = !isExpanded
                return .none
            case let .activeFileContextUpdated(context):
                state.activeFileContext = context
                return .none
            }
        }
    }
}
```

---

## Dependencies (via `@Dependency`)

All side effects are modeled as TCA dependencies. Each dependency has a live implementation and a test/preview implementation.

### FileClient

```swift
/// File system operations.
/// Implements: FR-crp-file-load, FR-crp-macos-file-open-panel,
/// FR-crp-macos-drag-drop-finder, FR-crp-macos-sandboxed-file-access
struct FileClient {
    /// Read a file's content. Returns (content, fileName, filePath).
    var readFile: @Sendable (URL) async throws -> (String, String, URL)
    /// Check if a file is binary by scanning for null bytes in the first 8192 bytes.
    var isBinaryFile: @Sendable (URL) async throws -> Bool
    /// Read all files from a list of URLs. Filters out binary files.
    var readFiles: @Sendable ([URL]) async throws -> [(content: String, name: String, url: URL)]
    /// Read session data from the session directory.
    var readSessionData: @Sendable (String) async throws -> SessionData
}

extension FileClient: DependencyKey {
    static let liveValue = FileClient(
        readFile: { url in
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) else {
                throw FileClientError.notTextFile
            }
            return (content, url.lastPathComponent, url)
        },
        isBinaryFile: { url in
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let scanLength = min(data.count, 8192)
            return data.prefix(scanLength).contains(0x00)
        },
        readFiles: { urls in
            // Implementation filters binary files, reads each valid file
            // ...
        },
        readSessionData: { sessionID in
            let sessionDir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".shepherd/sessions/\(sessionID)")
            let sessionFile = sessionDir.appendingPathComponent("session.json")
            let data = try Data(contentsOf: sessionFile)
            return try JSONDecoder().decode(SessionData.self, from: data)
        }
    )

    static let testValue = FileClient(
        readFile: unimplemented("FileClient.readFile"),
        isBinaryFile: unimplemented("FileClient.isBinaryFile"),
        readFiles: unimplemented("FileClient.readFiles"),
        readSessionData: unimplemented("FileClient.readSessionData")
    )
}

enum FileClientError: Error, LocalizedError {
    case notTextFile
    case permissionDenied
    case readFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notTextFile: return "This file does not appear to contain text."
        case .permissionDenied: return "The file could not be read. Check permissions."
        case .readFailed(let e): return "Failed to read file: \(e.localizedDescription)"
        }
    }
}
```

### ClipboardClient

```swift
/// System pasteboard operations.
/// Implements: FR-crp-prompt-copy, FR-crp-macos-clipboard
struct ClipboardClient {
    /// Copy text to the system clipboard.
    var copyText: @Sendable (String) async -> Void
    /// Read plain text from the system clipboard (for paste-to-load).
    var readText: @Sendable () async -> String?
}

extension ClipboardClient: DependencyKey {
    static let liveValue = ClipboardClient(
        copyText: { text in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        },
        readText: {
            NSPasteboard.general.string(forType: .string)
        }
    )

    static let testValue = ClipboardClient(
        copyText: unimplemented("ClipboardClient.copyText"),
        readText: unimplemented("ClipboardClient.readText")
    )
}
```

### SyntaxHighlightClient

```swift
/// Syntax highlighting via TreeSitter.
/// Implements: FR-crp-syntax-highlight
struct SyntaxHighlightClient {
    /// Highlight a file's content, returning an array of syntax tokens.
    /// Runs on a background thread for performance.
    var highlight: @Sendable (String, SyntaxLanguage) async -> [SyntaxToken]
}

extension SyntaxHighlightClient: DependencyKey {
    static let liveValue = SyntaxHighlightClient(
        highlight: { content, language in
            // Uses SwiftTreeSitter to parse and produce tokens.
            // Runs on a detached Task to avoid blocking the main actor.
            // Falls back to empty tokens (plain text) if parsing fails.
            // See "Syntax Highlighting Strategy" section for details.
            await TreeSitterHighlighter.shared.highlight(content, language: language)
        }
    )

    static let testValue = SyntaxHighlightClient(
        highlight: { _, _ in [] }
    )
}
```

### PromptGeneratorClient

```swift
/// Pure prompt generation.
/// Implements: FR-crp-prompt-generate, FR-crp-prompt-format,
/// FR-crp-multi-file-prompt-format, NFR-crp-prompt-gen-time
struct PromptGeneratorClient {
    /// Generate the structured prompt from files, comments, and the overall comment.
    /// Pure function -- no side effects.
    var generate: @Sendable (IdentifiedArrayOf<FileNode>, IdentifiedArrayOf<Comment>, String) async -> String?
}

extension PromptGeneratorClient: DependencyKey {
    static let liveValue = PromptGeneratorClient(
        generate: { files, comments, overallComment in
            PromptBuilder.build(files: files, comments: comments, overallComment: overallComment)
        }
    )

    static let testValue = PromptGeneratorClient(
        generate: { _, _, _ in nil }
    )
}
```

### SessionClient

```swift
/// Session directory operations.
/// Implements: FR-crp-prompt-handoff, FR-crp-macos-slash-command-launch
struct SessionClient {
    /// Load session data from ~/.shepherd/sessions/<session-id>/
    var loadSession: @Sendable (String) async throws -> SessionData
    /// Write prompt output to the session directory.
    var writePromptOutput: @Sendable (String, String) async throws -> Void
}

extension SessionClient: DependencyKey {
    static let liveValue = SessionClient(
        loadSession: { sessionID in
            let sessionDir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".shepherd/sessions/\(sessionID)")
            let sessionFile = sessionDir.appendingPathComponent("session.json")
            let data = try Data(contentsOf: sessionFile)
            return try JSONDecoder().decode(SessionData.self, from: data)
        },
        writePromptOutput: { sessionID, promptText in
            let outputPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".shepherd/sessions/\(sessionID)/prompt-output.md")
            try promptText.write(to: outputPath, atomically: true, encoding: .utf8)
        }
    )

    static let testValue = SessionClient(
        loadSession: unimplemented("SessionClient.loadSession"),
        writePromptOutput: unimplemented("SessionClient.writePromptOutput")
    )
}
```

### WindowClient

```swift
/// Window management operations.
/// Implements: FR-crp-macos-window-management, FR-crp-macos-auto-close
struct WindowClient {
    /// Close the frontmost window.
    var closeWindow: @Sendable () async -> Void
    /// Bring a window with a given session ID to the front.
    /// Returns true if an existing window was found and activated.
    var bringWindowToFront: @Sendable (String) async -> Bool
    /// Configure window geometry persistence for a session.
    /// Uses NSWindow.setFrameAutosaveName keyed by session ID, so each
    /// window independently saves/restores its position and size.
    var configureAutosave: @Sendable (String?) async -> Void
}

extension WindowClient: DependencyKey {
    static let liveValue = WindowClient(
        closeWindow: {
            await MainActor.run {
                NSApplication.shared.keyWindow?.close()
            }
        },
        bringWindowToFront: { sessionID in
            await MainActor.run {
                for window in NSApplication.shared.windows {
                    if window.frameAutosaveName == "session-\(sessionID)" {
                        window.makeKeyAndOrderFront(nil)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        return true
                    }
                }
                return false
            }
        },
        configureAutosave: { sessionID in
            await MainActor.run {
                guard let window = NSApplication.shared.keyWindow else { return }
                let name = sessionID.map { "session-\($0)" } ?? "standalone"
                window.setFrameAutosaveName(name)
            }
        }
    )

    static let testValue = WindowClient(
        closeWindow: unimplemented("WindowClient.closeWindow"),
        bringWindowToFront: unimplemented("WindowClient.bringWindowToFront"),
        configureAutosave: unimplemented("WindowClient.configureAutosave")
    )
}
```

---

## Prompt Builder

The prompt builder is a pure function with no dependencies. It lives in `SharedModels` and is used by both the `PromptGeneratorClient` and tests directly.

```swift
/// Implements: FR-crp-prompt-format, FR-crp-multi-file-prompt-format,
/// NFR-crp-prompt-gen-time
enum PromptBuilder {
    /// Build the structured prompt. Returns nil if no files have comments.
    static func build(
        files: IdentifiedArrayOf<FileNode>,
        comments: IdentifiedArrayOf<Comment>,
        overallComment: String
    ) -> String? {
        // Group comments by file
        let commentsByFile = Dictionary(grouping: comments.elements, by: \.fileID)

        // Filter to files that have comments, in file order
        let filesWithComments = files.filter { commentsByFile[$0.id]?.isEmpty == false }

        guard !filesWithComments.isEmpty else { return nil }

        var sections: [String] = []

        // Instructions section (overall comment)
        let trimmed = overallComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            sections.append("## Instructions\n\n\(trimmed)")
        }

        // Per-file sections
        for file in filesWithComments {
            let fileComments = (commentsByFile[file.id] ?? [])
                .sorted { ($0.startLine, $0.createdAt) < ($1.startLine, $1.createdAt) }

            let lang = file.language.rawValue
            let name = file.filePath ?? file.name
            var fileSection = "## File: \(name) (\(lang))\n\n### Requested Changes\n"

            for comment in fileComments {
                // Clamp defensively: a comment may reference lines outside the current
                // file (stale comment after content shrank, or malformed endLine <
                // startLine). An unguarded range would form lowerBound > upperBound and
                // crash prompt generation, which runs on every edit via regeneratePrompt.
                let range = snippetRange(for: comment, lineCount: file.lines.count)
                let snippet = file.lines[range].joined(separator: "\n")

                fileSection += "\n```\(lang)\n\(snippet)\n```\n\(comment.text)\n"
            }

            sections.append(fileSection)
        }

        return sections.joined(separator: "\n\n")
    }

    /// Half-open snippet range, clamped so out-of-range comments yield an empty snippet
    /// instead of crashing. `start = clamp(startLine-1, 0...count)`, `end = clamp(endLine,
    /// start...count)`.
    private static func snippetRange(for comment: Comment, lineCount: Int) -> Range<Int> { ... }
}
```

The prompt format is identical to the web version (`FR-crp-prompt-format`, `FR-crp-multi-file-prompt-format`), ensuring interoperability when users switch between platforms. Snippet extraction is **crash-safe**: comment line indices are clamped to the file's current line count, so a stale or malformed comment produces an empty snippet rather than an invalid `Range` fatal error (`FR-crp-prompt-generate`).

---

## View Architecture

### AppView (Root)

The root view uses `NavigationSplitView` for the three-column layout (file browser, code viewer, inspector) in multi-file mode, and a plain `HSplitView` for the two-column layout in single-file mode.

```swift
/// Root view. Implements the layout described in the design spec.
struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.files.isEmpty {
                FileDropZoneView(store: store)
            } else if store.isMultiFile {
                // Three-column layout
                // FR-crp-multi-file-nav, FR-crp-panel-resize
                NavigationSplitView(
                    sidebar: {
                        FileBrowserView(
                            store: store.scope(state: \.fileBrowser, action: \.fileBrowser)
                        )
                        .navigationSplitViewColumnWidth(
                            min: 180, ideal: store.fileBrowserWidth, max: 500
                        )
                    },
                    content: {
                        CodeViewerPanelView(store: store)
                    },
                    detail: {
                        InspectorView(
                            store: store.scope(state: \.inspector, action: \.inspector)
                        )
                        .navigationSplitViewColumnWidth(min: 240, ideal: 340)
                    }
                )
            } else {
                // Two-column layout (single file)
                HSplitView {
                    CodeViewerPanelView(store: store)
                    InspectorView(
                        store: store.scope(state: \.inspector, action: \.inspector)
                    )
                    .frame(minWidth: 240, idealWidth: 340)
                }
            }
        }
        .toolbar { ToolbarView(store: store) }
        .navigationTitle(store.session.windowTitle)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            // Handle file drops anywhere on the window
            // FR-crp-macos-drag-drop-finder
            true
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
```

### Menu Bar

The menu bar is defined at the app level using SwiftUI's `@CommandsBuilder`. Menu item states are derived from the store.

```swift
/// Implements: FR-crp-macos-menu-bar, FR-crp-macos-keyboard-shortcuts,
/// AC-crp-macos-menu-shortcuts
struct ShepherdCommands: Commands {
    @Bindable var store: StoreOf<AppFeature>

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                store.send(.fileOpenPanelRequested)
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandMenu("Review") {
            Button("Copy Prompt") {
                store.send(.copyPrompt)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(!store.hasComments)

            if store.session.isSlashCommandMode {
                Button("Done") {
                    store.send(.doneRequested)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!store.hasComments)
            }

            Divider()

            Button("Next Comment") {
                store.send(.codeViewer(.comment(.navigateComment(.next))))
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(!store.hasComments)

            Button("Previous Comment") {
                store.send(.codeViewer(.comment(.navigateComment(.previous))))
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(!store.hasComments)

            Divider()

            Button("Mark Current File as Reviewed") {
                if let id = store.activeFileID {
                    store.send(.fileBrowser(.toggleFileReviewed(id)))
                }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(store.activeFileID == nil)

            Divider()

            Button("Clear Session") {
                store.send(.clearSessionRequested)
            }
            .disabled(store.files.isEmpty)
        }

        CommandGroup(replacing: .toolbar) {
            Button("Toggle Line Wrapping") {
                store.send(.toggleLineWrap)
            }
            .disabled(store.files.isEmpty)

            Divider()

            Button("Toggle Sidebar") {
                // Toggle NavigationSplitView sidebar visibility
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
            .disabled(!store.isMultiFile)

            Button("Toggle Inspector") {
                // Toggle inspector sidebar visibility
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
            .disabled(store.files.isEmpty)
        }
    }
}
```

---

## Syntax Highlighting Strategy

Syntax highlighting uses **SwiftTreeSitter** (a Swift wrapper around TreeSitter) for native, high-performance parsing.

### Architecture

```swift
/// Singleton highlighter that manages TreeSitter parsers.
/// Runs highlighting on a background thread to avoid blocking the main actor.
actor TreeSitterHighlighter {
    static let shared = TreeSitterHighlighter()

    /// Cache of loaded language parsers.
    private var parsers: [SyntaxLanguage: Parser] = [:]

    /// Highlight content and return syntax tokens.
    func highlight(_ content: String, language: SyntaxLanguage) -> [SyntaxToken] {
        guard language != .plaintext else { return [] }

        let parser = getOrCreateParser(for: language)
        guard let tree = parser.parse(content) else { return [] }

        // Walk the syntax tree and produce tokens
        var tokens: [SyntaxToken] = []
        // ... tree traversal producing SyntaxToken array
        return tokens
    }
}
```

### Performance

- **Background execution**: All TreeSitter parsing runs in a `Task.detached` context (off the main actor) to avoid blocking UI rendering (`NFR-crp-render-time`).
- **Incremental parsing**: For future optimization, TreeSitter supports incremental re-parsing when file content changes. Not needed for v1 since files are read-only.
- **Parser caching**: Language parsers are created once and reused. The `TreeSitterHighlighter` actor manages the parser lifecycle.
- **Token caching**: Syntax tokens for each file are cached in `CodeViewerFeature.State.syntaxTokens`. When the user switches files, previously computed tokens are restored from `FileNode`-scoped storage (managed by the parent reducer) rather than re-parsed.
- **Progressive rendering**: The code viewer displays plain text immediately and applies syntax highlighting tokens as they become available. The text with line numbers is visible within 500ms (`NFR-crp-render-time`); syntax coloring appears shortly after.

### Language Support

All 13 required languages (`FR-crp-syntax-highlight`) are supported via TreeSitter grammar packages:

| Language | Grammar Package | Extensions |
|---|---|---|
| JavaScript | tree-sitter-javascript | `.js`, `.jsx`, `.mjs`, `.cjs` |
| TypeScript | tree-sitter-typescript | `.ts`, `.tsx` |
| Python | tree-sitter-python | `.py` |
| Go | tree-sitter-go | `.go` |
| Rust | tree-sitter-rust | `.rs` |
| Java | tree-sitter-java | `.java` |
| C | tree-sitter-c | `.c`, `.h` |
| C++ | tree-sitter-cpp | `.cpp`, `.cc`, `.cxx`, `.hpp` |
| HTML | tree-sitter-html | `.html`, `.htm` |
| CSS | tree-sitter-css | `.css` |
| JSON | tree-sitter-json | `.json` |
| YAML | tree-sitter-yaml | `.yaml`, `.yml` |
| Markdown | tree-sitter-markdown | `.md`, `.markdown` |

---

## Performance Strategy

### Large File Handling (`NFR-crp-large-file-perf`, `AC-crp-large-file-scroll`)

- **Virtualized rendering**: The code viewer uses `LazyVStack` inside a `ScrollView` with `ScrollViewReader`. Only visible lines (plus an overscan buffer of ~50 lines above and below) are rendered. This keeps the view hierarchy manageable for files with 10,000+ lines.
- **Line height pre-computation**: Line heights are pre-computed based on font metrics and the line wrapping setting. When wrapping is enabled, line heights are calculated using `NSString.boundingRect(with:attributes:)` with the current viewport width.
- **Scroll position restoration**: Each `FileNode` stores a `scrollOffset` (line index). When switching files, the scroll position is restored via `ScrollViewProxy.scrollTo()`.

### Syntax Highlighting Performance

- **Background thread**: TreeSitter parsing runs off the main actor (see Syntax Highlighting Strategy).
- **Progressive display**: Text is shown immediately; syntax tokens are applied asynchronously. Users see plain monospace text within the 500ms render window (`NFR-crp-render-time`), with coloring applied as tokens arrive.
- **Token cache per file**: When switching between files, cached tokens are restored immediately. No re-parsing needed for previously viewed files.
- **Unload inactive tokens**: When memory pressure is detected (or when more than 20 files are loaded), syntax tokens for files not recently viewed are released. The tokens are re-generated on next view.

### Prompt Generation Performance (`NFR-crp-prompt-gen-time`)

- **Debounced regeneration**: Prompt generation is triggered reactively whenever comments or the overall comment change. A 100ms debounce is applied via a TCA `cancellable` effect to coalesce rapid changes (e.g., typing in the overall comment field). The debounce key is `PromptRegenerationID`.
- **Pure function**: `PromptBuilder.build()` is a pure function with no I/O. It iterates files and comments once, building the output string. Complexity is O(F * C) where F is files with comments and C is comments per file. For the target workload (20 files, 200 comments), this completes in < 10ms.

### Memory Management (`NFR-crp-macos-memory`)

- **Lazy file content**: File content strings are loaded into memory when the file is added. For v1, all files remain in memory. For very large sessions (20+ files), future optimization could unload file content for inactive files and re-read from disk on demand.
- **Token release**: Syntax tokens for inactive files can be released under memory pressure.
- **Target**: < 200 MB for 10 files, 50 comments (`NFR-crp-macos-memory`). < 80 MB idle.

### Launch Performance (`NFR-crp-macos-launch-time`)

- **Minimal startup work**: The app creates the root store and renders the empty state view. No heavy initialization until files are loaded.
- **Lazy parser loading**: TreeSitter language parsers are loaded on first use, not at launch.
- **Target**: Window visible and interactive within 1 second from cold start.

---

## Error Handling

### File Loading Errors

| Error | Trigger | User Experience | Slug |
|---|---|---|---|
| Binary file detected | Null byte found in first 8,192 bytes | Native alert: "Cannot Open File" / "This file does not appear to contain text." | `AC-crp-binary-file-rejected` |
| Permission denied | File not readable | Native alert: "Cannot Read File" / "Check that the application has permission." | `AC-crp-macos-file-permission-error` |
| Read failure | I/O error | Native alert: "Failed to Read File" / "An error occurred. Please try again." | -- |
| Encoding failure | Non-UTF-8 file | Native alert: "Cannot Open File" / "This file does not appear to contain text." | -- |

All file loading errors are surfaced via TCA alert state (`@Presents var alert: AlertState<Action.Alert>?`), ensuring they are testable and dismissible.

### Prompt Handoff Errors

| Error | Trigger | User Experience | Slug |
|---|---|---|---|
| Session directory not writable | Permission or missing directory | Alert: "Could Not Send to Agent" / "Prompt copied to clipboard." Prompt is on clipboard. | `AC-crp-done-fallback-clipboard` |
| Write failure | I/O error | Same as above. | `AC-crp-done-fallback-clipboard` |

The Done flow always copies the prompt to the clipboard as a first step, so the fallback is always available.

---

## Security Considerations

### Local-Only Processing (`NFR-crp-client-only`)

All file content, comments, and prompt data remain within the application process. No network requests are made. The only file system I/O is:
- Reading files selected by the user (via open panel or drag-and-drop).
- Reading session data from `~/.shepherd/sessions/` (slash command mode).
- Writing prompt output to `~/.shepherd/sessions/<id>/prompt-output.md` (slash command mode).

### File Access (`FR-crp-macos-sandboxed-file-access`)

The application accesses files through the standard macOS security model:
- Files opened via the open panel are granted access through the user's explicit selection (NSOpenPanel provides security-scoped URLs).
- Files dropped from Finder are accessible via the drag-and-drop pasteboard.
- The session directory (`~/.shepherd/`) is in the user's home directory and is accessible without special entitlements when the app is not sandboxed.

For future App Store distribution, the sandbox entitlements would need:
- `com.apple.security.files.user-selected.read-only` (for open panel / drag-and-drop)
- `com.apple.security.files.bookmarks.app-scope` (for session directory access, if needed)

### Code Signing (`FR-crp-macos-distribution`, `AC-crp-macos-signed-notarized`)

The application is signed with a Developer ID certificate and notarized via `notarytool`. This ensures Gatekeeper allows the application to run without "unidentified developer" warnings.

---

## Build & Distribution

### Build Pipeline

```
Source Code (Swift)
    │
    ▼
Xcode Build (xcodebuild)
    │
    ├──► Debug build (development)
    │
    └──► Release build (distribution)
         │
         ▼
    Code Signing (Developer ID)
         │
         ▼
    Notarization (notarytool)
         │
         ▼
    .app bundle (ready for distribution)
```

### CI Configuration

- **Platform**: GitHub Actions with macOS runner (or Xcode Cloud).
- **Build command**: `xcodebuild -scheme Shepherd -configuration Release -derivedDataPath build/`
- **Test command**: `xcodebuild test -scheme ShepherdTests -configuration Debug`
- **Signing**: Developer ID certificate stored in CI keychain.
- **Notarization**: `xcrun notarytool submit Shepherd.app.zip --apple-id ... --team-id ... --password ...`

### Distribution Channels

1. **Direct download**: `.app` bundle in a `.zip` or `.dmg` from the project's releases page.
2. **Homebrew cask**: `brew install --cask shepherd`

```ruby
# Homebrew cask formula
cask "shepherd" do
  version "1.0.0"
  sha256 "..."

  url "https://github.com/.../releases/download/v#{version}/Shepherd-#{version}.dmg"
  name "Shepherd"
  desc "Code Review Prompt Generator for AI coding assistants"
  homepage "https://github.com/..."

  app "Shepherd.app"

  zap trash: [
    "~/Library/Preferences/com.shepherd.app.plist",
    "~/.shepherd",
  ]
end
```

### CLI Integration (`FR-crp-macos-slash-command-launch`)

The CLI launches the macOS app via a custom URL scheme. This approach works regardless of whether the app is already running — macOS delivers the URL to the running instance via `onOpenURL`, or launches the app and delivers it on startup.

```bash
# CLI launches via URL scheme (works whether app is running or not)
open "shepherd://open?session=abc123"
```

The URL scheme `shepherd://` is registered in the app's `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>shepherd</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.shepherd.app</string>
    </dict>
</array>
```

The `ShepherdApp` entry point handles both initial launch (command-line args for direct invocation) and URL-based launch (for the typical CLI flow):

```swift
@main
struct ShepherdApp: App {
    let store: StoreOf<AppFeature>

    init() {
        // Bare SwiftPM executable (no .app bundle): force regular activation
        // policy and activate so the window becomes key and text input works.
        // Without this, TextEditor key events beep because no first responder.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Handle direct invocation with --session flag (fallback for dev/testing)
        let sessionID = Self.parseSessionID()
        self.store = Store(initialState: AppFeature.State()) {
            AppFeature()
        }
        if let sessionID {
            store.send(.session(.launched(sessionID: sessionID)))
        }
    }

    static func parseSessionID() -> String? {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "--session"),
              idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
        .commands { ShepherdCommands(store: store) }
        .handlesExternalEvents(matching: ["shepherd"])
        .onOpenURL { url in
            // Parse shepherd://open?session=abc123
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let sessionID = components.queryItems?.first(where: { $0.name == "session" })?.value
            else { return }
            store.send(.session(.launched(sessionID: sessionID)))
        }
    }
}
```

Window deduplication (`AC-crp-macos-window-deduplicate`): When the app receives a URL with a session ID that already has an open window, the `.session(.launched(sessionID:))` action first checks via `WindowClient.bringWindowToFront`. If an existing window is found, it is activated and no new window is opened. If no existing window matches, a new window is created for the session. This works reliably for both first-launch and already-running scenarios because `onOpenURL` is delivered to the running app instance by macOS.

---

## Testing Strategy

### TCA TestStore

Every reducer is tested using TCA's `TestStore`, which provides exhaustive verification of state changes and effects.

```swift
import Testing
import ComposableArchitecture
@testable import CommentFeature

@Test
func testAddComment() async {
    let store = TestStore(initialState: CommentFeature.State()) {
        CommentFeature()
    }

    await store.send(.openEditor(.creating(anchorLine: 5, endLine: 5))) {
        $0.editorState = .creating(anchorLine: 5, endLine: 5)
        $0.editorText = ""
    }

    await store.send(.binding(.set(\.editorText, "Rename this variable"))) {
        $0.editorText = "Rename this variable"
    }

    await store.send(.submitComment) {
        $0.editorState = nil
        $0.editorText = ""
    }
}
```

### Dependency Overrides

All side effects are injectable. Tests override dependencies to provide deterministic behavior:

```swift
@Test
func testLoadSession() async {
    let mockSession = SessionData(
        sessionID: "abc123",
        workingDirectory: "/Users/dev/project",
        projectName: "myproject",
        files: [.init(path: "src/main.swift", content: "let x = 1")],
        reviewContext: nil
    )

    let store = TestStore(initialState: SessionFeature.State()) {
        SessionFeature()
    } withDependencies: {
        $0.sessionClient.loadSession = { _ in mockSession }
    }

    await store.send(.launched(sessionID: "abc123")) {
        $0.sessionID = "abc123"
        $0.isSlashCommandMode = true
    }

    await store.receive(.sessionDataLoaded(mockSession)) {
        $0.projectName = "myproject"
    }
}
```

### Prompt Builder Tests

The prompt builder is a pure function and is tested directly without `TestStore`:

```swift
import Testing
import CustomDump
@testable import SharedModels

@Test
func testSingleFilePromptFormat() {
    let file = FileNode(
        id: UUID(),
        name: "utils.ts",
        language: .typescript,
        content: "const x = 1;\nconst y = 2;\nconst z = 3;",
        lines: ["const x = 1;", "const y = 2;", "const z = 3;"]
    )
    let comment = Comment(
        id: UUID(),
        fileID: file.id,
        startLine: 1,
        endLine: 1,
        text: "Rename this variable",
        createdAt: Date()
    )

    let result = PromptBuilder.build(
        files: [file],
        comments: [comment],
        overallComment: "Refactor for readability"
    )

    expectNoDifference(result, """
    ## Instructions

    Refactor for readability

    ## File: utils.ts (typescript)

    ### Requested Changes

    ```typescript
    const x = 1;
    ```
    Rename this variable
    """)
}
```

### Snapshot Tests

Key views are snapshot-tested using `swift-snapshot-testing`:

```swift
import SnapshotTesting
import SwiftUI
@testable import FileBrowserFeature

@Test
func testFileBrowserSnapshot() {
    let view = FileBrowserView(store: Store(
        initialState: .mock(withFiles: 5, reviewed: 2),
        reducer: { FileBrowserFeature() }
    ))

    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 600)))
}
```

### Test Coverage Matrix

| Module | Test Type | Framework | What's Tested |
|---|---|---|---|
| `SharedModels` | Unit | Swift Testing | `PromptBuilder`, `SyntaxLanguage.detect`, `FileTreeNode` building |
| `AppFeature` | Reducer | TCA TestStore | File loading, clear session, done flow, alert presentation |
| `FileBrowserFeature` | Reducer | TCA TestStore | File selection, directory collapse, review toggle |
| `CodeViewerFeature` | Reducer | TCA TestStore | Line click, range selection, syntax highlight completion |
| `CommentFeature` | Reducer | TCA TestStore | Create, edit, delete, navigation |
| `InspectorFeature` | Reducer | TCA TestStore | Tab switching, context collapse |
| `PromptFeature` | Reducer | TCA TestStore | Regeneration trigger, debouncing |
| `SessionFeature` | Reducer | TCA TestStore | Session loading, slash command mode |
| Views | Snapshot | swift-snapshot-testing | FileBrowser, CodeViewer, Inspector, EmptyState |
| Integration | E2E | Xcode UI Tests | Full flow: load file, add comment, copy prompt |

---

## Implementation Plan

### Phase 1: Foundation

1. **Set up Xcode project and SPM workspace.** Create the project structure, add TCA and other dependencies, configure build targets for each feature module.
2. **Implement `SharedModels`.** Define all data types (`FileNode`, `Comment`, `ReviewContext`, `SessionData`, `SyntaxLanguage`, `PromptBuilder`, `FileTreeNode` builder). Write unit tests for `PromptBuilder` and `SyntaxLanguage.detect`.
3. **Implement `AppFeature` reducer (skeleton).** Root state, basic action handling, child reducer composition. Window lifecycle.
4. **Implement `FileClient` dependency.** File reading, binary detection, error handling. Write tests with dependency overrides.

### Phase 2: Core Features

5. **Implement `CodeViewerFeature`.** Line rendering with `LazyVStack`, line numbers, gutter, line click/range selection. Line wrapping toggle (`FR-crp-line-wrap`). Write reducer tests.
6. **Implement `SyntaxHighlightClient`.** TreeSitter integration, background parsing, token production. Test with sample files in each language.
7. **Implement `CommentFeature`.** InlineCommentEditor view, CommentBubble view, create/edit/delete flows, comment navigation. Write reducer tests.
8. **Implement `PromptFeature`.** Prompt generation with debouncing, PromptPreview view. Write reducer tests.

### Phase 3: Multi-File & Inspector

9. **Implement `FileBrowserFeature`.** Directory tree rendering, file selection, review status toggles, resize behavior. Write reducer tests and snapshot tests.
10. **Implement `InspectorFeature`.** Overall Comment editor, Preview/All Comments tabs, CommentSummary view. Write reducer tests.
11. **Implement `ReviewContextFeature`.** ReviewContextPanel (per-file), ReviewContextSection (overall), collapse behavior. Write reducer tests.
12. **Wire up multi-file flows in `AppFeature`.** File switching, state preservation, prompt regeneration across files, ActiveFilePath. Write integration tests.

### Phase 4: Session & Polish

13. **Implement `SessionFeature`.** Slash command launch, session data loading, window title. Write reducer tests.
14. **Implement Done flow.** Prompt handoff, clipboard copy, window close, error fallback. Write reducer tests.
15. **Implement menu bar.** All menus (File, Edit, View, Review, Window) with keyboard shortcuts. Validate shortcut conflicts.
16. **Implement empty state.** FileDropZone with drag-and-drop, paste, open panel integration.
17. **Implement confirmation dialogs.** Clear session, remove file (with comments). Wire up alert states.

### Phase 5: Distribution

18. **Implement `ClipboardClient`.** System pasteboard read/write. Write tests.
19. **Implement `WindowClient`.** Window close, deduplication, position persistence.
20. **Performance optimization.** Profile with Instruments for large files (10,000+ lines). Optimize LazyVStack rendering, syntax highlighting, and prompt generation.
21. **Accessibility audit.** VoiceOver testing, keyboard navigation, reduced motion, high contrast.
22. **Code signing and notarization.** Configure Developer ID signing, notarize the release build.
23. **Create Homebrew cask formula.** Publish to a tap.
24. **Write snapshot tests** for all key views (empty state, single file, multi-file, inspector tabs).
