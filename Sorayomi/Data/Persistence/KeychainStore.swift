import Foundation
import Security

// MARK: - KeychainStore

/// シンプルなキーチェーンラッパー
/// Provides basic save/load/delete operations for secure data storage
/// using the iOS Keychain Services API.
@MainActor
final class KeychainStore {

    // MARK: - Singleton

    static let shared = KeychainStore()

    // MARK: - Properties

    private let service: String

    // MARK: - Init

    init(service: String = Bundle.main.bundleIdentifier ?? "com.sorayomi.app") {
        self.service = service
    }

    // MARK: - Public API

    /// キーチェーンにデータを保存
    /// 既存のデータがある場合は上書きします。
    @discardableResult
    func save(data: Data, forKey key: String) -> Bool {
        // まず既存のアイテムを削除してから保存
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            #if DEBUG
            print("[KeychainStore] Failed to save key '\(key)': OSStatus \(status)")
            #endif
            return false
        }

        #if DEBUG
        print("[KeychainStore] Saved key '\(key)'")
        #endif
        return true
    }

    /// キーチェーンからデータを読み込み
    func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                #if DEBUG
                print("[KeychainStore] Failed to load key '\(key)': OSStatus \(status)")
                #endif
            }
            return nil
        }

        return data
    }

    /// キーチェーンからデータを削除
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            #if DEBUG
            print("[KeychainStore] Failed to delete key '\(key)': OSStatus \(status)")
            #endif
            return false
        }

        #if DEBUG
        if status == errSecSuccess {
            print("[KeychainStore] Deleted key '\(key)'")
        }
        #endif
        return true
    }

    // MARK: - Convenience Methods

    /// 文字列をキーチェーンに保存
    @discardableResult
    func saveString(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data: data, forKey: key)
    }

    /// キーチェーンから文字列を読み込み
    func loadString(forKey key: String) -> String? {
        guard let data = load(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// キーチェーンにキーが存在するかどうか
    func exists(forKey key: String) -> Bool {
        return load(forKey: key) != nil
    }

    /// このサービスのすべてのキーチェーンアイテムを削除（開発用）
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)

        #if DEBUG
        print("[KeychainStore] Cleared all items for service '\(service)'")
        #endif
    }
}
