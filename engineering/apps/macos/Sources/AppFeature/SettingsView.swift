import SwiftUI
import ComposableArchitecture
import ShepherdDependencies

/// Settings (Relays) sheet — form with a Relays section (add/remove URLs,
/// "use defaults" toggle) and a footer link to the Identity sheet.
/// Design: design/ios/shepherd-review.md (Settings (Relays)).
// Implements: FR-sri-relay-settings
public struct SettingsView: View {
    @Bindable public var store: StoreOf<SettingsFeature>
    /// Opens the Identity sheet; AppFeature supplies the closure.
    public var openIdentity: () -> Void

    public init(store: StoreOf<SettingsFeature>, openIdentity: @escaping () -> Void) {
        self.store = store
        self.openIdentity = openIdentity
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Use Default Relays", isOn: $store.useDefaults)
                    if !store.useDefaults {
                        ForEach(store.relays, id: \.self) { relay in
                            HStack {
                                Text(relay)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button {
                                    store.send(.removeRelay(relay))
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Remove \(relay)")
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                store.send(.removeRelay(store.relays[index]))
                            }
                        }
                        if store.relays.isEmpty {
                            Text("No custom relays — add one below.")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            TextField("wss://relay.example.com", text: $store.newRelay)
#if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
#endif
                                .autocorrectionDisabled()
                            Button("Add") {
                                store.send(.addRelayTapped)
                            }
                            .disabled(store.newRelay.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        if let error = store.error {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Relays")
                } footer: {
                    if store.useDefaults {
                        Text("Using the default public relays: \(RelayClient.defaultRelays.joined(separator: ", ")).")
                    }
                }

                Section {
                    Button("Identity…") {
                        openIdentity()
                    }
                } footer: {
                    Text("View, switch, or log out your reviewer identity.")
                }
            }
            .navigationTitle("Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.send(.saveTapped)
                    }
                }
            }
        }
    }
}
