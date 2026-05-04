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
            systemContext = Self.buildGeneralConsultationContext(profile: profile, category: category)
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
        case .flowerFortune:
            systemContext = FlowerFortunePrompt.build(profile: profile, category: category)
        case .stoneFortune:
            systemContext = StoneFortunePrompt.build(profile: profile, category: category)
        }

        sections.append(systemContext)

        return sections.joined(separator: "\n\n")
    }

    // MARK: - General Consultation Context

    /// 総合相談用のリッチコンテキスト構築
    /// ユーザーのプロフィールから利用可能な全占術データを横断的に集め、
    /// AIが自然に活用できる形で提供する。
    private static func buildGeneralConsultationContext(
        profile: UserProfile?,
        category: ReadingCategory
    ) -> String {
        let today = Date()
        let seasonal = SeasonalContext.from(date: today)
        var lines: [String] = []

        lines.append("【総合相談の文脈】")
        lines.append("相談テーマ：\(category.japaneseName)")
        lines.append("季節：\(seasonal.season)（\(seasonal.solarTerm)）— \(seasonal.seasonalImagery)")
        lines.append("")

        // ── プロフィール横断データ ──
        if let profile = profile {
            lines.append("【相談者プロフィールから読み取れる情報】")

            // 星座
            if let birthday = profile.birthday {
                let sign = ZodiacCalculator.calculate(from: birthday)
                let horoscope = ZodiacCalculator.dailyHoroscope(for: sign)
                lines.append("━━ 星座 ━━")
                lines.append("  星座：\(sign.japaneseName)（\(sign.element.japaneseName)・\(sign.modality.japaneseName)）")
                lines.append("  守護星：\(sign.rulingPlanet)")
                lines.append("  今日の星座運勢スコア：\(horoscope.overallScore)/5")
                lines.append("  ラッキーカラー：\(horoscope.luckyColor)")
                lines.append("  ラッキーナンバー：\(horoscope.luckyNumber)")
                lines.append("")

                // 数秘術
                let numProfile = NumerologyCalculator.profile(from: birthday)
                let numEnergy = NumerologyCalculator.dailyEnergy(birthday: birthday, on: today)
                let lpArchetype = NumerologyProfile.archetype(for: numProfile.lifePathNumber)
                lines.append("━━ 数秘術 ━━")
                lines.append("  ライフパスナンバー：\(numProfile.lifePathNumber)（\(lpArchetype.title)）")
                lines.append("  パーソナルイヤー：\(numProfile.personalYearNumber)")
                lines.append("  パーソナルデイ：\(numProfile.personalDayNumber)")
                lines.append("  今日のエネルギースコア：\(numEnergy.overallScore)/5")
                lines.append("  サイクルフェーズ：\(numEnergy.cyclePhase.rawValue)")
                lines.append("  現在のピナクル：\(numEnergy.currentPinnacle.number)（\(numEnergy.currentPinnacle.description)）")
                lines.append("")

                // 九星気学
                let kiProfile = NineStarKiCalculator.calculate(from: birthday)
                let kiEnergy = NineStarKiCalculator.dailyEnergy(profile: kiProfile)
                lines.append("━━ 九星気学 ━━")
                lines.append("  本命星：\(kiProfile.honmeisei.japaneseName)（\(kiProfile.honmeisei.element)）")
                lines.append("  月命星：\(kiProfile.getsumeisei.japaneseName)")
                lines.append("  今日の星：\(kiEnergy.dailyStar.japaneseName)")
                lines.append("  本命星との関係：\(kiEnergy.honmeiseiRelation.rawValue)（\(kiEnergy.honmeiseiRelation.description)）")
                lines.append("  吉方位：\(kiEnergy.auspiciousDirections.joined(separator: "・"))")
                lines.append("  総合スコア：\(kiEnergy.overallScore)/5")
                lines.append("")
            }

            // 血液型
            if let bloodType = profile.bloodType {
                let dailyFortune = BloodTypeCompatibility.dailyFortune(for: bloodType)
                lines.append("━━ 血液型 ━━")
                lines.append("  血液型：\(bloodType.japaneseName)")
                lines.append("  今日の運勢スコア：\(dailyFortune.overall)/5")
                lines.append("  ラッキーカラー：\(dailyFortune.luckyColor)")
                lines.append("  ラッキー方位：\(dailyFortune.luckyDirection)")
                lines.append("")
            }

            // 六曜（旧暦ベースの正確な計算）
            let todayRokuyo = RokuyoCalculator.today()
            lines.append("━━ 暦 ━━")
            lines.append("  六曜：\(todayRokuyo.japaneseName)")
            lines.append("")

            lines.append("【データ活用指示】")
            lines.append("上記のデータは参考情報です。すべてを羅列する必要はありません。")
            lines.append("相談テーマに関連するデータだけを自然に織り込んでください。")
            lines.append("例：恋愛相談なら星座の相性傾向を、仕事相談なら数秘のサイクルや九星の方位を活用。")
        } else {
            // プロフィール未設定のフォールバック（旧暦ベース）
            let todayRokuyo = RokuyoCalculator.today()
            lines.append("━━ 暦 ━━")
            lines.append("  六曜：\(todayRokuyo.japaneseName)")
            lines.append("")
            lines.append("（プロフィール未設定のため、季節と暦の流れを中心に見立ててください）")
        }

        return lines.joined(separator: "\n")
    }
}
