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
/// A reference is a 64-character hex event id, a `nevent1…` entity, or any URL
/// whose path contains a valid reference (deeplink, gitworkshop.dev share
/// link, other Nostr viewers); `naddr1` is rejected (NIP-34 patches are kind 1617
/// with no `naddr` form).
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

    /// Trim and classify `input`. Returns nil when the text is none of the accepted
    /// forms. The whole trimmed field must be one valid reference — surrounding
    /// prose is not parsed.
    ///
    /// Beyond a bare hex id / `nevent1…`, any URL carrying a valid reference in
    /// a path segment is accepted (a `shepherd://patch|pr/<ref>` deeplink pasted
    /// as text, an `https://gitworkshop.dev/.../e/<nevent>` share link, any other
    /// Nostr web viewer) — the reference is extracted and re-parsed. Implements
    /// FR-srm-patch-open-input.
    public static func parse(_ input: String) -> Valid? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if isHexID(trimmed) { return .hexID(trimmed.lowercased()) }
        if trimmed.hasPrefix("nevent1"), let ev = NIP19Decode.decodeNEvent(trimmed) {
            return .nevent(trimmed, ev)
        }
        // ponytail: URL forms are handled by scanning path segments (right-to-left)
        // for a hex id or nevent and re-parsing; no per-site link grammar. Add
        // per-site handling (e.g. relay hints from the URL's host) only if a real
        // site needs more than the embedded ref.
        guard trimmed.contains("://"), let url = URL(string: trimmed) else { return nil }
        for component in url.path.split(separator: "/").reversed() {
            let segment = component.removingPercentEncoding ?? String(component)
            if isHexID(segment) { return .hexID(segment.lowercased()) }
            if segment.hasPrefix("nevent1"), let ev = NIP19Decode.decodeNEvent(segment) {
                return .nevent(segment, ev)
            }
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

/// A NIP-01 subscription filter. The subset the relay client needs: single tag
/// values (`e` / `a` / `p`), the kinds list, an `ids` list (for fetch-by-id), and
/// an optional relay URL hint (preferred relays decoded from a `nevent1`
/// reference). Implements the `#a`/`#p` lookups of `FR-pb-repo-list` and
/// `FR-pb-npub-list`.
public struct NostrFilter: Sendable, Equatable {
    public var eTag: String?
    /// A repository coordinate (`30617:<pubkey>:<d>`) matched against events'
    /// `a` tags (`#a` REQ key).
    public var aTag: String?
    /// A pubkey matched against events' `p` tags (`#p` REQ key).
    public var pTag: String?
    public var kinds: [Int]
    public var ids: [String]
    /// Preferred relays for this subscription. When nil, the client uses its
    /// standard resolution (`NOSTR_RELAYS` / config / defaults). When non-empty,
    /// only those relays are contacted (e.g. the relays encoded in a `nevent1`).
    public var relays: [String]?

    public init(eTag: String? = nil, aTag: String? = nil, pTag: String? = nil, kinds: [Int] = [], ids: [String] = [], relays: [String]? = nil) {
        self.eTag = eTag
        self.aTag = aTag
        self.pTag = pTag
        self.kinds = kinds
        self.ids = ids
        self.relays = relays
    }

    /// The NIP-01 filter JSON object sent in a REQ frame.
    public var jsonObject: [String: Any] {
        var f: [String: Any] = [:]
        if let eTag { f["#e"] = [eTag] }
        if let aTag { f["#a"] = [aTag] }
        if let pTag { f["#p"] = [pTag] }
        if !kinds.isEmpty { f["kinds"] = kinds }
        if !ids.isEmpty { f["ids"] = ids }
        return f
    }
}

extension RelayClient: DependencyKey {
    public static let liveValue: RelayClient = {
        // NIP-42 AUTH: resolve the identity + signer at call time (not capture
        // time) so `withDependencies` overrides reach the auth closure. Signs
        // through `identityClient.sign`, which covers BOTH local-key identities
        // and bunker (NIP-46) identities — a bunker user has no local secret, so
        // the old `currentSecret()`-only path silently failed AUTH-required
        // relays for them (empty lookups on private relays).
        let auth: @Sendable (String, String) async -> String? = { challenge, relayURL in
            let deps = DependencyValues._current
            let identityLoaded = deps.identityClient.loadIdentity() != nil
            let frame = await RelayAuth.authFrame(
                challenge: challenge, relayURL: relayURL, sign: deps.identityClient.sign
            )
            RelayLog.debug("auth requested by \(relayURL): identityLoaded=\(identityLoaded) frameBuilt=\(frame != nil)")
            return frame
        }
        return RelayClient(
            subscribe: { filter in
                AsyncStream { continuation in
                    let relays = filter.relays ?? Self.resolveRelays()
                    RelayLog.debug("subscribe: relays=\(relays) filter=\(filter.jsonObject)")
                    let subID = "shep-" + UUID().uuidString.lowercased().prefix(8)
                    let task = RelaySubscriptionTask(
                        relays: relays, filter: filter, subID: String(subID), auth: auth
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
                await RelayPublisher.publish(event, auth: auth)
            }
        )
    }()

    public static let testValue = RelayClient(
        subscribe: { _ in AsyncStream { _ in } },
        reachableRelays: { _ in [] },
        publish: { _ in .failed }
    )

    /// Resolve relay URLs: in-app Settings list (UserDefaults, `FR-sri-relay-settings`),
    /// then NOSTR_RELAYS env, then ~/.config/nostr/relays.txt, then the defaults.
    /// In-app list takes highest precedence, mirroring Identity's Keychain-first
    /// precedence: the reviewer's most recent explicit in-app choice wins.
    public static func resolveRelays() -> [String] {
        if let saved = configuredRelays(), !saved.isEmpty { return saved }
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
        return Self.defaultRelays
    }

    /// Default public relay set, shared by macOS fallback and the iOS "use defaults"
    /// toggle (`FR-sri-relay-settings`).
    public static let defaultRelays = ["wss://relay.damus.io", "wss://nos.lol", "wss://relay.nostr.band"]

    /// UserDefaults key for the in-app configured relay list (`FR-sri-relay-settings`).
    /// Relay URLs are preferences, not secrets, so UserDefaults (not Keychain).
    public static let relaysDefaultsKey = "shepherd.relays"

    /// The in-app saved relay list, or nil when "use defaults" is active.
    public static func configuredRelays() -> [String]? {
        UserDefaults.standard.stringArray(forKey: relaysDefaultsKey)
    }

    /// Persist (nil clears to defaults) the in-app relay list.
    public static func saveConfiguredRelays(_ relays: [String]?) {
        if let relays, !relays.isEmpty {
            UserDefaults.standard.set(relays, forKey: relaysDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: relaysDefaultsKey)
        }
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
    /// NIP-42 AUTH frame builder: (challenge, relayURL) -> `["AUTH", {event}]` JSON,
    /// or nil when no reviewer identity is available. Async because a bunker
    /// identity signs remotely over NIP-46. Implements NIP-42 relay auth.
    let auth: @Sendable (String, String) async -> String?
    private let session = URLSession(configuration: .ephemeral)
    private var tasks: [URLSessionWebSocketTask] = []
    private let lock = NSLock()
    private var seen = Set<String>()
    private var reqString: String = ""

    init(relays: [String], filter: NostrFilter, subID: String, auth: @escaping @Sendable (String, String) async -> String?, onEvent: @escaping @Sendable (NostrEvent) -> Void) {
        self.relays = relays
        self.filter = filter
        self.subID = subID
        self.auth = auth
        self.onEvent = onEvent
    }

    func start() {
        let reqFrame: [Any] = ["REQ", subID, filter.jsonObject]
        guard let reqData = try? JSONSerialization.data(withJSONObject: reqFrame),
              let reqString = String(data: reqData, encoding: .utf8) else { return }
        self.reqString = reqString
        for url in relays {
            guard let URL = URL(string: url) else { continue }
            let task = session.webSocketTask(with: URL)
            tasks.append(task)
            task.resume()
            Task { [weak self] in
                // Send the REQ frame; tolerate send failure (relay may reject).
                RelayLog.debug("\(url) -> \(reqString)")
                try? await task.send(.string(reqString))
                await self?.receiveLoop(task: task, relayURL: url)
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

    private func receiveLoop(task: URLSessionWebSocketTask, relayURL: String) async {
        while task.closeCode == .invalid {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    await handleFrame(text, task: task, relayURL: relayURL)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        await handleFrame(text, task: task, relayURL: relayURL)
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

    private func handleFrame(_ text: String, task: URLSessionWebSocketTask, relayURL: String) async {
        RelayLog.debug("\(relayURL) <- \(text.prefix(200))")
        guard let data = text.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              array.count >= 2,
              let type = array[0] as? String else { return }
        switch type {
        case "AUTH":
            // NIP-42: sign challenge, re-send REQ.
            guard let challenge = array[1] as? String,
                  let frame = await auth(challenge, relayURL) else { return }
            try? await task.send(.string(frame))
            if !reqString.isEmpty { try? await task.send(.string(reqString)) }
        case "CLOSED":
            // ["CLOSED", subID, message] — an `auth-required` rejection means
            // this socket is poisoned for reading: ngit-style relays ignore ALL
            // later frames on a connection whose pre-auth REQ was rejected —
            // even a valid AUTH frame sent afterwards gets no response, so the
            // AUTH re-send above never recovers. Reconnect on a fresh socket and
            // authenticate BEFORE sending the REQ (auth-first handshake).
            guard array.count >= 3,
                  let closedSub = array[1] as? String, closedSub == subID,
                  let message = array[2] as? String,
                  message.hasPrefix("auth-required") else { return }
            RelayLog.debug("auth-required rejection from \(relayURL); reconnecting auth-first")
            await reconnectAuthFirst(relayURL: relayURL)
        case "EVENT":
            // ["EVENT", subID, eventObject]
            guard array.count >= 3, let eventObject = array[2] as? [String: Any] else { return }
            guard let id = eventObject["id"] as? String else { return }
            guard recordSeen(id) else { return }
            guard let event = decodeEvent(eventObject) else { return }
            onEvent(event)
        default:
            break // NOTICE (incl. auth-required), OK, EOSE, etc. — ignored.
        }
    }

    /// Reconnect to `relayURL` on a fresh socket and run the NIP-42 handshake
    /// BEFORE sending the REQ. Used after an `auth-required` CLOSED: relays that
    /// reject a pre-auth REQ (e.g. ngit's relay) ignore every subsequent frame on
    /// that connection — including the AUTH response — so the only recovery is a
    /// fresh connection where the first client frame after the challenge is the
    /// signed AUTH. If the new connection presents no challenge within a short
    /// budget (relay policy changed), falls back to an optimistic REQ.
    private func reconnectAuthFirst(relayURL: String) async {
        guard let url = URL(string: relayURL), !reqString.isEmpty else { return }
        let task = session.webSocketTask(with: url)
        addTask(task)
        task.resume()
        guard let challenge = await firstAuthChallenge(task) else {
            RelayLog.debug("reconnect: no AUTH challenge within budget; sending optimistic REQ")
            try? await task.send(.string(reqString))
            await receiveLoop(task: task, relayURL: relayURL)
            return
        }
        guard let frame = await auth(challenge, relayURL) else {
            RelayLog.debug("reconnect: AUTH frame build failed (no identity?) — giving up on \(relayURL)")
            return
        }
        try? await task.send(.string(frame))
        try? await task.send(.string(reqString))
        RelayLog.debug("reconnect: sent AUTH + REQ on fresh socket to \(relayURL)")
        await receiveLoop(task: task, relayURL: relayURL)
    }

    /// Wait for the relay's initial `["AUTH", challenge]` frame (NIP-42 relays
    /// send it on connect), up to a 3s budget. Returns nil on timeout or when
    /// the first frame is anything else. Consumes the first frame either way.
    private func firstAuthChallenge(_ task: URLSessionWebSocketTask) async -> String? {
        await withTaskGroup(of: String?.self) { group in
            group.addTask {
                guard let message = try? await task.receive(),
                      case .string(let text) = message,
                      let data = text.data(using: .utf8),
                      let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
                      array.count >= 2,
                      array[0] as? String == "AUTH",
                      let challenge = array[1] as? String else { return nil }
                return challenge
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result ?? nil
        }
    }

    /// Register a socket for later cancellation. Synchronous so the NSLock
    /// stays out of async context.
    private func addTask(_ task: URLSessionWebSocketTask) {
        lock.lock()
        defer { lock.unlock() }
        tasks.append(task)
    }

    /// Dedup-by-id gate. Synchronous so the NSLock stays out of async context.
    private func recordSeen(_ id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return seen.insert(id).inserted
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
    static func publish(_ event: NostrEvent, auth: @escaping @Sendable (String, String) async -> String?) async -> PublishResult {
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
                    await self.publishToOne(url: URL, frame: frameString, eventID: event.id, session: session, auth: auth, relayURL: url)
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
    private static func publishToOne(url: URL, frame: String, eventID: String, session: URLSession, auth: @escaping @Sendable (String, String) async -> String?, relayURL: String) async -> Bool? {
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
                guard let text else { continue }
                if let outcome = parseOK(text, eventID: eventID) {
                    task.cancel()
                    return outcome
                }
                // NIP-42: sign challenge, re-send EVENT.
                if let authFrame = await parseAuthChallenge(text, relayURL: relayURL, auth: auth) {
                    try? await task.send(.string(authFrame))
                    try? await task.send(.string(frame))
                }
            } catch {
                task.cancel()
                return nil
            }
        }
        task.cancel()
        return nil
    }

    /// If `text` is a `["AUTH", challenge]` frame, return the signed
    /// `["AUTH", {event}]` response for `relayURL` (or nil if no key/unparseable).
    private static func parseAuthChallenge(_ text: String, relayURL: String, auth: @escaping @Sendable (String, String) async -> String?) async -> String? {
        guard let data = text.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              array.count >= 2,
              array[0] as? String == "AUTH",
              let challenge = array[1] as? String else { return nil }
        return await auth(challenge, relayURL)
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

/// NIP-42 relay AUTH. Builds and signs the kind-22242 challenge-response event
/// and serializes the `["AUTH", {event}]` frame. Returns nil when no secret key
/// is configured or signing fails, so the caller falls back to unauthenticated
/// behavior (public relays keep working). Implements NIP-42 relay auth.
enum RelayAuth {
    /// Unsigned kind-22242 challenge-response event for a NIP-42 `AUTH`
    /// challenge. Shared by the local-key and bunker sign paths.
    static func authEvent(challenge: String, relayURL: String) -> NostrEvent {
        NostrEvent(
            id: "", pubkey: "", kind: 22242, content: "",
            tags: [["challenge", challenge], ["relay", relayURL]],
            createdAt: Int64(Date().timeIntervalSince1970)
        )
    }

    /// `["AUTH", {event}]` frame JSON for a signed kind-22242 event.
    static func frame(for signed: NostrEvent) -> String? {
        let dict: [String: Any] = [
            "id": signed.id, "pubkey": signed.pubkey, "created_at": signed.createdAt,
            "kind": signed.kind, "tags": signed.tags, "content": signed.content, "sig": signed.sig,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: ["AUTH", dict]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// `["AUTH", {event}]` frame for `challenge`+`relayURL`, signed via an
    /// async signer covering both identity forms — `identityClient.sign` signs
    /// locally for a key identity and remotely (NIP-46) for a bunker identity.
    /// Returns nil when no identity is loaded or signing fails.
    static func authFrame(challenge: String, relayURL: String, sign: @escaping @Sendable (NostrEvent) async -> NostrEvent?) async -> String? {
        guard let signed = await sign(authEvent(challenge: challenge, relayURL: relayURL)) else { return nil }
        return frame(for: signed)
    }

    /// `["AUTH", {event}]` frame for `challenge`+`relayURL`, signed locally
    /// with `secret` via `signer`, or nil. Local-key path (BunkerClient).
    static func authFrame(challenge: String, relayURL: String, secret: Data?, signer: NostrSigner) -> String? {
        guard let secret else { return nil }
        guard let signed = signer.sign(authEvent(challenge: challenge, relayURL: relayURL), secret) else { return nil }
        return frame(for: signed)
    }
}

/// Opt-in debug logging for the relay client. Silent by default (the app ships
/// with no console spam); set `SHEPHERD_RELAY_DEBUG=1` in the environment to
/// trace relay frames, NIP-42 auth, and subscription events to stdout. Intended
/// for diagnosing auth-required relay issues in the field.
public enum RelayLog {
    /// Env var (`SHEPHERD_RELAY_DEBUG=1`) or persisted default
    /// (`defaults write com.shepherd.app shepherd.relayDebug -bool true`) — the
    /// UserDefaults path survives launches from Finder/Xcode where env vars
    /// don't propagate.
    public static let enabled: Bool = {
        if let s = ProcessInfo.processInfo.environment["SHEPHERD_RELAY_DEBUG"], ["1", "true", "yes"].contains(s.lowercased()) { return true }
        return UserDefaults.standard.bool(forKey: "shepherd.relayDebug")
    }()
    public static func debug(_ message: @autoclosure () -> String) {
        guard enabled else { return }
        print("[relay] \(message())")
    }
}

/// Reachability probe for the Open Patch dialog and PR Browse. Implements:
/// FR-srm-patch-open-fetch (the no-relays-reachable guard). A relay is
/// reachable if it answers a minimal REQ with any NIP-01 frame within a 5s
/// budget. ponytail: fixed budget per relay; an adaptive RTT estimate is not
/// worth it for a one-shot gate.
/// NIP-42: the probe deliberately does NOT authenticate — AUTH-required relays
/// answer the probe with an AUTH challenge (proof of reachability), then
/// `RelaySubscriptionTask`/`RelayPublisher` authenticate on their own sockets
/// before the real REQ/EVENT.
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

    /// Probe one relay. Returns its URL string if the relay proves it speaks
    /// NIP-01 within the budget: the probe opens a socket, sends a minimal REQ,
    /// and treats ANY frame back (AUTH, NOTICE, EOSE, EVENT, CLOSED) as
    /// reachable. This is deliberately not a `sendPing`: AUTH-required relays
    /// abort pings from unauthenticated sockets (NIP-42), which both broke the
    /// probe and, before the ping bridge was once-guarded, crashed the app
    /// (`SWIFT TASK CONTINUATION MISUSE`) when the abort raced the timeout.
    /// The subscription task does the real AUTH on its own socket afterwards.
    private static func probeOne(url: URL, session: URLSession) async -> String? {
        let task = session.webSocketTask(with: url)
        task.resume()
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                do {
                    try await task.send(.string(#"["REQ","probe",{"kinds":[1],"limit":1}]"#))
                    _ = try await task.receive() // first frame = reachable
                    return true
                } catch {
                    return false
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                return false
            }
            let reachable = (await group.next()) ?? false
            group.cancelAll()
            task.cancel(with: .goingAway, reason: nil)
            return reachable ? url.absoluteString : nil
        }
    }

}
