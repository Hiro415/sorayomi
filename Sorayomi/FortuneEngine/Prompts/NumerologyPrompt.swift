import Foundation

// MARK: - NumerologyPrompt

/// 数秘術用のユーザープロンプトを構築する
/// Builds the numerology-specific section of the user prompt, including
/// life path number, birthday number, and personal year/month/day numbers
/// with their Japanese descriptions.
struct NumerologyPrompt {

    // MARK: - Public API

    /// Build the numerology context block for the user prompt.
    /// - Parameters:
    ///   - profile: The user's profile containing birthday for numerology calculation.
    ///   - category: The reading category to tailor the prompt.
    /// - Returns: A formatted Japanese numerology context string.
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let today = Date()
        let numProfile = NumerologyCalculator.profile(from: birthday, currentDate: today)

        var lines: [String] = []

        lines.append("【数秘術データ】")
        lines.append("")

        // Life Path Number
        lines.append("ライフパスナンバー：\(formatNumber(numProfile.lifePathNumber))")
        lines.append("  \(numProfile.lifePathDescription)")
        if isMasterNumber(numProfile.lifePathNumber) {
            lines.append("  ※マスターナンバーです。特別な使命とエネルギーを持っています。")
        }

        lines.append("")

        // Birthday Number
        lines.append("バースデーナンバー：\(formatNumber(numProfile.birthdayNumber))")

        lines.append("")

        // Personal Year
        lines.append("パーソナルイヤー：\(formatNumber(numProfile.personalYearNumber))")
        lines.append("  \(NumerologyProfile.description(for: numProfile.personalYearNumber))")

        lines.append("")

        // Personal Month
        lines.append("パーソナルマンス：\(formatNumber(numProfile.personalMonthNumber))")

        lines.append("")

        // Personal Day
        lines.append("パーソナルデイ：\(formatNumber(numProfile.personalDayNumber))")
        lines.append("  \(numProfile.personalDayDescription)")

        lines.append("")
        lines.append("上記の数秘術データを踏まえて、\(category.japaneseName)について鑑定してください。")
        lines.append("ライフパスナンバーが示す本質と、今日のパーソナルデイの")
        lines.append("エネルギーの関係性を解釈に織り込んでください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Fallback when no birthday is available.
    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let today = Date()
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: today)
        let universalDay = NumerologyCalculator.reduceToSingle(day)

        var lines: [String] = []
        lines.append("【数秘術データ】")
        lines.append("・誕生日情報が未設定です。")
        lines.append("・本日のユニバーサルデイナンバー：\(formatNumber(universalDay))")
        lines.append("")
        lines.append("誕生日が未設定のため、本日の日付が持つ数字のエネルギーを中心に、")
        lines.append("\(category.japaneseName)について鑑定してください。")
        return lines.joined(separator: "\n")
    }

    /// Format a number, highlighting master numbers.
    private static func formatNumber(_ number: Int) -> String {
        if isMasterNumber(number) {
            return "\(number)（マスターナンバー）"
        }
        return "\(number)"
    }

    /// Check if a number is a master number (11, 22, 33).
    private static func isMasterNumber(_ number: Int) -> Bool {
        return number == 11 || number == 22 || number == 33
    }
}
