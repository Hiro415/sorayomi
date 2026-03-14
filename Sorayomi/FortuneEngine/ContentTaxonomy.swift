import Foundation

// MARK: - ReadingDepth

/// 鑑定の深さレベル
/// Controls how detailed an AI-generated reading should be.
enum ReadingDepth: String, Codable, CaseIterable, Identifiable {
    case snapshot = "snapshot"   // Quick daily glance
    case standard = "standard"  // Normal reading
    case deep = "deep"          // Comprehensive analysis

    var id: String { rawValue }

    /// Maximum tokens the AI response should use for this depth.
    var maxTokens: Int {
        switch self {
        case .snapshot: return 200
        case .standard: return 500
        case .deep:     return 1000
        }
    }

    /// 日本語表示名
    var japaneseName: String {
        switch self {
        case .snapshot: return "ひとこと"
        case .standard: return "スタンダード"
        case .deep:     return "じっくり"
        }
    }

    /// 説明文
    var japaneseDescription: String {
        switch self {
        case .snapshot: return "今日のポイントをさっと確認"
        case .standard: return "バランスの取れた鑑定"
        case .deep:     return "詳細な分析と具体的なアドバイス"
        }
    }
}

// MARK: - SeasonalContext

/// 季節・暦の文脈情報
/// Provides seasonal and solar term context for enriching AI prompts
/// with traditional Japanese seasonal awareness.
struct SeasonalContext: Codable {
    /// 季節（春・夏・秋・冬）
    let season: String
    /// 二十四節気の名称
    let solarTerm: String
    /// 季節を表す詩的な表現（日本語）
    let seasonalImagery: String

    // MARK: - Factory

    /// Build seasonal context for a given date.
    static func from(date: Date) -> SeasonalContext {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let season = seasonName(month: month)
        let solarTerm = solarTermName(month: month, day: day)
        let imagery = seasonalImageryText(month: month)

        return SeasonalContext(
            season: season,
            solarTerm: solarTerm,
            seasonalImagery: imagery
        )
    }

    // MARK: - Season

    private static func seasonName(month: Int) -> String {
        switch month {
        case 3, 4, 5:   return "春"
        case 6, 7, 8:   return "夏"
        case 9, 10, 11: return "秋"
        default:         return "冬"
        }
    }

    // MARK: - 二十四節気 (Solar Terms)

    private static func solarTermName(month: Int, day: Int) -> String {
        switch (month, day) {
        // 春 Spring
        case (2, 4...18):   return "立春"
        case (2, 19...29):  return "雨水"
        case (3, 1...5):    return "雨水"
        case (3, 6...20):   return "啓蟄"
        case (3, 21...31):  return "春分"
        case (4, 1...4):    return "春分"
        case (4, 5...19):   return "清明"
        case (4, 20...30):  return "穀雨"
        case (5, 1...5):    return "穀雨"
        case (5, 6...20):   return "立夏"
        case (5, 21...31):  return "小満"
        // 夏 Summer
        case (6, 1...5):    return "小満"
        case (6, 6...20):   return "芒種"
        case (6, 21...30):  return "夏至"
        case (7, 1...6):    return "夏至"
        case (7, 7...22):   return "小暑"
        case (7, 23...31):  return "大暑"
        case (8, 1...6):    return "大暑"
        case (8, 7...22):   return "立秋"
        case (8, 23...31):  return "処暑"
        // 秋 Autumn
        case (9, 1...7):    return "処暑"
        case (9, 8...22):   return "白露"
        case (9, 23...30):  return "秋分"
        case (10, 1...7):   return "秋分"
        case (10, 8...22):  return "寒露"
        case (10, 23...31): return "霜降"
        case (11, 1...6):   return "霜降"
        case (11, 7...21):  return "立冬"
        case (11, 22...30): return "小雪"
        // 冬 Winter
        case (12, 1...6):   return "小雪"
        case (12, 7...21):  return "大雪"
        case (12, 22...31): return "冬至"
        case (1, 1...5):    return "冬至"
        case (1, 6...19):   return "小寒"
        case (1, 20...31):  return "大寒"
        case (2, 1...3):    return "大寒"
        default:            return "立春"
        }
    }

    // MARK: - Seasonal Imagery

    private static func seasonalImageryText(month: Int) -> String {
        switch month {
        case 1:  return "新年の清らかな空気と、静かに芽吹きを待つ大地"
        case 2:  return "梅のほころびと、春を告げるやわらかな風"
        case 3:  return "桜の蕾がふくらみ、万物が目覚める季節"
        case 4:  return "満開の桜と、若葉が光に透ける美しさ"
        case 5:  return "新緑の輝きと、薫風が運ぶ生命の息吹"
        case 6:  return "紫陽花が雨に濡れ、静かに心を潤す季節"
        case 7:  return "入道雲と蝉時雨、生命力あふれる盛夏"
        case 8:  return "夏の終わりの夕暮れと、ひぐらしの声"
        case 9:  return "秋風と虫の音、実りの季節の始まり"
        case 10: return "紅葉が色づき、澄んだ秋空が広がる季節"
        case 11: return "落葉と冬支度、静寂の中に見える美しさ"
        case 12: return "冬の凛とした空気と、年の瀬の感謝"
        default: return "四季折々の美しさに包まれた日本の暦"
        }
    }
}
