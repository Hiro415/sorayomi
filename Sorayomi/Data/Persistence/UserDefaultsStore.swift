import Foundation

// MARK: - UserDefault Property Wrapper

/// Codable 対応の UserDefaults プロパティラッパー
/// Provides type-safe UserDefaults access for any Codable type.
@propertyWrapper
struct UserDefault<T: Codable> {
    let key: String
    let defaultValue: T
    let store: UserDefaults

    init(key: String, defaultValue: T, store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    var wrappedValue: T {
        get {
            guard let data = store.data(forKey: key) else {
                return defaultValue
            }
            do {
                let decoded = try JSONDecoder.sorayomiDecoder.decode(T.self, from: data)
                return decoded
            } catch {
                #if DEBUG
                print("[UserDefault] Failed to decode \(key): \(error.localizedDescription)")
                #endif
                return defaultValue
            }
        }
        set {
            do {
                let data = try JSONEncoder.sorayomiEncoder.encode(newValue)
                store.set(data, forKey: key)
            } catch {
                #if DEBUG
                print("[UserDefault] Failed to encode \(key): \(error.localizedDescription)")
                #endif
            }
        }
    }
}

// MARK: - UserDefaultsStore

/// UserDefaults を使った汎用永続化ストア
/// Provides generic save/load/delete operations for Codable types.
@MainActor
final class UserDefaultsStore {

    // MARK: - Singleton

    static let shared = UserDefaultsStore()

    // MARK: - Properties

    private let defaults: UserDefaults
    private let prefix: String

    // MARK: - Init

    init(defaults: UserDefaults = .standard, prefix: String = AppConstants.userDefaultsPrefix) {
        self.defaults = defaults
        self.prefix = prefix
    }

    // MARK: - Public API

    /// 指定キーにデータを保存
    func save<T: Codable>(_ value: T, forKey key: String) {
        let prefixedKey = prefixed(key)
        do {
            let data = try JSONEncoder.sorayomiEncoder.encode(value)
            defaults.set(data, forKey: prefixedKey)
            #if DEBUG
            print("[UserDefaultsStore] Saved \(prefixedKey)")
            #endif
        } catch {
            #if DEBUG
            print("[UserDefaultsStore] Failed to save \(prefixedKey): \(error.localizedDescription)")
            #endif
        }
    }

    /// 指定キーからデータを読み込み
    func load<T: Codable>(forKey key: String) -> T? {
        let prefixedKey = prefixed(key)
        guard let data = defaults.data(forKey: prefixedKey) else {
            return nil
        }
        do {
            let decoded = try JSONDecoder.sorayomiDecoder.decode(T.self, from: data)
            return decoded
        } catch {
            #if DEBUG
            print("[UserDefaultsStore] Failed to load \(prefixedKey): \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    /// 指定キーのデータを削除
    func delete(forKey key: String) {
        let prefixedKey = prefixed(key)
        defaults.removeObject(forKey: prefixedKey)
        #if DEBUG
        print("[UserDefaultsStore] Deleted \(prefixedKey)")
        #endif
    }

    /// 指定キーにデータが存在するかどうか
    func exists(forKey key: String) -> Bool {
        let prefixedKey = prefixed(key)
        return defaults.data(forKey: prefixedKey) != nil
    }

    /// プレフィックス付きの全キーを削除（開発用）
    func clearAll() {
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
        #if DEBUG
        print("[UserDefaultsStore] Cleared all keys with prefix '\(prefix)'")
        #endif
    }

    // MARK: - Private

    private func prefixed(_ key: String) -> String {
        if key.hasPrefix(prefix) {
            return key
        }
        return "\(prefix)\(key)"
    }
}

// MARK: - Shared Encoder/Decoder

extension JSONEncoder {
    /// Sorayomi 共通の JSONEncoder（日付を ISO 8601 でエンコード）
    static let sorayomiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()
}

extension JSONDecoder {
    /// Sorayomi 共通の JSONDecoder（日付を ISO 8601 でデコード）
    static let sorayomiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
