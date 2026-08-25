import SwiftUI
import ComposableArchitecture

/// The Open Patch sheet. Implements the dialog surface in
/// `design/macos/shepherd-review.md` → In-App Patch Open (FR-srm-patch-open-input,
/// FR-srm-patch-open-fetch). The empty-state entry button + `Cmd+Shift+P` shortcut
/// live in `FileDropZoneView` (FR-srm-patch-open-entry); AppFeature presents this
/// view as a sheet.
public struct OpenPatchView: View {
    @Bindable public var store: StoreOf<OpenPatchFeature>

    public init(store: StoreOf<OpenPatchFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)

                Text("Open Patch or PR")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("Fetch a NIP-34 patch or pull request from a Nostr relay")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                TextField(
                    "Paste an event id, nevent1…, or link (patch or PR)",
                    text: $store.input
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .disableAutocorrection(true)
                .disabled(isFetching)
                .onSubmit { store.send(.fetchButtonTapped) }

                Text("Tip: paste a nevent1 address, the raw event id in hex, or a link containing either.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            statusLine
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(statusPadding)
                .background(statusBackground)
                .foregroundStyle(statusColor)

            HStack {
                Button("Cancel") { store.send(.cancelTapped) }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if isFetching {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Fetch") { store.send(.fetchButtonTapped) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(fetchDisabled)
            }
        }
        .padding(20)
        .frame(minWidth: 440)
    }

    private var isFetching: Bool {
        store.status == .fetching
    }

    private var fetchDisabled: Bool {
        store.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFetching
    }

    @ViewBuilder
    private var statusLine: some View {
        switch store.status {
        case .idle:
            EmptyView()
        case .invalidInput:
            Label("Enter an event id, nevent1 address, or a link containing one", systemImage: "exclamationmark.triangle")
        case .fetching:
            Label("Fetching event from relays…", systemImage: "antenna.radiowaves.left.and.right")
        case let .notFound(id):
            Label("Patch event \(shortId(id)) not found on the configured relays.", systemImage: "magnifyingglass")
        case let .wrongKind(id, kind):
            Label("Event \(shortId(id)) is not a NIP-34 patch or PR (kind \(kind)).", systemImage: "xmark.octagon")
        case let .badDiff(id):
            Label("Patch event \(shortId(id)) does not contain a valid unified diff.", systemImage: "xmark.octagon")
        case .noRelays:
            Label("No Nostr relays reachable — check your relay configuration.", systemImage: "wifi.exclamationmark")
        case let .prError(message):
            Label(message, systemImage: "exclamationmark.triangle")
        }
    }

    private var statusPadding: EdgeInsets {
        store.status == .idle ? .init() : .init(top: 8, leading: 10, bottom: 8, trailing: 10)
    }

    private var statusBackground: Color? {
        switch store.status {
        case .idle: nil
        case .fetching: .blue.opacity(0.08)
        default: .red.opacity(0.08)
        }
    }

    private var statusColor: Color {
        switch store.status {
        case .idle: .secondary
        case .fetching: .blue
        default: .red
        }
    }

    /// Long hex ids blow out the sheet width; show a short prefix in status messages.
    private func shortId(_ id: String) -> String {
        id.count > 12 ? "\(id.prefix(6))…\(id.suffix(4))" : id
    }
}
