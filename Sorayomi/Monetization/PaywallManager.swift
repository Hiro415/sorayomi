import Foundation

// MARK: - PaywallManager

/// ペイウォール表示の管理
/// クレジット不足時にペイウォールを表示するかどうかの判定を行う。
@Observable
@MainActor
final class PaywallManager {

    // MARK: - Properties

    /// ペイウォールを表示すべきかどうか
    private(set) var shouldShowPaywall: Bool = false

    /// 必要なクレジット数
    private(set) var requiredCredits: Int = 0

    // MARK: - Dependencies

    private let walletService: CreditWalletService
    private let analyticsService: AnalyticsService?

    // MARK: - Init

    init(
        walletService: CreditWalletService = CreditWalletService(),
        analyticsService: AnalyticsService? = nil
    ) {
        self.walletService = walletService
        self.analyticsService = analyticsService
    }

    // MARK: - Check Paywall

    /// 指定コストに対してペイウォールを表示すべきか判定する
    /// - Parameter cost: 必要なクレジット数
    /// - Returns: ペイウォールを表示すべき場合は true
    @discardableResult
    func checkAndShowPaywall(forCost cost: Int) -> Bool {
        requiredCredits = cost

        if walletService.canAfford(cost) {
            shouldShowPaywall = false
            return false
        }

        shouldShowPaywall = true

        // アナリティクスイベントを送信
        analyticsService?.track(.monetizationPaywallShown(
            requiredCredits: cost,
            currentBalance: walletService.totalAvailable
        ))

        #if DEBUG
        print("[PaywallManager] Paywall shown - required: \(cost), available: \(walletService.totalAvailable)")
        #endif

        return true
    }

    // MARK: - Dismiss

    /// ペイウォールを閉じる
    func dismissPaywall() {
        shouldShowPaywall = false
        requiredCredits = 0
    }
}
