import Foundation

/// ストーン占い用のユーザープロンプトを構築する
struct StoneFortunePrompt {

    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        guard let profile,
              let birthday = profile.birthday else {
            return fallbackPrompt(category: category)
        }

        let stoneProfile = StoneFortuneCalculator.profile(from: birthday)
        let dailyEnergy = StoneFortuneCalculator.dailyEnergy(birthday: birthday)
        let birthstone = stoneProfile.birthstone
        let todaysStone = dailyEnergy.todaysStone

        var lines: [String] = []

        lines.append("【ストーン占いデータ】")
        lines.append("")

        // 誕生石
        lines.append("■ 誕生石：\(birthstone.japaneseName)（\(birthstone.englishName)）")
        lines.append("  色：\(birthstone.colorHex) ／ 元素：\(birthstone.element.rawValue) ／ チャクラ：\(birthstone.chakra.rawValue)")
        lines.append("  石の力：\(birthstone.properties.joined(separator: "、"))")
        lines.append("  ヒーリング：\(birthstone.healingAspect)")
        lines.append("  守護：\(birthstone.protectionAspect)")
        lines.append("  幸運：\(birthstone.luckAspect)")
        lines.append("")

        // 人物像
        lines.append("■ 石が映す人物像")
        lines.append("  \(stoneProfile.personalityFromStone)")
        lines.append("  \(stoneProfile.birthstoneMessage)")
        lines.append("")

        // 今日のパワーストーン
        lines.append("■ 今日のパワーストーン：\(todaysStone.japaneseName)（\(todaysStone.englishName)）")
        lines.append("  色：\(todaysStone.colorHex) ／ 元素：\(todaysStone.element.rawValue) ／ チャクラ：\(todaysStone.chakra.rawValue)")
        lines.append("  石の力：\(todaysStone.properties.joined(separator: "、"))")
        lines.append("")

        // 石の共鳴
        lines.append("■ 石の共鳴")
        lines.append("  誕生石×今日の石：\(dailyEnergy.resonanceDescription)")
        lines.append("  元素の相互作用：\(dailyEnergy.elementInteraction)")
        lines.append("  チャクラの整列：\(dailyEnergy.chakraAlignment)")
        lines.append("  共鳴スコア：\(dailyEnergy.resonanceScore)/5")
        lines.append("  推奨アクション：\(dailyEnergy.recommendedAction)")
        lines.append("")

        // 鑑定指示
        lines.append("【鑑定指示】")
        lines.append("① 誕生石「\(birthstone.japaneseName)」の性質を軸に、相談者の生まれ持った資質を読み解いてください")
        lines.append("② 今日のパワーストーン「\(todaysStone.japaneseName)」と誕生石の共鳴から、今日のエネルギーの流れを説明してください")
        lines.append("③ チャクラの整列状態を、心身の過ごし方のアドバイスに反映してください")
        lines.append("④ 石の元素の相互作用（\(birthstone.element.rawValue)×\(todaysStone.element.rawValue)）を具体的な行動提案に織り込んでください")

        switch category {
        case .love, .relationships:
            lines.append("⑤ 恋愛の観点から、パワーストーンの力を活かした具体的な恋のアドバイスを含めてください")
        case .career, .wealth:
            lines.append("⑤ 仕事・金運の観点から、パワーストーンの力を活かした具体的なキャリアアドバイスを含めてください")
        default:
            lines.append("⑤ 相談テーマに合わせて、パワーストーンの力を活かした実践的な助言を含めてください")
        }

        return lines.joined(separator: "\n")
    }

    private static func fallbackPrompt(category: ReadingCategory) -> String {
        let todaysStone = StoneFortuneCalculator.todaysStone()

        return """
        【ストーン占いデータ】

        ■ 今日のパワーストーン：\(todaysStone.japaneseName)（\(todaysStone.englishName)）
          色：\(todaysStone.colorHex) ／ 元素：\(todaysStone.element.rawValue) ／ チャクラ：\(todaysStone.chakra.rawValue)
          石の力：\(todaysStone.properties.joined(separator: "、"))
          ヒーリング：\(todaysStone.healingAspect)

        ※ 誕生日情報が未設定のため、今日のパワーストーンのみでの鑑定です。

        【鑑定指示】
        ① 今日のパワーストーン「\(todaysStone.japaneseName)」の性質を軸に、今日のエネルギーの流れを説明してください
        ② 石の色や輝きを象徴として活用してください
        ③ 「石が守る」「クリスタルが映す」のような表現を自然に使ってください
        """
    }
}
