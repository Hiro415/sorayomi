import Foundation

// MARK: - StreakManager

/// 連続利用日数（ストリーク）を追跡し、マイルストーン報酬を管理する
@Observable
@MainActor
final class StreakManager {

    // MARK: - Properties

    /// 現在の連続日数
    private(set) var currentStreak: Int = 0

    /// 最長連続記録
    private(set) var longestStreak: Int = 0

    /// 今日すでに記録済みか
    private(set) var hasLoggedToday: Bool = false

    /// 最後の利用日
    private(set) var lastActiveDate: Date?

    /// マイルストーン達成クレジット（nil = 達成なし）
    private(set) var pendingMilestoneCredits: Int?

    // MARK: - Constants

    /// マイルストーンと報酬クレジット
    static let milestones: [(days: Int, credits: Int)] = [
        (7, 2),     // 7日連続で2クレジット
        (14, 3),    // 14日連続で3クレジット
        (30, 5),    // 30日連続で5クレジット
        (60, 8),    // 60日連続で8クレジット
        (90, 12)    // 90日連続で12クレジット
    ]

    // MARK: - Init

    init() {
        loadFromDefaults()
    }

    // MARK: - Record Activity

    /// 今日の利用を記録する。ストリークを更新し、マイルストーン達成をチェック。
    /// - Returns: マイルストーン達成時の報酬クレジット数（nil = 達成なし）
    @discardableResult
    func recordActivity() -> Int? {
        let today = Calendar.current.startOfDay(for: Date())

        // 既に今日記録済みなら何もしない
        if hasLoggedToday { return nil }

        if let last = lastActiveDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let daysDifference = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDifference == 1 {
                // 連続: ストリーク伸ばす
                currentStreak += 1
            } else if daysDifference > 1 {
                // 途切れた: リセット
                currentStreak = 1
            }
            // daysDifference == 0 shouldn't happen (hasLoggedToday check above)
        } else {
            // 初回利用
            currentStreak = 1
        }

        lastActiveDate = today
        hasLoggedToday = true

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        saveToDefaults()

        // マイルストーンチェック
        let milestoneReward = checkMilestone()
        pendingMilestoneCredits = milestoneReward

        #if DEBUG
        print("[StreakManager] Streak: \(currentStreak) days (longest: \(longestStreak))")
        if let reward = milestoneReward {
            print("[StreakManager] Milestone reached! +\(reward) credits")
        }
        #endif

        return milestoneReward
    }

    /// マイルストーン報酬をクリア（UIで表示した後に呼ぶ）
    func clearPendingMilestone() {
        pendingMilestoneCredits = nil
    }

    // MARK: - Milestone Check

    private func checkMilestone() -> Int? {
        for milestone in Self.milestones where currentStreak == milestone.days {
            return milestone.credits
        }
        return nil
    }

    // MARK: - Display Helpers

    /// ストリーク表示テキスト
    var streakDisplayText: String {
        if currentStreak == 0 {
            return "今日から始めよう"
        }
        return "\(currentStreak)日連続"
    }

    /// 次のマイルストーンまでの残り日数
    var daysToNextMilestone: Int? {
        for milestone in Self.milestones where milestone.days > currentStreak {
            return milestone.days - currentStreak
        }
        return nil
    }

    /// 次のマイルストーン情報
    var nextMilestoneInfo: (days: Int, credits: Int)? {
        Self.milestones.first { $0.days > currentStreak }
    }

    // MARK: - Persistence

    private func saveToDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(longestStreak, forKey: Keys.longestStreak)
        defaults.set(lastActiveDate?.timeIntervalSince1970, forKey: Keys.lastActiveDate)
    }

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard
        currentStreak = defaults.integer(forKey: Keys.currentStreak)
        longestStreak = defaults.integer(forKey: Keys.longestStreak)

        if let timestamp = defaults.object(forKey: Keys.lastActiveDate) as? TimeInterval {
            lastActiveDate = Date(timeIntervalSince1970: timestamp)

            // 今日記録済みかチェック
            let today = Calendar.current.startOfDay(for: Date())
            let lastDay = Calendar.current.startOfDay(for: lastActiveDate!)
            hasLoggedToday = today == lastDay

            // 2日以上経過していたらストリークをリセット
            let daysDifference = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if daysDifference > 1 {
                currentStreak = 0
                saveToDefaults()
            }
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let currentStreak = "sorayomi_streak_current"
        static let longestStreak = "sorayomi_streak_longest"
        static let lastActiveDate = "sorayomi_streak_last_active"
    }
}
