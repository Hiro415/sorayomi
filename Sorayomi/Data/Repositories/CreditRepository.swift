import Foundation

// MARK: - CreditRepository

/// クレジットウォレットと取引履歴の永続化リポジトリ
/// MVP では UserDefaultsStore を使用。将来的に Firestore に移行予定。
/// 単一デバイスでのアトミック操作を保証する。
@MainActor
final class CreditRepository {

    // MARK: - Singleton

    static let shared = CreditRepository()

    // MARK: - Dependencies

    private let store: UserDefaultsStore

    // MARK: - Init

    init(store: UserDefaultsStore = .shared) {
        self.store = store
    }

    // MARK: - Keys

    private func walletKey(for userId: String) -> String {
        "credit_wallet_\(userId)"
    }

    private func transactionsKey(for userId: String) -> String {
        "credit_transactions_\(userId)"
    }

    /// 処理済み StoreKit トランザクション ID のキー（重複付与防止）
    private let processedTransactionsKey = "sorayomi_processed_storekit_transactions"

    // MARK: - Idempotency Helpers

    /// 指定トランザクションが処理済みかどうかを返す
    private func hasProcessedTransaction(_ transactionId: String) -> Bool {
        let ids: [String] = store.load(forKey: processedTransactionsKey) ?? []
        return ids.contains(transactionId)
    }

    /// トランザクションを処理済みとしてマーク（最大200件保持）
    private func markTransactionProcessed(_ transactionId: String) {
        var ids: [String] = store.load(forKey: processedTransactionsKey) ?? []
        guard !ids.contains(transactionId) else { return }
        ids.insert(transactionId, at: 0)
        if ids.count > 200 { ids = Array(ids.prefix(200)) }
        store.save(ids, forKey: processedTransactionsKey)
    }

    // MARK: - Wallet CRUD

    /// ウォレットを取得（存在しない場合は残高0の新規ウォレットを作成）
    func getWallet(userId: String) -> CreditWallet {
        if let wallet: CreditWallet = store.load(forKey: walletKey(for: userId)) {
            return wallet
        }

        // データが存在するがデコード失敗の場合は上書きしない（データ保護）
        if store.exists(forKey: walletKey(for: userId)) {
            #if DEBUG
            print("[CreditRepository] ⚠️ Wallet data exists but decode failed for user: \(userId). Returning zero wallet WITHOUT overwriting storage.")
            #endif
            return CreditWallet(
                userId: userId,
                balance: 0,
                freeCreditsRemaining: 0,
                lastUpdated: Date()
            )
        }

        // 本当にデータが存在しない場合のみ新規作成・保存
        let defaultWallet = CreditWallet(
            userId: userId,
            balance: 0,
            freeCreditsRemaining: AppConstants.initialFreeCredits,
            lastUpdated: Date()
        )
        store.save(defaultWallet, forKey: walletKey(for: userId))
        #if DEBUG
        print("[CreditRepository] Created default wallet for user: \(userId)")
        #endif
        return defaultWallet
    }

    /// ウォレットを更新
    func updateWallet(_ wallet: CreditWallet) {
        let updatedWallet = CreditWallet(
            userId: wallet.userId,
            balance: wallet.balance,
            freeCreditsRemaining: wallet.freeCreditsRemaining,
            lastUpdated: Date()
        )
        store.save(updatedWallet, forKey: walletKey(for: wallet.userId))
        #if DEBUG
        print("[CreditRepository] Updated wallet for user: \(wallet.userId) " +
              "(balance: \(updatedWallet.balance), free: \(updatedWallet.freeCreditsRemaining))")
        #endif
    }

    // MARK: - Credit Operations

    /// クレジットを追加（購入・付与時）
    /// - Parameters:
    ///   - storeKitTransactionId: StoreKit トランザクション ID（指定時、重複付与を防止）
    /// - Returns: 更新後のウォレット
    @discardableResult
    func addCredits(
        userId: String,
        amount: Int,
        type: TransactionType,
        productId: String? = nil,
        description: String? = nil,
        storeKitTransactionId: String? = nil
    ) -> CreditWallet {
        // StoreKit トランザクションの重複付与を防止
        if let txId = storeKitTransactionId {
            guard !hasProcessedTransaction(txId) else {
                #if DEBUG
                print("[CreditRepository] Skipping duplicate transaction: \(txId)")
                #endif
                return getWalletUnsafe(userId: userId)
            }
        }

        var wallet = getWalletUnsafe(userId: userId)

        switch type {
        case .purchase, .refund:
            wallet = CreditWallet(
                userId: wallet.userId,
                balance: wallet.balance + amount,
                freeCreditsRemaining: wallet.freeCreditsRemaining,
                lastUpdated: Date()
            )
        case .freeGrant:
            wallet = CreditWallet(
                userId: wallet.userId,
                balance: wallet.balance,
                freeCreditsRemaining: wallet.freeCreditsRemaining + amount,
                lastUpdated: Date()
            )
        case .consumption:
            break // 追加操作では consumption は使用しない
        }

        store.save(wallet, forKey: walletKey(for: userId))

        // StoreKit トランザクションを処理済みとしてマーク
        if let txId = storeKitTransactionId {
            markTransactionProcessed(txId)
        }

        // 取引記録を保存
        let transaction = CreditTransaction(
            id: storeKitTransactionId ?? UUID().uuidString,
            userId: userId,
            type: type,
            amount: amount,
            productId: productId,
            readingId: nil,
            description: description,
            timestamp: Date()
        )
        appendTransaction(transaction, userId: userId)

        #if DEBUG
        print("[CreditRepository] Added \(amount) credits (\(type.rawValue)) for user: \(userId)")
        #endif

        return wallet
    }

