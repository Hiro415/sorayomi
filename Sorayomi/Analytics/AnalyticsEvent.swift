import Foundation

// MARK: - AnalyticsEvent

/// アプリ全体のアナリティクスイベント定義
/// 各画面・機能から送信されるイベントを統一的に管理する。
enum AnalyticsEvent {

    // MARK: - App Lifecycle

    /// アプリ起動
    case appLaunched(isFirstLaunch: Bool)
    /// セッション開始
    case sessionStarted(daysSinceLastSession: Int)

    // MARK: - Onboarding

    /// オンボーディング開始
    case onboardingStarted
    /// オンボーディングページ表示
    case onboardingPageViewed(page: Int)
    /// オンボーディング完了
    case onboardingCompleted(
        hasBirthday: Bool,
        hasBloodType: Bool,
        consentedToAI: Bool
    )
    /// オンボーディング離脱
    case onboardingAbandoned(lastPage: Int)

    // MARK: - Home & Entry

    /// ホーム画面表示
    case homeScreenViewed
    /// 悩みベース入口タップ
    case concernEntryTapped(concern: String)
    /// テーマショートカットタップ
    case themeShortcutTapped(theme: String, system: String)
    /// 占術ピッカー表示
    case fortunePickerOpened

    // MARK: - Daily

    /// 今日の運勢を閲覧
    case dailyFortuneViewed(
        zodiacSign: String?,
        overallScore: Int
    )

    // MARK: - Reading

    /// 鑑定を開始
    case readingStarted(
        system: String,
        category: String
    )
    /// ヒアリング応答数
    case readingHearingCompleted(
        system: String,
        responseCount: Int
    )
    /// 鑑定が完了
    case readingCompleted(
        system: String,
        category: String,
        creditsCost: Int
    )
    /// 鑑定結果を最後まで閲覧
    case readingResultViewed(
        system: String,
        scrolledToEnd: Bool
    )
    /// 安全性によりブロックされた
    case readingSafetyBlocked(
        classification: String
    )
    /// 鑑定エラーが発生
    case readingError(
        system: String,
        errorDescription: String
    )

    // MARK: - Monetization — Paywall

    /// ペイウォールが表示された
    case paywallShown(
        trigger: String,
        requiredCredits: Int,
        currentBalance: Int
    )
    /// ペイウォールを閉じた（購入せず）
    case paywallDismissed(trigger: String)

    // MARK: - Monetization — Purchase

    /// 購入を開始
    case purchaseStarted(productId: String)
    /// 購入が完了
    case purchaseCompleted(productId: String, credits: Int, revenue: Double)
    /// 購入が失敗
    case purchaseFailed(productId: String, errorDescription: String)
    /// 購入をキャンセル
    case purchaseCancelled(productId: String)
    /// 購入を復元
    case purchaseRestored

    // MARK: - Monetization — Starter Pack

    /// スターターパック表示
    case starterPackShown(location: String)
    /// スターターパック購入
    case starterPackPurchased

    // MARK: - Monetization — Subscription

    /// サブスクリプション開始
    case subscriptionStarted(productId: String)
    /// サブスクリプション更新
    case subscriptionRenewed(productId: String)
    /// サブスクリプション解約
    case subscriptionCancelled(productId: String)

    // MARK: - Ad Reward

    /// 広告リワードボタン表示
    case adRewardShown
    /// 広告視聴開始
    case adRewardStarted
    /// 広告視聴完了・クレジット付与
    case adRewardCompleted(creditsGranted: Int)
    /// 広告視聴失敗
    case adRewardFailed(reason: String)

    // MARK: - Credit

    /// クレジット残高がゼロになった
    case creditBalanceZero
    /// クレジット残高が低い（≤2）
    case creditBalanceLow(remaining: Int)

    // MARK: - Engagement

    /// ストリーク更新
    case streakUpdated(
        currentStreak: Int,
        longestStreak: Int
    )
    /// ストリークマイルストーン達成
    case streakMilestoneReached(
        days: Int,
        creditsAwarded: Int
    )
    /// 鑑定結果をシェア
    case readingShared(system: String, method: String)
    /// 通知を有効化
    case notificationsEnabled
    /// 通知を無効化
    case notificationsDisabled

    // MARK: - Review

    /// レビュー依頼ダイアログ表示
    case reviewRequestShown(readingCount: Int)
    /// レビュー依頼に応答（SKStoreReviewControllerでは結果不明だが表示は追跡）
    case reviewRequestPresented

