import Foundation

// MARK: - CacheManager

/// インメモリ TTL キャッシュマネージャー
/// Provides a generic in-memory cache with per-entry time-to-live (TTL).
/// Uses iOS 17+ @Observable for SwiftUI integration.
@Observable
@MainActor
final class CacheManager {

    // MARK: - Singleton

    static let shared = CacheManager()

    // MARK: - Types

    private struct CacheEntry {
        let value: Any
        let expiresAt: Date
    }

    // MARK: - Properties

    private var cache: [String: CacheEntry] = [:]

    /// Default TTL in seconds (5 minutes)
    private let defaultTTL: TimeInterval = 300

    // MARK: - Init

    init() {}

    // MARK: - Public API

    /// キャッシュに値を保存
    /// - Parameters:
    ///   - key: キャッシュキー
    ///   - value: 保存する値
    ///   - ttl: 有効期限（秒）。指定しない場合はデフォルトの5分
    func set<T>(key: String, value: T, ttl: TimeInterval? = nil) {
        let expiration = Date().addingTimeInterval(ttl ?? defaultTTL)
        let entry = CacheEntry(value: value, expiresAt: expiration)
        cache[key] = entry

        #if DEBUG
        print("[CacheManager] Set '\(key)' (TTL: \(ttl ?? defaultTTL)s)")
        #endif
    }

    /// キャッシュから値を取得（期限切れの場合は nil）
    func get<T>(key: String) -> T? {
        guard let entry = cache[key] else {
            return nil
        }

        // 有効期限チェック
        if Date() > entry.expiresAt {
            cache.removeValue(forKey: key)
            #if DEBUG
            print("[CacheManager] Expired '\(key)'")
            #endif
            return nil
        }

        guard let value = entry.value as? T else {
            #if DEBUG
            print("[CacheManager] Type mismatch for '\(key)': expected \(T.self)")
            #endif
            return nil
        }

        return value
    }

    /// 指定キーのキャッシュを無効化
    func invalidate(key: String) {
        cache.removeValue(forKey: key)
        #if DEBUG
        print("[CacheManager] Invalidated '\(key)'")
        #endif
    }

    /// 全キャッシュをクリア
    func clearAll() {
        cache.removeAll()
        #if DEBUG
        print("[CacheManager] Cleared all entries")
        #endif
    }

    /// 期限切れのエントリを一括削除
    func purgeExpired() {
        let now = Date()
        let expiredKeys = cache.filter { $0.value.expiresAt < now }.map { $0.key }
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
        #if DEBUG
        if !expiredKeys.isEmpty {
            print("[CacheManager] Purged \(expiredKeys.count) expired entries")
        }
        #endif
    }

    /// キャッシュに指定キーが存在し、有効期限内かどうか
    func isValid(key: String) -> Bool {
        guard let entry = cache[key] else { return false }
        return Date() <= entry.expiresAt
    }

    /// 現在のキャッシュエントリ数
    var count: Int {
        cache.count
    }
}

// MARK: - Cache Keys

/// アプリ全体で使用するキャッシュキーの定数
enum CacheKey {
    static let dailyFortune = "daily_fortune"
    static let userProfile = "user_profile"
    static let creditWallet = "credit_wallet"
    static let readingHistory = "reading_history"

    /// 日付付きキーを生成（デイリーキャッシュ用）
    static func daily(_ base: String, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(base)_\(formatter.string(from: date))"
    }
}
