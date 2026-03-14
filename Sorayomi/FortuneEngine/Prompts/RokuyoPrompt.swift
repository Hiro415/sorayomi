import Foundation

// MARK: - RokuyoPrompt

/// 六曜占い用のユーザープロンプトを構築する
/// Builds the rokuyo-specific section of the user prompt, including
/// today's rokuyo, its guidance, lucky time of day, and auspiciousness.
/// Rokuyo does not require a user profile (no birthday needed).
struct RokuyoPrompt {

    // MARK: - Public API

    /// Build the rokuyo context block for the user prompt.
    /// - Parameter category: The reading category to tailor the prompt.
    /// - Returns: A formatted Japanese rokuyo context string.
    static func build(category: ReadingCategory) -> String {
        let today = Date()
        let rokuyo = RokuyoCalculator.calculate(from: today)

        var lines: [String] = []

        lines.append("【六曜データ】")
        lines.append("・今日の六曜：\(rokuyo.japaneseName)（\(rokuyo.reading)）")
        lines.append("・吉凶：\(rokuyo.isAuspicious ? "吉日" : "注意が必要な日")")
        lines.append("・吉時間帯：\(rokuyo.luckyTimeOfDay)")
        lines.append("・ガイダンス：\(rokuyo.briefGuidance)")
        lines.append("・吉凶度：\(auspiciousnessDescription(score: rokuyo.auspiciousnessScore))")

        // Include upcoming rokuyo for context
        let upcoming = RokuyoCalculator.upcoming(from: today, days: 3)
        if upcoming.count > 1 {
            lines.append("")
            lines.append("今後の暦の流れ：")
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月d日（E）"
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

            for (date, upcomingRokuyo) in upcoming.dropFirst() {
                let dateStr = formatter.string(from: date)
                lines.append("  ・\(dateStr)：\(upcomingRokuyo.japaneseName)")
            }
        }

        lines.append("")
        lines.append("上記の六曜データを踏まえて、\(category.japaneseName)について鑑定してください。")
        lines.append("今日の六曜が示す時間帯の吉凶を具体的な過ごし方のアドバイスに")
        lines.append("活かしてください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Convert the auspiciousness score (1-5) to a Japanese description.
    private static func auspiciousnessDescription(score: Int) -> String {
        switch score {
        case 5: return "大吉（とても良い日です）"
        case 4: return "吉（良い日です）"
        case 3: return "小吉（まずまずの日です）"
        case 2: return "注意（慎重に過ごしましょう）"
        case 1: return "静観（内省や準備に充てましょう）"
        default: return "平常"
        }
    }
}
