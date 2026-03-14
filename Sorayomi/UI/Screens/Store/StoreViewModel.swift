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

    /// 利用可能なプロダクト一覧
    var products: [Product] = []

    /// 読み込み中かどうか
    var isLoading = false

    /// 購入処理中かどうか
    var isPurchasing = false

    /// 購入成功時の付与クレジット数（確認ダイアログ用）
    var purchasedCredits: Int?

    /// エラーメッセージ
    var errorMessage: String?

    // MARK: - Dependencies

    private let storeKitManager = StoreKitManager()

    // MARK: - Load Products

    /// App Store からプロダクト一覧を読み込む
    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        await storeKitManager.loadProducts()
        products = storeKitManager.products

        if products.isEmpty {
            // MVP: プロダクトが読み込めない場合はフォールバック表示
            #if DEBUG
            print("[StoreViewModel] No products loaded, StoreKit may not be configured")
            #endif
        }

        isLoading = false
    }

    // MARK: - Purchase

    /// プロダクトを購入してクレジットを付与する
    func purchase(product: Product, env: AppEnvironment) async {
        isPurchasing = true
        errorMessage = nil

        let credits = await storeKitManager.purchase(product)

        if let credits, credits > 0 {
            // クレジットをウォレットに追加
            await env.creditWalletService.addCredits(
                credits,
                productId: product.id,
                transactionId: UUID().uuidString
            )

            purchasedCredits = credits

            // Analytics
            env.analyticsService.track(.monetizationPurchaseCompleted(
                productId: product.id,
                credits: credits
            ))

            #if DEBUG
            print("[StoreViewModel] Purchase successful: +\(credits) credits")
            #endif
        } else if case .failed(let error) = storeKitManager.purchaseState {
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
    func restorePurchases() async {
        isLoading = true
        await storeKitManager.restorePurchases()
        isLoading = false
    }

    // MARK: - Helpers

    /// 購入確認ダイアログを閉じる
    func dismissPurchaseConfirmation() {
        purchasedCredits = nil
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
