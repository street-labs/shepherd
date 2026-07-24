import ComposableArchitecture
import SharedModels
import ShepherdDependencies

/// In-app Nostr identity login / creation / logout. Presents a single card where
/// the reviewer pastes an existing `nsec` or `bunker://` URI, or generates a new
/// local identity. Sends delegate actions back to `AppFeature` on adopt/skip/logout.
// Implements: FR-id-screen-when-no-identity, FR-id-optional-reentry
@Reducer
public struct IdentityFeature {
    @ObservableState
    public struct State: Equatable {
        /// Which login form is active.
        public enum Form: Equatable, Sendable { case secretKey, bunker }

        public var form: Form = .secretKey
        public var input: String = ""
        public var error: String? = nil
        /// True while a bunker connect handshake is in flight.
        public var connecting: Bool = false
        /// Non-nil while the backup-reveal state is shown after Create New Identity.
        public var generatedNsec: String? = nil
        /// The active identity, for the logged-in (on-demand) variant.
        public var activeIdentity: ReviewerIdentity? = nil
        /// When true, the card shows the active identity + Log Out / Switch actions
        /// instead of the input form. Set when opened on demand while logged in.
        public var showLoggedInVariant: Bool = false

        public init(activeIdentity: ReviewerIdentity? = nil) {
            self.activeIdentity = activeIdentity
            self.showLoggedInVariant = activeIdentity != nil
        }
    }

    @CasePathable
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case formChanged(State.Form)
        case signInTapped
        case createNewTapped
        case backupConfirmTapped
        case copyNsecTapped
        case nsecCopied
        case skipTapped
        case logoutTapped
        case switchIdentityTapped
        case loginResult(Result<ReviewerIdentity, IdentityLoginError>)
        case createResult(Result<CreateIdentityResult, IdentityLoginError>)
        case bunkerLoginResult(Result<ReviewerIdentity, IdentityLoginError>)
        // Delegates to the parent (AppFeature).
        case identityAdopted(ReviewerIdentity)
        case identitySkipped
        case identityLoggedOut
    }

    @Dependency(\.identityClient) var identityClient
    @Dependency(\.clipboardClient) var clipboardClient

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .formChanged(form):
                state.form = form
                state.input = ""
                state.error = nil
                return .none

            // Implements: FR-id-nsec-login, FR-id-bunker-login
            case .signInTapped:
                let input = state.input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !input.isEmpty else { return .none }
                state.error = nil
                switch state.form {
                case .secretKey:
                    let result = identityClient.loginWithKey(input)
                    return .send(.loginResult(result))
                case .bunker:
                    state.connecting = true
                    return .run { [identityClient] send in
                        let result = await identityClient.loginWithBunker(input)
                        await send(.bunkerLoginResult(result))
                    }
                }

            // Implements: FR-id-create-new
            case .createNewTapped:
                let result = identityClient.createNewIdentity()
                return .send(.createResult(result))

            // Implements: FR-id-show-new-nsec
            case let .createResult(.success(result)):
                state.generatedNsec = result.nsec
                state.activeIdentity = result.identity
                state.error = nil
                return .none

            case let .createResult(.failure(error)):
                state.error = errorMessage(error)
                return .none

            // Implements: FR-id-nsec-login
            case let .loginResult(.success(identity)):
                state.activeIdentity = identity
                return .send(.identityAdopted(identity))

            case let .loginResult(.failure(error)):
                state.error = errorMessage(error)
                return .none

            // Implements: FR-id-bunker-login, FR-id-bunker-connect-failure
            case let .bunkerLoginResult(.success(identity)):
                state.connecting = false
                state.activeIdentity = identity
                return .send(.identityAdopted(identity))

            case let .bunkerLoginResult(.failure(error)):
                state.connecting = false
                state.error = errorMessage(error)
                return .none

            // Implements: FR-id-show-new-nsec (confirmation gate)
            case .backupConfirmTapped:
                guard state.generatedNsec != nil else { return .none }
                state.generatedNsec = nil
                if let identity = state.activeIdentity {
                    return .send(.identityAdopted(identity))
                }
                return .none

            case .copyNsecTapped:
                guard let nsec = state.generatedNsec else { return .none }
                return .run { [clipboardClient] send in
                    await clipboardClient.copyText(nsec)
                    await send(.nsecCopied)
                }

            case .nsecCopied:
                return .none

            // Implements: FR-id-screen-when-no-identity (dismiss to read-only)
            case .skipTapped:
                return .send(.identitySkipped)

            // Implements: FR-id-logout
            case .logoutTapped:
                identityClient.logout()
                state.activeIdentity = nil
                state.showLoggedInVariant = false
                state.generatedNsec = nil
                return .send(.identityLoggedOut)

            // Implements: FR-id-optional-reentry
            case .switchIdentityTapped:
                state.showLoggedInVariant = false
                state.input = ""
                state.error = nil
                return .none

            case .identityAdopted, .identitySkipped, .identityLoggedOut:
                return .none
            }
        }
    }

    private func errorMessage(_ error: IdentityLoginError) -> String {
        switch error {
        case .invalidKey:
            return "Not a valid nsec — check it starts with nsec1 and is complete."
        case .storageFailed:
            return "Could not save identity — check Keychain access."
        case .invalidURI:
            return "Not a valid bunker URI — check it starts with bunker:// and includes a relay."
        case .connectFailed:
            return "Couldn't connect to the bunker — check the URI, relay, and secret. Your input is retained."
        }
    }
}
