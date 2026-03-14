import Foundation

// MARK: - BloodTypePrompt

/// 血液型占い用のユーザープロンプトを構築する
/// Builds the blood type specific section of the user prompt, including
/// blood type traits (personality, strengths, weaknesses, compatibility).
struct BloodTypePrompt {

    // MARK: - Public API

    /// Build the blood type context block for the user prompt.
    /// - Parameters:
    ///   - profile: The user's profile containing blood type.
    ///   - category: The reading category to tailor the prompt.
    /// - Returns: A formatted Japanese blood type context string.
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let bloodType = profile.bloodType else {
            return fallbackPrompt(category: category)
        }

        let traits = BloodTypeCalculator.traits(for: bloodType)

        var lines: [String] = []

        lines.append("【血液型占いデータ】")
        lines.append("・血液型：\(bloodType.japaneseName)")
        lines.append("・基本性格：\(traits.personality)")
        lines.append("・強み：\(traits.strengths)")
        lines.append("・注意点：\(traits.weaknesses)")

        // Compatibility information
        let compatNames = traits.compatibility.map { $0.japaneseName }
        lines.append("・相性の良い血液型：\(compatNames.joined(separator: "・"))")

        // Add today's Rokuyo for daily context (blood type readings often include daily advice)
        let todayRokuyo = RokuyoCalculator.calculate(from: Date())
        lines.append("")
        lines.append("・今日の暦：\(todayRokuyo.japaneseName)（参考情報）")

        lines.append("")
        lines.append("上記の血液型データを踏まえて、\(category.japaneseName)について鑑定してください。")
        lines.append("\(bloodType.japaneseName)の方の傾向として、今日特に意識すると良い点を")
        lines.append("具体的にお伝えください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Fallback when no blood type is set.
    private static func fallbackPrompt(category: ReadingCategory) -> String {
        var lines: [String] = []
        lines.append("【血液型占いデータ】")
        lines.append("・血液型が未設定です。")
        lines.append("")
        lines.append("血液型が未設定のため、各血液型（A型・B型・O型・AB型）に共通する")
        lines.append("一般的な傾向を踏まえて、\(category.japaneseName)について鑑定してください。")
        return lines.joined(separator: "\n")
    }
}
