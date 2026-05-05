import Foundation
import StoreKit

// MARK: - PurchaseState

/// 購入プロセスの状態
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case success(credits: Int)
    case subscribedSuccess
    case failed(Error)

    static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.purchasing, .purchasing):
            return true
        case (.success(let l), .success(let r)):
            return l == r
        case (.subscribedSuccess, .subscribedSuccess):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - StoreKitManager

/// StoreKit 2 を使った App Store 課金管理
/// プロダクトの読み込み、購入、サブスクリプション、トランザクション監視を統括する。
@Observable
@MainActor
final class StoreKitManager {

    // MARK: - Properties

    /// 利用可能なクレジットパック（スターターパック含む）
    private(set) var products: [Product] = []

    /// 利用可能なサブスクリプション
    private(set) var subscriptions: [Product] = []

    /// サブスクリプションが有効かどうか
    private(set) var isSubscribed: Bool = false

    /// 有効なサブスクリプションのプロダクトID
    private(set) var activeSubscriptionProductId: String?

    /// スターターパック購入済みかどうか
    private(set) var hasUsedStarterPack: Bool = false

    /// サブスクリプションの月次クレジット付与数
    var monthlyCreditsAllowance: Int {
        guard let productId = activeSubscriptionProductId else { return 0 }
        return ProductIdentifiers.monthlyCredits(for: productId)
    }

    /// サブスクリプションのプラン表示名
    var activeSubscriptionDisplayName: String? {
        guard activeSubscriptionProductId != nil else { return nil }
        return "月間プレミアム"
    }

    /// 現在の購入状態
    private(set) var purchaseState: PurchaseState = .idle

    /// トランザクション監視タスク
    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Starter Pack Persistence Key

    private let starterPackUsedKey = "sorayomi_starter_pack_used"

    // MARK: - Init

    init() {
        // One-time migration: UserDefaults → Keychain
        if UserDefaults.standard.bool(forKey: starterPackUsedKey) {
            KeychainStore.shared.saveString("1", forKey: starterPackUsedKey)
            UserDefaults.standard.removeObject(forKey: starterPackUsedKey)
        }
        hasUsedStarterPack = KeychainStore.shared.exists(forKey: starterPackUsedKey)
        listenForTransactions()
    }

    // MARK: - Load Products

    /// App Store からプロダクト情報を読み込む
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(
                for: Set(ProductIdentifiers.allProducts)
            )

            // クレジットパックとサブスクリプションを分離
            var creditPacks: [Product] = []
            var subs: [Product] = []

            for product in storeProducts {
                if ProductIdentifiers.allSubscriptions.contains(product.id) {
                    subs.append(product)
                } else {
                    creditPacks.append(product)
                }
            }

            products = creditPacks.sorted { $0.price < $1.price }
            subscriptions = subs.sorted { $0.price < $1.price }

