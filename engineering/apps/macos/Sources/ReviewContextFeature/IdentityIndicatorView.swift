import SwiftUI
import SharedModels

/// Surfaces the active reviewer Nostr identity in the inspector so the reviewer
/// knows which identity their published patch-thread replies will be attributed
/// to. 
// Implements: FR-srm-identity-indicator, FR-sr-reviewer-identity
///
/// Present only for patch reviews. Loaded state shows a key glyph + display name
/// (full npub in the tooltip/accessibility label); no-identity state shows a
/// warning that replies will not publish, plus the config hint. A transient
/// "Reply published to patch thread" confirmation renders here on success.
public struct IdentityIndicatorView: View {
    let identity: ReviewerIdentity?
    let showPublishConfirmation: Bool

    public init(identity: ReviewerIdentity?, showPublishConfirmation: Bool = false) {
        self.identity = identity
        self.showPublishConfirmation = showPublishConfirmation
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let identity {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(identity.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Reviewer identity \(identity.npub)")
                .help(identity.npub)
            } else {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No identity — replies won't publish")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text("Set SHEPHERD_NSEC or ~/.config/nostr/identity")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            }

            if showPublishConfirmation {
                Text("Reply published to patch thread")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
        .padding(12)
        .background(Color(nsColor: .quaternaryLabelColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.15), value: showPublishConfirmation)
    }
}
