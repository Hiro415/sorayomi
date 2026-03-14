import Foundation

// MARK: - FortuneCalculatorProtocol

/// 占い計算エンジンの基本プロトコル
/// Defines the generic interface for all fortune calculation engines.
/// Each fortune system (horoscope, numerology, nine star ki, etc.)
/// implements this protocol with its own Input and Output types.
protocol FortuneCalculatorProtocol {
    /// 計算に必要な入力型
    associatedtype Input

    /// 計算結果の出力型
    associatedtype Output

    /// 入力データから占い結果を計算する
    /// - Parameter input: 計算に必要な入力データ
    /// - Returns: 計算結果
    func calculate(input: Input) -> Output
}

// MARK: - DateBasedCalculatorProtocol

/// 日付ベースの占い計算プロトコル
/// For fortune systems that primarily use a date (birthday or current date) as input.
protocol DateBasedCalculatorProtocol: FortuneCalculatorProtocol where Input == Date {
    /// 指定日の占い結果を計算する
    func calculate(input: Date) -> Output
}

// MARK: - DailyFortuneCalculatorProtocol

/// デイリー運勢計算プロトコル
/// For systems that provide daily-changing fortune readings.
protocol DailyFortuneCalculatorProtocol {
    associatedtype DailyOutput

    /// 今日の運勢を計算する
    func calculateToday() -> DailyOutput

    /// 指定日の運勢を計算する
    func calculateForDate(_ date: Date) -> DailyOutput
}

// MARK: - FortuneCalculationError

/// 占い計算時のエラー型
enum FortuneCalculationError: LocalizedError {
    case invalidInput(String)
    case missingRequiredData(String)
    case calculationFailed(String)
    case dateOutOfRange

    var errorDescription: String? {
        switch self {
        case .invalidInput(let detail):
            return "入力データが不正です: \(detail)"
        case .missingRequiredData(let field):
            return "必要なデータが不足しています: \(field)"
        case .calculationFailed(let reason):
            return "計算に失敗しました: \(reason)"
        case .dateOutOfRange:
            return "指定された日付が有効範囲外です"
        }
    }

    /// ユーザー向けの簡潔なメッセージ
    var userFacingMessage: String {
        switch self {
        case .invalidInput:
            return "入力内容をご確認ください"
        case .missingRequiredData(let field):
            return "\(field)を入力してください"
        case .calculationFailed:
            return "計算できませんでした。もう一度お試しください"
        case .dateOutOfRange:
            return "有効な日付を入力してください"
        }
    }
}

// MARK: - ThrowingFortuneCalculatorProtocol

/// エラーを投げる可能性のある占い計算プロトコル
/// For calculation engines that may fail due to invalid input or other conditions.
protocol ThrowingFortuneCalculatorProtocol {
    associatedtype Input
    associatedtype Output

    /// 入力データから占い結果を計算する（失敗の可能性あり）
    /// - Parameter input: 計算に必要な入力データ
    /// - Returns: 計算結果
    /// - Throws: `FortuneCalculationError` if calculation fails
    func calculate(input: Input) throws -> Output
}
