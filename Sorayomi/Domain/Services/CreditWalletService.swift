import Foundation

// MARK: - CreditWalletService

/// クレジットウォレットの管理サービス
/// 残高の読み込み、消費、追加、無料クレジット付与を統括する。
/// 繰越上限（carryover cap）と月次プレミアム付与をサポート。
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

    /// 指定コストを支払えるかどうか（無償・有償合計）
    func canAfford(_ creditsCost: Int) -> Bool {
        totalAvailable >= creditsCost
    }

    /// 有償クレジット（購入分）のみで支払えるかどうか
    func canAffordWithPaidOnly(_ creditsCost: Int) -> Bool {
        balance >= creditsCost
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

    /// 有償クレジット（balance）のみから差し引く（深掘りフォローアップ専用）
    func deductPaidCredits(_ amount: Int, readingId: String? = nil) async throws {
        guard let userId = authService.currentUserId else {
            throw CreditError.walletNotFound
        }

        guard canAffordWithPaidOnly(amount) else {
            throw CreditError.insufficientBalance(required: amount, available: balance)
        }

        let updatedWallet = try repository.deductPaidCredits(
            userId: userId,
            amount: amount,
            readingId: readingId
        )

        balance = updatedWallet.balance
        freeCreditsRemaining = updatedWallet.freeCreditsRemaining

        #if DEBUG
        print("[CreditWalletService] Deducted \(amount) paid credits. Paid remaining: \(balance)")
        #endif
    }

    // MARK: - Monthly Premium Grant

    /// プレミアム会員への月次クレジット付与
    /// 月初（または初回サブスク開始時）に1回のみ付与。
    /// 繰越上限を適用し、付与後の残高が carryoverCap を超えないよう調整。
    func grantMonthlyPremiumCredits(allowance: Int, carryoverCap: Int) {
        guard allowance > 0 else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let lastGrantKey = "sorayomi_last_premium_grant_month"

        // 今月のキー（例: "2026-03"）
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonth = formatter.string(from: today)

        if let lastMonth = UserDefaults.standard.string(forKey: lastGrantKey),
           lastMonth == currentMonth {
            #if DEBUG
            print("[CreditWalletService] Monthly premium credits already granted for \(currentMonth)")
            #endif
            return
        }

        guard let userId = authService.currentUserId else { return }

        // 繰越上限を考慮した付与数を計算
        let currentTotal = totalAvailable
        let effectiveGrant: Int
        if currentTotal + allowance > carryoverCap {
            effectiveGrant = max(0, carryoverCap - currentTotal)
        } else {
            effectiveGrant = allowance
        }

        guard effectiveGrant > 0 else {
            // 繰越上限に達しているため付与なし（月のマーキングだけ行う）
            UserDefaults.standard.set(currentMonth, forKey: lastGrantKey)
            #if DEBUG
            print("[CreditWalletService] Carryover cap reached (\(currentTotal)/\(carryoverCap)), no credits granted")
            #endif
            return
        }

        let updatedWallet = repository.addCredits(
            userId: userId,
            amount: effectiveGrant,
            type: .freeGrant,
            description: "月間プレミアム付与 (\(effectiveGrant)クレジット)"
        )

        balance = updatedWallet.balance
        freeCreditsRemaining = updatedWallet.freeCreditsRemaining
        UserDefaults.standard.set(currentMonth, forKey: lastGrantKey)

        #if DEBUG
        print("[CreditWalletService] Granted \(effectiveGrant) monthly premium credits (cap: \(carryoverCap)). Balance: \(totalAvailable)")
        #endif
    }

    // MARK: - Daily Subscription Grant (Legacy compat — redirects to monthly)

    /// サブスクリプション会員への日次クレジット付与
    /// 新プランでは月次付与に変更。互換性のために残すが、内部的には月次処理を呼ぶ。
    func grantDailySubscriptionCredits(allowance: Int) {
        // 月次プレミアムに移行済み — 月次付与を使用
        grantMonthlyPremiumCredits(allowance: 30, carryoverCap: 30)
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

    // MARK: - Ad Reward Credit

    /// 広告視聴によるクレジット付与（1日1回）
    /// - Returns: 付与が成功したかどうか
    @discardableResult
    func grantAdRewardCredit() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let lastKey = "sorayomi_last_ad_reward_date"

        if let lastReward = UserDefaults.standard.object(forKey: lastKey) as? TimeInterval {
            let lastDate = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: lastReward))
            if lastDate >= today {
                #if DEBUG
                print("[CreditWalletService] Ad reward already granted today")
                #endif
                return false
            }
        }

        guard let userId = authService.currentUserId else { return false }

        let updatedWallet = repository.addCredits(
            userId: userId,
            amount: 1,
            type: .freeGrant,
            description: "広告視聴ボーナス (1クレジット)"
        )

        balance = updatedWallet.balance
        freeCreditsRemaining = updatedWallet.freeCreditsRemaining
        UserDefaults.standard.set(today.timeIntervalSince1970, forKey: lastKey)

        #if DEBUG
        print("[CreditWalletService] Granted 1 ad reward credit. Balance: \(totalAvailable)")
        #endif
        return true
    }

    /// 今日の広告リワードが利用可能かどうか
    var isAdRewardAvailableToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let lastKey = "sorayomi_last_ad_reward_date"

        if let lastReward = UserDefaults.standard.object(forKey: lastKey) as? TimeInterval {
            let lastDate = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: lastReward))
            return lastDate < today
        }
        return true
    }

    // MARK: - Streak Reward

    /// ストリークマイルストーン達成時のクレジット付与
    /// - Parameter credits: 付与クレジット数
    func grantStreakReward(_ credits: Int) {
        guard credits > 0 else { return }
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[CreditWalletService] No authenticated user, cannot grant streak reward")
            #endif
            return
        }

        let updatedWallet = repository.addCredits(
            userId: userId,
            amount: credits,
            type: .freeGrant,
            description: "ストリーク報酬 (+\(credits)クレジット)"
        )

        balance = updatedWallet.balance
        freeCreditsRemaining = updatedWallet.freeCreditsRemaining

        #if DEBUG
        print("[CreditWalletService] Granted \(credits) streak reward credits. Free remaining: \(freeCreditsRemaining)")
        #endif
    }

    // MARK: - Free Credits

    // MARK: - Reset (Account Deletion)

    /// ウォレットを完全リセットする（アカウント削除時）
    func resetWallet() {
        guard let userId = authService.currentUserId else { return }
        repository.deleteWallet(userId: userId)
        balance = 0
        freeCreditsRemaining = 0

        #if DEBUG
        print("[CreditWalletService] Wallet reset for user: \(userId)")
        #endif
    }

    /// 初回無料クレジットを付与
    /// Keychain flag (synchronizable) prevents double-granting even if UserDefaults
    /// is cleared or the app is reinstalled on the same device.
    func grantInitialFreeCredits() {
        let grantKey = "sorayomi_initial_credits_granted"
        guard !KeychainStore.shared.exists(forKey: grantKey, synchronizable: false) else {
            #if DEBUG
            print("[CreditWalletService] Initial free credits already granted, skipping")
            #endif
            return
        }

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
        KeychainStore.shared.saveString("1", forKey: grantKey, synchronizable: false)

        #if DEBUG
        print("[CreditWalletService] Granted \(amount) initial free credits. Free remaining: \(freeCreditsRemaining)")
        #endif
    }
}
