import Foundation

// MARK: - DailyContentService

/// デイリー運勢コンテンツの管理サービス
/// FortuneComposer を使って当日の総合運勢を生成し、
/// CacheManager で日付ベースのキャッシュを管理する。
@Observable
@MainActor
final class DailyContentService {

    // MARK: - Properties

    /// 今日の運勢データ
    private(set) var todaysFortune: ComposedDailyFortune?

    /// 読み込み中かどうか
    private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private let composer: FortuneComposer
    private let cache: CacheManager

    // MARK: - Init

    init(
        composer: FortuneComposer = FortuneComposer(),
        cache: CacheManager = .shared
    ) {
        self.composer = composer
        self.cache = cache
    }

    // MARK: - Load Daily Fortune

    /// 今日の運勢を読み込む
    /// キャッシュがあればそれを使用し、なければ新規に生成してキャッシュする。
    /// - Parameter profile: ユーザープロフィール
    func loadDailyFortune(profile: UserProfile) async {
        isLoading = true
        defer { isLoading = false }

        let cacheKey = dailyCacheKey(for: profile)

        // キャッシュチェック
        if let cached: ComposedDailyFortune = cache.get(key: cacheKey) {
            todaysFortune = cached
            #if DEBUG
            print("[DailyContentService] Loaded daily fortune from cache")
            #endif
            return
        }

        // 新規生成（軽い非同期待機を入れてUI更新を許す）
        await Task.yield()

        let fortune = composer.composeDailyFortune(profile: profile, date: Date())

        // キャッシュに保存（TTL: 当日の残り時間 or 最大6時間）
        let ttl = calculateTTL()
        cache.set(key: cacheKey, value: fortune, ttl: ttl)

        todaysFortune = fortune

        #if DEBUG
        print("[DailyContentService] Generated new daily fortune (score: \(fortune.overallScore), TTL: \(Int(ttl))s)")
        #endif
    }

    // MARK: - Refresh

    /// キャッシュを無効化して再読み込み
    func refresh(profile: UserProfile) async {
        let cacheKey = dailyCacheKey(for: profile)
        cache.invalidate(key: cacheKey)
        await loadDailyFortune(profile: profile)
    }

    // MARK: - Private Helpers

    /// 日付ベースのキャッシュキーを生成
    private func dailyCacheKey(for profile: UserProfile) -> String {
        CacheKey.daily(CacheKey.dailyFortune)
    }

    /// 当日の残り時間に基づいた TTL を計算（最大6時間）
    private func calculateTTL() -> TimeInterval {
        let calendar = Calendar(identifier: .gregorian)
        var tokyoCalendar = calendar
        tokyoCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current

        let now = Date()
        guard let endOfDay = tokyoCalendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: now
        ) else {
            return 21_600 // 6時間のフォールバック
        }

        let remainingSeconds = endOfDay.timeIntervalSince(now)
        // 最小15分、最大6時間
        return max(900, min(remainingSeconds, 21_600))
    }
}
