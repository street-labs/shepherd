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

        @CasePathable
        public enum FetchStatus: Equatable, Sendable {
            case idle
            case invalidInput
            case fetching
            case notFound(String)
            case wrongKind(String, Int)
            case badDiff(String)
            case noRelays
        }

        public init() {}
    }

    @CasePathable
    public enum Action: Equatable, Sendable, BindableAction {
        case binding(BindingAction<State>)
        case fetchButtonTapped
        case cancelTapped
        case noRelaysReached
        case eventFetched(NostrEvent)
        case fetchTimedOut(eventID: String)
        case delegate(Delegate)
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// A valid patch was fetched and parsed; host should load it for review.
            case patchLoaded([PatchDiffSplitter.DiffFile], ReviewContext.PatchMetadata)
            case cancelled
        }
    }

    @Dependency(\.relayClient) var relayClient
    @Dependency(\.continuousClock) var clock

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
                    // ids-only filter, no kinds, so a non-1617 event is returned
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

            // Implements: FR-srm-patch-open-fetch, FR-srm-patch-open-load, FR-sri-patch-open-load
            // kind + diff validation, then parse into per-file diff blocks.
            case let .eventFetched(event):
                switch PatchDiffSplitter.validate(event) {
                case let .wrongKind(kind):
                    state.status = .wrongKind(shortHex(event.id), kind)
                    return .none
                case .badDiff:
                    state.status = .badDiff(shortHex(event.id))
                    return .none
                case let .ok(files, metadata):
                    return .send(.delegate(.patchLoaded(files, metadata)))
                }

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
}

/// First 8 hex chars of a (presumably 64-char) event id, for short-id display.
private func shortHex(_ id: String) -> String {
    String(id.prefix(8))
}
