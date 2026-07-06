import SwiftUI

/// Read-only prompt preview, monospaced
public struct PromptPreviewView: View {
    let prompt: String?

    public init(prompt: String?) {
        self.prompt = prompt
    }

    public var body: some View {
        ScrollView {
            if let prompt {
                Text(prompt)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "text.document")
                        .font(.title2)
                        .foregroundStyle(.quaternary)
                    Text("Add comments to generate a prompt")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)
            }
        }
    }
}
