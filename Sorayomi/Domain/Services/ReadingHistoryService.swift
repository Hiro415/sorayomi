import Foundation

// MARK: - ReadingHistoryService

/// 占い鑑定の履歴管理サービス
/// 鑑定結果の読み込み・削除を統括する。
@Observable
@MainActor
final class ReadingHistoryService {

    // MARK: - Properties

    /// 鑑定履歴
    private(set) var readings: [FortuneReading] = []

    /// 読み込み中かどうか
    private(set) var isLoading: Bool = false

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

    /// 鑑定履歴を読み込む
    /// - Parameter limit: 取得件数制限（nil で全件取得）
    func loadHistory(limit: Int? = nil) {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[ReadingHistoryService] No authenticated user, skipping load")
            #endif
            return
        }

        isLoading = true
        readings = repository.getReadings(userId: userId, limit: limit)
        isLoading = false

        #if DEBUG
        print("[ReadingHistoryService] Loaded \(readings.count) readings")
        #endif
    }

    // MARK: - Save

    /// 新しい鑑定結果を保存し、ローカルリストも更新
    func saveReading(_ reading: FortuneReading) {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[ReadingHistoryService] No authenticated user, cannot save reading")
            #endif
            return
        }

        repository.save(reading, userId: userId)
        readings.insert(reading, at: 0)

        #if DEBUG
        print("[ReadingHistoryService] Saved reading: \(reading.id)")
        #endif
    }

    // MARK: - Delete

    /// 特定の鑑定結果を削除
    func deleteReading(id: String) {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[ReadingHistoryService] No authenticated user, cannot delete reading")
            #endif
            return
        }

        repository.delete(id: id, userId: userId)
        readings.removeAll(where: { $0.id == id })

        #if DEBUG
        print("[ReadingHistoryService] Deleted reading: \(id)")
        #endif
    }

    /// ユーザーのすべての鑑定履歴を削除する（アカウント削除時）
    func deleteAllReadings(for userId: String) {
        repository.deleteAll(userId: userId)
        readings = []

        #if DEBUG
        print("[ReadingHistoryService] All readings deleted for user: \(userId)")
        #endif
    }

    // MARK: - Helpers

    /// 鑑定履歴が空かどうか
    var isEmpty: Bool {
        readings.isEmpty
    }

    /// 特定の占いシステムの履歴を絞り込み
    func readings(for system: FortuneSystem) -> [FortuneReading] {
        readings.filter { $0.system == system }
    }
}
