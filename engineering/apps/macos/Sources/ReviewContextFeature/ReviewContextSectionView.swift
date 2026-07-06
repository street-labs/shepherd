import SwiftUI
import SharedModels

/// Overall context in inspector sidebar (collapsible)
public struct ReviewContextSectionView: View {
    let context: ReviewContext.ContextPair
    let isCollapsed: Bool
    let onExpandedChange: (Bool) -> Void

    public init(context: ReviewContext.ContextPair, isCollapsed: Bool, onExpandedChange: @escaping (Bool) -> Void) {
        self.context = context
        self.isCollapsed = isCollapsed
        self.onExpandedChange = onExpandedChange
    }

    public var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { !isCollapsed },
                set: { onExpandedChange($0) }
            )
        ) {
            VStack(alignment: .leading, spacing: 8) {
                if !context.neutral.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Changeset Summary")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text(context.neutral)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }

                if !context.review.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Agent Review")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text(context.review)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(.bottom, 4)
        } label: {
            Label("Review Context", systemImage: "doc.text.magnifyingglass")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(8)
    }
}
