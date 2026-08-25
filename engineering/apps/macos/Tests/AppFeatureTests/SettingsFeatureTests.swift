import Testing
import ComposableArchitecture
import Foundation
@testable import AppFeature
@testable import ShepherdDependencies

/// Settings (Relays) feature + relay resolution precedence.
/// Implements: FR-sri-relay-settings, AC-sri-relay-defaults, AC-sri-relay-custom,
/// AC-sri-relay-invalid, AC-sri-relay-persist.
/// RelayClient persists in UserDefaults.standard (process-global); each test
/// clears the `shepherd.relays` key before and after.
@Suite("SettingsFeature")
@MainActor
struct SettingsFeatureTests {

    private func clearKey() {
        UserDefaults.standard.removeObject(forKey: RelayClient.relaysDefaultsKey)
    }

    private func makeStore(relays: [String]? = nil) -> TestStore<SettingsFeature.State, SettingsFeature.Action> {
        clearKey()
        if let relays {
            UserDefaults.standard.set(relays, forKey: RelayClient.relaysDefaultsKey)
        }
        return TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    }

    @Test("defaults active when nothing saved (AC-sri-relay-defaults)")
    func defaultsActive() async {
        let store = makeStore()
        #expect(store.state.useDefaults)
        #expect(store.state.relays.isEmpty)
        clearKey()
    }

    @Test("saved list loads into the editor (AC-sri-relay-custom)")
    func savedListLoads() async {
        let store = makeStore(relays: ["wss://custom.example.com"])
        #expect(!store.state.useDefaults)
        #expect(store.state.relays == ["wss://custom.example.com"])
        clearKey()
    }

    @Test("invalid relay URL rejected inline (AC-sri-relay-invalid)")
    func invalidRelayRejected() async {
        let store = makeStore()
        #expect(!SettingsFeature.isValidRelayURL("not-a-url"))
        #expect(!SettingsFeature.isValidRelayURL("https://example.com"))
        #expect(SettingsFeature.isValidRelayURL("wss://relay.example.com"))
        #expect(SettingsFeature.isValidRelayURL("ws://relay.example.com"))

        await store.send(\.binding.newRelay, "not-a-url") {
            $0.newRelay = "not-a-url"
        }
        await store.send(.addRelayTapped) {
            $0.error = "Relay URLs must start with wss:// or ws:// and name a host."
        }
        #expect(store.state.relays.isEmpty)
        clearKey()
    }

    @Test("save persists custom list and delegate fires (AC-sri-relay-custom)")
    func savePersists() async {
        let store = makeStore()
        await store.send(\.binding.newRelay, "wss://custom.example.com") {
            $0.newRelay = "wss://custom.example.com"
        }
        await store.send(.addRelayTapped) {
            $0.relays = ["wss://custom.example.com"]
            $0.newRelay = ""
        }
        await store.send(\.binding.useDefaults, false) {
            $0.useDefaults = false
        }
        await store.send(.saveTapped)
        await store.receive(.settingsSaved)
        #expect(RelayClient.resolveRelays() == ["wss://custom.example.com"])
        clearKey()
    }

    @Test("re-enabling defaults clears the saved list (AC-sri-relay-persist)")
    func defaultsRestored() async {
        let store = makeStore(relays: ["wss://old.example.com"])
        await store.send(\.binding.useDefaults, true) {
            $0.useDefaults = true
        }
        await store.send(.saveTapped)
        await store.receive(.settingsSaved)
        #expect(RelayClient.configuredRelays() == nil)
        clearKey()
    }
}
