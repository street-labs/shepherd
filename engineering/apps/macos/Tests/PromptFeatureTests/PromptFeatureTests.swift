import Testing
import ComposableArchitecture
import Foundation
import IdentifiedCollections
@testable import PromptFeature
@testable import SharedModels
@testable import ShepherdDependencies

@Suite("PromptFeature")
@MainActor
struct PromptFeatureTests {
    @Test("Regenerate triggers prompt generation")
    func regenerateRequested() async {
        let fileID = UUID()
        let file = FileNode(id: fileID, name: "test.ts", language: .typescript, content: "const x = 1;")
        let comment = Comment(fileID: fileID, startLine: 1, endLine: 1, text: "Fix this")

        let store = TestStore(initialState: PromptFeature.State()) {
            PromptFeature()
        } withDependencies: {
            $0.promptGenerator.generate = { @Sendable _, _, _ in "generated prompt" }
        }

        await store.send(.regenerateRequested(
            files: [file],
            comments: [comment],
            overallComment: ""
        )) {
            $0.isGenerating = true
        }

        await store.receive(\.promptGenerated) {
            $0.generatedPrompt = "generated prompt"
            $0.isGenerating = false
        }
    }

    @Test("Prompt generated with nil clears prompt")
    func promptGeneratedNil() async {
        let store = TestStore(initialState: PromptFeature.State(
            generatedPrompt: "old prompt",
            isGenerating: true
        )) {
            PromptFeature()
        }

        await store.send(.promptGenerated(nil)) {
            $0.generatedPrompt = nil
            $0.isGenerating = false
        }
    }
}
