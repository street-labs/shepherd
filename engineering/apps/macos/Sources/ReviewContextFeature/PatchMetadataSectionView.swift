import SwiftUI
import SharedModels
import AppKit

/// NIP-34 patch metadata display for Nostr patch reviews.
/// Implements: FR-sr-patch-metadata-display
public struct PatchMetadataSectionView: View {
    let metadata: ReviewContext.PatchMetadata

    public init(metadata: ReviewContext.PatchMetadata) {
        self.metadata = metadata
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
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(metadata.eventID, forType: .string)
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

            // Parent Commit
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

            // Status
            HStack(alignment: .top, spacing: 8) {
                Text("Status")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)

                StatusBadge(status: metadata.status)
            }
        }
        .padding(12)
        .background(Color(nsColor: .quaternaryLabelColor).opacity(0.3))
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
