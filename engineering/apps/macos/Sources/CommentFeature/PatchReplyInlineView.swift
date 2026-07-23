import SwiftUI
import SharedModels

/// Read-only inline bubble for an anchored patch-thread reply, rendered on the diff
/// alongside the user's own editable Comment bubbles. Implements: FR-sr-patch-replies-display.
///
/// Visually distinct from CommentBubbleView: bot/agent replies use a purple tint +
/// cpu glyph; human replies use an orange tint + person glyph. No edit/delete chrome.
public struct PatchReplyInlineView: View {
    let reply: ReviewContext.PatchReply
    /// The reviewer's loaded pubkey (hex) for the `YOU` self-marker.
    let reviewerPubkey: String?
    /// Invoked when the reviewer taps the inline Reply button.
    // Implements: FR-srm-reply-to-reply
    let onReply: (ReviewContext.PatchReply) -> Void

    public init(
        reply: ReviewContext.PatchReply,
        reviewerPubkey: String? = nil,
        onReply: @escaping (ReviewContext.PatchReply) -> Void = { _ in }
    ) {
        self.reply = reply
        self.reviewerPubkey = reviewerPubkey
        self.onReply = onReply
    }

    private var isSelf: Bool {
        reviewerPubkey != nil && reply.authorPubkey == reviewerPubkey
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: reply.isBot ? "cpu" : "person.fill")
                .font(.caption)
                .foregroundStyle(reply.isBot ? Color.purple : Color.orange)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(reply.author)
                        .font(.caption2)
                        .fontWeight(.semibold)
                    if reply.isBot {
                        Text("BOT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple.opacity(0.12), in: Capsule())
                    }
                    if isSelf {
                        Text("YOU")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.12), in: Capsule())
                    }
                    Spacer()
                    Button("Reply") { onReply(reply) }
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                }
                Text(reply.content)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelf
                      ? Color.green.opacity(0.10)
                      : (reply.isBot ? Color.purple : Color.orange).opacity(0.08))
        )
    }
}
