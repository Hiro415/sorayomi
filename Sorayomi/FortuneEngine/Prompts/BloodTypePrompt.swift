import Foundation

// MARK: - BloodTypePrompt

struct BloodTypePrompt {

    // MARK: - Public API (mode-aware)

    static func build(
        profile: UserProfile?,
        category: ReadingCategory,
        mode: BloodTypeMode? = nil,
        partnerBloodType: BloodType? = nil
    ) -> String {
        guard let profile, let bloodType = profile.bloodType else {
            return fallbackPrompt(category: category)
        }

        guard let mode else {
            return legacyBuild(bloodType: bloodType, category: category)
        }

        switch mode {
        case .dailyFortune:
            return buildDailyFortune(bloodType: bloodType, category: category)
        case .compatibility:
            return buildCompatibility(bloodType: bloodType, partner: partnerBloodType, category: category)
        case .loveMatch:
            return buildLoveMatch(bloodType: bloodType, partner: partnerBloodType, category: category)
        case .ranking:
            return buildRanking(bloodType: bloodType, category: category)
        }
    }

    // MARK: - Daily Fortune

    private static func buildDailyFortune(bloodType: BloodType, category: ReadingCategory) -> String {
        let traits = BloodTypeCalculator.traits(for: bloodType)
        let fortune = BloodTypeCompatibility.dailyFortune(for: bloodType)
        let seasonal = SeasonalContext.from(date: Date())
        let season = seasonal.season

        var lines: [String] = []

        lines.append("【血液型占いデータ】")
        lines.append("・血液型：\(bloodType.japaneseName)")
        lines.append("・基本性格：\(traits.personality)")
        lines.append("・恋愛傾向：\(bloodType.loveTendency)")
        lines.append("・仕事傾向：\(bloodType.workTendency)")
        lines.append("・金銭感覚：\(bloodType.moneySense)")
        lines.append("・健康傾向：\(bloodType.healthTendency)")

        lines.append("")
        lines.append("【今日のバイオリズム】")
        lines.append("・総合運：\(starString(fortune.overall))（\(fortune.overall)/5）")
        lines.append("・恋愛運：\(starString(fortune.love))（\(fortune.love)/5）")
        lines.append("・仕事運：\(starString(fortune.work))（\(fortune.work)/5）")
        lines.append("・金運：\(starString(fortune.money))（\(fortune.money)/5）")

        lines.append("")
        lines.append("【今日の暦データ】")
        lines.append("・六曜：\(fortune.rokuyo.japaneseName)")
        lines.append("・九星日命星：\(fortune.dailyStar.japaneseName)（\(fortune.dailyStar.element)）")
        lines.append("・二十四節気：\(fortune.solarTerm)")
        lines.append("・数秘ユニバーサルデイ：\(fortune.universalDay)")
        lines.append("・ラッキーカラー：\(fortune.luckyColor)")
        lines.append("・ラッキー方位：\(fortune.luckyDirection)")

        lines.append("")
        lines.append("【季節の傾向】\(bloodType.seasonalTendency(for: season))")

        lines.append("")
        lines.append("【鑑定モード】今日の運勢")
        lines.append("→ バイオリズムの数値を根拠にしつつ、ユーザーの相談内容に寄り添った具体的アドバイスを。")
        lines.append("→ 今日一日の過ごし方のタイムライン（午前・午後・夜）を提案してください。")
        lines.append("→ 六曜・九星・節気のデータは「裏付け」として自然に織り込んでください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Compatibility

    private static func buildCompatibility(bloodType: BloodType, partner: BloodType?, category: ReadingCategory) -> String {
        guard let partner else {
            return legacyBuild(bloodType: bloodType, category: category)
        }

        let compat = BloodTypeCompatibility.compatibility(between: bloodType, and: partner)
        let traits1 = BloodTypeCalculator.traits(for: bloodType)
        let traits2 = BloodTypeCalculator.traits(for: partner)

        var lines: [String] = []

        lines.append("【血液型占いデータ】")
        lines.append("・あなた：\(bloodType.japaneseName)（\(traits1.personality)）")
        lines.append("・お相手：\(partner.japaneseName)（\(traits2.personality)）")

        lines.append("")
        lines.append("【相性データ】")
        lines.append("・総合相性：\(starString(compat.score))（\(compat.score)/5）")
        lines.append("・関係の特徴：\(compat.description)")

        lines.append("")
        lines.append("【\(bloodType.japaneseName)から見た\(partner.japaneseName)】")
        lines.append("・恋愛面：\(bloodType.loveTendency)")
        lines.append("・仕事面：\(bloodType.workTendency)")

        lines.append("")
        lines.append("【\(partner.japaneseName)から見た\(bloodType.japaneseName)】")
        lines.append("・恋愛面：\(partner.loveTendency)")
        lines.append("・仕事面：\(partner.workTendency)")

        lines.append("")
        lines.append("【鑑定モード】相性診断")
        lines.append("→ 相性スコアに基づきつつ、ユーザーの具体的な状況を踏まえた実践的アドバイスを。")
        lines.append("→ 両者の型の違いを「対立」ではなく「化学反応」として描いてください。")
        lines.append("→ 関係をより良くするための3つの具体的なアクションを提案してください。")
        lines.append("→ 相性が低い場合も否定せず、関係を良くするための道筋を示してください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Love Match

    private static func buildLoveMatch(bloodType: BloodType, partner: BloodType?, category: ReadingCategory) -> String {
        guard let partner else {
            return legacyBuild(bloodType: bloodType, category: category)
        }

        let compat = BloodTypeCompatibility.compatibility(between: bloodType, and: partner)
        let love = BloodTypeCompatibility.loveSubScores(between: bloodType, and: partner)

        var lines: [String] = []

        lines.append("【血液型占いデータ】")
        lines.append("・あなた：\(bloodType.japaneseName)（恋愛傾向：\(bloodType.loveTendency)）")
        lines.append("・お相手：\(partner.japaneseName)（恋愛傾向：\(partner.loveTendency)）")

        lines.append("")
        lines.append("【恋愛相性の詳細】")
        lines.append("・恋愛総合：\(starString(love.overall))（\(love.overall)/5）")
        lines.append("・コミュニケーション：\(starString(love.communication))（\(love.communication)/5）")
        lines.append("・価値観の一致：\(starString(love.values))（\(love.values)/5）")
        lines.append("・情熱度：\(starString(love.passion))（\(love.passion)/5）")
        lines.append("・長期安定度：\(starString(love.stability))（\(love.stability)/5）")

        lines.append("")
        lines.append("・恋愛の特徴：\(compat.loveDescription)")

        lines.append("")
        lines.append("【鑑定モード】恋愛相性")
        lines.append("→ 4つのサブスコアに順に触れながら、物語のように恋の行方を語ってください。")
        lines.append("→ 片思い・交際中・結婚などの状況に応じた具体的な行動指針を含めてください。")
        lines.append("→ 相談者が次にとるべき一歩を明確にしてください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Ranking

    private static func buildRanking(bloodType: BloodType, category: ReadingCategory) -> String {
        let ranking = BloodTypeCompatibility.dailyRanking()
        let userEntry = ranking.entries.first { $0.bloodType == bloodType }
        let userRank = userEntry?.rank ?? 0

        var lines: [String] = []

        lines.append("【血液型占いデータ】")
        lines.append("・あなた：\(bloodType.japaneseName)")

        lines.append("")
        lines.append("【今日の血液型ランキング】")
        for entry in ranking.entries {
            let marker = entry.bloodType == bloodType ? " ← あなた" : ""
            lines.append("・\(entry.rank)位：\(entry.bloodType.japaneseName) \(starString(entry.score)) — \(entry.oneLiner)\(marker)")
        }

        lines.append("")
        lines.append("・あなたの順位：\(userRank)位")

        lines.append("")
        lines.append("【鑑定モード】ランキング")
        lines.append("→ ランキング結果を踏まえ、ユーザーの型が今日どう過ごすべきかを中心に鑑定してください。")
        lines.append("→ 順位が低くても前向きな助言を。1位の型の良い影響を受ける方法にも言及してください。")
        lines.append("→ エンタメ感を保ちつつも、占い師としての深みある助言を提供してください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func starString(_ score: Int) -> String {
        String(repeating: "★", count: score) + String(repeating: "☆", count: max(0, 5 - score))
    }

    private static func legacyBuild(bloodType: BloodType, category: ReadingCategory) -> String {
        let traits = BloodTypeCalculator.traits(for: bloodType)
        var lines: [String] = []
        lines.append("【血液型占いデータ】")
        lines.append("・血液型：\(bloodType.japaneseName)")
        lines.append("・基本性格：\(traits.personality)")
        lines.append("・強み：\(traits.strengths)")
        lines.append("・注意点：\(traits.weaknesses)")
        let compatNames = traits.compatibility.map { $0.japaneseName }
        lines.append("・相性の良い血液型：\(compatNames.joined(separator: "・"))")
        let todayRokuyo = RokuyoCalculator.calculate(from: Date())
        lines.append("")
        lines.append("・今日の暦：\(todayRokuyo.japaneseName)（参考情報）")
        lines.append("")
        lines.append("上記の血液型データを踏まえて、\(category.japaneseName)について鑑定してください。")
        lines.append("\(bloodType.japaneseName)の方の傾向として、今日特に意識すると良い点を")
        lines.append("具体的にお伝えください。")
        return lines.joined(separator: "\n")
    }

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
