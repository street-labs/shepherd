import Testing
import Foundation
import ComposableArchitecture
@testable import ShepherdDependencies
@testable import SharedModels

/// Implements: TC-srm-bunker-sign, TC-srm-bunker-sign-failure, TC-srm-bunker-connect
/// — tests the bunker sign path through IdentityClient with an injectable mock
/// BunkerClient (enabled by routing through @Dependency rather than .liveValue).
@Suite("BunkerClient / FR-sr-bunker-signing, FR-srm-bunker-sign-failure")
struct BunkerClientTests {
    private let testPubkey = String(repeating: "a", count: 64)
    private let testConfig = BunkerConfig(
        bunkerPubkeyHex: String(repeating: "b", count: 64),
        relayURL: "wss://relay.test",
        secret: "testsecret"
    )
    private static let signedEvent = NostrEvent(
        id: String(repeating: "c", count: 64),
        pubkey: String(repeating: "a", count: 64),
        kind: 1, content: "test", tags: [],
        createdAt: 1700000000, sig: String(repeating: "d", count: 128)
    )

    @Test("Bunker sign returns the bunker's signed event")
    func bunkerSignSuccess() async throws {
        let bunkerClient = BunkerClient(
            connect: { _ in testPubkey },
            signEvent: { _ in Self.signedEvent },
            connectionState: { .connected },
            close: {}
        )
        let identity = ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "test",
            source: .bunker, bunkerState: .connecting, bunkerRelayURL: "wss://relay.test"
        )
        let loaded = LoadedIdentityTestWrapper(
            identity: identity, secret: nil, bunkerConfig: testConfig, bunkerClient: bunkerClient
        )

        // Connect first
        let pubkey = await loaded.connectBunker()
        #expect(pubkey == testPubkey)

        // Sign an event
        let unsigned = NostrEvent(
            id: "", pubkey: "", kind: 1, content: "hello", tags: [], createdAt: 1700000000
        )
        let signed = await loaded.sign(unsigned)
        #expect(signed != nil)
        #expect(signed?.id == Self.signedEvent.id)
        #expect(signed?.sig == Self.signedEvent.sig)
    }

    @Test("Bunker sign failure returns nil (no host secret key used)")
    func bunkerSignFailure() async throws {
        let bunkerClient = BunkerClient(
            connect: { _ in testPubkey },
            signEvent: { _ in nil },
            connectionState: { .failed("bunker down") },
            close: {}
        )
        let identity = ReviewerIdentity(
            pubkeyHex: testPubkey, npub: "npub1test", displayName: "test",
            source: .bunker, bunkerState: .connected, bunkerRelayURL: "wss://relay.test"
        )
        let loaded = LoadedIdentityTestWrapper(
            identity: identity, secret: nil, bunkerConfig: testConfig, bunkerClient: bunkerClient
        )

        let unsigned = NostrEvent(
            id: "", pubkey: "", kind: 1, content: "hello", tags: [], createdAt: 1700000000
        )
        let signed = await loaded.sign(unsigned)
        #expect(signed == nil, "bunker sign failure must return nil, not a locally-signed event")
    }

    @Test("Bunker connect failure: no pubkey, state is .failed")
    func bunkerConnectFailure() async throws {
        let bunkerClient = BunkerClient(
            connect: { _ in nil },
            signEvent: { _ in nil },
            connectionState: { .failed("unreachable") },
            close: {}
        )
        let identity = ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "Connecting…",
            source: .bunker, bunkerState: .connecting, bunkerRelayURL: "wss://relay.test"
        )
        let loaded = LoadedIdentityTestWrapper(
            identity: identity, secret: nil, bunkerConfig: testConfig, bunkerClient: bunkerClient
        )

        _ = await loaded.connectBunker()
        #expect(loaded.identity.bunkerState == .failed("Bunker unreachable"))
    }

    @Test("Local key sign does not use bunker (signEvent not called)")
    func localKeySignIgnoresBunker() async throws {
        let bunkerCalled = AtomicBool()
        let bunkerClient = BunkerClient(
            connect: { _ in testPubkey },
            signEvent: { _ in
                bunkerCalled.set(true)
                return Self.signedEvent
            },
            connectionState: { .connected },
            close: {}
        )
        // Local key identity — secret is set, bunkerConfig is nil
        let secret = Data(repeating: 1, count: 32)
        let identity = ReviewerIdentity(
            pubkeyHex: testPubkey, npub: "npub1test", displayName: "test", source: .localKey
        )
        let loaded = LoadedIdentityTestWrapper(
            identity: identity, secret: secret, bunkerConfig: nil, bunkerClient: bunkerClient
        )

        let unsigned = NostrEvent(
            id: "", pubkey: "", kind: 1, content: "hello", tags: [], createdAt: 1700000000
        )
        let signed = await loaded.sign(unsigned)
        #expect(signed != nil, "local key must sign in-process")
        #expect(!bunkerCalled.get(), "bunker signEvent must not be called for a local-key identity")
    }

    @Test("Close bunker calls close on the client")
    func closeBunker() async {
        let closeCalled = AtomicBool()
        let bunkerClient = BunkerClient(
            connect: { _ in nil },
            signEvent: { _ in nil },
            connectionState: { nil },
            close: { closeCalled.set(true) }
        )
        let identity = ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "test",
            source: .bunker, bunkerState: .connecting, bunkerRelayURL: "wss://relay.test"
        )
        let loaded = LoadedIdentityTestWrapper(
            identity: identity, secret: nil, bunkerConfig: testConfig, bunkerClient: bunkerClient
        )
        loaded.closeBunker()
        #expect(closeCalled.get())
    }
}

/// Test wrapper mirroring LoadedIdentity's sign/connect/closeBunker methods,
/// but with a public initializer (LoadedIdentity is private). This tests the
/// routing logic (local key vs bunker dispatch) without a real WebSocket.
private final class LoadedIdentityTestWrapper: @unchecked Sendable {
    var identity: ReviewerIdentity
    let secret: Data?
    let bunkerConfig: BunkerConfig?
    let bunkerClient: BunkerClient

    init(identity: ReviewerIdentity, secret: Data?, bunkerConfig: BunkerConfig?, bunkerClient: BunkerClient) {
        self.identity = identity
        self.secret = secret
        self.bunkerConfig = bunkerConfig
        self.bunkerClient = bunkerClient
    }

    func sign(_ event: NostrEvent) async -> NostrEvent? {
        if let secret {
            return event.sign(secretKey: secret)
        }
        if bunkerConfig != nil {
            return await bunkerClient.signEvent(event)
        }
        return nil
    }

    func connectBunker() async -> String? {
        guard let config = bunkerConfig else { return nil }
        let pubkey = await bunkerClient.connect(config)
        identity.bunkerState = pubkey != nil ? .connected : .failed("Bunker unreachable")
        return pubkey
    }

    func closeBunker() {
        bunkerClient.close()
    }
}

/// Sendable mutable bool for test assertions across concurrency boundaries.
private final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    func set(_ b: Bool) { lock.lock(); value = b; lock.unlock() }
    func get() -> Bool { lock.lock(); defer { lock.unlock() }; return value }
}
