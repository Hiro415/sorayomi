import Foundation

// MARK: - NumerologyPrompt

/// 数秘術用のユーザープロンプトを構築する
/// Builds a rich numerology context including Life Path archetype,
/// Personal/Universal cycle interaction, Pinnacle/Challenge stage,
/// number harmony, cycle phase, and lucky timing data.
struct NumerologyPrompt {

    // MARK: - Public API

    /// Build the numerology context block for the user prompt.
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let today = Date()
        let numProfile = NumerologyCalculator.profile(from: birthday, currentDate: today)
        let energy = NumerologyCalculator.dailyEnergy(birthday: birthday, on: today)
        let archetype = NumerologyProfile.archetype(for: numProfile.lifePathNumber)
        let yearTheme = NumerologyProfile.personalYearTheme(for: numProfile.personalYearNumber)
        let pinnacles = NumerologyCalculator.pinnacles(from: birthday)
        let pinIdx = NumerologyCalculator.currentPinnacleIndex(birthday: birthday, currentDate: today)
        let challenges = NumerologyCalculator.challenges(from: birthday)

        var lines: [String] = []

        // ── ライフパスナンバー（本質） ──
        lines.append("【数秘術データ】")
        lines.append("")
        lines.append("■ ライフパスナンバー：\(formatNumber(numProfile.lifePathNumber))「\(archetype.title)」")
        lines.append("  元素：\(archetype.element.rawValue) ／ 極性：\(archetype.polarity.rawValue) ／ 支配星：\(archetype.ruling)")
        lines.append("  性格：\(archetype.personality)")
        lines.append("  恋愛傾向：\(archetype.loveTendency)")
        lines.append("  仕事傾向：\(archetype.workTendency)")
        lines.append("  健康注意：\(archetype.healthAdvice)")
        lines.append("  影の側面：\(archetype.shadowSide)")
        lines.append("  相性の良い数字：\(archetype.compatibleNumbers.map(String.init).joined(separator: ", "))")
        lines.append("  パワーストーン：\(archetype.gemstone)")

        lines.append("")

        // ── バースデーナンバー ──
        let bdArch = NumerologyProfile.archetype(for: numProfile.birthdayNumber)
        lines.append("■ バースデーナンバー：\(formatNumber(numProfile.birthdayNumber))「\(bdArch.title)」")
        lines.append("  隠れた才能：\(bdArch.keyword)")

        lines.append("")

        // ── パーソナルサイクル（今の時期） ──
        lines.append("■ パーソナルサイクル")
        lines.append("  パーソナルイヤー：\(formatNumber(energy.personalYear))「\(yearTheme.theme)」")
        lines.append("    テーマ：\(yearTheme.keyword) ／ 季節：\(yearTheme.season)")
        lines.append("    概要：\(yearTheme.overview)")

        // Category-specific year advice
        switch category {
        case .love, .relationships:
            lines.append("    恋愛：\(yearTheme.loveAdvice)")
        case .career, .wealth:
            lines.append("    仕事：\(yearTheme.workAdvice)")
        default:
            lines.append("    恋愛：\(yearTheme.loveAdvice)")
            lines.append("    仕事：\(yearTheme.workAdvice)")
        }

        lines.append("  パーソナルマンス：\(formatNumber(energy.personalMonth))")
        lines.append("  パーソナルデイ：\(formatNumber(energy.personalDay))")
        lines.append("    今日のガイダンス：\(numProfile.personalDayDescription)")

        lines.append("")

        // ── ユニバーサルサイクル（宇宙のリズム） ──
        lines.append("■ ユニバーサルサイクル（今日の宇宙のリズム）")
        lines.append("  ユニバーサルイヤー：\(formatNumber(energy.universalYear))")
        lines.append("  ユニバーサルマンス：\(formatNumber(energy.universalMonth))")
        lines.append("  ユニバーサルデイ：\(formatNumber(energy.universalDay))")

        lines.append("")