    /// クレジットを差し引き（消費時）。無料クレジットを優先消費。
    /// - Returns: 更新後のウォレット
    /// - Throws: 残高不足の場合エラー
    @discardableResult
    func deductCredits(
        userId: String,
        amount: Int,
        readingId: String? = nil
    ) throws -> CreditWallet {
        let wallet = getWalletUnsafe(userId: userId)

        guard wallet.totalAvailable >= amount else {
            throw CreditError.insufficientBalance(
                required: amount,
                available: wallet.totalAvailable
            )
        }

        // CreditWallet.consuming を使って無料クレジット優先消費
        let updatedWallet = wallet.consuming(credits: amount)
        let finalWallet = CreditWallet(
            userId: updatedWallet.userId,
            balance: updatedWallet.balance,
            freeCreditsRemaining: updatedWallet.freeCreditsRemaining,
            lastUpdated: Date()
        )
        store.save(finalWallet, forKey: walletKey(for: userId))

        // 取引記録を保存
        let transaction = CreditTransaction(
            id: UUID().uuidString,
            userId: userId,
            type: .consumption,
            amount: amount,
            productId: nil,
            readingId: readingId,
            description: nil,
            timestamp: Date()
        )
        appendTransaction(transaction, userId: userId)

        #if DEBUG
        print("[CreditRepository] Deducted \(amount) credits for user: \(userId)")
        #endif

        return finalWallet
    }

    /// 有償クレジット（balance）のみから差し引く（深掘りフォローアップ専用）
    func deductPaidCredits(
        userId: String,
        amount: Int,
        readingId: String? = nil
    ) throws -> CreditWallet {
        let wallet = getWalletUnsafe(userId: userId)

        guard wallet.balance >= amount else {
            throw CreditError.insufficientBalance(required: amount, available: wallet.balance)
        }

        let updatedWallet = wallet.consumingPaidOnly(credits: amount)
        let finalWallet = CreditWallet(
            userId: updatedWallet.userId,
            balance: updatedWallet.balance,
            freeCreditsRemaining: updatedWallet.freeCreditsRemaining,
            lastUpdated: Date()
        )
        store.save(finalWallet, forKey: walletKey(for: userId))

        let transaction = CreditTransaction(
            id: UUID().uuidString,
            userId: userId,
            type: .consumption,
            amount: amount,
            productId: nil,
            readingId: readingId,
            description: "深掘り（有償クレジット）",
            timestamp: Date()
        )
        appendTransaction(transaction, userId: userId)

        #if DEBUG
        print("[CreditRepository] Deducted \(amount) paid credits for user: \(userId)")
        #endif

        return finalWallet
    }

    // MARK: - Transaction History

    /// 取引履歴を取得
    func getTransactions(userId: String, limit: Int? = nil) -> [CreditTransaction] {
        let transactions: [CreditTransaction]? = store.load(forKey: transactionsKey(for: userId))
        let allTransactions = transactions ?? []
        if let limit, limit > 0 {
            return Array(allTransactions.prefix(limit))
        }
        return allTransactions
    }

    // MARK: - Private Helpers

    /// ロックなしでウォレットを取得（内部用）
    private func getWalletUnsafe(userId: String) -> CreditWallet {
        if let wallet: CreditWallet = store.load(forKey: walletKey(for: userId)) {
            return wallet
        }

        // デコード失敗時はデータを保護（上書きしない）
        if store.exists(forKey: walletKey(for: userId)) {
            #if DEBUG
            print("[CreditRepository] ⚠️ getWalletUnsafe: decode failed, returning zero wallet without overwriting")
            #endif
            return CreditWallet(
                userId: userId,
                balance: 0,
                freeCreditsRemaining: 0,
                lastUpdated: Date()
            )
        }

        let defaultWallet = CreditWallet(
            userId: userId,
            balance: 0,
            freeCreditsRemaining: 0,
            lastUpdated: Date()
        )
        store.save(defaultWallet, forKey: walletKey(for: userId))
        return defaultWallet
    }

    /// 取引記録を追加
    private func appendTransaction(_ transaction: CreditTransaction, userId: String) {
        var transactions: [CreditTransaction] = store.load(forKey: transactionsKey(for: userId)) ?? []
        transactions.insert(transaction, at: 0)
        store.save(transactions, forKey: transactionsKey(for: userId))
    }

    // MARK: - Delete (Account Deletion)

    /// ウォレットと取引履歴を完全削除する（アカウント削除時）
    func deleteWallet(userId: String) {
        store.delete(forKey: walletKey(for: userId))
        store.delete(forKey: transactionsKey(for: userId))
    }
}

// MARK: - CreditError

/// クレジット操作エラー
enum CreditError: Error, LocalizedError {
    case insufficientBalance(required: Int, available: Int)
    case invalidAmount
    case walletNotFound

    var errorDescription: String? {
        switch self {
        case .insufficientBalance(let required, let available):
            return "クレジットが不足しています（必要: \(required)、残高: \(available)）"
        case .invalidAmount:
            return "無効な金額です"
        case .walletNotFound:
            return "ウォレットが見つかりません"
        }
    }
}
