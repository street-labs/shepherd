import SwiftUI
import ComposableArchitecture
import SharedModels

/// Per-file context (neutral + review feedback) shown above the code viewer
public struct ReviewContextPanelView: View {
    let store: StoreOf<ReviewContextFeature>

    public init(store: StoreOf<ReviewContextFeature>) {
        self.store = store
    }

    public var body: some View {
        if let context = store.activeFileContext {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { !store.isCollapsed },
                    set: { store.send(.expandedChanged($0)) }
                )
            ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if !context.neutral.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("What Changed")
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
                                Text("Review Feedback")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Text(context.review)
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
                }
                .frame(maxHeight: 200)
            } label: {
                Label("File Context", systemImage: "info.circle")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.bar)
            Divider()
        }
    }
}
