import ComposableArchitecture
import SharedModels
import ShepherdDependencies
import IdentifiedCollections

/// Implements: FR-crp-prompt-generate, FR-crp-prompt-format, FR-crp-multi-file-prompt,
/// FR-crp-multi-file-prompt-format, NFR-crp-prompt-gen-time
@Reducer
public struct PromptFeature {
    @ObservableState
    public struct State: Equatable {
        public var generatedPrompt: String?
        public var isGenerating: Bool = false

        public init(
            generatedPrompt: String? = nil,
            isGenerating: Bool = false
        ) {
            self.generatedPrompt = generatedPrompt
            self.isGenerating = isGenerating
        }
    }

    @CasePathable
    public enum Action: Equatable {
        case regenerateRequested(
            files: IdentifiedArrayOf<FileNode>,
            comments: IdentifiedArrayOf<Comment>,
            overallComment: String
        )
        case promptGenerated(String?)
    }

    @Dependency(\.promptGenerator) var promptGenerator

    public init() {}

    public var body: some ReducerOf<Self> {
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
