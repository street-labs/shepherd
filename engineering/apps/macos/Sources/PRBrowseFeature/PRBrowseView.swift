import SwiftUI
import ComposableArchitecture

/// The Browse PRs sheet. Implements the surface in `design/macos/pr-browse.md`
/// (FR-pb-watchlist-manage, FR-pb-repo-list, FR-pb-npub-list, FR-pb-open-pr):
/// watchlist on the left, npub lookup + PR list on the right. Presented from the
/// empty state; selecting a PR dismisses and routes through the Open Patch flow.
public struct PRBrowseView: View {
    @Bindable public var store: StoreOf<PRBrowseFeature>

    public init(store: StoreOf<PRBrowseFeature>) {
        self.store = store
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            watchlistPane
            Divider()
            listPane
        }
        .frame(minWidth: 620, minHeight: 420)
        .padding(20)
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Watchlist (left)

    private var watchlistPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Watched Repos")
                .font(.headline)

            List {
                ForEach(store.watchlist, id: \.self) { raw in
                    HStack {
                        Text(tail(raw))
                            .lineLimit(1)
                            .help(raw)
                        Spacer()
                        Button {
                            store.send(.removeTapped(raw))
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tertiary)
                        .help("Stop watching \(raw)")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { store.send(.repoSelected(raw)) }
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

            HStack {
                TextField("30617:<pubkey>:<d>", text: $store.addInput)
                    .textFieldStyle(.roundedBorder)
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
        .frame(width: 240)
    }

    // MARK: - PR list (right)

    private var listPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("npub1… or hex pubkey", text: $store.npubInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                    .onSubmit { store.send(.npubLookupTapped) }
                Button("Find") { store.send(.npubLookupTapped) }
            }
            if let error = store.npubError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            header
                .font(.headline)

            Divider()

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
                    List(store.prs) { pr in
                        PRRow(pr: pr)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) { store.send(.prTapped(pr.id)) }
                    }
                    .listStyle(.plain)
                }
            }

            HStack {
                Spacer()
                Button("Refresh") { store.send(.refreshTapped) }
                    .disabled(store.mode == nil || store.loading)
            }
        }
        .padding(.leading, 16)
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

/// One PR row: subject (bold, single line), author short form, relative age.
private struct PRRow: View {
    let pr: PRBrowseFeature.PRSummary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.subject)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(pr.author.prefix(10) + "…")
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
        case ..<3600: return "\(Int(seconds / 60))m"
        case ..<86_400: return "\(Int(seconds / 3600))h"
        default: return "\(Int(seconds / 86_400))d"
        }
    }
}
