import Foundation

// MARK: - FirebaseAuthService

/// Firebase Authentication スタブ実装
/// MVP ではローカルの UUID をユーザー ID として使用。
/// TODO: Replace with Firebase Authentication implementation
@Observable
@MainActor
final class FirebaseAuthService {

    // MARK: - Singleton

    static let shared = FirebaseAuthService()

    // MARK: - Properties

    /// 現在のユーザーID（未認証の場合は nil）
    private(set) var currentUserId: String?

    /// 認証済みかどうか
    var isAuthenticated: Bool {
        currentUserId != nil
    }

    // MARK: - Storage Keys

    private enum Keys {
        static let userId = "sorayomi_auth_user_id"
    }

    // MARK: - Init

    init() {
        let keychain = KeychainStore.shared

        // 既存ユーザーの UserDefaults → Keychain マイグレーション（一回限り）
        if let legacyId = UserDefaults.standard.string(forKey: Keys.userId) {
            keychain.saveString(legacyId, forKey: Keys.userId)
            UserDefaults.standard.removeObject(forKey: Keys.userId)
        }

        // Keychain から保存済みのユーザーIDを復元
        self.currentUserId = keychain.loadString(forKey: Keys.userId)
    }

    // MARK: - Authentication

    /// 匿名サインイン（MVP ではローカル UUID を生成）
    /// TODO: Replace with Firebase anonymous authentication
    func signInAnonymously() async {
        // 既にサインイン済みの場合はスキップ
        if let existingId = currentUserId {
            #if DEBUG
            print("[FirebaseAuth] Already signed in: \(existingId)")
            #endif
            return
        }

        // MVP: ローカル UUID を生成
        // TODO: Replace with Firebase implementation
        // let result = try await Auth.auth().signInAnonymously()
        // currentUserId = result.user.uid
        let localUserId = UUID().uuidString
        currentUserId = localUserId
        KeychainStore.shared.saveString(localUserId, forKey: Keys.userId)

        #if DEBUG
        print("[FirebaseAuth] Signed in anonymously: \(localUserId)")
        #endif
    }

    /// サインアウト
    func signOut() {
        // TODO: Replace with Firebase implementation
        // try Auth.auth().signOut()
        currentUserId = nil
        KeychainStore.shared.delete(forKey: Keys.userId)

        #if DEBUG
        print("[FirebaseAuth] Signed out")
        #endif
    }

    /// 現在のユーザーIDを取得（未認証の場合は匿名サインインを実行）
    func ensureAuthenticated() async -> String {
        if let userId = currentUserId {
            return userId
        }
        await signInAnonymously()
        return currentUserId ?? UUID().uuidString
    }
}
