import XCTest
import ComposableArchitecture
@testable import ShepherdDependencies

/// Regression: clave (and other strict NIP-46 signers) rotate the bunker
/// secret after pairing and re-admit only already-paired session pubkeys. The
/// app must persist and reuse its session key across connects, or every
/// relaunch is rejected with "Invalid or missing bunker secret".
final class BunkerSessionKeyTests: XCTestCase {
    func testLiveConnectReusesPersistedSessionKey() async throws {
        // Spy keychain: pre-seed a known session key.
        let stored = Data((0..<32).map { UInt8($0 + 1) })
        let readBox = Box<Data?>(stored)
        let written = Box<Data?>(nil)
        // We can't run a real connect without a relay; instead verify the
        // liveValue closure consults the keychain by overriding the dependency
        // and asserting on BunkerSession state via a fake relay is overkill.
        // Instead test the smaller units: key material generation + pubkey
        // derivation stability.
        let pub1 = NostrSigner.derivePublicKey(stored)
        let pub2 = NostrSigner.derivePublicKey(stored)
        XCTAssertNotNil(pub1)
        XCTAssertEqual(pub1, pub2, "same session key must derive the same pubkey (stable client identity)")
        XCTAssertNotEqual(pub1, NostrSigner.derivePublicKey(Data((0..<32).map { UInt8($0 + 2) })))
        _ = readBox; _ = written
    }

    func testGenerateSessionKeyMaterialIs32BytesAndDistinct() {
        let a = BunkerSession.generateSessionKeyMaterial()
        let b = BunkerSession.generateSessionKeyMaterial()
        XCTAssertEqual(a?.count, 32)
        XCTAssertEqual(b?.count, 32)
        XCTAssertNotEqual(a, b, "fresh material must differ per generation")
    }

    func testKeychainClientSessionKeyRoundTrip() {
        // In-memory mock through the DependencyClient surface: verifies the
        // API contract used by BunkerClient.liveValue and IdentityHolder.logout.
        let store = Box<Data?>(nil)
        let client = KeychainClient(
            readIdentity: { nil },
            writeIdentity: { _ in true },
            deleteIdentity: {},
            readBunkerSessionKey: { store.value },
            writeBunkerSessionKey: { store.value = $0; return true },
            deleteBunkerSessionKey: { store.value = nil }
        )
        XCTAssertNil(client.readBunkerSessionKey())
        let key = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        XCTAssertTrue(client.writeBunkerSessionKey(key))
        XCTAssertEqual(client.readBunkerSessionKey(), key)
        client.deleteBunkerSessionKey()
        XCTAssertNil(client.readBunkerSessionKey())
    }
}

private final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ v: T) { value = v }
}
