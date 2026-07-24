import SwiftUI
import SharedModels

/// Surfaces the active reviewer Nostr identity in the inspector so the reviewer
/// knows which identity their published patch-thread replies will be attributed
/// to.
// Implements: FR-srm-identity-indicator, FR-sr-reviewer-identity
///
/// Present only for patch reviews. Local-key state shows a key glyph + display
/// name (full npub in the tooltip/accessibility label). Bunker state shows a
/// shield glyph + `BUNKER` badge + a status dot (connected/connecting/failed).
/// No-identity state shows a warning that replies will not publish, plus the
/// config hint. A transient "Reply published to patch thread" confirmation
/// renders here on success.
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
                identityContent(identity)
            } else {
                noIdentityContent
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

    @ViewBuilder
    private func identityContent(_ identity: ReviewerIdentity) -> some View {
        switch identity.source {
        case .localKey:
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
        case .bunker:
            bunkerContent(identity)
        }
    }

    @ViewBuilder
    private func bunkerContent(_ identity: ReviewerIdentity) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(identity.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text("BUNKER")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
            if let state = identity.bunkerState {
                bunkerStateRow(state, relayURL: identity.bunkerRelayURL)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bunkerAccessibilityLabel(identity))
    }

    @ViewBuilder
    private func bunkerStateRow(_ state: BunkerConnectionState, relayURL: String?) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor(state))
                .frame(width: 6, height: 6)
            Text(statusText(state, relayURL: relayURL))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
    }

    private func statusColor(_ state: BunkerConnectionState) -> Color {
        switch state {
        case .connected: .green
        case .connecting: .orange
        case .failed: .red
        }
    }

    private func statusText(_ state: BunkerConnectionState, relayURL: String?) -> String {
        switch state {
        case .connected: "Connected"
        case .connecting: "Connecting…"
        case .failed(let cause): cause
        }
    }

    private func bunkerAccessibilityLabel(_ identity: ReviewerIdentity) -> String {
        let npub = identity.npub.isEmpty ? "unknown" : identity.npub
        let relay = identity.bunkerRelayURL ?? ""
        return "Reviewer identity \(npub), bunker on \(relay)"
    }

    private var noIdentityContent: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("No identity — replies won't publish")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("Set SHEPHERD_BUNKER / ~/.config/nostr/bunker, or SHEPHERD_NSEC / ~/.config/nostr/identity")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }
}
