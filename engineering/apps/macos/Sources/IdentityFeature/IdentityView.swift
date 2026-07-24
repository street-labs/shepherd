import SwiftUI
import ComposableArchitecture
import SharedModels

/// The in-app identity login / create card. Implements the screen described in
/// the design spec: a form toggle (Secret Key / Bunker URI), a Sign In button,
/// Create New Identity, Skip, and a logged-in variant with Log Out / Switch.
// Implements: FR-id-screen-when-no-identity, FR-id-show-new-nsec, FR-id-active-indicator
public struct IdentityView: View {
    @Bindable public var store: StoreOf<IdentityFeature>

    public init(store: StoreOf<IdentityFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            header

            if store.generatedNsec != nil {
                backupReveal
            } else if store.showLoggedInVariant, let identity = store.activeIdentity {
                loggedInVariant(identity)
            } else {
                loginForm
            }
        }
        .padding(28)
        .frame(maxWidth: 440)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image(systemName: "key.horizontal.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Sign in to publish review replies")
                .font(.system(size: 15, weight: .semibold))
            Text("Log in with your Nostr identity so your review replies are signed under your name.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var loginForm: some View {
        VStack(spacing: 12) {
            Picker("Form", selection: Binding(
                get: { store.form },
                set: { store.send(.formChanged($0)) }
            )) {
                Text("Secret Key").tag(IdentityFeature.State.Form.secretKey)
                Text("Bunker URI").tag(IdentityFeature.State.Form.bunker)
            }
            .pickerStyle(.segmented)

            if store.form == .secretKey {
                SecureField("nsec1…", text: $store.input)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Nostr secret key")
            } else {
                TextField("bunker://…", text: $store.input)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("NIP-46 bunker URI")
            }

            if let error = store.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                store.send(.signInTapped)
            } label: {
                if store.connecting {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Connecting…")
                    }
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.input.isEmpty || store.connecting)

            if store.form == .secretKey {
                Button {
                    store.send(.createNewTapped)
                } label: {
                    Text("Create New Identity")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }

            Spacer().frame(height: 4)

            Button {
                store.send(.skipTapped)
            } label: {
                Text("Skip for now")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // Implements: FR-id-show-new-nsec
    private var backupReveal: some View {
        VStack(spacing: 12) {
            Text("Back up your new identity")
                .font(.system(size: 13, weight: .semibold))
            Text(store.generatedNsec ?? "")
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .background(Color(nsColor: .quaternaryLabelColor).opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            HStack {
                Button("Copy") { store.send(.copyNsecTapped) }
                    .buttonStyle(.bordered)
                Spacer()
                Button("I've saved my key") { store.send(.backupConfirmTapped) }
                    .buttonStyle(.borderedProminent)
            }
            Text("This is your only chance to save this key. If you lose it, you lose access to this identity.")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
        }
    }

    // Implements: FR-id-active-indicator, FR-id-logout, FR-id-optional-reentry
    private func loggedInVariant(_ identity: ReviewerIdentity) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: identity.source == .bunker ? "shield.lefthalf.filled" : "key.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                Text(identity.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(identity.npub)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            HStack {
                Button("Log Out") { store.send(.logoutTapped) }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Switch Identity") { store.send(.switchIdentityTapped) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
