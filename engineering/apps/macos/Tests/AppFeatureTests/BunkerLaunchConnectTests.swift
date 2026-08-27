import Testing
import ComposableArchitecture
import Foundation
@testable import AppFeature
@testable import SharedModels
@testable import ShepherdDependencies

// Regression: a bunker identity loaded at launch must run the NIP-46 connect
// handshake immediately — not only when a patch-review session loads. Relay
// AUTH (NIP-42) signs through the bunker, and Browse PRs / Open Patch hit
// AUTH-required relays before any session exists; without the launch connect,
// the bunker session has no config and signing silently fails.
@Suite("Bunker identity connects at launch")
@MainActor
struct BunkerLaunchConnectTests {
    @Test("loadIdentityAtLaunch with a .connecting bunker identity starts connectBunker")
    func connectsAtLaunch() async {
        let bunkerIdentity = ReviewerIdentity(
            pubkeyHex: "", npub: "", displayName: "Connecting…",
            source: .bunker, bunkerState: .connecting, bunkerRelayURL: "wss://relay.example.com"
        )
        let didConnect = ActorBox(false)
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.identityClient.loadIdentity = { bunkerIdentity }
            $0.identityClient.connectBunker = {
                didConnect.value = true
                return String(repeating: "ab", count: 32)
            }
        }
        store.exhaustivity = .off
        await store.send(.loadIdentityAtLaunch)
        await store.receive(\.bunkerConnectCompleted)
        #expect(didConnect.value)
    }

    @Test("loadIdentityAtLaunch with no identity shows the identity screen and does not connect")
    func noIdentityGates() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.identityClient.loadIdentity = { nil }
        }
        store.exhaustivity = .off
        await store.send(.loadIdentityAtLaunch)
        #expect(store.state.identity != nil)
    }
}
