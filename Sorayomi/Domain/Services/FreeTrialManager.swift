import Foundation

// MARK: - FreeTrialManager

/// Manages the one-time free consultation trial.
///
/// Uses iCloud-synchronized Keychain storage so the flag survives
/// app deletion and reinstallation — users cannot reclaim the free
/// trial simply by deleting and reinstalling the app.
@Observable
@MainActor
final class FreeTrialManager {

    // MARK: - Properties

    private(set) var isFirstConsultationAvailable: Bool

    private let keychainKey = "sorayomi_free_trial_used"
    private let keychain: KeychainStore

    // MARK: - Init

    init(keychain: KeychainStore = .shared) {
        self.keychain = keychain
        // synchronizable: true → iCloud Keychain に同期し、再インストール後も保持
        self.isFirstConsultationAvailable = !keychain.exists(
            forKey: "sorayomi_free_trial_used",
            synchronizable: true
        )
    }

    // MARK: - Public API

    /// Returns true if the user should get this reading for free (first time only).
    /// Call this before credit deduction to decide whether to skip it.
    func shouldGrantFreeTrial() -> Bool {
        return isFirstConsultationAvailable
    }

    /// Marks the free trial as consumed. Call after successfully generating the reading.
    func consumeFreeTrial() {
        guard isFirstConsultationAvailable else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        keychain.saveString(timestamp, forKey: keychainKey, synchronizable: true)
        isFirstConsultationAvailable = false
    }

    /// フリートライアル状態をリセットする（アカウント削除時）
    func resetFreeTrial() {
        _ = keychain.delete(forKey: keychainKey, synchronizable: true)
        isFirstConsultationAvailable = true
    }
}
