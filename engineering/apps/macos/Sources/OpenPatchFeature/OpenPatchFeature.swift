import ComposableArchitecture
import SharedModels
import ShepherdDependencies
import Foundation

/// TCA reducer for the Open Patch dialog. Implements `FR-srm-patch-open-input`
/// and `FR-srm-patch-open-fetch`. States map 1:1 to the design's dialog states
/// (idle / invalid / fetching / not-found / wrong-kind / bad-diff / no-relays).
/// On a successful fetch + validate it emits `.delegate(.patchLoaded(...))`; the
/// hosting `AppFeature` loads the diff tabs, attaches patch metadata, and starts
/// the live patch-thread subscription (`FR-srm-patch-open-load`).
@Reducer
public struct OpenPatchFeature {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var input: String = ""
        public var status: FetchStatus = .idle
        /// The parsed reference for the in-flight fetch, retained so the PR paths
        /// can re-resolve relays / event ids after the kind is known.
        public var currentRef: PatchRef.Valid?

        @CasePathable
        public enum FetchStatus: Equatable, Sendable {
            case idle
            case invalidInput
            case fetching
            case notFound(String)
            case wrongKind(String, Int)
            case badDiff(String)
            case noRelays
            /// A PR-specific failure (missing tags, git fetch failure, empty diff,
            /// no git on PATH, or — on iOS — no reviewable referenced patches).
            /// Carries the exact user-facing message. Implements the failure states
            /// of `FR-srm-pr-open-fetch` / `FR-srm-pr-open-clone` / `NFR-srm-pr-open-git-required`
            /// and `FR-sri-pr-open-patches`.
            case prError(String)
        }