    // MARK: - Safety

    /// 危機的状況を検出
    case safetyCrisisDetected(crisisType: String)
    /// 安全な拒否メッセージを表示
    case safetySafeRefusalShown(classification: String)

    // MARK: - Navigation

    /// タブを切り替え
    case navigationTabSwitched(tabName: String)
    /// 設定を開いた
    case navigationSettingsOpened

    // MARK: - Legacy compat (旧イベント名の互換エイリアス)

    /// 旧ペイウォール表示イベント（互換用）
    static func monetizationPaywallShown(requiredCredits: Int, currentBalance: Int) -> AnalyticsEvent {
        .paywallShown(trigger: "credit_check", requiredCredits: requiredCredits, currentBalance: currentBalance)
    }

    /// 旧購入開始イベント（互換用）
    static func monetizationPurchaseStarted(productId: String) -> AnalyticsEvent {
        .purchaseStarted(productId: productId)
    }

    /// 旧購入完了イベント（互換用）
    static func monetizationPurchaseCompleted(productId: String, credits: Int) -> AnalyticsEvent {
        .purchaseCompleted(productId: productId, credits: credits, revenue: 0)
    }

    /// 旧購入失敗イベント（互換用）
    static func monetizationPurchaseFailed(productId: String, errorDescription: String) -> AnalyticsEvent {
        .purchaseFailed(productId: productId, errorDescription: errorDescription)
    }

    /// 旧購入復元イベント（互換用）
    static var monetizationPurchaseRestored: AnalyticsEvent {
        .purchaseRestored
    }

    // MARK: - Event Name

    /// アナリティクスプラットフォームに送信するイベント名
    var name: String {
        switch self {
        case .appLaunched:                return "app_launched"
        case .sessionStarted:             return "session_started"
        case .onboardingStarted:          return "onboarding_started"
        case .onboardingPageViewed:       return "onboarding_page_viewed"
        case .onboardingCompleted:        return "onboarding_completed"
        case .onboardingAbandoned:        return "onboarding_abandoned"
        case .homeScreenViewed:           return "home_screen_viewed"
        case .concernEntryTapped:         return "concern_entry_tapped"
        case .themeShortcutTapped:        return "theme_shortcut_tapped"
        case .fortunePickerOpened:        return "fortune_picker_opened"
        case .dailyFortuneViewed:         return "daily_fortune_viewed"
        case .readingStarted:             return "reading_started"
        case .readingHearingCompleted:    return "reading_hearing_completed"
        case .readingCompleted:           return "reading_completed"
        case .readingResultViewed:        return "reading_result_viewed"
        case .readingSafetyBlocked:       return "reading_safety_blocked"
        case .readingError:               return "reading_error"
        case .paywallShown:               return "paywall_shown"
        case .paywallDismissed:           return "paywall_dismissed"
        case .purchaseStarted:            return "purchase_started"
        case .purchaseCompleted:          return "purchase_completed"
        case .purchaseFailed:             return "purchase_failed"
        case .purchaseCancelled:          return "purchase_cancelled"
        case .purchaseRestored:           return "purchase_restored"
        case .starterPackShown:           return "starter_pack_shown"
        case .starterPackPurchased:       return "starter_pack_purchased"
        case .subscriptionStarted:        return "subscription_started"
        case .subscriptionRenewed:        return "subscription_renewed"
        case .subscriptionCancelled:      return "subscription_cancelled"
        case .adRewardShown:              return "ad_reward_shown"
        case .adRewardStarted:            return "ad_reward_started"
        case .adRewardCompleted:          return "ad_reward_completed"
        case .adRewardFailed:             return "ad_reward_failed"
        case .creditBalanceZero:          return "credit_balance_zero"
        case .creditBalanceLow:           return "credit_balance_low"
        case .streakUpdated:              return "streak_updated"
        case .streakMilestoneReached:     return "streak_milestone_reached"
        case .readingShared:              return "reading_shared"
        case .notificationsEnabled:       return "notifications_enabled"
        case .notificationsDisabled:      return "notifications_disabled"
        case .reviewRequestShown:         return "review_request_shown"
        case .reviewRequestPresented:     return "review_request_presented"
        case .safetyCrisisDetected:       return "crisis_detected"
        case .safetySafeRefusalShown:     return "safe_refusal_shown"
        case .navigationTabSwitched:      return "tab_switched"
        case .navigationSettingsOpened:   return "settings_opened"
        }
    }

