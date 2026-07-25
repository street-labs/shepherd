import Foundation
import ComposableArchitecture
import SharedModels

// Implements: FR-sri-event-publish

/// Nostr relay subscription client.
/// Implements: FR-sr-relay-client
///
/// The live implementation speaks NIP-01 over `URLSessionWebSocketTask`
/// (cross-platform macOS/iOS) -- no external `nak` CLI, no background process,
/// no sidecar. The app subscribes to patch-thread replies in-process. A future
/// impl swap is not required for iOS: `URLSessionWebSocketTask` already works
/// on both platforms.
public struct RelayClient: Sendable {
    /// Subscribe to events matching `filter` across configured relays. The
    /// returned stream emits each matching event (deduplicated by id across
    /// relays) as it arrives -- both stored events (delivered immediately) and
    /// new live events. The stream stays open until the consumer cancels it.
    /// Implements: FR-sr-relay-client, FR-srm-patch-open-fetch, FR-sri-patch-open-fetch.
    public var subscribe: @Sendable (NostrFilter) -> AsyncStream<NostrEvent>
    /// Probe which of the given relay URLs are reachable (complete the WebSocket
    /// handshake within a short budget). Implements the no-relays-reachable guard
    /// of `FR-srm-patch-open-fetch` / `AC-srm-patch-open-no-relays`: the Open Patch
    /// dialog calls this before fetching so it can report a precise no-relays
    /// error rather than timing out as "not found".
    public var reachableRelays: @Sendable ([String]) async -> [String]
    /// Publish a signed event to the configured relays. Implements: FR-srm-event-publish, FR-sri-event-publish.
    /// Sends an `EVENT` frame to each reachable relay and resolves to `accepted`
    /// when at least one relay returns `OK`, `rejected` when every reachable
    /// relay returns `OK: false`, or `failed` when no relay is reachable. Relay
    /// URL resolution reuses `RelayClient.resolveRelays`.
    public var publish: @Sendable (NostrEvent) async -> PublishResult
}

/// Input validation for the Open Patch dialog. Implements: FR-srm-patch-open-input, FR-sri-patch-open-input.
/// A reference is either a 64-character hex event id or a `nevent1…` entity;
/// `naddr1` is rejected (NIP-34 patches are kind 1617 with no `naddr` form).
public enum PatchRef {
    /// A normalized, valid patch reference ready to fetch.
    public enum Valid: Equatable, Sendable {
        case hexID(String)
        case nevent(String, NIP19Decode.NEvent)

        /// The referenced event id (64-char hex), whichever form the reference took.
        public var eventID: String {
            switch self {
            case let .hexID(id): id
            case let .nevent(_, ev): ev.eventID
            }
        }

        /// Relay hints to prefer for the fetch (non-empty only for `nevent` with encoded relays).
        public var relays: [String] {
            switch self {
            case .hexID: []
            case let .nevent(_, ev): ev.relays
            }
        }
    }

    /// Trim and classify `input`. Returns nil when the text is neither a 64-char
    /// hex id nor a `nevent1…` entity. The whole trimmed field must be one valid
    /// reference — surrounding prose is not parsed.
    public static func parse(_ input: String) -> Valid? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if isHexID(trimmed) { return .hexID(trimmed.lowercased()) }
        if trimmed.hasPrefix("nevent1"), let ev = NIP19Decode.decodeNEvent(trimmed) {
            return .nevent(trimmed, ev)
        }
        return nil
    }

    /// 64-character lowercase-hex Nostr event id.
    static func isHexID(_ s: String) -> Bool {
        guard s.count == 64 else { return false }
        return s.allSatisfy { $0.isHexDigit }
    }
}

/// Outcome of a publish attempt. Implements: FR-srm-event-publish, AC-srm-publish-relay-failure.
public enum PublishResult: Sendable, Equatable {
    /// At least one relay accepted the event (returned `OK: true`).
    case accepted
    /// Every reachable relay rejected the event (`OK: false`).
    case rejected
    /// No relay was reachable.
    case failed
}

/// A NIP-01 subscription filter. The subset the relay client needs: an `e` tag
/// value, the kinds list, an `ids` list (for fetch-by-id), and an optional relay
/// URL hint (preferred relays decoded from a `nevent1` reference).
public struct NostrFilter: Sendable, Equatable {
    public var eTag: String?
    public var kinds: [Int]
    public var ids: [String]
    /// Preferred relays for this subscription. When nil, the client uses its
    /// standard resolution (`NOSTR_RELAYS` / config / defaults). When non-empty,
    /// only those relays are contacted (e.g. the relays encoded in a `nevent1`).
    public var relays: [String]?

    public init(eTag: String? = nil, kinds: [Int] = [], ids: [String] = [], relays: [String]? = nil) {
        self.eTag = eTag
        self.kinds = kinds
        self.ids = ids
        self.relays = relays
    }

