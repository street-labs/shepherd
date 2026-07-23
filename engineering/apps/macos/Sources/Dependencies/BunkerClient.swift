import Foundation
import Security
import ComposableArchitecture
import P256K
import SharedModels

/// NIP-46 bunker control channel: delegates event signing to a remote signer
/// over a Nostr relay, so the reviewer's secret key never touches the host.
// Implements: FR-srm-bunker-connect, FR-srm-bunker-sign-failure, FR-sr-bunker-signing
///
/// The live value opens a WebSocket to the bunker relay (reusing the
/// `URLSessionWebSocketTask` transport pattern from `RelayClient`), sends
/// NIP-44-encrypted kind `24133` requests, and awaits encrypted responses.
/// `connect` runs the handshake + `get_public_key`; `signEvent` sends a
/// `sign_event` request per reply. The control channel stays open for the
/// review window's life. `testValue` is an injectable mock bunker.
@DependencyClient
public struct BunkerClient: Sendable {
    /// Run the NIP-46 connect handshake + get_public_key. Returns the reviewer's
    /// (user) pubkey hex on success, nil on failure.
    public var connect: @Sendable (BunkerConfig) async -> String?
    /// Send a sign_event request to the bunker. Returns the bunker's signed
    /// event, or nil if the bunker is unreachable/refuses/times out.
    public var signEvent: @Sendable (NostrEvent) async -> NostrEvent?
    /// The current connection state for the identity indicator. nil when no
    /// bunker session has been started.
    public var connectionState: @Sendable () -> BunkerConnectionState?
}

/// Parsed `bunker://` URI parameters.
public struct BunkerConfig: Sendable, Equatable {
    public let bunkerPubkeyHex: String
    public let relayURL: String
    public let secret: String?

    public init(bunkerPubkeyHex: String, relayURL: String, secret: String?) {
        self.bunkerPubkeyHex = bunkerPubkeyHex
        self.relayURL = relayURL
        self.secret = secret
    }

    /// Parse a `bunker://<pubkey>?relay=<url>[&secret=<token>]` URI.
    /// Returns nil on a malformed URI (missing relay, bad scheme, unparseable pubkey).
    /// Extra `relay=` params are accepted-but-ignored (first one wins).
    public static func parse(_ uri: String) -> BunkerConfig? {
        guard uri.hasPrefix("bunker://") else { return nil }
        let withoutScheme = String(uri.dropFirst("bunker://".count))
        guard let questionIdx = withoutScheme.firstIndex(of: "?") else { return nil }
        let pubkeyPart = String(withoutScheme[..<questionIdx])
        let queryPart = String(withoutScheme[questionIdx...].dropFirst())
        guard pubkeyPart.count == 64, pubkeyPart.allSatisfy({ $0.isHexDigit }) else { return nil }

        guard let comps = URLComponents(string: "https://x?" + queryPart) else { return nil }
        let items = comps.queryItems ?? []
        guard let relay = items.first(where: { $0.name == "relay" })?.value, !relay.isEmpty else {
            return nil
        }
        let secret = items.first(where: { $0.name == "secret" })?.value
        return BunkerConfig(bunkerPubkeyHex: pubkeyPart, relayURL: relay, secret: secret)
    }
}

extension BunkerClient: DependencyKey {
    public static let liveValue = BunkerClient(
        connect: { config in
            await BunkerSession.shared.connect(config: config)
        },
        signEvent: { event in
            await BunkerSession.shared.signEvent(event: event)
        },
        connectionState: {
            BunkerSession.shared.getState()
        }
    )

    public static let testValue = BunkerClient(
        connect: { _ in nil },
        signEvent: { _ in nil },
        connectionState: { nil }
    )
}

extension DependencyValues {
    public var bunkerClient: BunkerClient {
        get { self[BunkerClient.self] }
        set { self[BunkerClient.self] = newValue }
    }
}

// MARK: - BunkerSession
//
// Manages the NIP-46 WebSocket control channel. Shared (singleton) because the
// identity is loaded once per process and the session persists for the app's
// life. ponytail: singleton is fine for a desktop app with one identity; a
// per-window session would be over-engineering until multi-window matters.
// Uses NSLock wrapped in sync helpers to satisfy Swift 6.2's async-context
// lock restriction.

private final class BunkerSession: @unchecked Sendable {
    static let shared = BunkerSession()

