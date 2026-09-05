import SwiftUI
import ComposableArchitecture
import SharedModels

/// Sheet for submitting a review verdict (approve / request changes).
/// Shows an optional markdown summary, the read-only tip commit the verdict
/// binds to, and Submit. Implements: FR-pa-review, AC-pa-approval-tip.
public struct VerdictSheetView: View {
    let store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.verdictSheet?.verdict == "approval" ? "Approve PR" : "Request changes")
                .font(.headline)

            if let tip = store.reviewContextData?.patchMetadata?.tipCommitFull {
                // Read-only tip commit the verdict will bind to (AC-pa-approval-tip).
                HStack(spacing: 6) {
                    Text("Tip commit").font(.system(size: 11)).foregroundStyle(.secondary)
                    Text(tip).font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                }
            }

            TextEditor(text: Binding(
                get: { store.verdictSheet?.summary ?? "" },
                set: { store.send(.verdictSummaryChanged($0)) }
            ))
            .frame(minHeight: 80)
            .overlay(alignment: .topLeading) {
                if store.verdictSheet?.summary.isEmpty != false {
                    Text("Summary (optional markdown)")
                        .font(.system(size: 11)).foregroundStyle(.tertiary)
                        .padding(.top, 8).padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }
            .font(.system(size: 12))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if store.verdictFailed {
                Text("Publish failed — no relay accepted it. Retry or cancel.")
                    .font(.system(size: 11)).foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { store.send(.dismissVerdictSheet) }
                    .keyboardShortcut(.cancelAction)
                Button("Submit") { store.send(.submitVerdict) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(store.verdictSheet?.isSubmitting == true)
                if store.verdictSheet?.isSubmitting == true {
                    ProgressView().controlSize(.small)
                }
            }
        }
        .padding(16)
        .frame(width: 380)
    }
}