    /// The NIP-01 filter JSON object sent in a REQ frame.
    public var jsonObject: [String: Any] {
        var f: [String: Any] = [:]
        if let eTag { f["#e"] = [eTag] }
        if !kinds.isEmpty { f["kinds"] = kinds }
        if !ids.isEmpty { f["ids"] = ids }
        return f
    }
}

extension RelayClient: DependencyKey {
    public static let liveValue = RelayClient(
        subscribe: { filter in
            AsyncStream { continuation in
                let relays = filter.relays ?? Self.resolveRelays()
                let subID = "shep-" + UUID().uuidString.lowercased().prefix(8)
                let task = RelaySubscriptionTask(
                    relays: relays, filter: filter, subID: String(subID)
                ) { event in
                    continuation.yield(event)
                }
                task.start()
                continuation.onTermination = { _ in
                    task.cancel()
                }
            }
        },
        reachableRelays: { candidates in
            await RelayReachability.probe(candidates)
        },
        publish: { event in
            await RelayPublisher.publish(event)
        }
    )

    public static let testValue = RelayClient(
        subscribe: { _ in AsyncStream { _ in } },
        reachableRelays: { _ in [] },
        publish: { _ in .failed }
    )

    /// Resolve relay URLs: NOSTR_RELAYS env, then ~/.config/nostr/relays.txt,
    /// then the defaults. Same precedence as the command prompt + poller script.
    public static func resolveRelays() -> [String] {
        if let env = ProcessInfo.processInfo.environment["NOSTR_RELAYS"], !env.isEmpty {
            return env.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        let file = FileManager.default.shepherdHome
            .appendingPathComponent(".config/nostr/relays.txt")
        if let contents = try? String(contentsOf: file) {
            let lines = contents.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            if !lines.isEmpty { return lines }
        }
        return ["wss://relay.damus.io", "wss://nos.lol", "wss://relay.nostr.band"]
    }
}

extension DependencyValues {
    public var relayClient: RelayClient {
        get { self[RelayClient.self] }
        set { self[RelayClient.self] = newValue }
    }
}

/// Drives one WebSocket subscription per relay, merges EVENT frames, and
/// deduplicates by event id. Isolated so the live `RelayClient` stays Sendable.
private final class RelaySubscriptionTask: @unchecked Sendable {
    let relays: [String]
    let filter: NostrFilter
    let subID: String
    let onEvent: @Sendable (NostrEvent) -> Void
    private let session = URLSession(configuration: .ephemeral)
    private var tasks: [URLSessionWebSocketTask] = []
    private let lock = NSLock()
    private var seen = Set<String>()

    init(relays: [String], filter: NostrFilter, subID: String, onEvent: @escaping @Sendable (NostrEvent) -> Void) {
        self.relays = relays
        self.filter = filter
        self.subID = subID
        self.onEvent = onEvent
    }

    func start() {
        let reqFrame: [Any] = ["REQ", subID, filter.jsonObject]
        guard let reqData = try? JSONSerialization.data(withJSONObject: reqFrame),
              let reqString = String(data: reqData, encoding: .utf8) else { return }
        for url in relays {
            guard let URL = URL(string: url) else { continue }
            let task = session.webSocketTask(with: URL)
            tasks.append(task)
            task.resume()
            Task { [weak self] in
                // Send the REQ frame; tolerate send failure (relay may reject).
                try? await task.send(.string(reqString))
                await self?.receiveLoop(task: task)
            }
        }
    }

    func cancel() {
        lock.lock()
        let snap = tasks
        tasks = []
        lock.unlock()
        // Cancel each socket. CLOSE frames are best-effort and not worth an async
        // hop here; cancelling the task closes the WebSocket and ends the receive
        // loops. ponytail: skip the CLOSE frame, the socket close is sufficient.
        for task in snap {
            task.cancel(with: .goingAway, reason: nil)
        }
    }

