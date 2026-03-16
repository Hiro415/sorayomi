import Foundation

// MARK: - PromptTemplateEngine

/// ユーザープロンプトを構築する中央エンジン
/// Dispatches to the appropriate system-specific prompt builder and assembles
/// the complete user prompt with seasonal context, category, and user question.
///
/// Usage:
///   let userPrompt = PromptTemplateEngine.buildUserPrompt(
///       system: .horoscope,
///       profile: userProfile,
///       category: .love,
///       depth: .standard,
///       userQuestion: "最近気になる人がいます"
///   )
///
/// The resulting prompt is sent alongside the system prompt built by
/// `SystemPromptBuilder.build(system:depth:)`.
struct PromptTemplateEngine {

    // MARK: - Public API

    /// Build the complete user prompt for a fortune reading.
    /// - Parameters:
    ///   - system: The fortune-telling system to use.
    ///   - profile: The user's profile (may be nil for guest users).
    ///   - category: The reading category (love, career, etc.).
    ///   - depth: The reading depth (snapshot, standard, deep).
    ///   - userQuestion: An optional free-text question from the user.
    /// - Returns: A formatted Japanese user prompt string.
    static func buildUserPrompt(
        system: FortuneSystem,
        profile: UserProfile?,
        category: ReadingCategory,
        depth: ReadingDepth = .standard,
        userQuestion: String? = nil,
        preDrawnTarotCards: [DrawnTarotCard]? = nil,
        bloodTypeMode: BloodTypeMode? = nil,
        partnerBloodType: BloodType? = nil
    ) -> String {
        let seasonal = SeasonalContext.from(date: Date())

        var sections: [String] = []

        // Seasonal context
        sections.append("【季節の文脈】\(seasonal.season)（\(seasonal.solarTerm)）- \(seasonal.seasonalImagery)")

        // Reading category
        sections.append("【相談カテゴリ】\(category.japaneseName)")

        // User question (if provided)
        if let question = userQuestion, !question.isEmpty {
            sections.append("【相談内容】\(question)")
        }

        // System-specific context (calculated data for the AI to interpret)
        let systemContext: String
        switch system {
        case .generalConsultation:
            let seasonal = SeasonalContext.from(date: Date())
            systemContext = """
            【総合相談の文脈】
            相談者はテーマを絞らず、占い師に直接相談するように自由に話しかけています。
            季節：\(seasonal.season)（\(seasonal.solarTerm)）
            相談者のお話をよく聞き、最も適した視点から見立ててください。
            """
        case .omikuji:
            systemContext = OmikujiPrompt.build(profile: profile, category: category)
        case .horoscope:
            systemContext = HoroscopePrompt.build(profile: profile, category: category)
        case .bloodType:
            systemContext = BloodTypePrompt.build(profile: profile, category: category, mode: bloodTypeMode, partnerBloodType: partnerBloodType)
        case .birthdayPersonality:
            systemContext = BirthdayPrompt.build(profile: profile, category: category)
        case .rokuyo:
            systemContext = RokuyoPrompt.build(category: category)
        case .tarot:
            systemContext = TarotPrompt.build(category: category, depth: depth, preDrawnCards: preDrawnTarotCards)
        case .numerology:
            systemContext = NumerologyPrompt.build(profile: profile, category: category)
        case .nineStarKi:
            systemContext = NineStarKiPrompt.build(profile: profile, category: category)
        }

        sections.append(systemContext)

        return sections.joined(separator: "\n\n")
    }
}
