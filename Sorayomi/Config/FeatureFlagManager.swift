import Foundation

/// Controls feature visibility across the app.
///
/// For the MVP every flag defaults to a sensible local value.
/// Once Firebase Remote Config is integrated, call `syncFromRemoteConfig()`
/// on launch to override local defaults with server-driven values.
@Observable
@MainActor
final class FeatureFlagManager {

    // MARK: - Reading Types

    /// Western horoscope readings (always on for MVP).
    var isHoroscopeEnabled: Bool = true

    /// Tarot card readings.
    var isTarotEnabled: Bool = true

    /// Numerology readings.
    var isNumerologyEnabled: Bool = true

    /// Nine Star Ki (九星気学) readings.
    var isNineStarKiEnabled: Bool = true

    /// Combined multi-system reading (disabled for MVP; requires all engines).
    var isCombinedReadingEnabled: Bool = false

    // MARK: - Monetization

    /// In-app subscription tier.
    var isSubscriptionEnabled: Bool = true

    /// Credit store availability.
    var isCreditStoreEnabled: Bool = true

    /// スターターパック表示（1回限りの初回パック）
    var isStarterPackEnabled: Bool = true

    // MARK: - Advertising

    /// 広告リワード機能（デフォルトOFF — 初期リリースでは無効）
    /// ONにすると、非サブスク会員に1日1回の広告視聴で1クレジットを提供。
    var isAdRewardEnabled: Bool = false

    /// 広告リワードの1日あたりの上限回数
    var adRewardDailyLimit: Int = 1

    // MARK: - Premium Gating

    /// 鑑定履歴の閲覧をプレミアム限定にするか
    var isHistoryPremiumOnly: Bool = false

    /// 相手プロフィール保存をプレミアム限定にするか
    var isPartnerProfilePremiumOnly: Bool = true

    /// テンプレート相談をプレミアム限定にするか
    var isTemplatePremiumOnly: Bool = true

    /// プレミアム占術（数秘術・九星気学）の無制限利用をプレミアム特典にするか
    var isPremiumFortuneUnlimitedForSubscribers: Bool = true

    // MARK: - Operational

    /// When `true` the app shows a maintenance banner and disables readings.
    var maintenanceMode: Bool = false

    /// Message displayed during maintenance.
    var maintenanceMessage: String = "現在メンテナンス中です。しばらくお待ちください。"

    // MARK: - Experimental / A-B Tests

    /// Show the animated fortune reveal (vs. instant display).
    var isAnimatedRevealEnabled: Bool = true

    /// Show daily fortune push notification prompt.
    var isDailyNotificationPromptEnabled: Bool = false

    /// 悩みベースの入口を有効にするか（ホーム画面リデザイン）
    var isConcernBasedEntryEnabled: Bool = true

    /// レビュー依頼ダイアログを有効にするか
    var isReviewRequestEnabled: Bool = true

    // MARK: - Remote Config Sync

    /// Refreshes flags from Firebase Remote Config.
    /// TODO: Implement once FirebaseRemoteConfig is added as a dependency.
    func syncFromRemoteConfig() async {
        // TODO: Fetch and apply remote values.
        // Example:
        // let rc = RemoteConfig.remoteConfig()
        // try? await rc.fetchAndActivate()
        // isAdRewardEnabled = rc["ad_reward_enabled"].boolValue
        // isStarterPackEnabled = rc["starter_pack_enabled"].boolValue
        // ...
    }
}
