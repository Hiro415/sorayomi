import Foundation

// MARK: - AnalyticsEvent

/// アプリ全体のアナリティクスイベント定義
/// 各画面・機能から送信されるイベントを統一的に管理する。
enum AnalyticsEvent {

    // MARK: - Onboarding

    /// オンボーディング開始
    case onboardingStarted
    /// オンボーディング完了
    case onboardingCompleted(
        hasBirthday: Bool,
        hasBloodType: Bool,
        consentedToAI: Bool
    )

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
    /// 鑑定が完了
    case readingCompleted(
        system: String,
        category: String,
        creditsCost: Int
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

    // MARK: - Monetization

    /// ペイウォールが表示された
    case monetizationPaywallShown(
        requiredCredits: Int,
        currentBalance: Int
    )
    /// 購入を開始
    case monetizationPurchaseStarted(
        productId: String
    )
    /// 購入が完了
    case monetizationPurchaseCompleted(
        productId: String,
        credits: Int
    )
    /// 購入が失敗
    case monetizationPurchaseFailed(
        productId: String,
        errorDescription: String
    )
    /// 購入を復元
    case monetizationPurchaseRestored

    // MARK: - Safety

    /// 危機的状況を検出
    case safetyCrisisDetected(
        crisisType: String
    )
    /// 安全な拒否メッセージを表示
    case safetySafeRefusalShown(
        classification: String
    )

    // MARK: - Navigation

    /// タブを切り替え
    case navigationTabSwitched(
        tabName: String
    )
    /// 設定を開いた
    case navigationSettingsOpened

    // MARK: - Event Name

    /// アナリティクスプラットフォームに送信するイベント名
    var name: String {
        switch self {
        case .onboardingStarted:              return "onboarding_started"
        case .onboardingCompleted:            return "onboarding_completed"
        case .dailyFortuneViewed:             return "daily_fortune_viewed"
        case .readingStarted:                 return "reading_started"
        case .readingCompleted:               return "reading_completed"
        case .readingSafetyBlocked:           return "reading_safety_blocked"
        case .readingError:                   return "reading_error"
        case .monetizationPaywallShown:       return "paywall_shown"
        case .monetizationPurchaseStarted:    return "purchase_started"
        case .monetizationPurchaseCompleted:  return "purchase_completed"
        case .monetizationPurchaseFailed:     return "purchase_failed"
        case .monetizationPurchaseRestored:   return "purchase_restored"
        case .safetyCrisisDetected:           return "crisis_detected"
        case .safetySafeRefusalShown:         return "safe_refusal_shown"
        case .navigationTabSwitched:          return "tab_switched"
        case .navigationSettingsOpened:       return "settings_opened"
        }
    }

    // MARK: - Event Parameters

    /// イベントに付随するパラメータ
    var parameters: [String: String] {
        switch self {
        case .onboardingStarted:
            return [:]

        case .onboardingCompleted(let hasBirthday, let hasBloodType, let consentedToAI):
            return [
                "has_birthday": String(hasBirthday),
                "has_blood_type": String(hasBloodType),
                "consented_to_ai": String(consentedToAI)
            ]

        case .dailyFortuneViewed(let zodiacSign, let overallScore):
            var params: [String: String] = ["overall_score": String(overallScore)]
            if let sign = zodiacSign {
                params["zodiac_sign"] = sign
            }
            return params

        case .readingStarted(let system, let category):
            return [
                "system": system,
                "category": category
            ]

        case .readingCompleted(let system, let category, let creditsCost):
            return [
                "system": system,
                "category": category,
                "credits_cost": String(creditsCost)
            ]

        case .readingSafetyBlocked(let classification):
            return ["classification": classification]

        case .readingError(let system, let errorDescription):
            return [
                "system": system,
                "error": errorDescription
            ]

        case .monetizationPaywallShown(let requiredCredits, let currentBalance):
            return [
                "required_credits": String(requiredCredits),
                "current_balance": String(currentBalance)
            ]

        case .monetizationPurchaseStarted(let productId):
            return ["product_id": productId]

        case .monetizationPurchaseCompleted(let productId, let credits):
            return [
                "product_id": productId,
                "credits": String(credits)
            ]

        case .monetizationPurchaseFailed(let productId, let errorDescription):
            return [
                "product_id": productId,
                "error": errorDescription
            ]

        case .monetizationPurchaseRestored:
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
