import Foundation

// MARK: - CreditWalletManager

/// クレジットウォレットの薄いラッパー
/// CreditWalletService に委譲し、UI レイヤーに直接公開するプロパティとメソッドを提供する。
@Observable
@MainActor
final class CreditWalletManager {

    // MARK: - Dependencies

    private let walletService: CreditWalletService

    // MARK: - Init

    init(walletService: CreditWalletService = CreditWalletService()) {
        self.walletService = walletService
    }

    // MARK: - Properties

    /// 購入クレジット残高
    var balance: Int {
        walletService.balance
    }

    /// 無料クレジット残数
    var freeCreditsRemaining: Int {
        walletService.freeCreditsRemaining
    }

    /// 利用可能な合計クレジット
    var totalAvailable: Int {
        walletService.totalAvailable
    }

    /// 今日の広告リワードが利用可能かどうか
    var isAdRewardAvailableToday: Bool {
        walletService.isAdRewardAvailableToday
    }

    // MARK: - Methods

    /// ウォレットを読み込む
    func loadWallet() {
        walletService.loadWallet()
    }

    /// 指定コストを支払えるかどうか
    func canAfford(_ creditsCost: Int) -> Bool {
        walletService.canAfford(creditsCost)
    }

    /// クレジットを差し引く
    func deductCredits(_ amount: Int, readingId: String? = nil) async throws {
        try await walletService.deductCredits(amount, readingId: readingId)
    }

    /// クレジットを追加する
    func addCredits(_ amount: Int, productId: String, transactionId: String) async {
        await walletService.addCredits(amount, productId: productId, transactionId: transactionId)
    }

    /// 初回無料クレジットを付与
    func grantInitialFreeCredits() {
        walletService.grantInitialFreeCredits()
    }

    /// 月次プレミアムクレジットを付与（繰越上限あり）
    func grantMonthlyPremiumCredits(allowance: Int, carryoverCap: Int) {
        walletService.grantMonthlyPremiumCredits(allowance: allowance, carryoverCap: carryoverCap)
    }

    /// 広告視聴によるクレジット付与
    @discardableResult
    func grantAdRewardCredit() -> Bool {
        walletService.grantAdRewardCredit()
    }
}
