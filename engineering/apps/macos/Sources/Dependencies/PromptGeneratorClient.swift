import ComposableArchitecture
import IdentifiedCollections
import SharedModels

/// Pure prompt generation.
/// Implements: FR-crp-prompt-generate, FR-crp-prompt-format,
/// FR-crp-multi-file-prompt-format, NFR-crp-prompt-gen-time
public struct PromptGeneratorClient: Sendable {
    /// Generate the structured prompt from files, comments, and the overall comment.
    public var generate: @Sendable (IdentifiedArrayOf<FileNode>, IdentifiedArrayOf<Comment>, String) async -> String?

    public init(
        generate: @escaping @Sendable (IdentifiedArrayOf<FileNode>, IdentifiedArrayOf<Comment>, String) async -> String?
    ) {
        self.generate = generate
    }
}

extension PromptGeneratorClient: DependencyKey {
    public static let liveValue = PromptGeneratorClient(
        generate: { files, comments, overallComment in
            PromptBuilder.build(files: files, comments: comments, overallComment: overallComment)
        }
    )

    public static let testValue = PromptGeneratorClient(
        generate: unimplemented("PromptGeneratorClient.generate")
    )
}

extension DependencyValues {
    public var promptGenerator: PromptGeneratorClient {
        get { self[PromptGeneratorClient.self] }
        set { self[PromptGeneratorClient.self] = newValue }
    }
}
