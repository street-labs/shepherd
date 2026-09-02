import SwiftUI
import SharedModels

/// NIP-34 patch metadata display for Nostr patch reviews.
/// Implements: FR-sr-patch-metadata-display
public struct PatchMetadataSectionView: View {
    let metadata: ReviewContext.PatchMetadata
    /// Approval state for the Approve row (nil = not yet tapped). Implements
    /// FR-srm-pr-approve / FR-sri-pr-approve (display half).
    let approvalState: AppFeatureApprovalState?
    /// Reviewer identity present → Approve is enabled.
    let canApprove: Bool
    let onApprove: () -> Void

    /// View-agnostic approval state mirror (ReviewContextFeature must not
    /// depend on AppFeature).
    public enum AppFeatureApprovalState: Equatable, Sendable {
        case publishing, approved, failed(String)
    }

    public init(
        metadata: ReviewContext.PatchMetadata,
        approvalState: AppFeatureApprovalState? = nil,
        canApprove: Bool = false,
        onApprove: @escaping () -> Void = {}
    ) {
        self.metadata = metadata
        self.approvalState = approvalState
        self.canApprove = canApprove
        self.onApprove = onApprove
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Patch ID
            HStack(alignment: .top, spacing: 8) {
                Text("Patch ID")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)

                HStack(spacing: 6) {
                    Text(metadata.shortEventID)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)

                    Button(action: {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(metadata.eventID, forType: .string)
                        #elseif os(iOS)
                        UIPasteboard.general.string = metadata.eventID
                        #endif
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .help("Copy full event ID")
                }
            }

            // Author
            HStack(alignment: .top, spacing: 8) {
                Text("Author")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)

                Text(metadata.author)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
            }

            // Commit Message
            HStack(alignment: .top, spacing: 8) {
                Text("Message")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)

                Text(metadata.commitMessage.isEmpty ? "(no message)" : metadata.commitMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(metadata.commitMessage.isEmpty ? .tertiary : .primary)
                    .textSelection(.enabled)
            }

            // Parent Commit / Merge Base (PR uses the merge-base tag as parent)
            HStack(alignment: .top, spacing: 8) {
                Text("Parent")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)

                if let parent = metadata.parentCommit {
                    Text(parent)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                } else {
                    Text("(none)")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
            }

            // Tip Commit (PR only) — Implements: FR-sr-pr-metadata-display
            // Implements: FR-sr-pr-metadata-display
            if let tip = metadata.tipCommit {
                HStack(alignment: .top, spacing: 8) {
                    Text("Tip")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    Text(tip)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            // Branch Name (PR only, when present) — Implements: FR-sr-pr-metadata-display
            // Implements: FR-sr-pr-metadata-display
            if let branch = metadata.branchName {
                HStack(alignment: .top, spacing: 8) {
                    Text("Branch")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    Text(branch)
                        .font(.system(size: 13, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            // Status
            HStack(alignment: .top, spacing: 8) {
                Text("Status")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)

                StatusBadge(status: metadata.status)
            }

            // Approve (PR/patch reviews with an identity). Publishes a signed
            // kind-1 approval event the merge pipeline watches for.
            // Implements: FR-srm-pr-approve, FR-sri-pr-approve.
            HStack(alignment: .center, spacing: 8) {
                Text("Review")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)
                switch approvalState {
                case .approved:
                    Label("Approved", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.green)
                case .publishing:
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Publishing approval…").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                case .failed(let msg):
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Approval failed", systemImage: "exclamationmark.triangle")
                            .font(.system(size: 12)).foregroundStyle(.red)
                        Text(msg).font(.system(size: 10)).foregroundStyle(.secondary)
                        Button("Retry", action: onApprove).font(.system(size: 12))
                    }
                case nil:
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.seal")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!canApprove)
                    .help(canApprove ? "Publish a signed approval to the patch thread" : "Load an identity to approve")
                }
            }
        }
        .padding(12)
        .background(Color.quaternaryLabelFill.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .padding(.bottom, 16)
    }
}

/// Color-coded status badge for NIP-34 patch status.
private struct StatusBadge: View {
    let status: String

    private var backgroundColor: Color {
        switch status.lowercased() {
        case "open": return Color.blue.opacity(0.15)
        case "merged": return Color.green.opacity(0.15)
        case "closed": return Color.red.opacity(0.15)
        case "draft": return Color.gray.opacity(0.15)
        default: return Color.gray.opacity(0.15)
        }
    }

    private var textColor: Color {
        switch status.lowercased() {
        case "open": return .blue
        case "merged": return .green
        case "closed": return .red
        case "draft": return .gray
        default: return .gray
        }
    }

    var body: some View {
        Text(status.uppercased())
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
