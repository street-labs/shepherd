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
        }
    )

    public static let testValue = RelayClient(
        subscribe: { _ in AsyncStream { _ in } }
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
        return NostrEvent(id: id, pubkey: pubkey, kind: kind, content: content, tags: tags, createdAt: createdAt)
    }
}
