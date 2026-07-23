import ComposableArchitecture
import SharedModels
import ShepherdDependencies
import FileBrowserFeature
import CodeViewerFeature
import CommentFeature
import InspectorFeature
import PromptFeature
import SessionFeature
import ReviewContextFeature
import MarkdownRenderFeature
import IdentifiedCollections
import Foundation

/// A file loaded from disk or clipboard.
public struct LoadedFile: Equatable, Sendable {
    public let content: String
    public let name: String
    public let url: URL?

    public init(content: String, name: String, url: URL?) {
        self.content = content
        self.name = name
        self.url = url
    }
}

/// Root reducer composing all child features.
/// Implements: FR-crp-file-load, FR-crp-multi-file-load, FR-crp-line-comment-create,
/// FR-crp-prompt-generate, FR-crp-prompt-copy, FR-crp-done-action
@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        // Child feature states
        public var session: SessionFeature.State
        public var fileBrowser: FileBrowserFeature.State
        public var codeViewer: CodeViewerFeature.State
        public var comment: CommentFeature.State
        public var inspector: InspectorFeature.State
        public var prompt: PromptFeature.State
        public var reviewContext: ReviewContextFeature.State

        // Shared state (accessible by multiple children)
        public var files: IdentifiedArrayOf<FileNode> = []
        public var allComments: IdentifiedArrayOf<Comment> = []
        public var activeFileID: FileNode.ID?
        public var overallComment: String = ""
        public var lineWrapEnabled: Bool = true
        public var reviewContextData: ReviewContext?

        /// Markdown rendering mode (raw or rendered)
        /// Implements: FR-mdr-render-toggle
        public var renderMode: MarkdownRenderMode = .raw

        /// Transient: true for ~2s after a successful copy; drives the Copy Prompt
        /// toolbar checkmark animation. Implements: FR-crp-prompt-copy
        public var showCopyConfirmation: Bool = false

        // Navigation / alerts
        @Presents public var alert: AlertState<Action.Alert>?

        // Derived
        public var isMultiFile: Bool { files.count >= 2 }
        public var hasComments: Bool { !allComments.isEmpty }
        public var activeFile: FileNode? { activeFileID.flatMap { files[id: $0] } }
        public var commentCount: Int { allComments.count }
        public var generatedPrompt: String? { prompt.generatedPrompt }
        public var isActiveFileMarkdown: Bool { activeFile?.isMarkdownFile ?? false }

        public init(
            session: SessionFeature.State = SessionFeature.State(),
            fileBrowser: FileBrowserFeature.State = FileBrowserFeature.State(),
            codeViewer: CodeViewerFeature.State = CodeViewerFeature.State(),
            comment: CommentFeature.State = CommentFeature.State(),
            inspector: InspectorFeature.State = InspectorFeature.State(),
            prompt: PromptFeature.State = PromptFeature.State(),
            reviewContext: ReviewContextFeature.State = ReviewContextFeature.State(),
            files: IdentifiedArrayOf<FileNode> = [],
            allComments: IdentifiedArrayOf<Comment> = [],
            activeFileID: FileNode.ID? = nil,
            overallComment: String = "",
            lineWrapEnabled: Bool = true,
            reviewContextData: ReviewContext? = nil,
            renderMode: MarkdownRenderMode = .raw
        ) {
            self.session = session
            self.fileBrowser = fileBrowser
            self.codeViewer = codeViewer
            self.comment = comment
            self.inspector = inspector
            self.prompt = prompt
            self.reviewContext = reviewContext
            self.files = files
            self.allComments = allComments
            self.activeFileID = activeFileID
            self.overallComment = overallComment
            self.lineWrapEnabled = lineWrapEnabled
            self.reviewContextData = reviewContextData
            self.renderMode = renderMode
        }
    }

    @CasePathable
    public enum Action: Equatable, BindableAction {
        // Binding
        case binding(BindingAction<State>)

        // Child feature actions
        case session(SessionFeature.Action)
        case fileBrowser(FileBrowserFeature.Action)
        case codeViewer(CodeViewerFeature.Action)
        case comment(CommentFeature.Action)
        case inspector(InspectorFeature.Action)
        case prompt(PromptFeature.Action)
        case reviewContext(ReviewContextFeature.Action)

        // File loading
        case filesDropped([URL])
        case fileOpenPanelRequested
        case filesReadCompleted([FileReadResult])
        case filesLoaded([LoadedFile])
        case pasteFileFromClipboard

        // Session management
        case clearSessionRequested
        case removeFileRequested(FileNode.ID)
        case toggleLineWrap

        // Prompt lifecycle
        case copyPrompt
        case promptCopied
        case dismissCopyConfirmation
        case doneRequested
        case promptHandoffSucceeded
        case promptHandoffFailed(String)

        // Internal
        case regeneratePrompt
        case rebuildFileTree

        // Window lifecycle
        case windowAppeared
        case windowClosed

        // Patch-thread reply live subscription (FR-sr-patch-replies-live via
        // FR-sr-relay-client). The app subscribes to Nostr relays in-process and
        // merges incoming kind:1 root replies into patchMetadata.replies. UI is
        // already reactive to that array.
        case startPatchReplySubscription
        case patchRepliesRefreshedAppend(ReviewContext.PatchReply)

        // Alerts
        case alert(PresentationAction<Alert>)

        @CasePathable
        public enum Alert: Equatable {
            case clearConfirmed
            case removeFileConfirmed(FileNode.ID)
        }
    }

    @Dependency(\.fileClient) var fileClient
    @Dependency(\.clipboardClient) var clipboardClient
    @Dependency(\.promptGenerator) var promptGenerator
    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.windowClient) var windowClient
    @Dependency(\.syntaxHighlightClient) var syntaxHighlighter
    @Dependency(\.relayClient) var relayClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.continuousClock) var clock

    private enum CancelID {
        case promptRegeneration
        case copyConfirmation
        case patchReplySubscription
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.session, action: \.session) {
            SessionFeature()
        }
        Scope(state: \.fileBrowser, action: \.fileBrowser) {
            FileBrowserFeature()
        }
        Scope(state: \.codeViewer, action: \.codeViewer) {
            CodeViewerFeature()
        }

        // Must run BEFORE the comment Scope: child reducer clears
        // editorState/editorText on submit, so parent must read them first.
        Reduce { state, action in
            guard case .comment(.submitComment) = action,
                  let editor = state.comment.editorState else { return .none }
            let trimmed = state.comment.editorText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .none }
            switch editor {
            case let .creating(anchorLine, endLine):
                guard let fileID = state.activeFileID else { return .none }
                let start = min(anchorLine, endLine)
                let end = max(anchorLine, endLine)
                state.allComments.append(
                    Comment(
                        id: uuid(),
                        fileID: fileID,
                        startLine: start,
                        endLine: end,
                        text: trimmed
                    )
                )
            case let .editing(commentID):
                state.allComments[id: commentID]?.text = trimmed
            }
            return .merge(
                .send(.regeneratePrompt),
                .send(.rebuildFileTree)
            )
        }

        Scope(state: \.comment, action: \.comment) {
            CommentFeature()
        }
        Scope(state: \.inspector, action: \.inspector) {
            InspectorFeature()
        }
        Scope(state: \.prompt, action: \.prompt) {
            PromptFeature()
        }
        Scope(state: \.reviewContext, action: \.reviewContext) {
            ReviewContextFeature()
        }

        Reduce { state, action in
            switch action {
            case .binding(\.overallComment):
                return .send(.regeneratePrompt)

            case .binding:
                return .none

            // MARK: - File Loading

            case let .filesDropped(urls):
                return .run { [fileClient] send in
                    let results = try await fileClient.readFiles(urls)
                    await send(.filesReadCompleted(results))
                } catch: { _, send in
                    // Unexpected batch-level failure (per-file errors are reported
                    // as .failed results above, not thrown). Surface a generic error.
                    await send(.filesReadCompleted([.failed(name: "", reason: .readFailed)]))
                }

            // Implements: FR-crp-macos-sandboxed-file-access, AC-crp-binary-file-rejected, AC-crp-macos-file-permission-error
            case let .filesReadCompleted(results):
                let loaded = results.compactMap { result -> LoadedFile? in
                    guard case let .loaded(content, name, url) = result else { return nil }
                    return LoadedFile(content: content, name: name, url: url)
                }
                if let alert = fileErrorAlert(for: results) {
                    state.alert = alert
                }
                return loaded.isEmpty ? .none : .send(.filesLoaded(loaded))

            case .fileOpenPanelRequested:
                // The view handles the NSOpenPanel; results come back as filesDropped
                return .none

            case let .filesLoaded(loaded):
                for item in loaded {
                    let language = SyntaxLanguage.detect(from: item.name)
                    let fileNode = FileNode(
                        id: uuid(),
                        name: item.name,
                        filePath: item.url?.path,
                        language: language,
                        content: item.content
                    )
                    state.files.append(fileNode)
                    // Select the first loaded file if none is active
                    if state.activeFileID == nil {
                        state.activeFileID = fileNode.id
                    }
                }
                return .merge(
                    .send(.rebuildFileTree),
                    .send(.regeneratePrompt),
                    activeFileContextEffect(state: state),
                    highlightActiveFile(state: state)
                )

            case .pasteFileFromClipboard:
                return .run { [clipboardClient] send in
                    guard let text = await clipboardClient.readText(),
                          !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    await send(.filesLoaded([LoadedFile(content: text, name: "Untitled", url: nil)]))
                }

            // MARK: - Session Management

            // Implements: FR-crp-clear-session
            case .clearSessionRequested:
                guard !state.files.isEmpty else { return .none }
                // No comments to lose -> clear immediately, no confirmation dialog.
                // Implements: AC-crp-clear-no-confirm-empty
                guard state.hasComments else {
                    return performClearSession(state: &state)
                }
                state.alert = AlertState {
                    TextState("Clear Session")
                } actions: {
                    ButtonState(role: .destructive, action: .clearConfirmed) {
                        TextState("Clear")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("Remove all files and comments? This cannot be undone.")
                }
                return .none

            case let .removeFileRequested(fileID):
                let hasComments = state.allComments.contains(where: { $0.fileID == fileID })
                if hasComments {
                    state.alert = AlertState {
                        TextState("Remove File")
                    } actions: {
                        ButtonState(role: .destructive, action: .removeFileConfirmed(fileID)) {
                            TextState("Remove")
                        }
                        ButtonState(role: .cancel) {
                            TextState("Cancel")
                        }
                    } message: {
                        TextState("This file has comments. Remove it and its comments?")
                    }
                } else {
                    return removeFile(id: fileID, state: &state)
                }
                return .none

            case .toggleLineWrap:
                state.lineWrapEnabled.toggle()
                return .none

            // MARK: - Alert Actions

            case .alert(.presented(.clearConfirmed)):
                return performClearSession(state: &state)

            case let .alert(.presented(.removeFileConfirmed(fileID))):
                return removeFile(id: fileID, state: &state)

            case .alert(.dismiss):
                return .none

            // MARK: - Prompt Lifecycle

            case .copyPrompt:
                guard let prompt = state.prompt.generatedPrompt else { return .none }
                return .run { [clipboardClient] send in
                    await clipboardClient.copyText(prompt)
                    await send(.promptCopied)
                }

            // Implements: FR-crp-prompt-copy
            case .promptCopied:
                state.showCopyConfirmation = true
                return .run { [clock] send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.dismissCopyConfirmation)
                }
                .cancellable(id: CancelID.copyConfirmation, cancelInFlight: true)

            case .dismissCopyConfirmation:
                state.showCopyConfirmation = false
                return .none

            case .doneRequested:
                guard let prompt = state.prompt.generatedPrompt,
                      let sessionID = state.session.sessionID else { return .none }
                state.session.doneState = .sending
                return .run { [clipboardClient, sessionClient] send in
                    // Always copy to clipboard first as fallback
                    await clipboardClient.copyText(prompt)
                    do {
                        try await sessionClient.writePromptOutput(sessionID, prompt)
                        await send(.promptHandoffSucceeded)
                    } catch {
                        await send(.promptHandoffFailed(error.localizedDescription))
                    }
                }

            case .promptHandoffSucceeded:
                state.session.doneState = .sent
                return .run { [windowClient] _ in
                    await windowClient.closeWindow()
                }

            case .promptHandoffFailed:
                state.session.doneState = .idle
                // Prompt was already copied to clipboard as fallback
                return .none

            case .regeneratePrompt:
                return .run { [files = state.files, comments = state.allComments, overall = state.overallComment] send in
                    await send(.prompt(.regenerateRequested(
                        files: files,
                        comments: comments,
                        overallComment: overall
                    )))
                }
                .cancellable(id: CancelID.promptRegeneration, cancelInFlight: true)

            case .rebuildFileTree:
                let tree = FileTreeBuilder.buildFileTree(files: state.files)
                return .send(.fileBrowser(.fileTreeRebuilt(tree)))

            // MARK: - Window Lifecycle

            case .windowAppeared:
                return .run { [windowClient, sessionID = state.session.sessionID] _ in
                    await windowClient.configureAutosave(sessionID)
                }

            case .windowClosed:
                // Stop the relay subscription when the window goes away.
                return .cancel(id: CancelID.patchReplySubscription)

            // MARK: - Patch-thread reply live subscription (FR-sr-patch-replies-live)

            case .startPatchReplySubscription:
                guard state.reviewContextData?.patchMetadata != nil,
                      let patchID = state.reviewContextData?.patchMetadata?.eventID else {
                    return .none
                }
                return .run { [relayClient] send in
                    // Subscribe to kind:1 events whose root e tag is the patch id.
                    // The relay delivers stored replies first, then new ones live.
                    let filter = NostrFilter(eTag: patchID, kinds: [1])
                    let stream = relayClient.subscribe(filter)
                    for await event in stream {
                        if let reply = PatchReplyMapper.mapOne(event, patchEventID: patchID) {
                            await send(.patchRepliesRefreshedAppend(reply))
                        }
                    }
                }
                .cancellable(id: CancelID.patchReplySubscription, cancelInFlight: true)

            case let .patchRepliesRefreshedAppend(reply):
                // Incremental live append: merge a single incoming reply into the
                // existing ordered list, skipping dupes by id.
                guard var meta = state.reviewContextData?.patchMetadata else { return .none }
                if meta.replies.contains(where: { $0.id == reply.id }) { return .none }
                meta.replies.append(reply)
                meta.replies.sort { $0.timestamp < $1.timestamp }
                state.reviewContextData?.patchMetadata = meta
                return .none

            // MARK: - Child Feature Forwarding

            case let .fileBrowser(.fileSelected(fileID)):
                state.activeFileID = fileID
                // Update per-file review context for the newly-active file.
                return activeFileContextEffect(state: state)

            case let .fileBrowser(.toggleFileReviewed(fileID)):
                state.files[id: fileID]?.isReviewed.toggle()
                return .send(.rebuildFileTree)

            case let .fileBrowser(.removeFileRequested(fileID)):
                return .send(.removeFileRequested(fileID))

            case .fileBrowser:
                return .none

            case let .codeViewer(.openCommentEditor(anchorLine, endLine)):
                return .send(.comment(.openEditor(.creating(anchorLine: anchorLine, endLine: endLine))))

            case let .codeViewer(.scrolledToLine(line)):
                if let activeID = state.activeFileID {
                    state.files[id: activeID]?.scrollOffset = line
                }
                return .none

            case .codeViewer:
                return .none

            case let .comment(.editComment(commentID)):
                if let comment = state.allComments[id: commentID] {
                    state.comment.editorState = .editing(commentID: commentID)
                    state.comment.editorText = comment.text
                }
                return .none

            case let .comment(.deleteComment(commentID)):
                state.allComments.remove(id: commentID)
                return .merge(
                    .send(.regeneratePrompt),
                    .send(.rebuildFileTree)
                )

            case let .comment(.navigateComment(direction)):
                guard let activeFileID = state.activeFileID else { return .none }
                let fileComments = state.allComments
                    .filter { $0.fileID == activeFileID }
                    .sorted { $0.startLine < $1.startLine }
                guard !fileComments.isEmpty else { return .none }

                let currentID = state.comment.focusedCommentID
                let nextComment: Comment?
                switch direction {
                case .next:
                    if let current = currentID,
                       let idx = fileComments.firstIndex(where: { $0.id == current }),
                       idx + 1 < fileComments.count {
                        nextComment = fileComments[idx + 1]
                    } else {
                        nextComment = fileComments.first
                    }
                case .previous:
                    if let current = currentID,
                       let idx = fileComments.firstIndex(where: { $0.id == current }),
                       idx > 0 {
                        nextComment = fileComments[idx - 1]
                    } else {
                        nextComment = fileComments.last
                    }
                }
                if let next = nextComment {
                    state.comment.focusedCommentID = next.id
                    // Drive the viewer to scroll to and highlight the target line.
                    // Implements: FR-crp-comment-navigation
                    state.codeViewer.focusedLine = next.startLine
                }
                return .none

            case .comment:
                return .none

            case let .inspector(.commentSummaryCommentTapped(commentID)):
                // Navigate to the file containing this comment, then scroll to and
                // highlight its line. Implements: FR-crp-comment-navigation
                if let comment = state.allComments[id: commentID] {
                    state.activeFileID = comment.fileID
                    state.comment.focusedCommentID = commentID
                    state.codeViewer.focusedLine = comment.startLine
                }
                return .none

            case .inspector:
                return .none

            case .prompt:
                return .none

            case let .session(.sessionDataLoaded(data)):
                // Load files from session
                var loadedFiles: [LoadedFile] = []
                for sessionFile in data.files {
                    let name = (sessionFile.path as NSString).lastPathComponent
                    loadedFiles.append(LoadedFile(content: sessionFile.content, name: name, url: URL(fileURLWithPath: sessionFile.path)))
                }
                // Store review context
                state.reviewContextData = data.reviewContext
                if !loadedFiles.isEmpty {
                    return .merge(
                        .send(.filesLoaded(loadedFiles)),
                        // Begin live relay subscription for patch reviews.
                        // Implements: FR-sr-patch-replies-live (in-app RelayClient).
                        data.reviewContext?.patchMetadata != nil
                            ? .send(.startPatchReplySubscription) : .none
                    )
                }
                return data.reviewContext?.patchMetadata != nil
                    ? .send(.startPatchReplySubscription) : .none

            case .session:
                return .none

            case .reviewContext:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - Helpers

    /// Reset the session to the initial empty state: drop all files, comments, the
    /// overall comment, and every child feature's state. Shared by the confirmed-clear
    /// alert path and the no-confirmation-when-empty short-circuit.
    /// Implements: FR-crp-clear-session
    private func performClearSession(state: inout State) -> Effect<Action> {
        state.files = []
        state.allComments = []
        state.activeFileID = nil
        state.overallComment = ""
        state.codeViewer = CodeViewerFeature.State()
        state.comment = CommentFeature.State()
        state.fileBrowser = FileBrowserFeature.State()
        return .merge(
            .send(.rebuildFileTree),
            .send(.regeneratePrompt)
        )
    }

    /// Build a native alert describing files that failed to load. One failure uses the
    /// design's exact per-reason wording; multiple failures are listed in one alert.
    /// Returns nil when nothing failed. Implements: AC-crp-binary-file-rejected, AC-crp-macos-file-permission-error
    private func fileErrorAlert(for results: [FileReadResult]) -> AlertState<Action.Alert>? {
        let failures: [(name: String, reason: FileLoadFailureReason)] = results.compactMap {
            guard case let .failed(name, reason) = $0 else { return nil }
            return (name, reason)
        }
        guard !failures.isEmpty else { return nil }

        if failures.count == 1 {
            let reason = failures[0].reason
            return AlertState {
                TextState(reason.alertTitle)
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState(reason.alertMessage)
            }
        }

        let list = failures.map { "• \($0.name): \($0.reason.shortLabel)" }.joined(separator: "\n")
        return AlertState {
            TextState("Some Files Couldn't Be Opened")
        } actions: {
            ButtonState(role: .cancel) { TextState("OK") }
        } message: {
            TextState(list)
        }
    }

    private func removeFile(id: FileNode.ID, state: inout State) -> Effect<Action> {
        state.files.remove(id: id)
        state.allComments = IdentifiedArrayOf(uniqueElements: state.allComments.filter { $0.fileID != id })

        // Update active file
        if state.activeFileID == id {
            state.activeFileID = state.files.first?.id
        }

        return .merge(
            .send(.rebuildFileTree),
            .send(.regeneratePrompt)
        )
    }

    /// Push the currently-active file's per-file review context to the ReviewContext
    /// feature. Used both when a file is selected and when files first load, so the
    /// context panel appears for the initially-active file — not only after the user
    /// switches files. Resolves to `nil` (panel hidden) when there is no context for
    /// the active file or no active file.
    /// Implements: FR-crp-review-context-per-file
    private func activeFileContextEffect(state: State) -> Effect<Action> {
        let context = state.activeFile?.filePath.flatMap { state.reviewContextData?.files[$0] }
        return .send(.reviewContext(.activeFileContextUpdated(context)))
    }

    private func highlightActiveFile(state: State) -> Effect<Action> {
        guard let activeFile = state.activeFile else { return .none }
        return .run { [syntaxHighlighter, content = activeFile.content, language = activeFile.language] send in
            let tokens = await syntaxHighlighter.highlight(content, language)
            await send(.codeViewer(.syntaxHighlightingCompleted(tokens)))
        }
    }

    /// Create a comment from the current editor state.
    /// Called from AppView after the comment editor submits.
    public static func createComment(
        from editorState: EditorState,
        text: String,
        activeFileID: FileNode.ID,
        uuid: UUID
    ) -> Comment? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        switch editorState {
        case let .creating(anchorLine, endLine):
            return Comment(
                id: uuid,
                fileID: activeFileID,
                startLine: min(anchorLine, endLine),
                endLine: max(anchorLine, endLine),
                text: trimmed
            )
        case .editing:
            return nil // Editing updates existing comment
        }
    }
}