        // ── 数字のハーモニー ──
        lines.append("■ 今日の数字のハーモニー")
        lines.append("  パーソナル×ユニバーサル：\(energy.personalUniversalHarmony.rawValue)（\(energy.personalUniversalHarmony.description)）")
        lines.append("  ライフパス×パーソナルデイ：\(energy.lifePathDayHarmony.rawValue)（\(energy.lifePathDayHarmony.description)）")
        lines.append("  総合エネルギースコア：\(energy.overallScore)/5")
        lines.append("  サイクル位相：\(energy.cyclePhase.rawValue)（\(energy.cyclePhase.description)）")

        lines.append("")

        // ── 転換期と課題 ──
        lines.append("■ 人生の転換期（ピナクル）")
        for (i, pin) in pinnacles.enumerated() {
            let marker = (i == pinIdx) ? "★現在" : "　"
            lines.append("  \(marker) \(pin.name)（\(pin.ageRange)）：\(formatNumber(pin.number)) — \(pin.description)")
        }

        lines.append("")
        lines.append("■ 人生の課題（チャレンジ）")
        for chal in challenges {
            lines.append("  \(chal.name)（\(chal.ageRange)）：\(formatNumber(chal.number)) — \(chal.description)")
        }

        lines.append("")

        // ── ラッキータイミング ──
        lines.append("■ 今日のラッキータイム：\(energy.luckyHours.joined(separator: "、"))")
        lines.append("■ ラッキーナンバー：\(archetype.luckyDays.map(String.init).joined(separator: "、"))")

        lines.append("")

        // ── AI指示 ──
        lines.append("【鑑定指示】")
        lines.append("① ライフパスナンバー\(numProfile.lifePathNumber)「\(archetype.title)」の本質を軸に、相談者の性格と使命を読み解いてください")
        lines.append("② パーソナルデイ\(energy.personalDay)×ユニバーサルデイ\(energy.universalDay)の\(energy.personalUniversalHarmony.rawValue)の関係を、今日の具体的な過ごし方のアドバイスに反映してください")
        lines.append("③ パーソナルイヤー\(energy.personalYear)「\(yearTheme.theme)」の9年サイクルの中で、今の相談がどのような意味を持つかを示してください")
        lines.append("④ 現在の転換期（\(pinnacles[pinIdx].name)）と課題の文脈で、相談者が直面している状況を解釈してください")
        lines.append("⑤ 数字の持つ象徴性（\(archetype.element.rawValue)の元素、\(archetype.polarity.rawValue)の極性、\(archetype.ruling)の影響）を鑑定に織り込んでください")
        lines.append("⑥ \(category.japaneseName)の観点から、今日のラッキータイム（\(energy.luckyHours.joined(separator: "、"))）を活用した具体的な行動提案を含めてください")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let today = Date()
        let ud = NumerologyCalculator.universalDayNumber(for: today)
        let um = NumerologyCalculator.universalMonthNumber(for: today)
        let uy = NumerologyCalculator.universalYearNumber(for: today)
        let udArch = NumerologyProfile.archetype(for: ud)

        var lines: [String] = []
        lines.append("【数秘術データ】")
        lines.append("・誕生日情報が未設定のため、ユニバーサルサイクルを中心に鑑定します。")
        lines.append("")
        lines.append("■ ユニバーサルデイ：\(formatNumber(ud))「\(udArch.title)」")
        lines.append("  今日の宇宙のテーマ：\(udArch.keyword)")
        lines.append("■ ユニバーサルマンス：\(formatNumber(um))")
        lines.append("■ ユニバーサルイヤー：\(formatNumber(uy))")
        lines.append("")
        lines.append("本日の数字が持つエネルギーを中心に、\(category.japaneseName)について鑑定してください。")
        lines.append("ユニバーサルデイ\(ud)の「\(udArch.keyword)」のテーマを日常の行動提案に反映してください。")
        return lines.joined(separator: "\n")
    }

    private static func formatNumber(_ number: Int) -> String {
        if NumerologyCalculator.isMasterNumber(number) {
            return "\(number)（マスターナンバー）"
        }
        return "\(number)"
    }
}
