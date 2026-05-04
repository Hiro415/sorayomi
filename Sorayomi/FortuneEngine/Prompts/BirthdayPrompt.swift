import Foundation

// MARK: - BirthdayPrompt

/// 誕生日占い用のユーザープロンプトを構築する
/// Builds the birthday personality specific section of the user prompt,
/// integrating day archetypes, month guardians, personal numerology cycles,
/// birth stone/flower, and today's birthday energy.
struct BirthdayPrompt {

    // MARK: - Public API

    /// Build the birthday personality context block for the user prompt.
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let bp = BirthdayPersonalityCalculator.profile(from: birthday)
        let todayEnergy = BirthdayPersonalityCalculator.todaysEnergy(birthday: birthday)
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)

        var lines: [String] = []

        // 基本プロフィール
        lines.append("【誕生日占いデータ】")
        lines.append("・誕生日：\(month)月\(day)日")
        lines.append("・日の原型：「\(bp.dayArchetype.title)」（\(day)日生まれ）")
        lines.append("・月の守護：「\(bp.monthGuardian.guardianName)」（\(month)月・\(bp.monthGuardian.element)のエネルギー）")
        lines.append("・季節の元素：\(bp.seasonalElement.season)・\(bp.seasonalElement.element)（\(bp.seasonalElement.yinYang)）")

        // 性格の詳細
        lines.append("")
        lines.append("【性格の核心】")
        lines.append("・基本性格：\(bp.personality)")
        lines.append("・恋愛傾向：\(bp.dayArchetype.loveTendency)")
        lines.append("・仕事スタイル：\(bp.dayArchetype.workStyle)")
        lines.append("・隠された才能：\(bp.dayArchetype.hiddenPotential)")
        lines.append("・成長の課題：\(bp.challenge)")

        // 守護シンボル
        lines.append("")
        lines.append("【守護シンボル】")
        lines.append("・誕生石：\(bp.birthStone)")
        lines.append("・誕生花：\(bp.birthFlower)")
        lines.append("・ラッキーカラー：\(bp.luckyColor)")
        lines.append("・ラッキーナンバー：\(bp.luckyNumber)")

        // 月の守護エネルギー
        lines.append("")
        lines.append("【\(month)月生まれの守護エネルギー】")
        lines.append("・キーワード：\(bp.monthGuardian.keyword)")
        lines.append("・\(bp.monthGuardian.monthEnergy)")

        // 相性
        lines.append("")
        lines.append("【日の相性】")
        lines.append("・相性の良い日：\(bp.compatibleDays.map { "\($0)日" }.joined(separator: "・"))生まれの方")
        lines.append("・刺激的な相手：\(bp.challengingDays.map { "\($0)日" }.joined(separator: "・"))生まれの方")

        // 数秘術連携：今日のパーソナルサイクル
        lines.append("")
        lines.append("【今日のパーソナルサイクル（数秘術）】")
        lines.append("・パーソナルイヤー：\(todayEnergy.personalYear)（\(todayEnergy.yearTheme)）")
        lines.append("・パーソナルマンス：\(todayEnergy.personalMonth)（\(todayEnergy.monthTheme)）")
        lines.append("・パーソナルデイ：\(todayEnergy.personalDay)（\(todayEnergy.dayTheme)）")
        lines.append("")
        lines.append("・今日の総合エネルギー：\(todayEnergy.overallEnergy)")
        lines.append("・行動アドバイス：\(todayEnergy.actionAdvice)")

        // 鑑定指示
        lines.append("")
        lines.append("【鑑定モード】誕生日占い")
        lines.append("→ \(category.japaneseName)について、\(month)月\(day)日生まれの「\(bp.dayArchetype.title)」の特質を中心に鑑定してください。")
        lines.append("→ 月の守護「\(bp.monthGuardian.guardianName)」の\(bp.monthGuardian.element)のエネルギーを織り込んでください。")
        lines.append("→ 今日のパーソナルデイ「\(todayEnergy.personalDay)」が示す流れと、誕生日の資質がどう共鳴するかを具体的に。")
        lines.append("→ 誕生石（\(bp.birthStone)）や誕生花（\(bp.birthFlower)）を象徴的に鑑定に織り込んでください。")
        lines.append("→ 成長の課題（\(bp.challenge)）にも優しく触れ、前向きな指針を示してください。")
        lines.append("→ パーソナルイヤーの大きな流れの中で「今日」がどういう位置づけかを説明してください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Fallback when no birthday is available.
    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let today = Date()
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)

        let todayProfile = BirthdayPersonalityCalculator.profile(from: today)

        var lines: [String] = []
        lines.append("【誕生日占いデータ】")
        lines.append("・誕生日情報が未設定です。")
        lines.append("")
        lines.append("誕生日が未設定のため、本日（\(month)月\(day)日）が持つエネルギーを中心に鑑定します。")
        lines.append("・今日の日の原型：「\(todayProfile.dayArchetype.title)」")
        lines.append("・今日の守護：「\(todayProfile.monthGuardian.guardianName)」")
        lines.append("")
        lines.append("\(category.japaneseName)について、本日のエネルギーから鑑定してください。")
        return lines.joined(separator: "\n")
    }
}
