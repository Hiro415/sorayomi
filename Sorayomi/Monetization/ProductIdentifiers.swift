import Foundation

// MARK: - ProductIdentifiers

/// App Store 課金アイテムのプロダクトID定義
/// クレジットパック・スターターパック・サブスクリプションの識別子と付与クレジット数を管理する。
enum ProductIdentifiers {

    // MARK: - Starter Pack (1回限り)

    /// スターターパック（5クレジット・¥160・1回限り購入可能）
    static let starterPack = "com.sorayomi.credits.starter"

    // MARK: - Credit Packs

    /// 12クレジットパック（¥480）
    static let pack12 = "com.sorayomi.credits.pack12"

    /// 30クレジットパック（¥980）
    static let pack30 = "com.sorayomi.credits.pack30"

    /// 60クレジットパック（¥1,600）
    static let pack60 = "com.sorayomi.credits.pack60"

    // MARK: - Subscriptions

    /// 月間プレミアムパス（30クレジット/月・¥980）
    static let monthlyPremium = "com.sorayomi.sub.monthly"

    /// 月次クレジット付与数
    static func monthlyCredits(for productId: String) -> Int {
        switch productId {
        case monthlyPremium: return 30
        default: return 0
        }
    }

    /// 全サブスクリプションのプロダクトID配列
    static let allSubscriptions: [String] = [
        monthlyPremium
    ]

    // MARK: - All Packs

    /// 全クレジットパックのプロダクトID配列（スターターパック含む）
    static let allCreditPacks: [String] = [
        starterPack,
        pack12,
        pack30,
        pack60
    ]

    /// 全プロダクトID
    static let allProducts: [String] = allSubscriptions + allCreditPacks

    // MARK: - Credit Mapping

    /// プロダクトID から付与クレジット数を取得
    /// - Parameter productId: App Store プロダクトID
    /// - Returns: 付与されるクレジット数（不明なIDの場合は 0）
    static func creditsFor(productId: String) -> Int {
        switch productId {
        case starterPack: return 5
        case pack12:      return 12
        case pack30:      return 30
        case pack60:      return 60
        default:          return 0
        }
    }

    /// スターターパックかどうか
    static func isStarterPack(_ productId: String) -> Bool {
        productId == starterPack
    }

    // MARK: - Display Info

    /// プロダクトID の日本語表示名
    static func displayName(for productId: String) -> String {
        switch productId {
        case starterPack:    return "はじめてパック"
        case pack12:         return "おすすめパック"
        case pack30:         return "じっくり相談パック"
        case pack60:         return "たっぷり鑑定パック"
        case monthlyPremium: return "月間プレミアム"
        default:             return "不明なパック"
        }
    }

    /// プロダクトID の単価表示
    static func unitPrice(for productId: String) -> String {
        switch productId {
        case starterPack: return "¥32/回"
        case pack12:      return "¥40/回"
        case pack30:      return "¥33/回"
        case pack60:      return "¥27/回"
        default:          return ""
        }
    }
}
