import ComposableArchitecture
import SharedModels
import ShepherdDependencies
import Foundation

/// TCA reducer for the Browse PRs sheet. Implements `FR-pb-watchlist-manage`
/// (watchlist state + persistence), `FR-pb-repo-list` and `FR-pb-npub-list`
/// (kind `1618` lookups by `a` / `p` tag), and `FR-pb-open-pr` (delegate emission
/// only — the host `AppFeature` routes the event id through the existing
/// Open Patch load path; this feature contains no review logic).
@Reducer
public struct PRBrowseFeature {
    @ObservableState
    public struct State: Equatable, Sendable {
        /// Watched repo coordinates, raw `30617:<pubkey>:<d>` strings.
        public var watchlist: [String] = []
        public var addInput: String = ""
        public var addError: String?

        public var npubInput: String = ""
        public var npubError: String?

        /// The active lookup. `nil` = idle.
        public var mode: Mode?
        public var loading = false
        public var noRelays = false
        public var prs: [PRSummary] = []

        @CasePathable
        public enum Mode: Equatable, Sendable {
            case repo(String)
            case npub(String)
        }

        public init() {}
    }

    /// A listed PR row. Implements the list fields of `FR-pb-repo-list` /
    /// `FR-pb-npub-list`: subject, author, age (computed at render), newest first.
    public struct PRSummary: Equatable, Identifiable, Sendable {
        public let id: String
        public let subject: String
        public let author: String
        public let createdAt: Int64
        public init(id: String, subject: String, author: String, createdAt: Int64) {
            self.id = id
            self.subject = subject
            self.author = author
            self.createdAt = createdAt
        }

        /// Maps a kind `1618` event to a row. Subject resolution reuses
        /// `PatchDiffSplitter.subject` (subject tag, else first content line).
        public init(event: NostrEvent) {
            self.init(
                id: event.id,
                subject: PatchDiffSplitter.subject(from: event),
                author: event.pubkey,
                createdAt: event.createdAt
            )
        }
    }

    @CasePathable
    public enum Action: Equatable, Sendable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case addTapped
        case removeTapped(String)
        case repoSelected(String)
        case npubLookupTapped
        case refreshTapped
        case backTapped
        case prTapped(String)
        case lookupFinished([NostrEvent])
        case noRelaysReached
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// Open the PR with this event id through the in-app review flow.
            /// Implements `FR-pb-open-pr`.
            case openPR(String)
        }
    }

    @Dependency(\.relayClient) var relayClient
    @Dependency(\.watchlistClient) var watchlistClient

    public init() {}

    private enum CancelID { case lookup }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.addInput), .binding(\.npubInput):
                state.addError = nil
                state.npubError = nil
                return .none

            case .binding:
                return .none

            // Implements: FR-pb-watchlist-manage
            case .onAppear:
                state.watchlist = watchlistClient.load()
                return .none

            // Implements: FR-pb-watchlist-manage (add half)
            case .addTapped:
                guard let coord = RepoCoordinate.parse(state.addInput) else {
                    state.addError = "Enter a repo coordinate: 30617:<pubkey>:<d>"
                    return .none
                }
                guard !state.watchlist.contains(coord.raw) else {
                    state.addError = "Already watching this repo"
                    return .none
                }
                state.watchlist.append(coord.raw)
                state.addInput = ""
                watchlistClient.save(state.watchlist)
                return .none

            // Implements: FR-pb-watchlist-manage (remove half)
            case let .removeTapped(raw):
                state.watchlist.removeAll { $0 == raw }
                watchlistClient.save(state.watchlist)
                if state.mode == .repo(raw) {
                    state.mode = nil
                    state.prs = []
                }
                return .none

            // Implements: FR-pb-repo-list
            case let .repoSelected(raw):
                return lookup(state: &state, mode: .repo(raw))

            // Implements: FR-pb-npub-list
            case .npubLookupTapped:
                let trimmed = state.npubInput.trimmingCharacters(in: .whitespacesAndNewlines)
                let pubkey: String?
                if trimmed.hasPrefix("npub1") {
                    pubkey = NIP19Decode.decodeNPub(trimmed)
                } else if trimmed.count == 64, trimmed.allSatisfy({ $0.isHexDigit }) {
                    pubkey = trimmed.lowercased()
                } else {
                    pubkey = nil
                }
                guard let pubkey else {
                    state.npubError = "Enter an npub1… or 64-char hex pubkey"
                    return .none
                }
                return lookup(state: &state, mode: .npub(pubkey))

            // Implements: FR-pb-repo-list / FR-pb-npub-list (refresh half)
            case .refreshTapped:
                if let mode = state.mode {
                    return lookup(state: &state, mode: mode)
                }
                return .none

            // Implements: FR-pb-repo-list — compact back affordance clears the
            // active lookup and returns to the watchlist screen.
            case .backTapped:
                state.mode = nil
                state.prs = []
                state.loading = false
                state.noRelays = false
                return .none

            // Implements: FR-pb-open-pr
            case let .prTapped(id):
                return .send(.delegate(.openPR(id)))

            // Implements: FR-pb-repo-list / FR-pb-npub-list (collection half):
            // dedupe by id, newest first.
            case let .lookupFinished(events):
                state.loading = false
                var seen = Set<String>()
                state.prs = events
                    .filter { seen.insert($0.id).inserted }
                    .map(PRSummary.init(event:))
                    .sorted { $0.createdAt > $1.createdAt }
                return .none

            case .noRelaysReached:
                state.loading = false
                state.noRelays = true
                return .none

            case .delegate:
                return .none
            }
        }
    }

    /// Shared lookup effect for both modes: probe relays, subscribe with the
    /// mode's tag filter, collect every event within the 8s window
    /// (`NFR-pb-fetch-window`).
    private func lookup(state: inout State, mode: State.Mode) -> Effect<Action> {
        // Implements: NFR-pb-fetch-window
        state.mode = mode
        state.loading = true
        state.noRelays = false
        state.prs = []
        let filter: NostrFilter
        switch mode {
        case let .repo(raw):
            filter = NostrFilter(aTag: raw, kinds: [1618])
        case let .npub(pubkey):
            filter = NostrFilter(pTag: pubkey, kinds: [1618])
        }
        return .run { [relayClient] send in
            let reachable = await relayClient.reachableRelays(RelayClient.resolveRelays())
            guard !reachable.isEmpty else {
                await send(.noRelaysReached)
                return
            }
        var f = filter
        f.relays = reachable
        let events = await Self.collectEvents(
            relayClient.subscribe(f),
            seconds: 8
        )
            await send(.lookupFinished(events))
        }
        .cancellable(id: CancelID.lookup, cancelInFlight: true)
    }

    /// Collect every event from a subscription within a time window, then stop.
    /// Generalizes `OpenPatchFeature.firstEventOrTimeout` to all events — a repo
    /// with many PRs gets them all in one subscription, no paging.
    static func collectEvents(
        _ stream: AsyncStream<NostrEvent>, seconds: UInt64
    ) async -> [NostrEvent] {
        await withTaskGroup(of: [NostrEvent]?.self) { group in
            group.addTask {
                var out: [NostrEvent] = []
                for await event in stream { out.append(event) }
                return out
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first ?? []
        }
    }
}
