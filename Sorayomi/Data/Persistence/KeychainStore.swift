import Foundation
import Security

// MARK: - KeychainStore

/// シンプルなキーチェーンラッパー
/// Provides basic save/load/delete operations for secure data storage
/// using the iOS Keychain Services API.
///
/// The `synchronizable` flag makes an item sync to iCloud Keychain,
/// which persists across app deletions and reinstalls — useful for
/// one-time flags like the free-trial marker.
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
    /// - Parameters:
    ///   - synchronizable: `true` にするとiCloudキーチェーン経由で同期され、
    ///     アプリ再インストール後も値が保持されます。
    @discardableResult
    func save(data: Data, forKey key: String, synchronizable: Bool = false) -> Bool {
        // 先に既存アイテムを削除（上書き用）
        delete(forKey: key, synchronizable: synchronizable)

        var query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data,
            // synchronizable items must NOT use ThisDeviceOnly variants
            kSecAttrAccessible as String: synchronizable
                ? kSecAttrAccessibleAfterFirstUnlock
                : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            #if DEBUG
            print("[KeychainStore] Failed to save key '\(key)': OSStatus \(status)")
            #endif
            return false
        }

        #if DEBUG
        print("[KeychainStore] Saved key '\(key)' (synchronizable: \(synchronizable))")
        #endif
        return true
    }

    /// キーチェーンからデータを読み込み
    func load(forKey key: String, synchronizable: Bool = false) -> Data? {
        var query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

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
    func delete(forKey key: String, synchronizable: Bool = false) -> Bool {
        var query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

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
    func saveString(_ string: String, forKey key: String, synchronizable: Bool = false) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data: data, forKey: key, synchronizable: synchronizable)
    }

    /// キーチェーンから文字列を読み込み
    func loadString(forKey key: String, synchronizable: Bool = false) -> String? {
        guard let data = load(forKey: key, synchronizable: synchronizable) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// キーチェーンにキーが存在するかどうか
    func exists(forKey key: String, synchronizable: Bool = false) -> Bool {
        return load(forKey: key, synchronizable: synchronizable) != nil
    }

    /// このサービスのすべてのキーチェーンアイテムを削除（開発用）
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)

        #if DEBUG
        print("[KeychainStore] Cleared all items for service '\(service)'")
        #endif
    }
}
