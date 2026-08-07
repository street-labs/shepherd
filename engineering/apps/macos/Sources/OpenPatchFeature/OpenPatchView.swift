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
            Text("Open Patch or PR")
                .font(.headline)

            TextField("Paste a 64-char event id or nevent1… (patch or PR)", text: $store.input)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .disabled(isFetching)
                .onSubmit { store.send(.fetchButtonTapped) }

            statusLine
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .frame(minWidth: 420)
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
            Text(" ").foregroundStyle(.clear)
        case .invalidInput:
            Text("Enter a 64-character hex event id or a nevent1 reference")
        case .fetching:
            Text("Fetching event from relays…")
        case let .notFound(id):
            Text("Patch event \(id) not found on the configured relays.")
        case let .wrongKind(id, kind):
            Text("Event \(id) is not a NIP-34 patch or PR (kind \(kind)).")
        case let .badDiff(id):
            Text("Patch event \(id) does not contain a valid unified diff.")
        case .noRelays:
            Text("No Nostr relays reachable — check your relay configuration.")
        case let .prError(message):
            Text(message)
        }
    }

    private var statusColor: Color {
        switch store.status {
        case .fetching, .idle: .secondary
        default: .red
        }
    }
}
