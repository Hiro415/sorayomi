import Foundation

// MARK: - DailyFortune

/// 今日の運勢スナップショット
/// Aggregates daily fortune data from multiple systems (horoscope, blood type,
/// rokuyo, numerology) into a single daily overview.
struct DailyFortune: Codable {
    let date: Date
    let zodiacSign: ZodiacSign
    let bloodType: BloodType?
    let rokuyo: Rokuyo
    let horoscopeSnippet: String
    let bloodTypeSnippet: String
    let luckyColor: String
    let luckyItem: String
    let overallScore: Int
    let numerologyDay: Int?

    // MARK: - Computed Properties

    /// 運勢スコアを星で表示（1-5）
    var starRating: String {
        let clampedScore = min(max(overallScore, 1), 5)
        let filled = String(repeating: "★", count: clampedScore)
        let empty = String(repeating: "☆", count: 5 - clampedScore)
        return filled + empty
    }

    /// 運勢レベルの日本語テキスト
    var fortuneLevel: String {
        let clampedScore = min(max(overallScore, 1), 5)
        switch clampedScore {
        case 5: return "大吉"
        case 4: return "中吉"
        case 3: return "吉"
        case 2: return "小吉"
        case 1: return "末吉"
        default: return "吉"
        }
    }

    /// ラッキーカラーとラッキーアイテムの表示テキスト
    var luckyInfo: String {
        "ラッキーカラー: \(luckyColor)　ラッキーアイテム: \(luckyItem)"
    }

    /// 数秘術デイナンバーの説明
    var numerologyDayDescription: String? {
        guard let day = numerologyDay else { return nil }
        return NumerologyProfile.dayGuidance(for: day)
    }

    /// 六曜が吉日かどうか
    var isAuspiciousDay: Bool {
        rokuyo.isAuspicious
    }

    /// 総合的な運勢サマリー
    var dailySummary: String {
        var parts: [String] = []
        parts.append("今日の運勢: \(fortuneLevel)")
        parts.append("六曜: \(rokuyo.japaneseName)")
        parts.append(luckyInfo)
        return parts.joined(separator: "\n")
    }

    // MARK: - Validation

    /// スコアが有効範囲内かどうか
    var isValidScore: Bool {
        overallScore >= 1 && overallScore <= 5
    }

    // MARK: - Preview Mock

    /// プレビュー用モックデータ
    static let mock = DailyFortune(
        date: Date(),
        zodiacSign: .leo,
        bloodType: .a,
        rokuyo: .taian,
        horoscopeSnippet: "今日のしし座は、創造力が高まる一日。新しいアイデアが浮かびやすく、自分の表現を大切にすると良い流れが生まれます。",
        bloodTypeSnippet: "A型の今日の傾向: 几帳面さが良い方向に働きます。計画的に行動すると、思いがけない成果が得られるでしょう。",
        luckyColor: "ゴールド",
        luckyItem: "手帳",
        overallScore: 4,
        numerologyDay: 3
    )

    /// プレビュー用：運勢が低い日のモック
    static let lowFortuneMock = DailyFortune(
        date: Date(),
        zodiacSign: .pisces,
        bloodType: .b,
        rokuyo: .butsumetsu,
        horoscopeSnippet: "今日のうお座は、少し休息が必要な日。無理をせず、自分のペースを大切にしましょう。明日からまた良い流れが戻ってきます。",
        bloodTypeSnippet: "B型の今日の傾向: マイペースに過ごすのが吉。周囲に流されず、自分の直感を信じて行動しましょう。",
        luckyColor: "ラベンダー",
        luckyItem: "お気に入りの音楽",
        overallScore: 2,
        numerologyDay: 7
    )
}
