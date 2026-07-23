import SwiftUI
import SharedModels

/// Renders other agents' and humans' replies on the patch review thread as a
/// distinct section in the inspector. Implements: FR-sr-patch-replies-display.
///
/// Replies with a line anchor are also surfaced inline on the diff (see
/// CodeViewerView); this section lists every reply regardless of anchoring so
/// the whole conversation is visible in one place. Bot/agent replies carry a
/// distinct visual marker from human comments.
public struct PatchRepliesSectionView: View {
    let replies: [ReviewContext.PatchReply]

    public init(replies: [ReviewContext.PatchReply]) {
        self.replies = replies
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 11))
                Text("Patch Thread (\(replies.count))")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)

            if replies.isEmpty {
                Text("No replies yet on this patch.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(replies) { reply in
                        PatchReplyRow(reply: reply)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .quaternaryLabelColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .padding(.bottom, 16)
    }
}

/// A single reply row. Bot/agent authors get a robot badge + accent tint; humans
/// get a person badge + neutral tint. Anchored replies show a file:line chip.
private struct PatchReplyRow: View {
    let reply: ReviewContext.PatchReply

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: reply.isBot ? "cpu" : "person.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(reply.isBot ? Color.purple : Color.orange)
                Text(reply.author)
                    .font(.system(size: 11, weight: .medium))
                if reply.isBot {
                    Text("BOT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.12), in: Capsule())
                }
                Spacer()
                Text(timestampLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Text(reply.content)
                .font(.system(size: 12))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let anchor = reply.lineAnchor {
                HStack(spacing: 3) {
                    Image(systemName: "link")
                        .font(.system(size: 8))
                    Text(anchorLabel(anchor))
                        .font(.system(size: 9, design: .monospaced))
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((reply.isBot ? Color.purple : Color.orange).opacity(0.08))
        )
    }

    private var timestampLabel: String {
        let date = Date(timeIntervalSince1970: TimeInterval(reply.timestamp))
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func anchorLabel(_ anchor: ReviewContext.PatchReply.LineAnchor) -> String {
        let name = (anchor.filePath as NSString).lastPathComponent
        return anchor.startLine == anchor.endLine
            ? "\(name):\(anchor.startLine)"
            : "\(name):\(anchor.startLine)-\(anchor.endLine)"
    }
}
