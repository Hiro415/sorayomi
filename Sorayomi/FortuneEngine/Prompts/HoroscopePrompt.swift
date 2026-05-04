import Foundation

// MARK: - HoroscopePrompt

/// 星座占い用の本格AIプロンプト構築
/// Builds a comprehensive horoscope context block integrating zodiac sign,
/// decan, ruling planet, element harmony, planetary day influence,
/// daily scores, compatibility, and actionable advice.
struct HoroscopePrompt {

    // MARK: - Public API

    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let sign = ZodiacCalculator.calculate(from: birthday)
        let decan = ZodiacCalculator.decan(from: birthday)
        let currentSeason = ZodiacCalculator.currentSeason()
        let horoscope = ZodiacCalculator.dailyHoroscope(for: sign)
        let decanDesc = ZodiacCalculator.decanDescription(sign: sign, decan: decan)
        let subRuler = ZodiacCalculator.decanSubRuler(sign: sign, decan: decan)

        var lines: [String] = []

        // 基本星座データ
        lines.append("【星座占いデータ】")
        lines.append("・星座：\(sign.japaneseName)（\(sign.emoji)）\(sign.dateRange)")
        lines.append("・エレメント：\(sign.element.japaneseName)（\(sign.element.description)）")
        lines.append("・モダリティ：\(sign.modality.japaneseName)（\(sign.modality.description)）")
        lines.append("・支配星：\(sign.rulingPlanet.japaneseName)（\(sign.rulingPlanet.influence)）")
        lines.append("・デーカン：\(decan.japaneseName)（副支配星：\(subRuler.japaneseName)）")
        lines.append("・性格キーワード：\(sign.personalityKeywords.joined(separator: "・"))")

        // 詳細性格
        lines.append("")
        lines.append("【性格の深層】")
        lines.append("・\(sign.personalityDescription)")
        lines.append("・デーカンの影響：\(decanDesc)")
        lines.append("・恋愛傾向：\(sign.loveTendency)")

        // 今日のホロスコープ
        lines.append("")
        lines.append("【今日のホロスコープ】")
        lines.append("・現在の太陽星座：\(currentSeason.japaneseName)シーズン")
        lines.append("・\(horoscope.planetaryInfluence)")
        lines.append("・\(horoscope.elementHarmony)")
        lines.append("")
        lines.append("・総合運：\(starRating(horoscope.overallScore))")
        lines.append("・恋愛運：\(starRating(horoscope.loveScore))")
        lines.append("・仕事運：\(starRating(horoscope.workScore))")
        lines.append("・金運：\(starRating(horoscope.moneyScore))")
        lines.append("・健康運：\(starRating(horoscope.healthScore))")

        // ラッキー情報
        lines.append("")
        lines.append("【開運情報】")
        lines.append("・ラッキーカラー：\(horoscope.luckyColor)")
        lines.append("・ラッキーナンバー：\(horoscope.luckyNumber)")
        lines.append("・吉方位：\(horoscope.luckyDirection)")
        lines.append("・パワーストーン：\(sign.powerStone)")
        lines.append("・ラッキーデー：\(sign.luckyDay)")

        // 相性情報（相性の良い星座）
        lines.append("")
        lines.append("【相性の良い星座】")
        let bestSigns = sign.bestCompatible.prefix(3)
        for compatSign in bestSigns {
            let compat = ZodiacCalculator.compatibility(between: sign, and: compatSign)
            lines.append("・\(compatSign.japaneseName)（\(starRating(compat.overallScore))）：\(compat.description)")
        }

        // 今日のアドバイス
        lines.append("")
        lines.append("・今日のアドバイス：\(horoscope.advice)")

        // 鑑定指示
        lines.append("")
        lines.append("【鑑定モード】星座占い")
        lines.append("→ \(category.japaneseName)について、\(sign.japaneseName)（\(sign.element.japaneseName)のエレメント・\(sign.modality.japaneseName)）の特質を中心に鑑定してください。")
        lines.append("→ 支配星\(sign.rulingPlanet.japaneseName)の影響と、今日の惑星の配置がもたらすエネルギーを織り込んでください。")
        lines.append("→ \(decan.japaneseName)の副支配星\(subRuler.japaneseName)がもたらす個性にも触れてください。")
        lines.append("→ 現在の\(currentSeason.japaneseName)シーズンとの相性（\(horoscope.elementHarmony)）を踏まえた時期的なアドバイスを。")
        lines.append("→ パワーストーン（\(sign.powerStone)）を使った開運法も提案してください。")
        lines.append("→ 西洋占星術の専門家として、格調と親しみやすさを兼ねた語り口で鑑定してください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private static func starRating(_ score: Int) -> String {
        String(repeating: "★", count: score) + String(repeating: "☆", count: max(0, 5 - score))
    }

    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let currentSeason = ZodiacCalculator.currentSeason()
        let horoscope = ZodiacCalculator.dailyHoroscope(for: currentSeason)

        var lines: [String] = []
        lines.append("【星座占いデータ】")
        lines.append("・星座情報が未設定です。")
        lines.append("・現在の太陽星座：\(currentSeason.japaneseName)シーズン")
        lines.append("・\(horoscope.planetaryInfluence)")
        lines.append("")
        lines.append("星座が未設定のため、現在の\(currentSeason.japaneseName)シーズンの一般的な傾向を踏まえて、")
        lines.append("\(category.japaneseName)について鑑定してください。")
        return lines.joined(separator: "\n")
    }
}
