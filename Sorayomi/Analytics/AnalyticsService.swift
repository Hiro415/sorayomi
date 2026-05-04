import Foundation

// MARK: - AnalyticsService

/// アナリティクスイベントの送信サービス
/// AnalyticsProviderProtocol に準拠した任意のプロバイダーに
/// イベントを委譲する。
@Observable
@MainActor
final class AnalyticsService {

    // MARK: - Singleton

    static let shared = AnalyticsService()

    // MARK: - Dependencies

    private let provider: AnalyticsProviderProtocol

    // MARK: - Properties

    /// 送信済みイベント数（デバッグ用）
    private(set) var eventCount: Int = 0

    // MARK: - Init

    init(provider: AnalyticsProviderProtocol = ConsoleAnalyticsProvider.shared) {
        self.provider = provider
    }

    // MARK: - Track Event

    /// AnalyticsEvent を送信する
    /// - Parameter event: 送信するイベント
    func track(_ event: AnalyticsEvent) {
        provider.track(name: event.name, parameters: event.parameters)
        eventCount += 1
    }

    // MARK: - User Properties

    /// ユーザープロパティを設定する
    /// - Parameters:
    ///   - name: プロパティ名
    ///   - value: プロパティ値（nil で削除）
    func setUserProperty(_ name: String, value: String?) {
        provider.setUserProperty(name: name, value: value)
    }

    // MARK: - Convenience Methods

    /// オンボーディング開始を記録
    func trackOnboardingStarted() {
        track(.onboardingStarted)
    }

    /// オンボーディング完了を記録
    func trackOnboardingCompleted(profile: UserProfile) {
        track(.onboardingCompleted(
            hasBirthday: profile.birthday != nil,
            hasBloodType: profile.bloodType != nil,
            consentedToAI: profile.hasConsentedToAI
        ))
    }

    /// 鑑定開始を記録
    func trackReadingStarted(system: FortuneSystem, category: ReadingCategory) {
        track(.readingStarted(
            system: system.rawValue,
            category: category.rawValue
        ))
    }

    /// 鑑定完了を記録
    func trackReadingCompleted(reading: FortuneReading) {
        track(.readingCompleted(
            system: reading.system.rawValue,
            category: reading.theme.rawValue,
            creditsCost: reading.creditsCost
        ))
    }

    /// 購入完了を記録
    func trackPurchaseCompleted(productId: String, credits: Int) {
        track(.purchaseCompleted(
            productId: productId,
            credits: credits,
            revenue: 0
        ))
    }

    /// ペイウォール表示を記録
    func trackPaywallShown(trigger: String, requiredCredits: Int, currentBalance: Int) {
        track(.paywallShown(
            trigger: trigger,
            requiredCredits: requiredCredits,
            currentBalance: currentBalance
        ))
    }

    /// スターターパック表示を記録
    func trackStarterPackShown(location: String) {
        track(.starterPackShown(location: location))
    }

    /// レビュー依頼表示を記録
    func trackReviewRequestShown(readingCount: Int) {
        track(.reviewRequestShown(readingCount: readingCount))
    }
}
