import Foundation

/// 花占い用のユーザープロンプトを構築する
struct FlowerFortunePrompt {

    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let flowerProfile = FlowerFortuneCalculator.profile(from: birthday)
        let dailyEnergy = FlowerFortuneCalculator.dailyEnergy(birthday: birthday)
        let birthFlower = flowerProfile.birthMonthFlower
        let dayFlower = flowerProfile.birthDayFlower
        let todaysFlower = dailyEnergy.todaysFlower

        var lines: [String] = []

        lines.append("【花占いデータ】")
        lines.append("")

        // 誕生月の花
        lines.append("■ 誕生月の花：\(birthFlower.japaneseName)（\(birthFlower.englishName)）")
        lines.append("  花言葉：\(birthFlower.hanakotoba.joined(separator: "、"))")
        lines.append("  季節：\(birthFlower.season.rawValue) ／ 元素：\(birthFlower.element.rawValue)")
        lines.append("")

        // 誕生日の花
        lines.append("■ 誕生日の花：\(dayFlower.japaneseName)（\(dayFlower.englishName)）")
        lines.append("  花言葉：\(dayFlower.hanakotoba.joined(separator: "、"))")
        lines.append("")

        // 性格傾向
        lines.append("■ 花が映す人物像")
        lines.append("  \(flowerProfile.personalityTraits)")
        lines.append("")

        // 今日の花
        lines.append("■ 今日の花：\(todaysFlower.japaneseName)（\(todaysFlower.englishName)）")
        lines.append("  花言葉：\(todaysFlower.hanakotoba.joined(separator: "、"))")
        lines.append("  季節：\(todaysFlower.season.rawValue) ／ 元素：\(todaysFlower.element.rawValue)")
        lines.append("")

        // 花の共鳴
        lines.append("■ 花の共鳴")
        lines.append("  誕生花×今日の花：\(dailyEnergy.resonanceDescription)")
        lines.append("  共鳴スコア：\(dailyEnergy.resonanceScore)/5")
        lines.append("  複合メッセージ：\(dailyEnergy.combinedMessage)")
        lines.append("  開運アクション：\(dailyEnergy.luckyFlowerAction)")
        lines.append("")

        // 鑑定指示
        lines.append("【鑑定指示】")
        lines.append("① 誕生花の花言葉「\(flowerProfile.primaryHanakotoba)」を軸に、相談者の本質を詩的に読み解いてください")
        lines.append("② 今日の花「\(todaysFlower.japaneseName)」の花言葉と誕生花の関係から、今日の過ごし方を導いてください")
        lines.append("③ 花の元素の相性（\(birthFlower.element.rawValue)×\(todaysFlower.element.rawValue)）を具体的な行動提案に反映してください")
        lines.append("④ 季節と花の結びつきを、相談テーマに合わせて自然に織り込んでください")

        switch category {
        case .love, .relationships:
            lines.append("⑤ 恋愛の観点から、花言葉を活かした具体的な恋のアドバイスを含めてください")
        case .career, .wealth:
            lines.append("⑤ 仕事・金運の観点から、花言葉を活かした具体的なキャリアアドバイスを含めてください")
        default:
            lines.append("⑤ 相談テーマに合わせて、花言葉を活かした具体的なアドバイスを含めてください")
        }

        return lines.joined(separator: "\n")
    }

    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let todaysFlower = FlowerFortuneCalculator.todaysFlower()

        return """
        【花占いデータ】

        ■ 今日の花：\(todaysFlower.japaneseName)（\(todaysFlower.englishName)）
          花言葉：\(todaysFlower.hanakotoba.joined(separator: "、"))
          季節：\(todaysFlower.season.rawValue) ／ 元素：\(todaysFlower.element.rawValue)

        ※ 誕生日情報が未設定のため、今日の花のみでの鑑定です。

        【鑑定指示】
        ① 今日の花「\(todaysFlower.japaneseName)」の花言葉を軸に、今日の過ごし方を導いてください
        ② 花の持つ象徴的な意味を詩的に語ってください
        ③ 「花が語る」「花言葉が示す」のような表現を自然に使ってください
        """
    }
}