            #if DEBUG
            print("[StoreKitManager] Loaded \(products.count) credit packs, \(subscriptions.count) subscriptions")
            #endif
        } catch {
            #if DEBUG
            print("[StoreKitManager] Failed to load products: \(error.localizedDescription)")
            #endif
            products = []
            subscriptions = []
        }

        // サブスクリプション状態を確認
        await checkSubscriptionStatus()
        // スターターパック購入済みチェック
        await checkStarterPackStatus()
    }

    // MARK: - Subscription Status

    /// 現在のサブスクリプション状態を確認
    func checkSubscriptionStatus() async {
        var foundProductId: String?

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try ReceiptValidator.verify(result)
                if ProductIdentifiers.allSubscriptions.contains(transaction.productID) {
                    foundProductId = transaction.productID
                    break
                }
            } catch {
                continue
            }
        }

        activeSubscriptionProductId = foundProductId
        isSubscribed = foundProductId != nil

        #if DEBUG
        print("[StoreKitManager] Subscription status: \(isSubscribed ? "active (\(foundProductId ?? ""))" : "inactive")")
        #endif
    }

    // MARK: - Starter Pack Status

    /// スターターパック購入済みをチェック（Transaction履歴 + UserDefaults両方）
    /// Note: Consumable products don't appear in `currentEntitlements`.
    /// Use `Transaction.all` to scan finished consumable transaction history.
    func checkStarterPackStatus() async {
        if hasUsedStarterPack { return }

        for await result in Transaction.all {
            do {
                let transaction = try ReceiptValidator.verify(result)
                if ProductIdentifiers.isStarterPack(transaction.productID) {
                    markStarterPackUsed()
                    return
                }
            } catch {
                continue
            }
        }
    }

    /// スターターパック使用済みをマーク
    private func markStarterPackUsed() {
        hasUsedStarterPack = true
        KeychainStore.shared.saveString("1", forKey: starterPackUsedKey)
    }

    // MARK: - Purchase

    /// プロダクトを購入する
    /// - Parameter product: 購入するプロダクト
    /// - Returns: 付与されるクレジット数（クレジットパック購入成功時）、nil（キャンセル時）
    @discardableResult
    /// - Returns: (付与クレジット数, StoreKitトランザクションID) または nil
    func purchase(_ product: Product) async -> (credits: Int, transactionId: String)? {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try ReceiptValidator.verify(verification)
                let transactionId = String(transaction.id)
                await transaction.finish()

                // サブスクリプション購入の場合
                if ProductIdentifiers.allSubscriptions.contains(product.id) {
                    activeSubscriptionProductId = product.id
                    isSubscribed = true
                    purchaseState = .subscribedSuccess
                    #if DEBUG
                    print("[StoreKitManager] Subscription activated: \(product.id)")
                    #endif
                    return nil
                }

                // スターターパック購入の場合
                if ProductIdentifiers.isStarterPack(product.id) {
                    markStarterPackUsed()
                }

                // クレジットパック購入の場合
                let credits = ProductIdentifiers.creditsFor(productId: product.id)
                purchaseState = .success(credits: credits)

                #if DEBUG
                print("[StoreKitManager] Purchase successful: \(product.id), \(credits) credits, txId: \(transactionId)")
                #endif

                return (credits: credits, transactionId: transactionId)

            case .pending:
                purchaseState = .idle
                return nil

            case .userCancelled:
                purchaseState = .idle
                return nil

            @unknown default:
                purchaseState = .idle
                return nil
            }
        } catch {
            purchaseState = .failed(error)
            #if DEBUG
            print("[StoreKitManager] Purchase failed: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    // MARK: - Restore Purchases

    /// 以前の購入を復元
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            await checkStarterPackStatus()
            #if DEBUG
            print("[StoreKitManager] Purchases restored successfully")
            #endif
        } catch {
            #if DEBUG
            print("[StoreKitManager] Failed to restore purchases: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Transaction Listener

    /// バックグラウンドでトランザクション更新を監視
    func listenForTransactions() {
        transactionListenerTask?.cancel()

        transactionListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try ReceiptValidator.verify(result)

                    await transaction.finish()

                    if ProductIdentifiers.allSubscriptions.contains(transaction.productID) {
                        await self?.handleSubscriptionUpdate()
                    } else {
                        let credits = ProductIdentifiers.creditsFor(productId: transaction.productID)
                        if credits > 0 {
                            await self?.applyTransactionUpdate(credits: credits)
                        }
                        if ProductIdentifiers.isStarterPack(transaction.productID) {
                            await self?.markStarterPackUsed()
                        }
                    }
                } catch {
                    #if DEBUG
                    print("[StoreKitManager] Transaction verification failed: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }

    // MARK: - Helpers

    /// 購入状態をリセット
    func resetPurchaseState() {
        purchaseState = .idle
    }

    /// 特定のプロダクトIDのプロダクトを取得
    func product(for productId: String) -> Product? {
        products.first { $0.id == productId }
    }

    /// サブスクリプションの中から特定のプロダクトを取得
    func subscription(for productId: String) -> Product? {
        subscriptions.first { $0.id == productId }
    }

    private func applyTransactionUpdate(credits: Int) {
        purchaseState = .success(credits: credits)
    }

    private func handleSubscriptionUpdate() {
        Task {
            await checkSubscriptionStatus()
        }
    }
}
