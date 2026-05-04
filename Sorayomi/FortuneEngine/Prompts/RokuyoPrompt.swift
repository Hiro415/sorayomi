import Foundation

// MARK: - RokuyoPrompt

/// 六曜占い用のユーザープロンプトを構築する
/// Builds the rokuyo-specific section of the user prompt, including
/// today's rokuyo, hourly luck timeline, special days, event suitability,
/// cultural/historical context, and upcoming calendar flow.
struct RokuyoPrompt {

    // MARK: - Public API

    /// Build the rokuyo context block for the user prompt.
    /// - Parameter category: The reading category to tailor the prompt.
    /// - Returns: A formatted Japanese rokuyo context string.
    static func build(category: ReadingCategory) -> String {
        let today = Date()
        let rokuyo = RokuyoCalculator.calculate(from: today)
        let specialDays = SpecialDayCalculator.specialDays(for: today)
        let currentLuck = rokuyo.currentTimeLuck

        var lines: [String] = []

        // 基本データ
        lines.append("【六曜データ】")
        lines.append("・今日の六曜：\(rokuyo.japaneseName)（\(rokuyo.reading)）")
        lines.append("・吉凶度：\(starString(rokuyo.auspiciousnessScore))（\(rokuyo.auspiciousnessScore)/5）")
        lines.append("・陰陽五行：\(rokuyo.elementCorrespondence)")
        lines.append("・ガイダンス：\(rokuyo.briefGuidance)")

        // 由来・詳細
        lines.append("")
        lines.append("【六曜の由来】")
        lines.append(rokuyo.detailedMeaning)

        // 時間帯別の吉凶タイムライン
        lines.append("")
        lines.append("【時間帯別の吉凶】")
        for slot in rokuyo.hourlyLuck {
            let luckLabel = luckDescription(score: slot.score)
            lines.append("・\(slot.period)（\(slot.hours)）：\(starString(slot.score)) \(luckLabel)")
        }
        lines.append("")
        lines.append("→ 現在の時間帯：\(currentLuck.period)（\(luckDescription(score: currentLuck.score))）")

        // 特別な日
        if !specialDays.isEmpty {
            lines.append("")
            lines.append("【今日の暦注・選日】")
            for day in specialDays {
                let marker = day.isAuspicious ? "◎吉" : "▲凶"
                lines.append("・\(day.name)（\(day.reading)）[\(marker)]")
                lines.append("  → \(day.description)")
                if !day.suitableFor.isEmpty {
                    lines.append("  ○ 適する事柄：\(day.suitableFor.joined(separator: "、"))")
                }
                if !day.avoidFor.isEmpty {
                    lines.append("  × 避ける事柄：\(day.avoidFor.joined(separator: "、"))")
                }
            }
        } else {
            lines.append("")
            lines.append("【今日の暦注・選日】特になし（通常の日）")
        }

        // カテゴリに応じた行事の適否
        let relevantEvents = categoryRelevantEvents(category: category)
        if !relevantEvents.isEmpty {
            lines.append("")
            lines.append("【\(category.japaneseName)に関連する行事の吉凶】")
            for eventName in relevantEvents {
                if let suitability = rokuyo.suitability(for: eventName) {
                    lines.append("・\(suitability.event)：\(starString(suitability.suitability)) — \(suitability.note)")
                }
            }
        }

        // 今後の暦の流れ
        let upcoming = RokuyoCalculator.upcoming(from: today, days: 5)
        if upcoming.count > 1 {
            lines.append("")
            lines.append("【今後の暦の流れ】")
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月d日（E）"
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

            for (date, upcomingRokuyo) in upcoming.dropFirst() {
                let dateStr = formatter.string(from: date)
                let upcomingSpecial = SpecialDayCalculator.specialDays(for: date)
                let specialSuffix = upcomingSpecial.isEmpty ? "" : " ＋ \(upcomingSpecial.map { $0.name }.joined(separator: "・"))"
                lines.append("  ・\(dateStr)：\(upcomingRokuyo.japaneseName)\(starString(upcomingRokuyo.auspiciousnessScore))\(specialSuffix)")
            }
        }

        // 鑑定指示
        lines.append("")
        lines.append("【鑑定モード】六曜暦注鑑定")
        lines.append("→ \(category.japaneseName)について、今日の六曜「\(rokuyo.japaneseName)」を中心に鑑定してください。")
        lines.append("→ 時間帯別の吉凶を活かした具体的なタイムライン（早朝→午前→昼→午後→夕方→夜）を提案してください。")
        lines.append("→ 現在の時間帯（\(currentLuck.period)）を踏まえ、「今からどう動くべきか」を具体的に。")
        if !specialDays.isEmpty {
            let specialNames = specialDays.map { $0.name }.joined(separator: "・")
            lines.append("→ 今日は「\(specialNames)」でもあります。六曜との相乗効果・打ち消し効果を解説してください。")
        }
        lines.append("→ 六曜の由来・五行の属性は「裏付け」として自然に織り込み、深みのある鑑定を。")
        lines.append("→ 今後数日の暦の流れにも触れ、「今日すべきこと」と「後日に回すべきこと」を切り分けてください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private static func starString(_ score: Int) -> String {
        String(repeating: "★", count: score) + String(repeating: "☆", count: max(0, 5 - score))
    }

    private static func luckDescription(score: Int) -> String {
        switch score {
        case 5: return "大吉"
        case 4: return "小吉"
        case 3: return "平"
        case 2: return "小凶"
        case 1: return "凶"
        default: return "平"
        }
    }

    /// カテゴリに関連する行事名を返す
    private static func categoryRelevantEvents(category: ReadingCategory) -> [String] {
        switch category {
        case .love:
            return ["結婚", "入籍"]
        case .career:
            return ["開業", "契約"]
        case .wealth:
            return ["財布", "契約"]
        case .health:
            return ["お見舞い"]
        case .relationships:
            return ["結婚", "入籍", "旅行"]
        case .personality:
            return ["自己分析", "学び"]
        case .general, .daily:
            return ["結婚", "開業", "引越し", "旅行", "契約"]
        }
    }
}
