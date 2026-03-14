import Foundation

// MARK: - NineStarKiPrompt

/// 九星気学用のユーザープロンプトを構築する
/// Builds the Nine Star Ki specific section of the user prompt, including
/// honmeisei (birth year star) and getsumeisei (birth month star) with
/// their elements, directions, colors, and personality traits.
struct NineStarKiPrompt {

    // MARK: - Public API

    /// Build the Nine Star Ki context block for the user prompt.
    /// - Parameters:
    ///   - profile: The user's profile containing birthday for star calculation.
    ///   - category: The reading category to tailor the prompt.
    /// - Returns: A formatted Japanese Nine Star Ki context string.
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let nineStarProfile = NineStarKiCalculator.calculate(from: birthday)
        let dailyStar = NineStarKiCalculator.dailyStar()

        var lines: [String] = []

        lines.append("【九星気学データ】")
        lines.append("")

        // Honmeisei (Birth Year Star)
        lines.append("本命星：\(nineStarProfile.honmeisei.japaneseName)")
        lines.append("  ・五行：\(nineStarProfile.honmeisei.element)")
        lines.append("  ・方位：\(nineStarProfile.honmeisei.direction)")
        lines.append("  ・色：\(nineStarProfile.honmeisei.color)")
        lines.append("  ・性格：\(nineStarProfile.honmeisei.personality)")

        lines.append("")

        // Getsumeisei (Birth Month Star)
        lines.append("月命星：\(nineStarProfile.getsumeisei.japaneseName)")
        lines.append("  ・五行：\(nineStarProfile.getsumeisei.element)")
        lines.append("  ・方位：\(nineStarProfile.getsumeisei.direction)")
        lines.append("  ・色：\(nineStarProfile.getsumeisei.color)")
        lines.append("  ・性格：\(nineStarProfile.getsumeisei.personality)")

        lines.append("")

        // Daily Star
        lines.append("本日の日命星：\(dailyStar.japaneseName)")
        lines.append("  ・五行：\(dailyStar.element)")
        lines.append("  ・方位：\(dailyStar.direction)")

        lines.append("")

        // Element relationships
        let honmeiseiDailyRelation = elementRelationship(
            star1Element: nineStarProfile.honmeisei.element,
            star2Element: dailyStar.element
        )
        lines.append("本命星と日命星の関係：\(honmeiseiDailyRelation)")

        lines.append("")
        lines.append("上記の九星気学データを踏まえて、\(category.japaneseName)について鑑定してください。")
        lines.append("本命星と月命星の組み合わせ（\(nineStarProfile.japaneseSummary)）が示す本質と、")
        lines.append("本日の日命星（\(dailyStar.japaneseName)）との関係を解釈に織り込んでください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Fallback when no birthday is available.
    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let dailyStar = NineStarKiCalculator.dailyStar()

        var lines: [String] = []
        lines.append("【九星気学データ】")
        lines.append("・誕生日情報が未設定です。")
        lines.append("")
        lines.append("本日の日命星：\(dailyStar.japaneseName)")
        lines.append("  ・五行：\(dailyStar.element)")
        lines.append("  ・方位：\(dailyStar.direction)")
        lines.append("")
        lines.append("誕生日が未設定のため、本日の日命星のエネルギーを中心に、")
        lines.append("\(category.japaneseName)について鑑定してください。")
        return lines.joined(separator: "\n")
    }

    /// Describe the Five Element (五行) relationship between two stars.
    private static func elementRelationship(star1Element: String, star2Element: String) -> String {
        if star1Element == star2Element {
            return "比和（同じ五行）― 安定した気の流れがあります"
        }

        // Five Element cycle: 木 -> 火 -> 土 -> 金 -> 水 -> 木 (generating/相生)
        let generatingPairs: Set<String> = [
            "木火", "火土", "土金", "金水", "水木"
        ]
        // Controlling cycle: 木 -> 土 -> 水 -> 火 -> 金 -> 木 (overcoming/相剋)
        let controllingPairs: Set<String> = [
            "木土", "土水", "水火", "火金", "金木"
        ]

        let pair = star1Element + star2Element
        let reversePair = star2Element + star1Element

        if generatingPairs.contains(pair) {
            return "相生（\(star1Element)が\(star2Element)を生む）― 良い気の流れに乗れる日です"
        } else if generatingPairs.contains(reversePair) {
            return "相生（\(star2Element)が\(star1Element)を生む）― 周囲からの支援が期待できる日です"
        } else if controllingPairs.contains(pair) {
            return "相剋（\(star1Element)が\(star2Element)を剋す）― 主導的に動くと良い日です"
        } else if controllingPairs.contains(reversePair) {
            return "相剋（\(star2Element)が\(star1Element)を剋す）― 慎重に行動すると良い日です"
        }

        return "独立した関係 ― 自分のペースを大切にすると良い日です"
    }
}