    // MARK: - Event Parameters

    /// イベントに付随するパラメータ
    var parameters: [String: String] {
        switch self {
        case .appLaunched(let isFirstLaunch):
            return ["is_first_launch": String(isFirstLaunch)]

        case .sessionStarted(let days):
            return ["days_since_last": String(days)]

        case .onboardingStarted:
            return [:]

        case .onboardingPageViewed(let page):
            return ["page": String(page)]

        case .onboardingCompleted(let hasBirthday, let hasBloodType, let consentedToAI):
            return [
                "has_birthday": String(hasBirthday),
                "has_blood_type": String(hasBloodType),
                "consented_to_ai": String(consentedToAI)
            ]

        case .onboardingAbandoned(let lastPage):
            return ["last_page": String(lastPage)]

        case .homeScreenViewed:
            return [:]

        case .concernEntryTapped(let concern):
            return ["concern": concern]

        case .themeShortcutTapped(let theme, let system):
            return ["theme": theme, "system": system]

        case .fortunePickerOpened:
            return [:]

        case .dailyFortuneViewed(let zodiacSign, let overallScore):
            var params: [String: String] = ["overall_score": String(overallScore)]
            if let sign = zodiacSign { params["zodiac_sign"] = sign }
            return params

        case .readingStarted(let system, let category):
            return ["system": system, "category": category]

        case .readingHearingCompleted(let system, let responseCount):
            return ["system": system, "response_count": String(responseCount)]

        case .readingCompleted(let system, let category, let creditsCost):
            return ["system": system, "category": category, "credits_cost": String(creditsCost)]

        case .readingResultViewed(let system, let scrolledToEnd):
            return ["system": system, "scrolled_to_end": String(scrolledToEnd)]

        case .readingSafetyBlocked(let classification):
            return ["classification": classification]

        case .readingError(let system, let errorDescription):
            return ["system": system, "error": errorDescription]

        case .paywallShown(let trigger, let requiredCredits, let currentBalance):
            return [
                "trigger": trigger,
                "required_credits": String(requiredCredits),
                "current_balance": String(currentBalance)
            ]

        case .paywallDismissed(let trigger):
            return ["trigger": trigger]

        case .purchaseStarted(let productId):
            return ["product_id": productId]

        case .purchaseCompleted(let productId, let credits, let revenue):
            return ["product_id": productId, "credits": String(credits), "revenue": String(format: "%.2f", revenue)]

        case .purchaseFailed(let productId, let errorDescription):
            return ["product_id": productId, "error": errorDescription]

        case .purchaseCancelled(let productId):
            return ["product_id": productId]

        case .purchaseRestored:
            return [:]

        case .starterPackShown(let location):
            return ["location": location]

        case .starterPackPurchased:
            return [:]

        case .subscriptionStarted(let productId):
            return ["product_id": productId]

        case .subscriptionRenewed(let productId):
            return ["product_id": productId]

        case .subscriptionCancelled(let productId):
            return ["product_id": productId]

        case .adRewardShown:
            return [:]

        case .adRewardStarted:
            return [:]

        case .adRewardCompleted(let creditsGranted):
            return ["credits_granted": String(creditsGranted)]

        case .adRewardFailed(let reason):
            return ["reason": reason]

        case .creditBalanceZero:
            return [:]

        case .creditBalanceLow(let remaining):
            return ["remaining": String(remaining)]

        case .streakUpdated(let currentStreak, let longestStreak):
            return ["current_streak": String(currentStreak), "longest_streak": String(longestStreak)]

        case .streakMilestoneReached(let days, let creditsAwarded):
            return ["days": String(days), "credits_awarded": String(creditsAwarded)]

        case .readingShared(let system, let method):
            return ["system": system, "method": method]

        case .notificationsEnabled, .notificationsDisabled:
            return [:]

        case .reviewRequestShown(let readingCount):
            return ["reading_count": String(readingCount)]

        case .reviewRequestPresented:
            return [:]

        case .safetyCrisisDetected(let crisisType):
            return ["crisis_type": crisisType]

        case .safetySafeRefusalShown(let classification):
            return ["classification": classification]

        case .navigationTabSwitched(let tabName):
            return ["tab_name": tabName]

        case .navigationSettingsOpened:
            return [:]
        }
    }
}
