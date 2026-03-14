import SwiftUI

/// Central dependency-injection container for the Sorayomi app.
///
/// `AppEnvironment` owns every service the UI layer needs and is
/// injected into the SwiftUI environment at the root.  For the MVP
/// build all services use local / mock implementations.  Firebase-backed
/// implementations will replace them once the backend is wired.
@Observable
@MainActor
final class AppEnvironment {

    // MARK: - Services

    /// Provides safety-reviewed UI copy for every user-facing string.
    let copyProvider: CopyProvider

    /// Manages the authenticated user profile.
    let userProfileService: UserProfileService

    /// Tracks credit balance, purchases, and consumption.
    let creditWalletService: CreditWalletService

    /// Fires analytics events (screen views, reading completions, etc.).
    let analyticsService: AnalyticsService

    /// Controls which features are visible / enabled.
    let featureFlags: FeatureFlagManager

    /// Pricing resolved from remote config with local fallbacks.
    let pricingConfig: PricingConfig

    /// Programmatic navigation across tabs.
    let navigationRouter: NavigationRouter

    /// StoreKit 2 課金管理（クレジットパック＆サブスクリプション）
    let storeKitManager: StoreKitManager

    /// 日次ローカル通知管理
    let notificationManager: NotificationManager

    /// 連続利用日数（ストリーク）の追跡
    let streakManager: StreakManager

    // MARK: - Onboarding State

    /// `true` after the user completes the first-run onboarding flow.
    /// Persisted in `UserDefaults` so the decision survives app restarts.
    var isOnboardingComplete: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingComplete, forKey: Keys.onboardingComplete)
        }
    }

    // MARK: - Init

    init() {
        self.copyProvider = .shared
        self.userProfileService = UserProfileService()
        self.creditWalletService = CreditWalletService()
        self.analyticsService = AnalyticsService()
        self.featureFlags = FeatureFlagManager()
        self.pricingConfig = PricingConfig()
        self.navigationRouter = NavigationRouter()
        self.storeKitManager = StoreKitManager()
        self.notificationManager = NotificationManager()
        self.streakManager = StreakManager()
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: Keys.onboardingComplete)
    }

    // MARK: - Actions

    /// Call this once the user finishes the onboarding flow.
    func completeOnboarding() {
        isOnboardingComplete = true
        analyticsService.track(.onboardingCompleted(
            hasBirthday: userProfileService.currentProfile?.birthday != nil,
            hasBloodType: userProfileService.currentProfile?.bloodType != nil,
            consentedToAI: userProfileService.currentProfile?.hasConsentedToAI ?? false
        ))

        // オンボーディング完了後に通知許可をリクエスト
        Task {
            await notificationManager.requestAuthorization()
        }
    }

    /// Resets onboarding (useful during development / testing).
    func resetOnboarding() {
        isOnboardingComplete = false
    }

    // MARK: - Keys

    private enum Keys {
        static let onboardingComplete = "sorayomi_onboarding_complete"
    }
}
