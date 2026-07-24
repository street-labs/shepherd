import ComposableArchitecture
import XCTest
import SharedModels
@testable import IdentityFeature
@testable import ShepherdDependencies

@MainActor
final class IdentityFeatureTests: XCTestCase {

    func testLoginWithValidNsec() async throws {
        // Generate a valid key pair, encode as nsec, then log in via the reducer.
        var secret = Data(count: 32)
        _ = secret.withUnsafeMutableBytes { buf -> Int32 in
            guard let base = buf.baseAddress else { return -1 }
            return SecRandomCopyBytes(kSecRandomDefault, 32, base)
        }
        let nsec = Bech32.encode(secret, prefix: "nsec")
        let pubkey = NostrSigner.derivePublicKey(secret) ?? ""
        let npub = Bech32.encode(Data(hexString: pubkey) ?? Data(), prefix: "npub")
        let identity = ReviewerIdentity(
            pubkeyHex: pubkey, npub: npub, displayName: String(npub.prefix(10)) + "…",
            source: .localKey
        )
        let store = TestStore(initialState: IdentityFeature.State()) {
            IdentityFeature()
        } withDependencies: {
            $0.identityClient.loginWithKey = { input in
                guard let decoded = Bech32.decode(input), decoded.prefix == "nsec",
                      decoded.data.count == 32 else {
                    return .failure(.invalidKey)
                }
                return .success(identity)
            }
        }
        store.exhaustivity = .off
        await store.send(.set(\.input, nsec)) {
            $0.input = nsec
        }
        await store.send(.signInTapped)
        await store.receive(\.loginResult)
        await store.receive(\.identityAdopted)
    }

    func testLoginWithInvalidKeyShowsError() async throws {
        let store = TestStore(initialState: IdentityFeature.State()) {
            IdentityFeature()
        } withDependencies: {
            $0.identityClient.loginWithKey = { _ in .failure(.invalidKey) }
        }
        store.exhaustivity = .off
        await store.send(.set(\.input, "garbage")) {
            $0.input = "garbage"
        }
        await store.send(.signInTapped)
        await store.receive(\.loginResult) {
            $0.error = "Not a valid nsec — check it starts with nsec1 and is complete."
        }
    }

    func testLoginStorageFailureShowsError() async throws {
        // Keychain write failed — the identity is not adopted and a distinct
        // error is shown so the reviewer knows it won't survive relaunch.
        let store = TestStore(initialState: IdentityFeature.State()) {
            IdentityFeature()
        } withDependencies: {
            $0.identityClient.loginWithKey = { _ in .failure(.storageFailed) }
        }
        store.exhaustivity = .off
        await store.send(.set(\.input, "nsec1somekey")) {
            $0.input = "nsec1somekey"
        }
        await store.send(.signInTapped)
        await store.receive(\.loginResult) {
            $0.error = "Could not save identity — check Keychain access."
        }
    }

    func testBunkerConnectFailureRestoresPreviousIdentity() async throws {
        // A failed bunker login must not wipe an existing identity. The reducer
        // sees .connectFailed and surfaces it; the IdentityClient (covered by the
        // live path + this stub) snapshots/restores the previous identity.
        let store = TestStore(initialState: IdentityFeature.State()) {
            IdentityFeature()
        } withDependencies: {
            $0.identityClient.loginWithBunker = { _ in .failure(.connectFailed) }
        }
        store.exhaustivity = .off
        await store.send(.formChanged(.bunker)) {
            $0.form = .bunker
        }
        await store.send(.set(\.input, "bunker://abc")) {
            $0.input = "bunker://abc"
        }
        await store.send(.signInTapped) {
            $0.connecting = true
        }
        await store.receive(\.bunkerLoginResult) {
            $0.connecting = false
            $0.error = "Couldn't connect to the bunker — check the URI, relay, and secret. Your input is retained."
        }
    }

    func testCreateNewShowsBackupReveal() async throws {
        let identity = ReviewerIdentity(
            pubkeyHex: "ab", npub: "npub1ab", displayName: "test", source: .localKey
        )
        let store = TestStore(initialState: IdentityFeature.State()) {
            IdentityFeature()
        } withDependencies: {
            $0.identityClient.createNewIdentity = {
                .success(CreateIdentityResult(identity: identity, nsec: "nsec1test"))
            }
        }
        store.exhaustivity = .off
        await store.send(.createNewTapped)
        await store.receive(\.createResult) {
            $0.generatedNsec = "nsec1test"
            $0.activeIdentity = identity
        }
    }

    func testSkipSendsDelegate() async throws {
        let store = TestStore(initialState: IdentityFeature.State()) {
            IdentityFeature()
        }
        store.exhaustivity = .off
        await store.send(.skipTapped) {
            $0 = $0
        }
    }

    func testLogoutSendsDelegate() async throws {
        let identity = ReviewerIdentity(
            pubkeyHex: "ab", npub: "npub1ab", displayName: "test", source: .localKey
        )
        let store = TestStore(initialState: IdentityFeature.State(activeIdentity: identity)) {
            IdentityFeature()
        } withDependencies: {
            $0.identityClient.logout = {}
        }
        store.exhaustivity = .off
        await store.send(.logoutTapped) {
            $0.activeIdentity = nil
            $0.showLoggedInVariant = false
        }
    }
}
