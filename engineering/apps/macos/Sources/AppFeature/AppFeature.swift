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
        @Shared public var files: IdentifiedArrayOf<FileNode>
        @Shared public var allComments: IdentifiedArrayOf<Comment>
        public var activeFileID: FileNode.ID?
        public var overallComment: String = ""
        public var lineWrapEnabled: Bool = true
        public var reviewContextData: ReviewContext?

        // Navigation / alerts
        @Presents public var alert: AlertState<Action.Alert>?

        // Derived
        public var isMultiFile: Bool { files.count >= 2 }
        public var hasComments: Bool { !allComments.isEmpty }
        public var activeFile: FileNode? { activeFileID.flatMap { files[id: $0] } }
        public var commentCount: Int { allComments.count }
        public var generatedPrompt: String? { prompt.generatedPrompt }

        public init(
            session: SessionFeature.State = SessionFeature.State(),
            codeViewer: CodeViewerFeature.State = CodeViewerFeature.State(),
            comment: CommentFeature.State = CommentFeature.State(),
            prompt: PromptFeature.State = PromptFeature.State(),
            reviewContext: ReviewContextFeature.State = ReviewContextFeature.State(),
            files: Shared<IdentifiedArrayOf<FileNode>> = Shared(value: []),
            allComments: Shared<IdentifiedArrayOf<Comment>> = Shared(value: []),
            activeFileID: FileNode.ID? = nil,
            overallComment: String = "",
            lineWrapEnabled: Bool = true,
            reviewContextData: ReviewContext? = nil
        ) {
            self._files = files
            self._allComments = allComments
            self.session = session
            // fileBrowser and inspector read files/allComments via @Shared — construct them
            // with the same shared storage so no explicit view-param threading is needed.
            self.fileBrowser = FileBrowserFeature.State(files: files, allComments: allComments)
            self.codeViewer = codeViewer
            self.comment = comment
            self.inspector = InspectorFeature.State(files: files, allComments: allComments)
            self.prompt = prompt
            self.reviewContext = reviewContext
            self.activeFileID = activeFileID
            self.overallComment = overallComment
            self.lineWrapEnabled = lineWrapEnabled
            self.reviewContextData = reviewContextData
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
        case filesLoaded([LoadedFile])
        case pasteFileFromClipboard

        // Session management
        case clearSessionRequested
        case removeFileRequested(FileNode.ID)
        case toggleLineWrap

        // Prompt lifecycle
        case copyPrompt
        case promptCopied
        case doneRequested
        case promptHandoffSucceeded
        case promptHandoffFailed(String)

        // Internal
        case regeneratePrompt
        case rebuildFileTree

        // Window lifecycle
        case windowAppeared
        case windowClosed

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
    @Dependency(\.uuid) var uuid

    private enum CancelID {
        case promptRegeneration
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
                state.$allComments.withLock {
                    _ = $0.append(
                        Comment(
                            id: uuid(),
                            fileID: fileID,
                            startLine: start,
                            endLine: end,
                            text: trimmed
                        )
                    )
                }
            case let .editing(commentID):
                state.$allComments.withLock { $0[id: commentID]?.text = trimmed }
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
                    let mapped = results.map { LoadedFile(content: $0.content, name: $0.name, url: $0.url) }
                    await send(.filesLoaded(mapped))
                } catch: { _, _ in
                    // Silently ignore file load errors for drag-and-drop
                }

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
                    state.$files.withLock { _ = $0.append(fileNode) }
                    // Select the first loaded file if none is active
                    if state.activeFileID == nil {
                        state.activeFileID = fileNode.id
                    }
                }
                return .merge(
                    .send(.rebuildFileTree),
                    .send(.regeneratePrompt),
                    highlightActiveFile(state: state)
                )

            case .pasteFileFromClipboard:
                return .run { [clipboardClient] send in
                    guard let text = await clipboardClient.readText(),
                          !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    await send(.filesLoaded([LoadedFile(content: text, name: "Untitled", url: nil)]))
                }

            // MARK: - Session Management

            case .clearSessionRequested:
                guard !state.files.isEmpty else { return .none }
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
                state.$files.withLock { $0 = [] }
                state.$allComments.withLock { $0 = [] }
                state.activeFileID = nil
                state.overallComment = ""
                state.codeViewer = CodeViewerFeature.State()
                state.comment = CommentFeature.State()
                state.fileBrowser = FileBrowserFeature.State()
                return .merge(
                    .send(.rebuildFileTree),
                    .send(.regeneratePrompt)
                )

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

            case .promptCopied:
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
                return .none

            // MARK: - Child Feature Forwarding

            case let .fileBrowser(.fileSelected(fileID)):
                state.activeFileID = fileID
                // Update per-file review context
                if let filePath = state.files[id: fileID]?.filePath {
                    let context = state.reviewContextData?.files[filePath]
                    return .send(.reviewContext(.activeFileContextUpdated(context)))
                }
                return .send(.reviewContext(.activeFileContextUpdated(nil)))

            case let .fileBrowser(.toggleFileReviewed(fileID)):
                state.$files.withLock { $0[id: fileID]?.isReviewed.toggle() }
                return .send(.rebuildFileTree)

            case let .fileBrowser(.removeFileRequested(fileID)):
                return .send(.removeFileRequested(fileID))

            case .fileBrowser:
                return .none

            case let .codeViewer(.openCommentEditor(anchorLine, endLine)):
                return .send(.comment(.openEditor(.creating(anchorLine: anchorLine, endLine: endLine))))

            case let .codeViewer(.scrolledToLine(line)):
                if let activeID = state.activeFileID {
                    state.$files.withLock { $0[id: activeID]?.scrollOffset = line }
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
                state.$allComments.withLock { _ = $0.remove(id: commentID) }
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
                }
                return .none

            case .comment:
                return .none

            case let .inspector(.commentSummaryCommentTapped(commentID)):
                // Navigate to the file containing this comment
                if let comment = state.allComments[id: commentID] {
                    state.activeFileID = comment.fileID
                    state.comment.focusedCommentID = commentID
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
                    return .send(.filesLoaded(loadedFiles))
                }
                return .none

            case .session:
                return .none

            case .reviewContext:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - Helpers

    private func removeFile(id: FileNode.ID, state: inout State) -> Effect<Action> {
        state.$files.withLock { _ = $0.remove(id: id) }
        state.$allComments.withLock { $0 = IdentifiedArrayOf(uniqueElements: $0.filter { $0.fileID != id }) }

        // Update active file
        if state.activeFileID == id {
            state.activeFileID = state.files.first?.id
        }

        return .merge(
            .send(.rebuildFileTree),
            .send(.regeneratePrompt)
        )
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
