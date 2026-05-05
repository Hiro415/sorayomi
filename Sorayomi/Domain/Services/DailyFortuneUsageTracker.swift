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

    /// 日付キー生成用フォーマッター（生成コストが高いため static でキャッシュ）
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f
    }()

    private var todayDateString: String {
        Self.dateFormatter.string(from: Date())
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

        // 今日以外の古い日付キーを削除（蓄積防止）
        purgeStaleDateKeys(today: today)

        #if DEBUG
        print("[DailyFortuneUsageTracker] Loaded used systems: \(usedSystemIDs)")
        if todayOmikujiResult != nil { print("[DailyFortuneUsageTracker] Loaded stored omikuji result") }
        #endif
    }

    /// 今日以外の日付をキーに持つ古いエントリを UserDefaults から削除する。
    private func purgeStaleDateKeys(today: String) {
        let defaults = UserDefaults.standard
        let prefixes = ["sorayomi_daily_used_", "sorayomi_omikuji_result_"]
        let staleKeys = defaults.dictionaryRepresentation().keys.filter { key in
            prefixes.contains(where: { key.hasPrefix($0) }) && !key.hasSuffix(today)
        }
        for key in staleKeys {
            defaults.removeObject(forKey: key)
        }
        #if DEBUG
        if !staleKeys.isEmpty {
            print("[DailyFortuneUsageTracker] Purged \(staleKeys.count) stale date key(s)")
        }
        #endif
    }

    private func saveUsedToDefaults() {
        UserDefaults.standard.set(Array(usedSystemIDs), forKey: todayUsedKey)
    }
}
