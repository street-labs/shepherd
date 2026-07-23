import Foundation
import ComposableArchitecture
import SharedModels

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
    public var subscribe: @Sendable (NostrFilter) -> AsyncStream<NostrEvent>
    /// Publish a signed event to the configured relays. Implements: FR-srm-event-publish.
    /// Sends an `EVENT` frame to each reachable relay and resolves to `accepted`
    /// when at least one relay returns `OK`, `rejected` when every reachable
    /// relay returns `OK: false`, or `failed` when no relay is reachable. Relay
    /// URL resolution reuses `RelayClient.resolveRelays`.
    public var publish: @Sendable (NostrEvent) async -> PublishResult
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

/// A NIP-01 subscription filter. Only the subset the patch-reply loop needs:
/// an `e` tag value (for `{"#e": [id]}`) and the kinds list.
public struct NostrFilter: Sendable, Equatable {
    public var eTag: String?
    public var kinds: [Int]

    public init(eTag: String? = nil, kinds: [Int] = []) {
        self.eTag = eTag
        self.kinds = kinds
    }

    /// The NIP-01 filter JSON object sent in a REQ frame.
    public var jsonObject: [String: Any] {
        var f: [String: Any] = [:]
        if let eTag { f["#e"] = [eTag] }
        if !kinds.isEmpty { f["kinds"] = kinds }
        return f
    }
}

extension RelayClient: DependencyKey {
    public static let liveValue = RelayClient(
        subscribe: { filter in
            AsyncStream { continuation in
                let relays = Self.resolveRelays()
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
        publish: { event in
            await RelayPublisher.publish(event)
        }
    )

    public static let testValue = RelayClient(
        subscribe: { _ in AsyncStream { _ in } },
        publish: { _ in .failed }
    )

    /// Resolve relay URLs: NOSTR_RELAYS env, then ~/.config/nostr/relays.txt,
    /// then the defaults. Same precedence as the command prompt + poller script.
    static func resolveRelays() -> [String] {
        if let env = ProcessInfo.processInfo.environment["NOSTR_RELAYS"], !env.isEmpty {
            return env.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        let file = FileManager.default.homeDirectoryForCurrentUser
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
