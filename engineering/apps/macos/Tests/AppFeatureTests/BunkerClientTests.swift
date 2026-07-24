import Testing
import Foundation
import ComposableArchitecture
@testable import ShepherdDependencies
@testable import SharedModels

/// Implements: TC-srm-bunker-sign, TC-srm-bunker-sign-failure, TC-srm-bunker-connect
/// — tests the bunker sign path through the real LoadedIdentity with an
/// injectable mock BunkerClient (enabled by routing through @Dependency).
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

    /// A bunker identity with the initial .connecting state.
    private func bunkerIdentity() -> ReviewerIdentity {
        ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "Connecting…",
            source: .bunker, bunkerState: .connecting, bunkerRelayURL: testConfig.relayURL
        )
    }

    @Test("Bunker sign returns the bunker's signed event")
    func bunkerSignSuccess() async throws {
        let bunkerClient = BunkerClient(
            connect: { _ in testPubkey },
            signEvent: { _ in Self.signedEvent },
            connectionState: { .connected },
            close: {}
        )
        let loaded = LoadedIdentity.bunker(config: testConfig, bunkerClient: bunkerClient)

        let pubkey = try #require(await loaded.connectBunker())
        #expect(pubkey == testPubkey)

        let unsigned = NostrEvent(
            id: "", pubkey: "", kind: 1, content: "hello", tags: [], createdAt: 1700000000
        )
        let signed = try #require(await loaded.sign(unsigned))
        #expect(signed.id == Self.signedEvent.id)
        #expect(signed.sig == Self.signedEvent.sig)
    }

    @Test("Bunker sign failure returns nil (no host secret key used)")
    func bunkerSignFailure() async throws {
        let bunkerClient = BunkerClient(
            connect: { _ in testPubkey },
            signEvent: { _ in nil },
            connectionState: { .failed("bunker down") },
            close: {}
        )
        let loaded = LoadedIdentity.bunker(config: testConfig, bunkerClient: bunkerClient)
        _ = try #require(await loaded.connectBunker())

        let unsigned = NostrEvent(
            id: "", pubkey: "", kind: 1, content: "hello", tags: [], createdAt: 1700000000
        )
        #expect(await loaded.sign(unsigned) == nil, "bunker sign failure must return nil, not a locally-signed event")
    }

    @Test("Bunker connect failure: no pubkey, state is .failed")
    func bunkerConnectFailure() async throws {
        let bunkerClient = BunkerClient(
            connect: { _ in nil },
            signEvent: { _ in nil },
            connectionState: { .failed("unreachable") },
            close: {}
        )
        let loaded = LoadedIdentity.bunker(config: testConfig, bunkerClient: bunkerClient)

        #expect(await loaded.connectBunker() == nil)
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
        // Local key identity — secret is set, bunkerConfig is nil.
        let secret = Data(repeating: 1, count: 32)
        let identity = ReviewerIdentity(
            pubkeyHex: testPubkey, npub: "npub1test", displayName: "test", source: .localKey
        )
        let loaded = LoadedIdentity(
            identity: identity, secret: secret, bunkerConfig: nil, bunkerClient: bunkerClient
        )

        let unsigned = NostrEvent(
            id: "", pubkey: "", kind: 1, content: "hello", tags: [], createdAt: 1700000000
        )
        let signed = try #require(await loaded.sign(unsigned))
        #expect(!bunkerCalled.get(), "bunker signEvent must not be called for a local-key identity")
        #expect(signed.pubkey != "", "local key must sign in-process")
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
        let loaded = LoadedIdentity.bunker(config: testConfig, bunkerClient: bunkerClient)
        loaded.closeBunker()
        #expect(closeCalled.get())
    }
}

/// Sendable mutable bool for test assertions across concurrency boundaries.
private final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    func set(_ b: Bool) { lock.lock(); value = b; lock.unlock() }
    func get() -> Bool { lock.lock(); defer { lock.unlock() }; return value }
}
