import Foundation

// MARK: - NineStarKiPrompt

/// 九星気学用の本格AIプロンプト構築
/// Builds a comprehensive Nine Star Ki context block integrating
/// honmeisei, getsumeisei, daily/monthly/yearly stars, five element relationships,
/// ki-grid palace positions, auspicious directions, and daily energy profiles.
struct NineStarKiPrompt {

    // MARK: - Public API

    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let nsk = NineStarKiCalculator.calculate(from: birthday)
        let energy = NineStarKiCalculator.dailyEnergy(profile: nsk)

        // Calculate grid positions
        let honmeiseiPosition = NineStarKiCalculator.gridPosition(
            of: nsk.honmeisei, centralStar: energy.yearlyStar
        )
        let honmeiseiPalace = NineStarKiCalculator.directionForPosition(honmeiseiPosition)
        let palaceInfluence = NineStarKiCalculator.palaceInfluence(position: honmeiseiPosition)

        var lines: [String] = []

        // 基本情報
        lines.append("【九星気学データ】")
        lines.append("")

        // 本命星
        lines.append("■ 本命星：\(nsk.honmeisei.japaneseName)")
        lines.append("  ・五行：\(nsk.honmeisei.element)（\(nsk.honmeisei.elementDescription)）")
        lines.append("  ・定位方位：\(nsk.honmeisei.direction)")
        lines.append("  ・象意の色：\(nsk.honmeisei.color)")
        lines.append("  ・性格：\(nsk.honmeisei.detailedPersonality)")
        lines.append("  ・恋愛傾向：\(nsk.honmeisei.loveTendency)")
        lines.append("  ・仕事傾向：\(nsk.honmeisei.workTendency)")

        // 月命星
        lines.append("")
        lines.append("■ 月命星：\(nsk.getsumeisei.japaneseName)")
        lines.append("  ・五行：\(nsk.getsumeisei.element)")
        lines.append("  ・方位：\(nsk.getsumeisei.direction)")
        lines.append("  ・性格（内面）：\(nsk.getsumeisei.personality)")

        // 本命星×月命星の組み合わせ
        let innerRelation = NineStarKiCalculator.elementRelation(from: nsk.honmeisei, to: nsk.getsumeisei)
        lines.append("")
        lines.append("■ 本命星×月命星の関係")
        lines.append("  ・\(innerRelation.rawValue)（\(nsk.honmeisei.element)と\(nsk.getsumeisei.element)）")
        lines.append("  ・意味：外面（\(nsk.honmeisei.shortName)）と内面（\(nsk.getsumeisei.shortName)）の関係が\(innerRelation.rawValue)。\(innerPersonalityDescription(innerRelation))")

        // 今日の星の配置
        lines.append("")
        lines.append("【今日の星の配置】")
        lines.append("・年命星：\(energy.yearlyStar.japaneseName)（\(energy.yearlyStar.element)）")
        lines.append("・月命星（今月）：\(energy.monthlyStar.japaneseName)（\(energy.monthlyStar.element)）")
        lines.append("・日命星（今日）：\(energy.dailyStar.japaneseName)（\(energy.dailyStar.element)）")
        lines.append("")
        lines.append("・本命星と日命星の関係：\(energy.honmeiseiRelation.rawValue)")
        lines.append("  → \(energy.honmeiseiRelation.description)")
        lines.append("・今日の運勢スコア：\(starRating(energy.overallScore))")

        // 九宮格の配置
        lines.append("")
        lines.append("【九宮格（年盤）の配置】")
        lines.append("・あなたの本命星（\(nsk.honmeisei.shortName)）は現在「\(honmeiseiPalace)」に在泊")
        lines.append("  → \(palaceInfluence)")

        // 方位
        lines.append("")
        lines.append("【方位の吉凶】")
        lines.append("・吉方位：\(energy.auspiciousDirections.joined(separator: "・"))")
        lines.append("・凶方位：\(energy.inauspiciousDirections.joined(separator: "・"))")

        // 相性の良い星
        lines.append("")
        lines.append("【相性の良い星】")
        let goodStars = nsk.honmeisei.generatedByStars
        for star in goodStars.prefix(3) {
            lines.append("・\(star.japaneseName)（\(star.element)）→ あなたを育む相生の関係")
        }

        // 今日のアドバイス
        lines.append("")
        lines.append("・今日のアドバイス：\(energy.advice)")

        // 鑑定指示
        lines.append("")
        lines.append("【鑑定モード】九星気学")
        lines.append("→ \(category.japaneseName)について、\(nsk.honmeisei.japaneseName)の本質と\(nsk.getsumeisei.japaneseName)の内面性を中心に鑑定してください。")
        lines.append("→ 今日の日命星\(energy.dailyStar.japaneseName)との五行関係（\(energy.honmeiseiRelation.rawValue)）が示すエネルギーの流れを具体的に。")
        lines.append("→ 九宮格で本命星が「\(honmeiseiPalace)」に在泊していることの意味を鑑定に織り込んでください。")
        lines.append("→ 吉方位（\(energy.auspiciousDirections.prefix(2).joined(separator: "・"))）を活用した具体的な開運アクションを提案してください。")
        lines.append("→ 九星気学の専門家として、五行の流れと方位の知恵を織り交ぜた本格的な鑑定を。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private static func starRating(_ score: Int) -> String {
        String(repeating: "★", count: score) + String(repeating: "☆", count: max(0, 5 - score))
    }

    private static func innerPersonalityDescription(_ relation: FiveElementRelation) -> String {
        switch relation {
        case .same:
            return "表と裏が一致しており、自然体でいられる。人に安心感を与えるタイプ"
        case .generating:
            return "外面が内面を活かす形。社会性と本来の自分が調和し、成果を出しやすい"
        case .generated:
            return "内面が外面を支える形。見えないところで力が湧き、底力がある人"
        case .controlling:
            return "外面が内面を抑える形。社会的な顔と本音にギャップがあり、ストレスを溜めやすい面も"
        case .controlled:
            return "内面が外面を制する形。本当の自分を出しにくいが、深い内面を理解してくれる人との縁で開花"
        }
    }

    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let daily = NineStarKiCalculator.dailyStar()
        let monthly = NineStarKiCalculator.monthlyStar()
        let yearly = NineStarKiCalculator.yearStar()

        var lines: [String] = []
        lines.append("【九星気学データ】")
        lines.append("・誕生日情報が未設定です。")
        lines.append("")
        lines.append("・年命星：\(yearly.japaneseName)（\(yearly.element)）")
        lines.append("・月命星：\(monthly.japaneseName)（\(monthly.element)）")
        lines.append("・日命星：\(daily.japaneseName)（\(daily.element)）")
        lines.append("")
        lines.append("誕生日が未設定のため、今日の日命星\(daily.japaneseName)と")
        lines.append("今月の月命星\(monthly.japaneseName)のエネルギーを中心に、")
        lines.append("\(category.japaneseName)について鑑定してください。")
        return lines.joined(separator: "\n")
    }
}
