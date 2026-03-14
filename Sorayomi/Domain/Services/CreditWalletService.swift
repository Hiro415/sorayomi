import Foundation

// MARK: - CreditWalletService

/// クレジットウォレットの管理サービス
/// 残高の読み込み、消費、追加、無料クレジット付与を統括する。
@Observable
@MainActor
final class CreditWalletService {

    // MARK: - Properties

    /// 購入クレジット残高
    private(set) var balance: Int = 0

    /// 無料クレジット残数
    private(set) var freeCreditsRemaining: Int = 0

    /// 利用可能な合計クレジット
    var totalAvailable: Int {
        balance + freeCreditsRemaining
    }

    // MARK: - Dependencies

    private let repository: CreditRepository
    private let authService: FirebaseAuthService

    // MARK: - Init

    init(
        repository: CreditRepository = .shared,
        authService: FirebaseAuthService = .shared
    ) {
        self.repository = repository
        self.authService = authService
    }

    // MARK: - Load

    /// ウォレットを読み込み、プロパティを更新
    func loadWallet() {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[CreditWalletService] No authenticated user, skipping load")
            #endif
            return
        }

        let wallet = repository.getWallet(userId: userId)
        balance = wallet.balance
        freeCreditsRemaining = wallet.freeCreditsRemaining

        #if DEBUG
        print("[CreditWalletService] Loaded wallet - balance: \(balance), free: \(freeCreditsRemaining)")
        #endif
    }

    // MARK: - Affordability Check

    /// 指定コストを支払えるかどうか
    func canAfford(_ creditsCost: Int) -> Bool {
        totalAvailable >= creditsCost
    }

    // MARK: - Deduction

    /// クレジットを差し引き（無料クレジットを優先消費）
    /// - Parameters:
    ///   - amount: 消費クレジット数
    ///   - readingId: 関連する鑑定ID（任意）
    func deductCredits(_ amount: Int, readingId: String? = nil) async throws {
        guard let userId = authService.currentUserId else {
            throw CreditError.walletNotFound
        }

        guard canAfford(amount) else {
            throw CreditError.insufficientBalance(required: amount, available: totalAvailable)
        }

        let updatedWallet = try repository.deductCredits(
            userId: userId,
            amount: amount,
            readingId: readingId
        )

        balance = updatedWallet.balance
        freeCreditsRemaining = updatedWallet.freeCreditsRemaining

        #if DEBUG
        print("[CreditWalletService] Deducted \(amount) credits. Remaining: \(totalAvailable)")
        #endif
    }

    // MARK: - Addition

    /// クレジットを追加（購入完了時）
    /// - Parameters:
    ///   - amount: 追加クレジット数
    ///   - productId: App Store プロダクトID
    ///   - transactionId: App Store トランザクションID
    func addCredits(_ amount: Int, productId: String, transactionId: String) async {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[CreditWalletService] No authenticated user, cannot add credits")
            #endif
            return
        }

        let updatedWallet = repository.addCredits(
            userId: userId,
            amount: amount,
            type: .purchase,
            productId: productId,
            description: "クレジット購入 (Transaction: \(transactionId))"
        )

        balance = updatedWallet.balance
        freeCreditsRemaining = updatedWallet.freeCreditsRemaining

        #if DEBUG
        print("[CreditWalletService] Added \(amount) credits from purchase. Balance: \(balance)")
        #endif
    }

    // MARK: - Free Credits

    /// 初回無料クレジットを付与
    func grantInitialFreeCredits() {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[CreditWalletService] No authenticated user, cannot grant free credits")
            #endif
            return
        }

        let amount = AppConstants.initialFreeCredits

        let updatedWallet = repository.addCredits(
            userId: userId,
            amount: amount,
            type: .freeGrant,
            description: "初回無料クレジット付与"
        )

        balance = updatedWallet.balance
        freeCreditsRemaining = updatedWallet.freeCreditsRemaining

        #if DEBUG
        print("[CreditWalletService] Granted \(amount) initial free credits. Free remaining: \(freeCreditsRemaining)")
        #endif
    }
}
