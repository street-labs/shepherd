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
        /// When false (default) the list shows open PRs only; toggled by the
        /// `Show all` control. Implements: FR-pb-status.
        public var showAll = false

        @CasePathable
        public enum Mode: Equatable, Sendable {
            case repo(String)
            case npub(String)
        }

        public init() {}
    }

    /// A listed PR row. Implements the list fields of `FR-pb-repo-list` /
    /// `FR-pb-npub-list`: subject, author, age (computed at render), newest first.
    /// `status` resolves from NIP-34 kind `1630`–`1633` status events (newest
    /// per PR wins), defaulting to `open`. Implements: FR-pb-status.
    public struct PRSummary: Equatable, Identifiable, Sendable {
        public let id: String
        public let subject: String
        public let author: String
        public let createdAt: Int64
        public var status: String
        public init(id: String, subject: String, author: String, createdAt: Int64, status: String = "open") {
            self.id = id
            self.subject = subject
            self.author = author
            self.createdAt = createdAt
            self.status = status
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

        /// NIP-34 status kind → display label. Implements: FR-pb-status.
        public static func statusLabel(_ kind: Int) -> String {
            switch kind {
            case 1630: return "open"
            case 1631: return "merged"
            case 1632: return "closed"
            case 1633: return "draft"
            default: return "open"
            }
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
        case dismissed
        case prTapped(String)
        case lookupFinished([NostrEvent])
        case toggleShowAll
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

            // iOS sheet dismissal: clear any stale lookup so the next
            // presentation starts fresh (watchlist itself persists).
            case .dismissed:
                state.mode = nil
                state.prs = []
                state.loading = false
                state.noRelays = false
                state.npubInput = ""
                state.npubError = nil
                return .none

            // Implements: FR-pb-open-pr
            case let .prTapped(id):
                return .send(.delegate(.openPR(id)))

            // Implements: FR-pb-repo-list / FR-pb-npub-list (collection half):
            // dedupe by id, newest first; resolve status from the collected
            // NIP-34 status events. Implements: FR-pb-status.
            case let .lookupFinished(events):
                state.loading = false
                state.prs = Self.resolvePRs(events)
                return .none

            // `Show all` toggle: list open PRs only by default.
            // Implements: FR-pb-status.
            case .toggleShowAll:
                state.showAll.toggle()
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

    /// PR rows from a collected event batch: dedupe kind-1618 events by id,
    /// resolve each PR's status from the newest kind `1630`–`1633` status event
    /// whose `e` tag matches the PR id (open default), sort newest first.
    // Implements: FR-pb-repo-list, FR-pb-status
    static func resolvePRs(_ events: [NostrEvent]) -> [PRSummary] {
        var seen = Set<String>()
        var prs = events.filter { $0.kind == 1618 }
            .filter { seen.insert($0.id).inserted }
            .map(PRSummary.init(event:))
        let statuses = events.filter { (1630...1633).contains($0.kind) }
            .sorted { $0.createdAt > $1.createdAt }
        for i in prs.indices {
            if let statusEvent = statuses.first(where: { event in
                event.tags.contains { $0.count >= 2 && $0[0] == "e" && $0[1] == prs[i].id }
            }) {
                prs[i].status = PRSummary.statusLabel(statusEvent.kind)
            }
        }
        return prs.sorted { $0.createdAt > $1.createdAt }
    }

    /// Shared lookup effect for both modes: probe relays, subscribe with the
    /// mode's tag filter, collect every event within the 8s window
    /// (`NFR-pb-fetch-window`). Repo mode first resolves the repo `30617`
    /// announcement: its `relay` tags become the fetch target set so PRs on
    /// private grasp relays are queried directly; missing event/tag falls back
    /// to configured relays. NIP-42 AUTH challenges are answered by the
    /// existing `RelayAuth` path inside the subscription.
    // Implements: FR-pb-repo-list (repo-relay targeting)
    private func lookup(state: inout State, mode: State.Mode) -> Effect<Action> {
        // Implements: NFR-pb-fetch-window
        state.mode = mode
        state.loading = true
        state.noRelays = false
        state.prs = []
        state.showAll = false
        let filter: NostrFilter
        switch mode {
        case let .repo(raw):
            filter = NostrFilter(aTag: raw, kinds: [1618, 1630, 1631, 1632, 1633])
        case let .npub(pubkey):
            filter = NostrFilter(pTag: pubkey, kinds: [1618, 1630, 1631, 1632, 1633])
        }
        let repoCoordinate: String? =
            if case let .repo(raw) = mode { raw } else { nil }
        return .run { [relayClient] send in
            // Repo-relay targeting: resolve the repo announcement's relay set.
            var candidateRelays = RelayClient.resolveRelays()
            if let repoCoordinate {
                let repoFilter = NostrFilter(aTag: repoCoordinate, kinds: [30617])
                let repoEvent = await Self.firstEventOrTimeout(
                    relayClient.subscribe(repoFilter), seconds: 5
                )
                let repoRelays = repoEvent.map { event in
                    event.tags.filter { $0.count >= 2 && $0[0] == "relay" }.map { $0[1] }
                } ?? []
                if !repoRelays.isEmpty { candidateRelays = repoRelays }
            }
            let reachable = await relayClient.reachableRelays(candidateRelays)
            RelayLog.debug("pr-browse lookup: candidates=\(candidateRelays) reachable=\(reachable)")
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
            RelayLog.debug("pr-browse lookup finished: \(events.count) event(s)")
            await send(.lookupFinished(events))
        }
        .cancellable(id: CancelID.lookup, cancelInFlight: true)
    }

    /// First event from a subscription within a window, or nil.
    private static func firstEventOrTimeout(
        _ stream: AsyncStream<NostrEvent>, seconds: UInt64
    ) async -> NostrEvent? {
        await withTaskGroup(of: NostrEvent?.self) { group in
            group.addTask {
                for await event in stream { return event }
                return nil
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    /// Collect every event from a subscription within a time window, then stop.
    /// Generalizes `OpenPatchFeature.firstEventOrTimeout` to all events — a repo
    /// with many PRs gets them all in one subscription, no paging.
    ///
    /// The accumulator lives in a shared buffer (not as the group task's return
    /// value): the subscription stream never terminates on its own, so the
    /// accumulating task never completes and its return value would be discarded
    /// when the timeout wins the race — returning the buffer instead keeps every
    /// event collected before the window closes.
    static func collectEvents(
        _ stream: AsyncStream<NostrEvent>, seconds: UInt64
    ) async -> [NostrEvent] {
        let buffer = EventBuffer()
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await event in stream { await buffer.append(event) }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            }
            await group.next()
            group.cancelAll()
        }
        return await buffer.events
    }

    /// Shared accumulator for `collectEvents` — the collecting task outlives the
    /// timeout race, so results are read from here after cancellation.
    private actor EventBuffer {
        private(set) var events: [NostrEvent] = []
        func append(_ event: NostrEvent) { events.append(event) }
    }
}