    private let lock = NSLock()
    private var sessionKey: Data?
    private var sessionPubkeyHex: String?
    private var bunkerPubkeyHex: String?
    private var conversationKey: Data?
    private var reviewerPubkeyHex: String?
    private var wsTask: URLSessionWebSocketTask?
    private var urlSession = URLSession(configuration: .ephemeral)
    private var pending: [String: CheckedContinuation<String?, Never>] = [:]
    private var receiveTask: Task<Void, Never>?
    private var _state: BunkerConnectionState? = nil

    // Sync lock helpers — callable from async contexts because the lock/unlock
    // calls are inside a sync function, not directly in an async function.
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    func getState() -> BunkerConnectionState? {
        withLock { _state }
    }

    private func setState(_ s: BunkerConnectionState?) {
        withLock { _state = s }
    }

    /// Connect to the bunker and run the NIP-46 handshake. Returns the reviewer's
    /// pubkey hex on success, nil on failure.
    // Implements: FR-srm-bunker-connect
    func connect(config: BunkerConfig) async -> String? {
        guard let (secKey, pubHex) = generateSessionKey() else {
            setState(.failed("couldn't generate session key"))
            return nil
        }
        withLock {
            self.sessionKey = secKey
            self.sessionPubkeyHex = pubHex
            self.bunkerPubkeyHex = config.bunkerPubkeyHex
        }
        setState(.connecting)

        guard let bunkerPub = Data(hexString: config.bunkerPubkeyHex),
              let convKey = NIP44Crypto.conversationKey(privateKey: secKey, peerPubkey: bunkerPub) else {
            setState(.failed("couldn't derive conversation key"))
            return nil
        }
        withLock { self.conversationKey = convKey }

        guard let url = URL(string: config.relayURL) else {
            setState(.failed("invalid relay URL"))
            return nil
        }
        let task = urlSession.webSocketTask(with: url)
        withLock { self.wsTask = task }
        task.resume()

        let subID = "bunker-" + pubHex.prefix(8)
        let reqFrame: [Any] = ["REQ", subID, ["#p": [pubHex], "kinds": [24133]]]
        if let reqData = try? JSONSerialization.data(withJSONObject: reqFrame),
           let reqString = String(data: reqData, encoding: .utf8) {
            try? await task.send(.string(reqString))
        }

        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }

        // Send connect request
        let clientMetadata = "{\"name\":\"Shepherd\"}"
        let connectParams: [String] = [config.bunkerPubkeyHex, config.secret ?? "", "", clientMetadata]
        guard let _ = await sendRequest(method: "connect", params: connectParams) else {
            setState(.failed("bunker didn't respond to connect"))
            return nil
        }

        // Send get_public_key request
        guard let pubkeyResp = await sendRequest(method: "get_public_key", params: []) else {
            setState(.failed("bunker didn't respond to get_public_key"))
            return nil
        }

