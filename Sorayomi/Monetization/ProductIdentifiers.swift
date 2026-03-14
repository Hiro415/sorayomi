import Foundation

// MARK: - ProductIdentifiers

/// App Store 課金アイテムのプロダクトID定義
/// クレジットパックの識別子と付与クレジット数のマッピングを管理する。
enum ProductIdentifiers {

    // MARK: - Product IDs

    /// 4クレジットパック
    static let pack4 = "com.sorayomi.credits.pack4"

    /// 12クレジットパック
    static let pack12 = "com.sorayomi.credits.pack12"

    /// 24クレジットパック
    static let pack24 = "com.sorayomi.credits.pack24"

    // MARK: - All Packs

    /// 全クレジットパックのプロダクトID配列
    static let allCreditPacks: [String] = [
        pack4,
        pack12,
        pack24
    ]

    // MARK: - Credit Mapping

    /// プロダクトID から付与クレジット数を取得
    /// - Parameter productId: App Store プロダクトID
    /// - Returns: 付与されるクレジット数（不明なIDの場合は 0）
    static func creditsFor(productId: String) -> Int {
        switch productId {
        case pack4:  return 4
        case pack12: return 12
        case pack24: return 24
        default:     return 0
        }
    }

    // MARK: - Display Info

    /// プロダクトID の日本語表示名
    static func displayName(for productId: String) -> String {
        let credits = creditsFor(productId: productId)
        guard credits > 0 else { return "不明なパック" }
        return "\(credits)クレジットパック"
    }
}
