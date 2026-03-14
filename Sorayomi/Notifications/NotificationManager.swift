import Foundation
import UserNotifications

// MARK: - NotificationManager

/// 日次ローカル通知のスケジュールと権限管理
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
            if isEnabled {
                scheduleDailyNotification()
            } else {
                cancelAllNotifications()
            }
        }
    }

    /// 通知時刻（時）
    var notificationHour: Int {
        didSet {
            UserDefaults.standard.set(notificationHour, forKey: Keys.notificationHour)
            if isEnabled { scheduleDailyNotification() }
        }
    }

    /// 通知時刻（分）
    var notificationMinute: Int {
        didSet {
            UserDefaults.standard.set(notificationMinute, forKey: Keys.notificationMinute)
            if isEnabled { scheduleDailyNotification() }
        }
    }

    // MARK: - Constants

    private static let dailyNotificationID = "sorayomi_daily_reading"

    private static let messages: [String] = [
        "今日の宙よみが届いています ✨",
        "星の導きを確認しましょう 🌙",
        "今日のあなたの運勢は？",
        "宇宙からのメッセージが届いています",
        "今日も一日、星に見守られて ⭐",
        "あなたの宙よみを見てみましょう",
        "今日の流れを宙に聞いてみませんか？",
        "星たちがあなたに伝えたいことがあるようです"
    ]

    // MARK: - Init

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        self.notificationHour = UserDefaults.standard.object(forKey: Keys.notificationHour) as? Int ?? 7
        self.notificationMinute = UserDefaults.standard.object(forKey: Keys.notificationMinute) as? Int ?? 0
    }

    // MARK: - Authorization

    /// 通知の許可をリクエスト
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted

            if granted && isEnabled {
                scheduleDailyNotification()
            }

            #if DEBUG
            print("[NotificationManager] Authorization \(granted ? "granted" : "denied")")
            #endif
        } catch {
            #if DEBUG
            print("[NotificationManager] Authorization request failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// 現在の許可状態を確認
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    /// 日次通知をスケジュール
    func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()

        // 既存の通知をキャンセルしてから再スケジュール
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyNotificationID])

        let content = UNMutableNotificationContent()
        content.title = AppConstants.appName
        content.body = Self.messages.randomElement() ?? Self.messages[0]
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.dailyNotificationID,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            #if DEBUG
            if let error {
                print("[NotificationManager] Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("[NotificationManager] Daily notification scheduled for \(dateComponents.hour ?? 0):\(String(format: "%02d", dateComponents.minute ?? 0))")
            }
            #endif
        }
    }

    /// すべての通知をキャンセル
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationsEnabled = "sorayomi_notifications_enabled"
        static let notificationHour = "sorayomi_notification_hour"
        static let notificationMinute = "sorayomi_notification_minute"
    }
}
