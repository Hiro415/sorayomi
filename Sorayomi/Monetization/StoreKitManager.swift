import Foundation
import StoreKit

// MARK: - PurchaseState

/// 購入プロセスの状態
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case success(credits: Int)
    case failed(Error)

    static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.purchasing, .purchasing):
            return true
        case (.success(let l), .success(let r)):
            return l == r
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - StoreKitManager

/// StoreKit 2 を使った App Store 課金管理
/// プロダクトの読み込み、購入、トランザクション監視を統括する。
@Observable
@MainActor
final class StoreKitManager {

    // MARK: - Properties

    /// 利用可能なプロダクト一覧
    private(set) var products: [Product] = []

    /// 現在の購入状態
    private(set) var purchaseState: PurchaseState = .idle

    /// トランザクション監視タスク
    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        // トランザクション監視を開始
        listenForTransactions()
    }

    // MARK: - Load Products

    /// App Store からプロダクト情報を読み込む
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(
                for: Set(ProductIdentifiers.allCreditPacks)
            )
            // 価格順にソート
            products = storeProducts.sorted { $0.price < $1.price }

            #if DEBUG
            print("[StoreKitManager] Loaded \(products.count) products")
            for product in products {
                print("  - \(product.id): \(product.displayPrice)")
            }
            #endif
        } catch {
            #if DEBUG
            print("[StoreKitManager] Failed to load products: \(error.localizedDescription)")
            #endif
            products = []
        }
    }

    // MARK: - Purchase

    /// プロダクトを購入する
    /// - Parameter product: 購入するプロダクト
    /// - Returns: 付与されるクレジット数（購入成功時）、nil（キャンセル時）
    @discardableResult
    func purchase(_ product: Product) async -> Int? {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try ReceiptValidator.verify(verification)
                let credits = ProductIdentifiers.creditsFor(productId: product.id)

                // トランザクションを完了済みにする
                await transaction.finish()

                purchaseState = .success(credits: credits)

                #if DEBUG
                print("[StoreKitManager] Purchase successful: \(product.id), \(credits) credits")
                #endif

                return credits

            case .pending:
                purchaseState = .idle
                #if DEBUG
                print("[StoreKitManager] Purchase pending: \(product.id)")
                #endif
                return nil

            case .userCancelled:
                purchaseState = .idle
                #if DEBUG
                print("[StoreKitManager] Purchase cancelled by user: \(product.id)")
                #endif
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
                    let credits = ProductIdentifiers.creditsFor(productId: transaction.productID)

                    #if DEBUG
                    print("[StoreKitManager] Transaction update: \(transaction.productID)")
                    #endif

                    // トランザクションを完了済みにする
                    await transaction.finish()

                    if credits > 0 {
                        await self?.applyTransactionUpdate(credits: credits)
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

    private func applyTransactionUpdate(credits: Int) {
        purchaseState = .success(credits: credits)
    }
}