    private func receiveLoop(task: URLSessionWebSocketTask) async {
        while task.closeCode == .invalid {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    handleFrame(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleFrame(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                // Connection closed or errored; stop this relay's loop.
                return
            }
        }
    }

    private func handleFrame(_ text: String) {
        guard let data = text.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              array.count >= 3,
              let type = array[0] as? String,
              type == "EVENT" else { return }
        // ["EVENT", subID, eventObject]
        guard let eventObject = array[2] as? [String: Any] else { return }
        guard let id = eventObject["id"] as? String else { return }
        lock.lock()
        let inserted = seen.insert(id).inserted
        lock.unlock()
        guard inserted else { return }
        guard let event = decodeEvent(eventObject) else { return }
        onEvent(event)
    }

    private func decodeEvent(_ o: [String: Any]) -> NostrEvent? {
        guard let id = o["id"] as? String,
              let pubkey = o["pubkey"] as? String,
              let kind = o["kind"] as? Int,
              let content = o["content"] as? String else { return nil }
        let tags = (o["tags"] as? [[Any]])?.map { $0.map { "\($0)" } } ?? []
        let createdAt = (o["created_at"] as? Int64) ?? Int64((o["created_at"] as? Int) ?? 0)
        let sig = (o["sig"] as? String) ?? ""
        return NostrEvent(id: id, pubkey: pubkey, kind: kind, content: content, tags: tags, createdAt: createdAt, sig: sig)
    }
}

// Implements: FR-srm-event-publish
/// Sends `EVENT` frames to relays and resolves the aggregate publish outcome.
/// A relay is "reachable" if its socket connects and returns an `OK` frame; success
/// is at-least-one-relay-accepted, individual relay failures tolerated.
private enum RelayPublisher {
    static func publish(_ event: NostrEvent) async -> PublishResult {
        let relays = RelayClient.resolveRelays()
        guard !relays.isEmpty else { return .failed }
        // Build the EVENT frame once: ["EVENT", {event-object}].
        let eventDict = eventJSONObject(event)
        let frame: [Any] = ["EVENT", eventDict]
        guard let frameData = try? JSONSerialization.data(withJSONObject: frame),
              let frameString = String(data: frameData, encoding: .utf8) else { return .failed }

        let session = URLSession(configuration: .ephemeral)
        var reachedAny = false
        var anyAccepted = false
        await withTaskGroup(of: Bool?.self) { group in
            for url in relays {
                guard let URL = URL(string: url) else { continue }
                group.addTask {
                    await self.publishToOne(url: URL, frame: frameString, eventID: event.id, session: session)
                }
            }
            for await result in group {
                if let accepted = result {
                    reachedAny = true
                    if accepted { anyAccepted = true }
                }
            }
        }
        if anyAccepted { return .accepted }
        return reachedAny ? .rejected : .failed
    }

    /// Publish to one relay. Returns true if the relay accepted (OK: true),
    /// false if it reached us but rejected, nil if unreachable.
    private static func publishToOne(url: URL, frame: String, eventID: String, session: URLSession) async -> Bool? {
        let task = session.webSocketTask(with: url)
        task.resume()
        try? await task.send(.string(frame))
        // Wait briefly for an OK frame. ponytail: fixed 5s budget per relay; a
        // per-relay adaptive timeout is not worth the complexity for a best-effort publish.
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while ContinuousClock.now < deadline {
            do {
                let message = try await task.receive()
                let text: String? = switch message {
                case .string(let s): s
                case .data(let d): String(data: d, encoding: .utf8)
                @unknown default: nil
                }
                if let text, let outcome = parseOK(text, eventID: eventID) {
                    task.cancel()
                    return outcome
                }
            } catch {
                task.cancel()
                return nil
            }
        }
        task.cancel()
        return nil
    }

    /// Parse a `["OK", <id>, <bool>, ...]` frame for our event id. Returns the
    /// bool if it matches, else nil (some relays send NOTICE/other frames first).
    private static func parseOK(_ text: String, eventID: String) -> Bool? {
        guard let data = text.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              array.count >= 3,
              array[0] as? String == "OK",
              array[1] as? String == eventID else { return nil }
        return array[2] as? Bool
    }

    /// Serialize a `NostrEvent` to the JSON object form used in an EVENT frame.
    private static func eventJSONObject(_ event: NostrEvent) -> [String: Any] {
        [
            "id": event.id,
            "pubkey": event.pubkey,
            "created_at": event.createdAt,
            "kind": event.kind,
            "tags": event.tags,
            "content": event.content,
            "sig": event.sig,
        ]
    }
}

/// Reachability probe for the Open Patch dialog. Implements: FR-srm-patch-open-fetch
/// (the no-relays-reachable guard). A relay is reachable if its WebSocket
/// completes the handshake quickly enough to answer a ping. ponytail: fixed 3s
/// budget per relay; an adaptive RTT estimate is not worth it for a one-shot gate.
private enum RelayReachability {
    static func probe(_ candidates: [String]) async -> [String] {
        let session = URLSession(configuration: .ephemeral)
        return await withTaskGroup(of: String?.self) { group in
            for url in candidates {
                guard let URL = URL(string: url) else { continue }
                group.addTask { await probeOne(url: URL, session: session) }
            }
            var reachable: [String] = []
            for await result in group {
                if let url = result { reachable.append(url) }
            }
            return reachable
        }
    }

    /// Probe one relay. Returns its URL string if the WebSocket handshake
    /// completes (a ping succeeds within the budget), else nil.
    private static func probeOne(url: URL, session: URLSession) async -> String? {
        let task = session.webSocketTask(with: url)
        task.resume()
        // Race the ping against a 3s timeout. sendPing completes once the socket
        // is connected; if it errors or times out, the relay is unreachable.
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                do {
                    try await ping(task)
                    return url.absoluteString
                } catch {
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            task.cancel(with: .goingAway, reason: nil)
            return result
        }
    }

    /// `URLSessionWebSocketTask.sendPing` is callback-based; bridge to async.
    private static func ping(_ task: URLSessionWebSocketTask) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            task.sendPing { error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume() }
            }
        }
    }
}
