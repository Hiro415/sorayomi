import Foundation

// MARK: - CreditWallet

/// ユーザーのクレジット残高管理
/// Tracks a user's credit balance including purchased credits
/// and daily free credits for fortune readings.
struct CreditWallet: Codable {
    let userId: String
    var balance: Int
    var freeCreditsRemaining: Int
    let lastUpdated: Date

    // MARK: - Computed Properties

    /// 利用可能な合計クレジット（購入分 + 無料分）
    var totalAvailable: Int {
        balance + freeCreditsRemaining
    }

    /// クレジットが残っているかどうか
    var hasCredits: Bool {
        totalAvailable > 0
    }

    /// 無料クレジットが残っているかどうか
    var hasFreeCredits: Bool {
        freeCreditsRemaining > 0
    }

    /// 表示用の残高テキスト
    var balanceDisplayText: String {
        if freeCreditsRemaining > 0 {
            return "\(balance)クレジット（＋無料\(freeCreditsRemaining)回）"
        }
        return "\(balance)クレジット"
    }

    // MARK: - Methods

    /// 指定コストの鑑定が利用可能かどうか
    func canAfford(creditsCost: Int) -> Bool {
        totalAvailable >= creditsCost
    }

    /// 有償クレジット（balance）のみから消費後のウォレットを返す（深掘り専用）
    func consumingPaidOnly(credits: Int) -> CreditWallet {
        var newWallet = self
        newWallet.balance = max(0, newWallet.balance - credits)
        return newWallet
    }

    /// クレジット消費後の新しいウォレットを返す（無料分を優先消費）
    func consuming(credits: Int) -> CreditWallet {
        var newWallet = self
        var remaining = credits

        // 無料クレジットを先に消費
        if newWallet.freeCreditsRemaining > 0 {
            let freeToUse = min(newWallet.freeCreditsRemaining, remaining)
            newWallet.freeCreditsRemaining -= freeToUse
            remaining -= freeToUse
        }

        // 残りは購入クレジットから消費
        if remaining > 0 {
            newWallet.balance = max(0, newWallet.balance - remaining)
        }

        return newWallet
    }

    // MARK: - Preview Mock

    /// プレビュー用モックデータ
    static let mock = CreditWallet(
        userId: "mock-user-001",
        balance: 10,
        freeCreditsRemaining: 3,
        lastUpdated: Date()
    )

    /// プレビュー用：残高ゼロ
    static let emptyMock = CreditWallet(
        userId: "mock-user-002",
        balance: 0,
        freeCreditsRemaining: 0,
        lastUpdated: Date()
    )

    /// 新規ユーザー用の初期ウォレット
    static func initial(userId: String) -> CreditWallet {
        CreditWallet(
            userId: userId,
            balance: 0,
            freeCreditsRemaining: 3,
            lastUpdated: Date()
        )
    }
}
