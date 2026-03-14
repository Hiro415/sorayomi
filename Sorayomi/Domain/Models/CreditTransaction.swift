import Foundation

// MARK: - TransactionType

/// クレジット取引の種類
enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case purchase = "purchase"
    case consumption = "consumption"
    case freeGrant = "free_grant"
    case refund = "refund"

    var id: String { rawValue }

    /// 日本語表示名
    var japaneseName: String {
        switch self {
        case .purchase:    return "購入"
        case .consumption: return "使用"
        case .freeGrant:   return "無料付与"
        case .refund:      return "返金"
        }
    }

    /// 取引の符号（+/-表示用）
    var sign: String {
        switch self {
        case .purchase, .freeGrant, .refund: return "+"
        case .consumption:                   return "-"
        }
    }

    /// SF Symbolsアイコン名
    var iconName: String {
        switch self {
        case .purchase:    return "creditcard.fill"
        case .consumption: return "sparkles"
        case .freeGrant:   return "gift.fill"
        case .refund:      return "arrow.uturn.backward.circle.fill"
        }
    }

    /// 収入（クレジット増加）かどうか
    var isCredit: Bool {
        switch self {
        case .purchase, .freeGrant, .refund: return true
        case .consumption:                   return false
        }
    }
}

// MARK: - CreditTransaction

/// クレジットの取引記録
/// Records a single credit transaction for audit and history purposes.
struct CreditTransaction: Codable, Identifiable {
    let id: String
    let userId: String
    let type: TransactionType
    let amount: Int
    let productId: String?
    let readingId: String?
    let description: String?
    let timestamp: Date

    // MARK: - Computed Properties

    /// 表示用の金額テキスト（符号付き）
    var displayAmount: String {
        "\(type.sign)\(amount)"
    }

    /// 取引の説明テキスト
    var displayDescription: String {
        if let description {
            return description
        }
        switch type {
        case .purchase:
            return "クレジット購入"
        case .consumption:
            return "占い鑑定に使用"
        case .freeGrant:
            return "無料クレジット付与"
        case .refund:
            return "クレジット返金"
        }
    }

    // MARK: - Factory Methods

    /// 購入取引を作成
    static func purchase(userId: String, amount: Int, productId: String) -> CreditTransaction {
        CreditTransaction(
            id: UUID().uuidString,
            userId: userId,
            type: .purchase,
            amount: amount,
            productId: productId,
            readingId: nil,
            description: nil,
            timestamp: Date()
        )
    }

    /// 消費取引を作成
    static func consumption(userId: String, amount: Int, readingId: String) -> CreditTransaction {
        CreditTransaction(
            id: UUID().uuidString,
            userId: userId,
            type: .consumption,
            amount: amount,
            productId: nil,
            readingId: readingId,
            description: nil,
            timestamp: Date()
        )
    }

    /// 無料付与取引を作成
    static func freeGrant(userId: String, amount: Int, description: String? = nil) -> CreditTransaction {
        CreditTransaction(
            id: UUID().uuidString,
            userId: userId,
            type: .freeGrant,
            amount: amount,
            productId: nil,
            readingId: nil,
            description: description ?? "デイリー無料クレジット",
            timestamp: Date()
        )
    }

    // MARK: - Preview Mocks

    /// プレビュー用：購入取引
    static let mockPurchase = CreditTransaction(
        id: "txn-mock-001",
        userId: "mock-user-001",
        type: .purchase,
        amount: 10,
        productId: "com.sorayomi.credits.10",
        readingId: nil,
        description: nil,
        timestamp: Date().addingTimeInterval(-3600)
    )

    /// プレビュー用：消費取引
    static let mockConsumption = CreditTransaction(
        id: "txn-mock-002",
        userId: "mock-user-001",
        type: .consumption,
        amount: 1,
        productId: nil,
        readingId: "reading-mock-001",
        description: nil,
        timestamp: Date()
    )

    /// プレビュー用：無料付与
    static let mockFreeGrant = CreditTransaction(
        id: "txn-mock-003",
        userId: "mock-user-001",
        type: .freeGrant,
        amount: 3,
        productId: nil,
        readingId: nil,
        description: "デイリー無料クレジット",
        timestamp: Date().addingTimeInterval(-86400)
    )
}
