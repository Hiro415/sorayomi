import Foundation

// MARK: - ReadingRepository

/// 占い鑑定結果の永続化リポジトリ
/// MVP では UserDefaultsStore を使用。将来的に Firestore に移行予定。
@MainActor
final class ReadingRepository {

    // MARK: - Singleton

    static let shared = ReadingRepository()

    // MARK: - Dependencies

    private let store: UserDefaultsStore

    // MARK: - Init

    init(store: UserDefaultsStore = .shared) {
        self.store = store
    }

    // MARK: - Keys

    /// ユーザーID に基づくストレージキー
    private func key(for userId: String) -> String {
        "user_readings_\(userId)"
    }

    // MARK: - Save

    /// 新しい鑑定結果を保存（既存リストの先頭に追加）
    func save(_ reading: FortuneReading, userId: String) {
        var readings = getAllReadings(userId: userId)
        readings.insert(reading, at: 0)
        store.save(readings, forKey: key(for: userId))
        #if DEBUG
        print("[ReadingRepository] Saved reading \(reading.id) for user: \(userId)")
        #endif
    }

    // MARK: - Get (List)

    /// ユーザーの鑑定履歴を取得（制限付き）
    func getReadings(userId: String, limit: Int? = nil) -> [FortuneReading] {
        let readings = getAllReadings(userId: userId)
        if let limit, limit > 0 {
            return Array(readings.prefix(limit))
        }
        return readings
    }

    // MARK: - Get (Single)

    /// 特定の鑑定結果を取得
    func getReading(id: String, userId: String) -> FortuneReading? {
        let readings = getAllReadings(userId: userId)
        return readings.first(where: { $0.id == id })
    }

    // MARK: - Delete

    /// 特定の鑑定結果を削除
    func delete(id: String, userId: String) {
        var readings = getAllReadings(userId: userId)
        readings.removeAll(where: { $0.id == id })
        store.save(readings, forKey: key(for: userId))
        #if DEBUG
        print("[ReadingRepository] Deleted reading \(id) for user: \(userId)")
        #endif
    }

    /// ユーザーの全鑑定結果を削除
    func deleteAll(userId: String) {
        store.delete(forKey: key(for: userId))
        #if DEBUG
        print("[ReadingRepository] Deleted all readings for user: \(userId)")
        #endif
    }

    // MARK: - Private

    /// 全鑑定結果を内部的に取得
    private func getAllReadings(userId: String) -> [FortuneReading] {
        let readings: [FortuneReading]? = store.load(forKey: key(for: userId))
        return readings ?? []
    }
}
