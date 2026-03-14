import Foundation
import StoreKit

// MARK: - StoreViewModel

/// クレジットストア画面の ViewModel
/// StoreKitManager を通じてプロダクト読み込み・購入処理を管理し、
/// CreditWalletService に購入クレジットを反映する。
@Observable
@MainActor
final class StoreViewModel {

    // MARK: - State

    /// 利用可能なクレジットパック
    var products: [Product] = []

    /// 利用可能なサブスクリプション
    var subscriptions: [Product] = []

    /// サブスクリプションが有効かどうか
    var isSubscribed: Bool = false

    /// 読み込み中かどうか
    var isLoading = false

    /// 購入処理中かどうか
    var isPurchasing = false

    /// 購入成功時の付与クレジット数（確認ダイアログ用）
    var purchasedCredits: Int?

    /// サブスクリプション購入成功フラグ
    var didSubscribe = false

    /// エラーメッセージ
    var errorMessage: String?

    // MARK: - Load Products

    /// App Store からプロダクト一覧を読み込む
    func loadProducts(storeKitManager: StoreKitManager) async {
        guard products.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        await storeKitManager.loadProducts()
        products = storeKitManager.products
        subscriptions = storeKitManager.subscriptions
        isSubscribed = storeKitManager.isSubscribed

        if products.isEmpty && subscriptions.isEmpty {
            #if DEBUG
            print("[StoreViewModel] No products loaded, StoreKit may not be configured")
            #endif
        }

        isLoading = false
    }

    // MARK: - Purchase Credit Pack

    /// クレジットパックを購入してクレジットを付与する
    func purchase(product: Product, env: AppEnvironment) async {
        isPurchasing = true
        errorMessage = nil

        let credits = await env.storeKitManager.purchase(product)

        if let credits, credits > 0 {
            await env.creditWalletService.addCredits(
                credits,
                productId: product.id,
                transactionId: UUID().uuidString
            )

            purchasedCredits = credits

            env.analyticsService.track(.monetizationPurchaseCompleted(
                productId: product.id,
                credits: credits
            ))

            #if DEBUG
            print("[StoreViewModel] Purchase successful: +\(credits) credits")
            #endif
        } else if case .failed(let error) = env.storeKitManager.purchaseState {
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"

            env.analyticsService.track(.monetizationPurchaseFailed(
                productId: product.id,
                errorDescription: error.localizedDescription
            ))
        }

        isPurchasing = false
    }

    // MARK: - Purchase Subscription

    /// サブスクリプションを購入する
    func purchaseSubscription(product: Product, env: AppEnvironment) async {
        isPurchasing = true
        errorMessage = nil

        _ = await env.storeKitManager.purchase(product)

        if case .subscribedSuccess = env.storeKitManager.purchaseState {
            isSubscribed = true
            didSubscribe = true

            env.analyticsService.track(.monetizationPurchaseCompleted(
                productId: product.id,
                credits: 0
            ))

            #if DEBUG
            print("[StoreViewModel] Subscription activated: \(product.id)")
            #endif
        } else if case .failed(let error) = env.storeKitManager.purchaseState {
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"

            env.analyticsService.track(.monetizationPurchaseFailed(
                productId: product.id,
                errorDescription: error.localizedDescription
            ))
        }

        isPurchasing = false
    }

    // MARK: - Restore

    /// 以前の購入を復元する
    func restorePurchases(storeKitManager: StoreKitManager) async {
        isLoading = true
        await storeKitManager.restorePurchases()
        isSubscribed = storeKitManager.isSubscribed
        isLoading = false
    }

    // MARK: - Helpers

    /// 購入確認ダイアログを閉じる
    func dismissPurchaseConfirmation(storeKitManager: StoreKitManager) {
        purchasedCredits = nil
        didSubscribe = false
        storeKitManager.resetPurchaseState()
    }

    /// 各パックの付与クレジット数を取得
    func credits(for product: Product) -> Int {
        ProductIdentifiers.creditsFor(productId: product.id)
    }

    /// パックのおすすめバッジ（12 クレジットに "人気" を付与）
    func badge(for product: Product) -> String? {
        switch product.id {
        case ProductIdentifiers.pack12: return "人気"
        case ProductIdentifiers.pack24: return "お得"
        default: return nil
        }
    }

    /// パックのラベル
    func label(for product: Product) -> String {
        switch product.id {
        case ProductIdentifiers.pack4:  return "おためしパック"
        case ProductIdentifiers.pack12: return "おすすめパック"
        case ProductIdentifiers.pack24: return "お得パック"
        default: return "\(credits(for: product))クレジット"
        }
    }
}
