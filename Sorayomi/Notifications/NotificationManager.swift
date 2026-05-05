import Foundation
@preconcurrency import UserNotifications

// MARK: - NotificationManager

/// ローカル通知の権限管理・スケジュール管理
///
/// 3種類の通知を管理する:
/// 1. 朝の運勢通知 — ユーザー設定時刻（デフォルト 7:30）、7日分を事前スケジュール
/// 2. ストリークリマインダー — 毎日20時、ユーザーが当日の占いを済ませたらキャンセル
/// 3. 大安通知 — 今後30日以内の大安日の08:00
@Observable
@MainActor
final class NotificationManager {

    // MARK: - Properties

    /// 通知の許可状態
    private(set) var isAuthorized: Bool = false

    /// 通知が有効かどうか（ユーザー設定）
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.notificationsEnabled)
            if !isEnabled { cancelAllNotifications() }
        }
    }

    /// 朝の通知時刻（時）
    var notificationHour: Int {
        didSet { UserDefaults.standard.set(notificationHour, forKey: Keys.notificationHour) }
    }

    /// 朝の通知時刻（分）
    var notificationMinute: Int {
        didSet { UserDefaults.standard.set(notificationMinute, forKey: Keys.notificationMinute) }
    }

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let morningPrefix  = "sorayomi_morning_"    // + "yyyy-MM-dd"
        static let streakReminder = "sorayomi_streak_reminder"
        static let luckyDayPrefix = "sorayomi_lucky_"      // + "yyyy-MM-dd"
    }

    // MARK: - Copy

    /// 曜日インデックス(0=日〜6=土)や日付から選ぶ朝の通知メッセージ
    private static let morningMessages: [(title: String, body: String)] = [
        ("今日の宙よみ ✨",         "星たちがあなたに伝えたいことがあるようです"),
        ("🌙 朝の導き",             "今日一日の流れを宙に聞いてみましょう"),
        ("✨ 運勢が届いています",   "あなたの宙よみを開いてみてください"),
        ("🌟 星の声",               "宇宙からのメッセージが待っています"),
        ("今朝の占い 🔮",           "今日も星に見守られた一日を"),
        ("🌸 朝の宙よみ",           "今日のあなたへ、星からの贈りもの"),
        ("✨ 今日の流れは？",        "宙よみで今日の運気をチェックしましょう"),
    ]

    private static let streakReminderTitle = "🌙 今日の占いはまだですか？"
    private static let streakReminderBody  = "連続記録を守って、星の加護を受け続けましょう"

    private static let luckyDayTitle = "✨ 今日は大安です"
    private static let luckyDayBody  = "縁起の良い日。宙よみで今日のエネルギーを受け取りましょう"

    // MARK: - Init

    init() {
        self.isEnabled        = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        self.notificationHour = UserDefaults.standard.object(forKey: Keys.notificationHour)   as? Int ?? 7
        self.notificationMinute = UserDefaults.standard.object(forKey: Keys.notificationMinute) as? Int ?? 30
    }

    // MARK: - Authorization

    /// 通知許可をリクエスト（オンボーディングから呼ぶ）
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                isEnabled = true
                scheduleAllNotifications(hasLoggedToday: false)
            }
            #if DEBUG
            print("[NotificationManager] Authorization \(granted ? "granted" : "denied")")
            #endif
        } catch {
            #if DEBUG
            print("[NotificationManager] Authorization error: \(error.localizedDescription)")
            #endif
        }
    }

    /// 現在の許可状態を確認（アプリ起動時に呼ぶ）
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Public API

    /// アプリ起動時・ホーム表示時に呼ぶ。通知を最新状態に更新する。
    func refresh(hasLoggedToday: Bool) {
        guard isAuthorized && isEnabled else { return }
        scheduleAllNotifications(hasLoggedToday: hasLoggedToday)
    }

    /// ユーザーが今日の占いを記録したときに呼ぶ。ストリークリマインダーを当日キャンセル。
    func onUserLoggedActivity() {
        guard isAuthorized && isEnabled else { return }
        cancelStreakReminder()
    }

    // MARK: - Scheduling

    private func scheduleAllNotifications(hasLoggedToday: Bool) {
        scheduleMorningNotifications()
        scheduleLuckyDayNotifications()

        if hasLoggedToday {
            cancelStreakReminder()
        } else {
            scheduleStreakReminder()
        }
    }

    /// 朝の運勢通知を今日から7日分スケジュール（固定日時指定、repeats: false）
    private func scheduleMorningNotifications() {
        let center   = UNUserNotificationCenter.current()
        let calendar = Calendar(identifier: .gregorian)
        let now      = Date()
        let hour     = notificationHour
        let minute   = notificationMinute

        // 今日の通知時刻を計算して過去であればスキップ
        for dayOffset in 0..<7 {
            guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            var dc = calendar.dateComponents([.year, .month, .day], from: targetDay)
            dc.hour   = hour
            dc.minute = minute
            dc.second = 0

            guard let fireDate = calendar.date(from: dc), fireDate > now else { continue }

            let dateStr = isoDateString(from: targetDay)
            let id      = NotificationID.morningPrefix + dateStr

            // メッセージは日付の日(1〜31)をインデックスに使って分散させる
            let dayOfMonth  = calendar.component(.day, from: targetDay)
            let messageIdx  = dayOfMonth % Self.morningMessages.count
            let message     = Self.morningMessages[messageIdx]

            let content      = UNMutableNotificationContent()
            content.title    = message.title
            content.body     = message.body
            content.sound    = .default

            let trigger  = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
            let request  = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            center.add(request) { error in
                #if DEBUG
                if let error { print("[NotificationManager] Morning \(dateStr) error: \(error.localizedDescription)") }
                #endif
            }
        }

        removeStaleMorningNotifications()
    }

    /// ストリークリマインダーを毎日 20:00 の繰り返し通知でスケジュール
    private func scheduleStreakReminder() {
        let content      = UNMutableNotificationContent()
        content.title    = Self.streakReminderTitle
        content.body     = Self.streakReminderBody
        content.sound    = .default

        var dc        = DateComponents()
        dc.hour       = 20
        dc.minute     = 0

        let trigger   = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request   = UNNotificationRequest(
            identifier: NotificationID.streakReminder,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error { print("[NotificationManager] Streak reminder error: \(error.localizedDescription)") }
            else         { print("[NotificationManager] Streak reminder scheduled at 20:00") }
            #endif
        }
    }

    /// ストリークリマインダーをキャンセル（今日占い済みのとき）
    func cancelStreakReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [NotificationID.streakReminder])
    }

    /// 今後30日以内の大安を最大5件スケジュール（各日08:00）
    private func scheduleLuckyDayNotifications() {
        let center   = UNUserNotificationCenter.current()
        let calendar = Calendar(identifier: .gregorian)
        let now      = Date()
        let endDate  = calendar.date(byAdding: .day, value: 30, to: now) ?? now
        let taianDates = Calendar.dates(withRokuyo: .taian, from: now, to: endDate)

        for taianDate in taianDates.prefix(5) {
            var dc      = calendar.dateComponents([.year, .month, .day], from: taianDate)
            dc.hour     = 8
            dc.minute   = 0
            dc.second   = 0

            guard let fireDate = calendar.date(from: dc), fireDate > now else { continue }

            let dateStr = isoDateString(from: taianDate)
            let id      = NotificationID.luckyDayPrefix + dateStr

            let content      = UNMutableNotificationContent()
            content.title    = Self.luckyDayTitle
            content.body     = Self.luckyDayBody
            content.sound    = .default

            let trigger  = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
            let request  = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            center.add(request) { error in
                #if DEBUG
                if let error { print("[NotificationManager] Lucky day \(dateStr) error: \(error.localizedDescription)") }
                #endif
            }
        }
    }

    // MARK: - Cleanup

    /// すべての通知をキャンセル
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// 過去分の朝の通知 ID を削除（ISO 文字列の辞書順比較で判定）
    private func removeStaleMorningNotifications() {
        let center     = UNUserNotificationCenter.current()
        let prefix     = NotificationID.morningPrefix
        let todayStr   = isoDateString(from: Calendar.current.startOfDay(for: Date()))

        center.getPendingNotificationRequests { requests in
            // 注意: このクロージャはバックグラウンドスレッドで呼ばれる。
            // self へのアクセスは行わず、キャプチャした String 値のみを使用する。
            let staleIDs = requests
                .map(\.identifier)
                .filter { id in
                    guard id.hasPrefix(prefix) else { return false }
                    let dateStr = String(id.dropFirst(prefix.count))
                    return dateStr < todayStr   // ISO 8601 形式は辞書順 == 時系列順
                }
            if !staleIDs.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: staleIDs)
            }
        }
    }

    // MARK: - Helpers

    /// "yyyy-MM-dd" 形式の日付文字列を返す（ID生成・比較用）
    private func isoDateString(from date: Date) -> String {
        let formatter        = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale     = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationsEnabled = "sorayomi_notifications_enabled"
        static let notificationHour     = "sorayomi_notification_hour"
        static let notificationMinute   = "sorayomi_notification_minute"
    }
}
