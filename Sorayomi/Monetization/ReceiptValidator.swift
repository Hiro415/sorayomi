import Foundation
import StoreKit

// MARK: - ReceiptValidator

/// StoreKit 2 トランザクション検証ユーティリティ
/// VerificationResult を検証し、正当なトランザクションのみを返す。
struct ReceiptValidator {

    // MARK: - Verification Error

    /// レシート検証エラー
    enum ValidationError: Error, LocalizedError {
        case unverified
        case invalidSignature

        var errorDescription: String? {
            switch self {
            case .unverified:
                return "トランザクションの検証に失敗しました"
            case .invalidSignature:
                return "トランザクションの署名が無効です"
            }
        }
    }

    // MARK: - Verify

    /// VerificationResult を検証し、正当な値を返す
    /// - Parameter result: StoreKit の VerificationResult
    /// - Returns: 検証済みの値
    /// - Throws: 検証に失敗した場合エラー
    static func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            #if DEBUG
            print("[ReceiptValidator] Unverified transaction: \(error.localizedDescription)")
            #endif
            throw ValidationError.unverified

        case .verified(let value):
            #if DEBUG
            print("[ReceiptValidator] Transaction verified successfully")
            #endif
            return value
        }
    }
}
