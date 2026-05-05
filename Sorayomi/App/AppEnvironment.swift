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

    /// 初回無料相談の管理（Keychain永続化）
    let freeTrialManager: FreeTrialManager

    /// 鑑定履歴の保存・読み込み
    let readingHistoryService: ReadingHistoryService

    /// App Storeレビュー依頼の管理
    let reviewRequestManager: ReviewRequestManager

    /// 広告リワード機能の管理
    let adRewardManager: AdRewardManager

    /// 無料コンテンツ（1日1回制限）の使用状況追跡
    let dailyFortuneTracker: DailyFortuneUsageTracker

    // MARK: - Onboarding State

    /// `true` after the user completes the first-run onboarding flow.
    /// UserDefaults に保存。アプリ削除時にリセットされるため、
    /// 再インストール後は正しくオンボーディングが表示される。
    /// （Keychain はシミュレータで削除をまたいで残存するため不適切）
    var isOnboardingComplete: Bool {
        didSet {
            if isOnboardingComplete {
                UserDefaults.standard.set(true, forKey: Keys.onboardingComplete)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.onboardingComplete)
            }
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
        // トランザクションリスナー開始前にコールバックを渡して StoreKitManager を生成する。
        // これにより、init 内で listenForTransactions() が始まる前にハンドラが確実にセットされる。
        let walletServiceRef = creditWalletService
        self.storeKitManager = StoreKitManager(creditTransactionHandler: { @Sendable credits, productId, transactionId in
            await walletServiceRef.addCredits(credits, productId: productId, transactionId: transactionId)
        })
        self.notificationManager = NotificationManager()
        self.streakManager = StreakManager()
        self.freeTrialManager = FreeTrialManager()
        self.readingHistoryService = ReadingHistoryService()
        self.reviewRequestManager = ReviewRequestManager(analyticsService: analyticsService, featureFlags: featureFlags)
        self.adRewardManager = AdRewardManager(featureFlags: featureFlags, walletService: creditWalletService, analyticsService: analyticsService)
        self.dailyFortuneTracker = DailyFortuneUsageTracker()
        // ワンタイム移行: Keychain → UserDefaults
        // 旧バージョンで Keychain に保存されていた場合は UserDefaults へ移行して Keychain を削除する。
        if KeychainStore.shared.exists(forKey: Keys.onboardingComplete, synchronizable: false) {
            UserDefaults.standard.set(true, forKey: Keys.onboardingComplete)
            KeychainStore.shared.delete(forKey: Keys.onboardingComplete, synchronizable: false)
            #if DEBUG
            print("[AppEnvironment] Migrated onboarding flag: Keychain → UserDefaults")
            #endif
        }
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: Keys.onboardingComplete)

        // 起動時にウォレット残高をストレージから読み込み
        creditWalletService.loadWallet()
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
        // 通知許可はオンボーディングの通知ページ（NotificationPermissionPageView）で処理する
    }

    /// アプリ起動時にサブスクリプション月次クレジットを付与
    func grantPremiumCreditsIfNeeded() async {
        await storeKitManager.checkSubscriptionStatus()

        // AdRewardManagerにサブスク状態を同期
        adRewardManager.isSubscribed = storeKitManager.isSubscribed

        if storeKitManager.isSubscribed {
            creditWalletService.grantMonthlyPremiumCredits(
                allowance: pricingConfig.premiumMonthlyCredits,
                carryoverCap: pricingConfig.creditCarryoverCap
            )
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
