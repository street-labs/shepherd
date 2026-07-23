import SwiftUI
import SharedModels

/// Read-only inline bubble for an anchored patch-thread reply, rendered on the diff
/// alongside the user's own editable Comment bubbles. Implements: FR-sr-patch-replies-display.
///
/// Visually distinct from CommentBubbleView: bot/agent replies use a purple tint +
/// cpu glyph; human replies use an orange tint + person glyph. No edit/delete chrome.
public struct PatchReplyInlineView: View {
    let reply: ReviewContext.PatchReply

    public init(reply: ReviewContext.PatchReply) {
        self.reply = reply
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
                .fill((reply.isBot ? Color.purple : Color.orange).opacity(0.08))
        )
    }
}
