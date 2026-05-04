import Foundation

// MARK: - AdRewardManager

/// 広告リワード機能の管理
/// デフォルトOFF（FeatureFlagManager.isAdRewardEnabled で制御）。
/// ONの場合、非サブスク会員に1日1回の広告視聴で1クレジットを提供する。
///
/// 初期リリースでは広告SDK未導入のため、このマネージャーは
/// UIの表示制御とクレジット付与ロジックのみを担当する。
/// 実際の広告表示は AdMob / AppLovin 等のSDK統合後に実装する。
@Observable
@MainActor
final class AdRewardManager {

    // MARK: - Properties

    /// 広告リワードが利用可能かどうか（Feature Flag + 1日上限 + 非サブスク）
    var isAvailable: Bool {
        guard isEnabled else { return false }
        guard !isSubscribed else { return false }
        return canWatchToday
    }

    /// 広告視聴中かどうか
    private(set) var isWatching: Bool = false

    /// 最後に付与されたクレジット数（UI表示用）
    private(set) var lastRewardCredits: Int?

    // MARK: - Dependencies

    private let featureFlags: FeatureFlagManager
    private let walletService: CreditWalletService
    private let analyticsService: AnalyticsService

    /// 外部から注入されるサブスク状態
    var isSubscribed: Bool = false

    // MARK: - Computed

    private var isEnabled: Bool {
        featureFlags.isAdRewardEnabled
    }

    private var canWatchToday: Bool {
        walletService.isAdRewardAvailableToday
    }

    // MARK: - Init

    init(
        featureFlags: FeatureFlagManager = FeatureFlagManager(),
        walletService: CreditWalletService = CreditWalletService(),
        analyticsService: AnalyticsService = .shared
    ) {
        self.featureFlags = featureFlags
        self.walletService = walletService
        self.analyticsService = analyticsService
    }

    // MARK: - Public API

    /// 広告視聴を開始する
    /// 実際の広告SDK呼び出しは将来実装。現在は即座に報酬を付与。
    func startWatchingAd() {
        guard isAvailable else {
            #if DEBUG
            print("[AdRewardManager] Ad reward not available")
            #endif
            return
        }

        isWatching = true
        analyticsService.track(.adRewardStarted)

        // TODO: 広告SDK統合後、ここで実際の広告を表示する
        // 現在はシミュレーションとして即座に完了扱い
        completeAdReward()
    }

    /// 広告視聴完了後のクレジット付与
    /// 広告SDK統合後はコールバックから呼ばれる。
    func completeAdReward() {
        let granted = walletService.grantAdRewardCredit()

        if granted {
            lastRewardCredits = 1
            analyticsService.track(.adRewardCompleted(creditsGranted: 1))
            #if DEBUG
            print("[AdRewardManager] Ad reward granted: 1 credit")
            #endif
        } else {
            analyticsService.track(.adRewardFailed(reason: "daily_limit_reached"))
            #if DEBUG
            print("[AdRewardManager] Ad reward failed: daily limit reached")
            #endif
        }

        isWatching = false
    }

    /// 報酬表示をクリア
    func clearLastReward() {
        lastRewardCredits = nil
    }
}
