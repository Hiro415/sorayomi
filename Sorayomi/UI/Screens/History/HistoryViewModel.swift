import Foundation

/// 鑑定履歴画面の ViewModel
/// ReadingRepository から鑑定結果を読み込み、削除操作を提供する。
@Observable
@MainActor
final class HistoryViewModel {

    // MARK: - Properties

    /// 読み込まれた鑑定結果一覧（新しい順）
    var readings: [FortuneReading] = []

    /// 読み込み中かどうか
    var isLoading: Bool = false

    // MARK: - Dependencies

    private let repository: ReadingRepository
    private let authService: FirebaseAuthService

    // MARK: - Init

    init(
        repository: ReadingRepository = .shared,
        authService: FirebaseAuthService = .shared
    ) {
        self.repository = repository
        self.authService = authService
    }

    // MARK: - Load

    /// 認証済みユーザーの鑑定履歴を読み込む
    func loadReadings(env: AppEnvironment) async {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[HistoryViewModel] No authenticated user, skipping load")
            #endif
            return
        }

        isLoading = true
        readings = repository.getReadings(userId: userId)
        isLoading = false

        #if DEBUG
        print("[HistoryViewModel] Loaded \(readings.count) readings")
        #endif
    }

    // MARK: - Delete

    /// 指定IDの鑑定結果を削除する
    func deleteReading(id: String, env: AppEnvironment) async {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[HistoryViewModel] No authenticated user, cannot delete")
            #endif
            return
        }

        repository.delete(id: id, userId: userId)
        readings.removeAll { $0.id == id }

        #if DEBUG
        print("[HistoryViewModel] Deleted reading: \(id)")
        #endif
    }
}
