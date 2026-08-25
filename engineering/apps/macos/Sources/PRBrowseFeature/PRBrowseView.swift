import SwiftUI
import ComposableArchitecture
import ShepherdDependencies

/// The PR Browse surface — the app's default empty state (FR-pb-default-state).
/// Implements the surface in `design/macos/pr-browse.md` (FR-pb-watchlist-manage,
/// FR-pb-repo-list, FR-pb-npub-list, FR-pb-open-pr): watchlist on the left, npub
/// lookup + PR list on the right, hosted inline in the empty state; selecting a
/// PR routes through the Open Patch flow.
public struct PRBrowseView: View {
    @Bindable public var store: StoreOf<PRBrowseFeature>
    @State private var selectedPRID: String?
    @Environment(\.horizontalSizeClass) private var sizeClass

    public init(store: StoreOf<PRBrowseFeature>) {
        self.store = store
    }

    /// Adaptive layout (design/ios/pr-browse.md): compact (iPhone) is a single
    /// column — watchlist screen with a back-pushed PR list; expanded (iPad /
    /// macOS) keeps the two-column layout. Single tap opens a PR on compact;
    /// double-tap/Enter stays for pointer/keyboard.
    public var body: some View {
        Group {
            if sizeClass == .compact {
                compactBody
            } else {
                HStack(alignment: .top, spacing: 0) {
                    watchlistPane
                    Divider()
                    listPane
                }
                // The 620×420 floor applies only on iOS expanded (iPad form
                // sheet). On macOS, browse renders inline as the default empty
                // state (FR-pb-default-state), so a min width here would force
                // the whole main window to 640pt.
                #if os(iOS)
                .frame(minWidth: 620, minHeight: 420)
                #endif
            }
        }
        .padding(20)
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Compact (iPhone)

    private var compactBody: some View {
        NavigationStack {
            if store.mode == nil {
                compactWatchlist
            } else {
                compactPRList
            }
        }
    }

    /// Compact watchlist screen: npub lookup on top, watched-repos list with
    /// swipe-to-delete (tap selects), add field at the bottom.
    private var compactWatchlist: some View {
        VStack(alignment: .leading, spacing: 10) {
            npubField
            Text("Watched Repos")
                .font(.headline)
            List {
                ForEach(store.watchlist, id: \.self) { raw in
                    watchlistRow(raw)
                }
                .onDelete { indices in
                    for index in indices where index < store.watchlist.count {
                        store.send(.removeTapped(store.watchlist[index]))
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if store.watchlist.isEmpty {
                    Text("No watched repos yet")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
            }
            addField
        }
        .navigationTitle("Browse PRs")
    }

    /// Compact PR list: replaces the watchlist while a lookup is active; the
    /// toolbar back affordance clears the mode and returns to the watchlist.
    private var compactPRList: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
                .font(.headline)
            Divider()
            prListGroup
            refreshRow
        }
        .navigationTitle("Browse PRs")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.send(.backTapped)
                } label: {
                    Label("Watchlist", systemImage: "chevron.backward")
                }
            }
        }
    }

    /// Keyboard open: the List selection binding sets `selectedPRID` via arrow
    /// keys; Enter (`.onSubmit`) opens it. Implements the "Enter on keyboard
    /// selection" half of design/macos/pr-browse.md → PR rows.
    private func openSelected() {
        if let id = selectedPRID { store.send(.prTapped(id)) }
    }

    // MARK: - Watchlist (left)

    private var watchlistPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Watched Repos")
                .font(.headline)

            List {
                ForEach(store.watchlist, id: \.self) { raw in
                    watchlistRow(raw)
                        .listRowBackground(
                            store.mode == .repo(raw)
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                }
            }
            .listStyle(.sidebar)
            .overlay {
                if store.watchlist.isEmpty {
                    Text("No watched repos yet")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
            }

            addField
        }
        .frame(width: 240)
    }

    /// One watched-repo row: the coordinate's `d` tail; trailing ✕ on expanded
    /// layouts, swipe-to-delete on compact.
    private func watchlistRow(_ raw: String) -> some View {
        HStack {
            Text(tail(raw))
                .lineLimit(1)
                .help(raw)
            Spacer()
            if sizeClass != .compact {
                Button {
                    store.send(.removeTapped(raw))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
                .help("Stop watching \(raw)")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { store.send(.repoSelected(raw)) }
    }

    /// Add-a-repo input row, shared by both layouts.
    private var addField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("30617:<pubkey>:<d>", text: $store.addInput)
                    .iOSInputField()
                    .font(.system(.caption, design: .monospaced))
                    .onSubmit { store.send(.addTapped) }
                Button("Add") { store.send(.addTapped) }
            }
            if let error = store.addError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - PR list (right)

    private var listPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            npubField

            header
                .font(.headline)

            Divider()

            prListGroup

            refreshRow
        }
        .padding(.leading, 16)
    }

    /// npub lookup input row, shared by both layouts.
    private var npubField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("npub1… or hex pubkey", text: $store.npubInput)
                    .iOSInputField()
                    .font(.system(.caption, design: .monospaced))
                    .onSubmit { store.send(.npubLookupTapped) }
                Button("Find") { store.send(.npubLookupTapped) }
            }
            if let error = store.npubError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    /// The PR list body (loading / no-relays / empty / populated), shared by
    /// both layouts. Single tap opens on compact; double-tap elsewhere.
    private var prListGroup: some View {
        Group {
            if store.loading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Fetching pull requests…")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.noRelays {
                Text("No relays reachable.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.prs.isEmpty {
                Text(emptyMessage)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedPRID) {
                    ForEach(store.prs) { pr in
                        PRRow(pr: pr)
                            .tag(pr.id)
                            .contentShape(Rectangle())
                            .onTapGesture(count: sizeClass == .compact ? 1 : 2) {
                                store.send(.prTapped(pr.id))
                            }
                    }
                }
                .listStyle(.plain)
                .onSubmit { openSelected() }
            }
        }
    }

    private var refreshRow: some View {
        HStack {
            Spacer()
            Button("Refresh") { store.send(.refreshTapped) }
                .disabled(store.mode == nil || store.loading)
        }
    }

    private var header: Text {
        switch store.mode {
        case let .repo(raw):
            Text("Pull requests — \(tail(raw))")
        case let .npub(pubkey):
            Text("Pull requests tagged \(short(pubkey))")
        case nil:
            Text("Pull requests")
        }
    }

    private var emptyMessage: String {
        store.mode == nil ? "Select a watched repo or enter an npub." : "No pull requests found."
    }

    /// The `d` identifier (last path component) of a coordinate.
    private func tail(_ raw: String) -> String {
        raw.split(separator: ":").last.map(String.init) ?? raw
    }

    private func short(_ hex: String) -> String {
        String(hex.prefix(10)) + "…"
    }
}