        public init(input: String = "") {
            self.input = input
        }
    }

    @CasePathable
    public enum Action: Equatable, Sendable, BindableAction {
        case binding(BindingAction<State>)
        case fetchButtonTapped
        case cancelTapped
        case noRelaysReached
        case eventFetched(NostrEvent)
        case fetchTimedOut(eventID: String)
        /// macOS PR path: the git-subprocess diff acquisition finished.
        case prDiffResult(GitDiffClient.Result, NostrEvent)
        /// iOS PR path: the PR's referenced patch events have been fetched.
        case prPatchesFetched([NostrEvent], NostrEvent)
        case delegate(Delegate)
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// A valid patch or PR was fetched and parsed; host should load it for
                       /// review. For a PR, the metadata carries `tipCommit`/`branchName`.
            case patchLoaded([PatchDiffSplitter.DiffFile], ReviewContext.PatchMetadata)
            case cancelled
        }
    }

    @Dependency(\.relayClient) var relayClient
    @Dependency(\.continuousClock) var clock
    #if os(macOS)
    @Dependency(\.gitDiffClient) var gitDiffClient
    #endif

    public init() {}

    private enum CancelID { case fetch }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.input):
                // Editing the field clears any prior error so the reviewer can retry.
                state.status = .idle
                return .none

            case .binding:
                return .none

            // Implements: FR-srm-patch-open-input, FR-srm-patch-open-fetch, FR-sri-patch-open-input, FR-sri-patch-open-fetch
            case .fetchButtonTapped:
                guard let ref = PatchRef.parse(state.input) else {
                    state.status = .invalidInput
                    return .none
                }
                state.status = .fetching
                state.currentRef = ref
                let eventID = ref.eventID
                // nevent relay hints are preferred; otherwise standard resolution.
                let candidates = ref.relays.isEmpty
                    ? RelayClient.resolveRelays()
                    : ref.relays
                return .run { [relayClient] send in
                    // Implements: AC-srm-patch-open-no-relays — probe before fetching
                    // so a dead relay config surfaces as a precise no-relays error,
                    // not a silent not-found timeout.
                    let reachable = await relayClient.reachableRelays(candidates)
                    guard !reachable.isEmpty else {
                        await send(.noRelaysReached)
                        return
                    }
                    // Implements: FR-srm-patch-open-fetch
                    // ids-only filter, no kinds, so a non-1617/1618 event is returned
                    // and rejected as wrong-kind rather than filtered out upstream.
                    let filter = NostrFilter(ids: [eventID], relays: reachable)
                    let stream = relayClient.subscribe(filter)
                    let event = await Self.firstEventOrTimeout(stream, seconds: 8)
                    if let event {
                        await send(.eventFetched(event))
                    } else {
                        await send(.fetchTimedOut(eventID: eventID))
                    }
                }
                .cancellable(id: CancelID.fetch, cancelInFlight: true)

            case .noRelaysReached:
                state.status = .noRelays
                return .none

            // Implements: FR-srm-patch-open-fetch, FR-srm-patch-open-load, FR-sri-patch-open-load, FR-srm-pr-open-fetch, FR-srm-pr-open-clone, FR-srm-pr-open-load, FR-sri-pr-open-patches, FR-sri-pr-open-load
            // kind dispatch: 1617 -> patch validate; 1618 -> PR path (platform-specific);
            // anything else -> wrong-kind.
            case let .eventFetched(event):
                switch event.kind {
                case PatchDiffSplitter.patchKind:
                    switch PatchDiffSplitter.validate(event) {
                    case let .wrongKind(kind):
                        state.status = .wrongKind(shortHex(event.id), kind)
                        return .none
                    case .badDiff where PatchDiffSplitter.isCoverLetter(event):
                        // NIP-34 patch series: the root is a cover letter with no
                        // diff of its own; the diffs live in kind-1617 replies that
                        // reference it via `e` tags. Fetch the series and union.
                        state.status = .fetching
                        let candidates = state.currentRef?.relays.isEmpty ?? true
                            ? RelayClient.resolveRelays()
                            : (state.currentRef?.relays ?? RelayClient.resolveRelays())
                        return .run { [relayClient] send in
                            let reachable = await relayClient.reachableRelays(candidates)
                            let relays = reachable.isEmpty ? candidates : reachable
                            let events = await Self.fetchPatchReplies(rootID: event.id, relays: relays, relayClient: relayClient)
                            await send(.prPatchesFetched(events, event))
                        }
                        .cancellable(id: CancelID.fetch, cancelInFlight: true)
                    case .badDiff:
                        state.status = .badDiff(shortHex(event.id))
                        return .none
                    case let .ok(files, metadata):
                        return .send(.delegate(.patchLoaded(files, metadata)))
                    }
                case PatchDiffSplitter.prKind:
                    state.status = .fetching
                    let short = shortHex(event.id)
                    #if os(macOS)
                    // FR-srm-pr-open-fetch: validate required tags (clone, c).
                    // merge-base is optional — without it the diff is the tip
                    // commit against its parent.
                    let clones = PatchDiffSplitter.cloneURLs(from: event.tags)
                    let tip = PatchDiffSplitter.tipCommit(from: event.tags)
                    if clones.isEmpty {
                        state.status = .prError("Pull request \(short) has no clone URL — cannot fetch changes.")
                        return .none
                    }
                    guard let tip else {
                        state.status = .prError("Pull request \(short) has no commit id.")
                        return .none
                    }
                    let spec = GitDiffClient.Spec(
                        cloneURLs: clones,
                        tipCommit: tip,
                        mergeBase: PatchDiffSplitter.mergeBase(from: event.tags),
                        branchName: PatchDiffSplitter.branchName(from: event.tags)
                    )
                    return .run { [gitDiffClient] send in
                        // Implements: FR-srm-pr-open-clone, NFR-srm-pr-open-git-required
                        let result = await gitDiffClient.acquirePRDiff(spec)
                        await send(.prDiffResult(result, event))
                    }
                    .cancellable(id: CancelID.fetch, cancelInFlight: true)
                    #else
                    // FR-sri-pr-open-patches: iterate the PR's `e`-tagged patch events.
                    let ids = PatchDiffSplitter.referencedPatchIDs(from: event.tags)
                    if ids.isEmpty {
                        state.status = .prError("PR \(short) has no reviewable patch events. Its changes may be available only via git clone — open this PR on macOS.")
                        return .none
                    }
                    let candidates = state.currentRef?.relays.isEmpty ?? true
                        ? RelayClient.resolveRelays()
                        : (state.currentRef?.relays ?? RelayClient.resolveRelays())
                    return .run { [relayClient] send in
                        let reachable = await relayClient.reachableRelays(candidates)
                        let relays = reachable.isEmpty ? candidates : reachable
                        let events = await Self.fetchReferencedPatches(ids: ids, relays: relays, relayClient: relayClient)
                        await send(.prPatchesFetched(events, event))
                    }
                    .cancellable(id: CancelID.fetch, cancelInFlight: true)
                    #endif
                default:
                    state.status = .wrongKind(shortHex(event.id), event.kind)
                    return .none
                }

            // Implements: FR-srm-pr-open-load — split the git-acquired diff and
            // attach PR metadata; reuse the patch load delegate.
            case let .prDiffResult(result, event):
                let short = shortHex(event.id)
                switch result {
                case .noGit:
                    state.status = .prError("git is required to review pull requests but was not found on your system")
                    return .none
                case let .fetchFailed(msg):
                    state.status = .prError("Could not fetch commits from \(msg)")
                    return .none
                case .empty:
                    state.status = .prError("Pull request \(short) has no changes.")
                    return .none
                case let .diff(diff):
                    guard let files = PatchDiffSplitter.splitUnifiedDiff(diff) else {
                        state.status = .prError("Pull request \(short) has no changes.")
                        return .none
                    }
                    return .send(.delegate(.patchLoaded(files, PatchDiffSplitter.prMetadata(from: event))))
                }

            // Implements: FR-sri-pr-open-load — union the referenced patches'
            // diffs by file path and attach PR metadata; reuse the patch load delegate.
            case let .prPatchesFetched(events, prEvent):
                var union: [String: [String]] = [:]
                var order: [String] = []
                for ev in events {
                    // Skip non-1617 / malformed-diff referenced events (FR-sri-pr-open-patches).
                    guard case let .ok(files, _) = PatchDiffSplitter.validate(ev) else { continue }
                    for f in files {
                        if union[f.filePath] == nil { order.append(f.filePath) }
                        union[f.filePath, default: []].append(f.diffBlock)
                    }
                }
                let short = shortHex(prEvent.id)
                guard !union.isEmpty else {
                    state.status = .prError("PR \(short) has no reviewable patch events. Its changes may be available only via git clone — open this PR on macOS.")
                    return .none
                }
                let files = order.map { filePath in
                    PatchDiffSplitter.DiffFile(filePath: filePath, diffBlock: union[filePath]!.joined(separator: "\n"))
                }
                var metadata = PatchDiffSplitter.prMetadata(from: prEvent)
                metadata.seriesPatchCount = events.count
                return .send(.delegate(.patchLoaded(files, metadata)))

            case let .fetchTimedOut(eventID):
                state.status = .notFound(shortHex(eventID))
                return .none

            case .cancelTapped:
                return .merge(
                    .cancel(id: CancelID.fetch),
                    .send(.delegate(.cancelled))
                )

            case .delegate:
                return .none
            }
        }
    }

    /// Race the first event from a subscription against a timeout. Returns the
    /// event if one arrives, nil if the window elapses first. Cancelling the
    /// winner cancels the other branch; the subscription stream terminates
    /// (tearing down its relay sockets) when iteration stops.
    static func firstEventOrTimeout(
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

    /// Fetch each referenced patch event by id in parallel, taking the first
    /// event per id within the wait window. Used by the iOS PR path
    /// (`FR-sri-pr-open-patches`) to gather the kind `1617` patches a PR
    /// references. Events that don't arrive in time are nil and skipped by the
    /// caller. Implements the fetch half of `FR-sri-pr-open-patches`.
    static func fetchReferencedPatches(
        ids: [String], relays: [String], relayClient: RelayClient
    ) async -> [NostrEvent] {
        await withTaskGroup(of: NostrEvent?.self) { group in
            for id in ids {
                group.addTask {
                    let stream = relayClient.subscribe(NostrFilter(ids: [id], relays: relays))
                    return await firstEventOrTimeout(stream, seconds: 8)
                }
            }
            var out: [NostrEvent] = []
            for await event in group {
                if let event { out.append(event) }
            }
            return out
        }
    }

    /// Fetch the kind-1617 patch replies that reference a patch-series cover
    /// letter via `e` tag (NIP-34 series published by `ngit send --force-patch`).
    /// Collects every distinct event that arrives within an 8s window, oldest
    /// first, so the union preserves commit order. The fetched count is surfaced
    /// via `PatchMetadata.seriesPatchCount` so a truncated series (slow relay,
    /// window expired) is visible rather than presented as complete.
    private final class EventBox: @unchecked Sendable {
        // Sendability invariant: exactly one task appends; reads happen only
        // after the task group below completes. Confine or actor-ify if that
        // ever stops holding.
        var events: [NostrEvent] = []
    }

    static func fetchPatchReplies(
        rootID: String, relays: [String], relayClient: RelayClient
    ) async -> [NostrEvent] {
        let stream = relayClient.subscribe(NostrFilter(eTag: rootID, kinds: [PatchDiffSplitter.patchKind], relays: relays))
        let box = EventBox()
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await event in stream { box.events.append(event) }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
            }
            await group.next()
            group.cancelAll()
        }
        var byID: [String: NostrEvent] = [:]
        for event in box.events { byID[event.id] = event }
        // ponytail: createdAt ordering is a heuristic — same-second ngit sends
        // have no guaranteed commit order, and a re-published patch sorts by its
        // original timestamp. Walk the `e`-tag reply chain from the root if
        // exact ordering ever matters.
        return byID.values.sorted { $0.createdAt < $1.createdAt }
    }
}

/// First 8 hex chars of a (presumably 64-char) event id, for short-id display.
private func shortHex(_ id: String) -> String {
    String(id.prefix(8))
}
