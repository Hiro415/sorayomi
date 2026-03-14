import Foundation

// MARK: - HoroscopePrompt

/// 星座占い用のユーザープロンプトを構築する
/// Builds the horoscope-specific section of the user prompt, including
/// the user's zodiac sign, element, modality, and personality keywords.
struct HoroscopePrompt {

    // MARK: - Public API

    /// Build the horoscope context block for the user prompt.
    /// - Parameters:
    ///   - profile: The user's profile containing birthday for zodiac calculation.
    ///   - category: The reading category to tailor the prompt.
    /// - Returns: A formatted Japanese horoscope context string.
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let sign = ZodiacCalculator.calculate(from: birthday)
        let currentSeason = ZodiacCalculator.currentSeason()

        var lines: [String] = []

        lines.append("【星座占いデータ】")
        lines.append("・星座：\(sign.japaneseName)（\(sign.dateRange)）")
        lines.append("・エレメント：\(sign.element.japaneseName)の星座")
        lines.append("・モダリティ：\(sign.modality.japaneseName)")
        lines.append("・性格キーワード：\(sign.personalityKeywords.joined(separator: "・"))")
        lines.append("・現在の太陽星座：\(currentSeason.japaneseName)")

        // Element relationship with current zodiac season
        let elementRelation = elementRelationship(userElement: sign.element, seasonElement: currentSeason.element)
        lines.append("・エレメント相性：\(elementRelation)")

        lines.append("")
        lines.append("上記の星座情報を踏まえて、\(category.japaneseName)について鑑定してください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Fallback when no birthday is available.
    private static func fallbackPrompt(category: ReadingCategory) -> String {
        var lines: [String] = []
        lines.append("【星座占いデータ】")
        lines.append("・星座情報が未設定です。")
        lines.append("")
        lines.append("星座が未設定のため、現在の太陽星座（\(ZodiacCalculator.currentSeason().japaneseName)）の")
        lines.append("一般的な傾向を踏まえて、\(category.japaneseName)について鑑定してください。")
        return lines.joined(separator: "\n")
    }

    /// Describe the elemental relationship between the user's sign and the current season.
    private static func elementRelationship(userElement: ZodiacElement, seasonElement: ZodiacElement) -> String {
        if userElement == seasonElement {
            return "同じエレメント同士 ― エネルギーが共鳴しやすい時期です"
        }

        switch (userElement, seasonElement) {
        // Harmonious pairs (fire-air, earth-water)
        case (.fire, .air), (.air, .fire):
            return "火と風の調和 ― アイデアが広がりやすい時期です"
        case (.earth, .water), (.water, .earth):
            return "地と水の調和 ― 着実な成長が見込める時期です"
        // Challenging pairs (fire-water, earth-air)
        case (.fire, .water), (.water, .fire):
            return "火と水の緊張 ― バランスを意識すると良い時期です"
        case (.earth, .air), (.air, .earth):
            return "地と風の緊張 ― 新しい視点を取り入れると良い時期です"
        // Neutral pairs (fire-earth, air-water)
        case (.fire, .earth), (.earth, .fire):
            return "火と地の組み合わせ ― 情熱を形にできる時期です"
        case (.air, .water), (.water, .air):
            return "風と水の組み合わせ ― 感性と知性が響き合う時期です"
        default:
            return "穏やかなエネルギーの時期です"
        }
    }
}
