import Foundation

// MARK: - BirthdayPrompt

/// 誕生日占い用のユーザープロンプトを構築する
/// Builds the birthday personality specific section of the user prompt,
/// including personality traits, strength, lucky color, lucky number,
/// seasonal advice, and compatible date derived from BirthdayPersonalityCalculator.
struct BirthdayPrompt {

    // MARK: - Public API

    /// Build the birthday personality context block for the user prompt.
    /// - Parameters:
    ///   - profile: The user's profile containing birthday.
    ///   - category: The reading category to tailor the prompt.
    /// - Returns: A formatted Japanese birthday personality context string.
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let birthdayProfile = BirthdayPersonalityCalculator.profile(from: birthday)
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)

        var lines: [String] = []

        lines.append("【誕生日占いデータ】")
        lines.append("・誕生日：\(month)月\(day)日")
        lines.append("・基本性格：\(birthdayProfile.personality)")
        lines.append("・強み：\(birthdayProfile.strength)")
        lines.append("・ラッキーカラー：\(birthdayProfile.luckyColor)")
        lines.append("・ラッキーナンバー：\(birthdayProfile.luckyNumber)")
        lines.append("・季節のアドバイス：\(birthdayProfile.seasonalAdvice)")

        // Compatible date
        let compatMonth = birthdayProfile.compatibleMonthDay.month
        let compatDay = birthdayProfile.compatibleMonthDay.day
        lines.append("・相性の良い誕生日：\(compatMonth)月\(compatDay)日")

        // Numerological birthday number for added depth
        let birthdayNumber = NumerologyCalculator.birthdayNumber(from: birthday)
        lines.append("・誕生日数（数秘術）：\(birthdayNumber)")

        lines.append("")
        lines.append("上記の誕生日データを踏まえて、\(category.japaneseName)について鑑定してください。")
        lines.append("\(month)月\(day)日生まれの方が持つ特別なエネルギーと、")
        lines.append("今日という日の組み合わせから導かれるメッセージをお伝えください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Fallback when no birthday is available.
    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let today = Date()
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)

        var lines: [String] = []
        lines.append("【誕生日占いデータ】")
        lines.append("・誕生日情報が未設定です。")
        lines.append("")
        lines.append("誕生日が未設定のため、本日（\(month)月\(day)日）という日が持つ")
        lines.append("エネルギーを中心に、\(category.japaneseName)について鑑定してください。")
        return lines.joined(separator: "\n")
    }
}