        withLock { self.reviewerPubkeyHex = pubkeyResp }
        setState(.connected)
        return pubkeyResp
    }

    /// Send a sign_event request to the bunker. Returns the signed event, or nil.
    // Implements: FR-sr-bunker-signing, FR-srm-bunker-sign-failure
    func signEvent(event: NostrEvent) async -> NostrEvent? {
        guard getState() == .connected else { return nil }
        let eventDict: [String: Any] = [
            "content": event.content,
            "kind": event.kind,
            "tags": event.tags,
            "created_at": event.createdAt,
        ]
        guard let eventJSON = try? JSONSerialization.data(withJSONObject: eventDict),
              let eventString = String(data: eventJSON, encoding: .utf8) else { return nil }

        guard let resp = await sendRequest(method: "sign_event", params: [eventString]) else {
            setState(.failed("bunker didn't respond to sign_event"))
            return nil
        }

        guard let respData = resp.data(using: .utf8),
              let signed = try? JSONSerialization.jsonObject(with: respData) as? [String: Any],
              let id = signed["id"] as? String,
              let pubkey = signed["pubkey"] as? String,
              let sig = signed["sig"] as? String,
              let kind = signed["kind"] as? Int,
              let content = signed["content"] as? String,
              let tags = signed["tags"] as? [[Any]] else {
            return nil
        }
        let createdAt: Int64 = {
            if let v = signed["created_at"] as? Int { return Int64(v) }
            if let v = signed["created_at"] as? Int64 { return v }
            if let v = signed["created_at"] as? NSNumber { return v.int64Value }
            return 0
        }()
        return NostrEvent(
            id: id, pubkey: pubkey, kind: kind, content: content,
            tags: tags.map { $0.map { "\($0)" } }, createdAt: createdAt, sig: sig
        )
    }

    // MARK: - Private

    private func generateSessionKey() -> (Data, String)? {
        var key = Data(count: 32)
        let result = key.withUnsafeMutableBytes { buf -> Int32 in
            guard let base = buf.baseAddress else { return -1 }
            return SecRandomCopyBytes(kSecRandomDefault, 32, base)
        }
        guard result == errSecSuccess else { return nil }
        guard let pubHex = NostrSigner.derivePublicKey(key) else { return nil }
        return (key, pubHex)
    }

    private func sendRequest(method: String, params: [String]) async -> String? {
        let secKey = withLock { sessionKey }
        let pubHex = withLock { sessionPubkeyHex }
        let bunkerHex = withLock { bunkerPubkeyHex }
        let convKey = withLock { conversationKey }
        let task = withLock { wsTask }
        guard let secKey, let pubHex, let bunkerHex, let convKey, let task else { return nil }

        let requestID = UUID().uuidString.prefix(16).description
        let rpc: [String: Any] = ["id": requestID, "method": method, "params": params]
        guard let rpcJSON = try? JSONSerialization.data(withJSONObject: rpc),
              let rpcString = String(data: rpcJSON, encoding: .utf8) else { return nil }

        guard let encrypted = NIP44Crypto.encrypt(
            rpcString, conversationKey: convKey, nonce: NIP44Crypto.randomBytes(32)
        ) else { return nil }

        let event = NostrEvent(
            id: "", pubkey: pubHex, kind: 24133, content: encrypted,
            tags: [["p", bunkerHex]], createdAt: Int64(Date().timeIntervalSince1970)
        )
        guard let signed = event.sign(secretKey: secKey) else { return nil }

        let frame: [Any] = ["EVENT", signed.eventJSONObject]
        guard let frameData = try? JSONSerialization.data(withJSONObject: frame),
              let frameString = String(data: frameData, encoding: .utf8) else { return nil }
        try? await task.send(.string(frameString))

        return await withCheckedContinuation { continuation in
            withLock { pending[requestID] = continuation }
            // Timeout: resolve with nil after 10 seconds.
            // ponytail: fixed 10s budget; a per-method adaptive timeout is not worth it.
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(10))
                self?.resolveRequest(requestID, with: nil)
            }
        }
    }

    private func resolveRequest(_ id: String, with result: String?) {
        let cont = withLock { pending.removeValue(forKey: id) }
        cont?.resume(returning: result)
    }

    private func receiveLoop() async {
        let task = withLock { wsTask }
        guard let task else { return }
        while task.closeCode == .invalid {
            do {
                let message = try await task.receive()
                let text: String? = switch message {
                case .string(let s): s
                case .data(let d): String(data: d, encoding: .utf8)
                @unknown default: nil
                }
                guard let text else { continue }
                handleResponse(text)
            } catch {
                return
            }
        }
    }

    private func handleResponse(_ text: String) {
        let convKey = withLock { conversationKey }
        guard let convKey else { return }
        guard let data = text.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              array.count >= 3,
              array[0] as? String == "EVENT",
              let eventObj = array[2] as? [String: Any],
              let kind = eventObj["kind"] as? Int, kind == 24133,
              let content = eventObj["content"] as? String,
              let decrypted = NIP44Crypto.decrypt(content, conversationKey: convKey),
              let respData = decrypted.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: respData) as? [String: Any],
              let respID = resp["id"] as? String else { return }

        if let error = resp["error"] as? String, !error.isEmpty {
            resolveRequest(respID, with: nil)
            return
        }
        if let result = resp["result"] as? String {
            resolveRequest(respID, with: result)
        }
    }
}

// MARK: - NostrEvent JSON serialization helper

private extension NostrEvent {
    var eventJSONObject: [String: Any] {
        [
            "id": id,
            "pubkey": pubkey,
            "created_at": createdAt,
            "kind": kind,
            "tags": tags,
            "content": content,
            "sig": sig,
        ]
    }
}