/// Text input traits for shared macOS/iOS fields: rounded border on macOS;
/// on iOS a system-filled field with URL keyboard, no autocapitalization,
/// and no autocorrect (design/ios/pr-browse.md → Dynamic Type/input fields).
private extension View {
    @ViewBuilder
    func iOSInputField() -> some View {
        #if os(iOS)
        self.textFieldStyle(.plain)
            .padding(8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        #else
        self.textFieldStyle(.roundedBorder)
        #endif
    }
}

/// One PR row: subject (bold, single line), author short form, relative age.
private struct PRRow: View {
    let pr: PRBrowseFeature.PRSummary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.subject)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(shortNPub(pr.author))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospaced()
            }
            Spacer()
            Text(age(pr.createdAt))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func age(_ createdAt: Int64) -> String {
        let seconds = max(0, Date().timeIntervalSince1970 - Double(createdAt))
        switch seconds {
        case ..<60: return "now"
        case ..<3600: return "\(Int(seconds / 60))m"
        case ..<86_400: return "\(Int(seconds / 3600))h"
        default: return "\(Int(seconds / 86_400))d"
        }
    }

    /// Bech32-encode a hex pubkey to its `npub1…` short form (first 10 chars),
    /// per design/macos/pr-browse.md → PR rows.
    private func shortNPub(_ hex: String) -> String {
        guard hex.count == 64, hex.allSatisfy({ $0.isHexDigit }),
              let data = hexToBytes(hex) else { return hex }
        return Bech32.encode(data, prefix: "npub").prefix(10) + "…"
    }

    private func hexToBytes(_ hex: String) -> Data? {
        var bytes = [UInt8](); bytes.reserveCapacity(hex.count / 2)
        var idx = hex.startIndex
        while idx < hex.endIndex {
            let next = hex.index(idx, offsetBy: 2)
            guard let b = UInt8(hex[idx..<next], radix: 16) else { return nil }
            bytes.append(b)
            idx = next
        }
        return Data(bytes)
    }
}
