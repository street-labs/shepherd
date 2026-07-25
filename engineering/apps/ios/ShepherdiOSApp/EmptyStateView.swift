import SwiftUI
import ComposableArchitecture
import AppFeature

/// Empty state for the iOS app. Leads with "Open Patch" — local file loading is not
/// offered on iOS (content arrives via an in-app opened NIP-34 patch).
// Implements: FR-crp-ios-patch-only-entry, FR-sri-patch-open-entry, AC-crp-empty-state
struct EmptyStateView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "patch.text")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Review a patch")
                    .font(.title2.bold())
                Text("Open a NIP-34 patch to review and comment")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                store.send(.openPatchRequested)
            } label: {
                Label("Open Patch", systemImage: "square.and.pencil")
                    .frame(maxWidth: 220)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Open Patch")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
