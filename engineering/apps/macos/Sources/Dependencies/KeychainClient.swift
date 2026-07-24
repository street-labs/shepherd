import Foundation
import Security
import ComposableArchitecture

/// Secure storage for the reviewer's in-app Nostr identity. Holds either a
/// 32-byte secret key (local-key form) or a UTF-8 `bunker://` URI (bunker form),
/// never written to disk in plaintext. Implements: FR-id-persistence,
/// FR-id-bunker-persist, NFR-id-no-plaintext-key.
@DependencyClient
public struct KeychainClient: Sendable {
    /// Read the stored identity material: 32 bytes of secret key (local-key
    /// form) or a UTF-8 `bunker://` URI (bunker form), or nil if none stored.
    public var readIdentity: @Sendable () -> Data?
    /// Store identity material (32-byte secret key or UTF-8 bunker URI as Data).
    /// Overwrites any existing entry. Returns true on success, false on a
    /// Keychain write failure (locked keychain, duplicate, etc.) so callers can
    /// refuse to adopt an identity that was not persisted.
    public var writeIdentity: @Sendable (Data) -> Bool = { _ in false }
    /// Delete the stored identity (logout). No-op if none stored.
    public var deleteIdentity: @Sendable () -> Void
}

extension KeychainClient: DependencyKey {
    public static let liveValue: KeychainClient = {
        let service = "com.street-labs.shepherd"
        let account = "shepherd-nostr-identity"
        return KeychainClient(
            readIdentity: { Self.read(service: service, account: account) },
            writeIdentity: { Self.write(data: $0, service: service, account: account) },
            deleteIdentity: { Self.delete(service: service, account: account) }
        )
    }()

    public static let testValue = Self()

    private static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return data
    }

    private static func write(data: Data, service: String, account: String) -> Bool {
        delete(service: service, account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

extension DependencyValues {
    public var keychainClient: KeychainClient {
        get { self[KeychainClient.self] }
        set { self[KeychainClient.self] = newValue }
    }
}
