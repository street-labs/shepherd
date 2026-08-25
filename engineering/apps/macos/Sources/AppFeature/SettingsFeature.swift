import ComposableArchitecture
import Foundation
import ShepherdDependencies

/// In-app Settings (Relays) sheet — the iOS counterpart to macOS's
/// `NOSTR_RELAYS` / `~/.config/nostr/relays.txt`. Add/remove relay URLs,
/// "use defaults" toggle, inline `wss://`/`ws://` validation. Persists via
/// `UserDefaults` (relay URLs are preferences, not secrets) and the saved list
/// takes highest precedence in `RelayClient.resolveRelays()`.
// Implements: FR-sri-relay-settings, AC-sri-relay-defaults, AC-sri-relay-custom,
// AC-sri-relay-invalid, AC-sri-relay-persist
@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        /// Saved custom relay list; empty when "use defaults" is active.
        public var relays: [String] = []
        /// True when the default public set is in use (no custom list saved).
        public var useDefaults: Bool = true
        /// Input for the add-relay field.
        public var newRelay: String = ""
        /// Inline validation message for the add-relay field.
        public var error: String? = nil

        public init() {
            if let saved = RelayClient.configuredRelays(), !saved.isEmpty {
                relays = saved
                useDefaults = false
            }
        }
    }

    @CasePathable
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case addRelayTapped
        case removeRelay(String)
        case saveTapped
        // Delegates to the parent (AppFeature).
        case settingsSaved
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            // Implements: AC-sri-relay-invalid — reject non-wss/ws URLs inline.
            case .addRelayTapped:
                let raw = state.newRelay.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !raw.isEmpty else { return .none }
                guard Self.isValidRelayURL(raw) else {
                    state.error = "Relay URLs must start with wss:// or ws:// and name a host."
                    return .none
                }
                state.error = nil
                if !state.relays.contains(raw) { state.relays.append(raw) }
                state.newRelay = ""
                return .none

            case let .removeRelay(relay):
                state.relays.removeAll { $0 == relay }
                return .none

            // Implements: AC-sri-relay-custom, AC-sri-relay-persist.
            case .saveTapped:
                let custom = state.useDefaults ? nil : state.relays
                RelayClient.saveConfiguredRelays(custom)
                return .send(.settingsSaved)

            case .settingsSaved:
                return .none
            }
        }
    }

    /// A relay URL is a `wss://` or `ws://` URL with a host.
    static func isValidRelayURL(_ raw: String) -> Bool {
        guard let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "wss" || scheme == "ws",
              url.host() != nil
        else { return false }
        return true
    }
}
