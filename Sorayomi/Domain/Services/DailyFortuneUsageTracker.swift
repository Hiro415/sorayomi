import Foundation

// MARK: - DailyFortuneUsageTracker

/// 無料コンテンツ（creditCost == 0 の占術）の当日使用を追跡する。
/// UserDefaults に日付をキーとして保存し、日付が変わると自動リセット。
@Observable
@MainActor
final class DailyFortuneUsageTracker {

    // MARK: - Properties

    /// 本日使用済みの占術ID集合
    private(set) var usedSystemIDs: Set<String> = []

    /// 本日のおみくじ結果（引いた時点で保存、翌日自動リセット）
    private(set) var todayOmikujiResult: Omikuji? = nil

    /// 最後にロードした日付文字列（日付変更検知に使用）
    private var lastLoadedDate: String = ""

    // MARK: - Init

    init() {
        loadFromDefaults()
    }

    // MARK: - Public API

    /// 日付が変わっていれば UserDefaults からリロードしてリセットする。
    /// HomeScreen.task や ReadingScreen.onAppear から呼ぶことでアプリ復帰時に自動リフレッシュ。
    func refreshIfNeeded() {
        guard lastLoadedDate != todayDateString else { return }
        loadFromDefaults()
        #if DEBUG
        print("[DailyFortuneUsageTracker] Date changed — refreshed state for \(todayDateString)")
        #endif
    }

    /// 今日その占術が使用済みかどうか（creditCost > 0 の占術は常に false）
    func isUsedToday(system: FortuneSystem) -> Bool {
        guard system.creditCost == 0 else { return false }
        return usedSystemIDs.contains(system.rawValue)
    }

    /// 使用済みとしてマーク（creditCost == 0 の占術のみ）
    func markUsed(system: FortuneSystem) {
        guard system.creditCost == 0 else { return }
        usedSystemIDs.insert(system.rawValue)
        saveUsedToDefaults()

        #if DEBUG
        print("[DailyFortuneUsageTracker] Marked used: \(system.rawValue)")
        #endif
    }

    /// おみくじ結果を保存（ドラッグ選択後、ランクが確定した瞬間に呼ぶ）
    func storeOmikujiResult(_ result: Omikuji) {
        todayOmikujiResult = result
        if let data = try? JSONEncoder().encode(result) {
            UserDefaults.standard.set(data, forKey: todayOmikujiResultKey)
        }

        #if DEBUG
        print("[DailyFortuneUsageTracker] Stored omikuji result: \(result.rank.japaneseName)")
        #endif
    }

    // MARK: - Persistence

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: Date())
    }

    private var todayUsedKey: String {
        "sorayomi_daily_used_\(todayDateString)"
    }

    private var todayOmikujiResultKey: String {
        "sorayomi_omikuji_result_\(todayDateString)"
    }

    private func loadFromDefaults() {
        let today = todayDateString
        lastLoadedDate = today

        // 使用済み占術
        if let saved = UserDefaults.standard.stringArray(forKey: todayUsedKey) {
            usedSystemIDs = Set(saved)
        } else {
            usedSystemIDs = []
        }

        // おみくじ結果
        if let data = UserDefaults.standard.data(forKey: todayOmikujiResultKey),
           let result = try? JSONDecoder().decode(Omikuji.self, from: data) {
            todayOmikujiResult = result
        } else {
            todayOmikujiResult = nil
        }

        #if DEBUG
        print("[DailyFortuneUsageTracker] Loaded used systems: \(usedSystemIDs)")
        if todayOmikujiResult != nil { print("[DailyFortuneUsageTracker] Loaded stored omikuji result") }
        #endif
    }

    private func saveUsedToDefaults() {
        UserDefaults.standard.set(Array(usedSystemIDs), forKey: todayUsedKey)
    }
}
