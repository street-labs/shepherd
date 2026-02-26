import ComposableArchitecture
import SharedModels
import ShepherdDependencies

/// Implements: FR-crp-file-display, FR-crp-syntax-highlight, FR-crp-comment-indicator,
/// FR-crp-line-wrap, FR-crp-line-range-comment, NFR-crp-large-file-perf
@Reducer
public struct CodeViewerFeature {
    @ObservableState
    public struct State: Equatable {
        /// Syntax tokens for the active file (produced by SyntaxHighlightClient).
        public var syntaxTokens: [SyntaxToken] = []
        /// The currently focused line (keyboard navigation).
        public var focusedLine: Int?
        /// The currently selected line range for range-commenting.
        public var selectedRange: ClosedRange<Int>?
        /// Whether a large file warning banner is visible.
        public var showLargeFileWarning: Bool = false

        public init(
            syntaxTokens: [SyntaxToken] = [],
            focusedLine: Int? = nil,
            selectedRange: ClosedRange<Int>? = nil,
            showLargeFileWarning: Bool = false
        ) {
            self.syntaxTokens = syntaxTokens
            self.focusedLine = focusedLine
            self.selectedRange = selectedRange
            self.showLargeFileWarning = showLargeFileWarning
        }
    }

    @CasePathable
    public enum Action: Equatable {
        case lineClicked(Int)
        case lineRangeSelected(ClosedRange<Int>)
        case scrolledToLine(Int)
        case focusedLineChanged(Int?)
        case syntaxHighlightingCompleted([SyntaxToken])
        case largeBannerDismissed
        case openCommentEditor(anchorLine: Int, endLine: Int)
    }

    @Dependency(\.syntaxHighlightClient) var syntaxHighlighter

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .lineClicked(line):
                state.selectedRange = nil
                return .send(.openCommentEditor(anchorLine: line, endLine: line))

            case let .lineRangeSelected(range):
                state.selectedRange = range
                return .none

            case .scrolledToLine:
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
                // Handled by parent (AppFeature routes to CommentFeature)
                return .none
            }
        }
    }
}
