import Foundation

// MARK: - UserRepository

/// ユーザープロフィールの永続化リポジトリ
/// MVP では UserDefaultsStore を使用。将来的に Firestore に移行予定。
@MainActor
final class UserRepository {

    // MARK: - Singleton

    static let shared = UserRepository()

    // MARK: - Dependencies

    private let store: UserDefaultsStore

    // MARK: - Init

    init(store: UserDefaultsStore = .shared) {
        self.store = store
    }

    // MARK: - Keys

    /// ユーザーID に基づくストレージキー
    private func key(for userId: String) -> String {
        "user_profile_\(userId)"
    }

    // MARK: - CRUD

    /// プロフィールを保存
    func save(_ profile: UserProfile) {
        store.save(profile, forKey: key(for: profile.id))
        #if DEBUG
        print("[UserRepository] Saved profile for user: \(profile.id)")
        #endif
    }

    /// プロフィールを取得
    func get(userId: String) -> UserProfile? {
        let profile: UserProfile? = store.load(forKey: key(for: userId))
        #if DEBUG
        if let profile {
            print("[UserRepository] Loaded profile for user: \(profile.id)")
        } else {
            print("[UserRepository] No profile found for user: \(userId)")
        }
        #endif
        return profile
    }

    /// プロフィールを更新（取得→変更→保存のショートカット）
    func update(userId: String, transform: (inout UserProfile) -> Void) -> UserProfile? {
        guard var profile = get(userId: userId) else {
            #if DEBUG
            print("[UserRepository] Cannot update: no profile for user \(userId)")
            #endif
            return nil
        }
        transform(&profile)
        save(profile)
        return profile
    }

    /// プロフィールを削除
    func delete(userId: String) {
        store.delete(forKey: key(for: userId))
        #if DEBUG
        print("[UserRepository] Deleted profile for user: \(userId)")
        #endif
    }

    /// プロフィールが存在するかどうか
    func exists(userId: String) -> Bool {
        store.exists(forKey: key(for: userId))
    }
}
