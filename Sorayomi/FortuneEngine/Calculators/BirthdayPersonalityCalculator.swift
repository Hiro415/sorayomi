import Foundation

/// Generates birthday-based personality insights using the day of year (1-366).
/// Uses algorithmic generation of personality traits based on numerological
/// and seasonal patterns rather than a static 366-entry database.
struct BirthdayPersonalityCalculator {

    struct BirthdayProfile {
        let monthDay: (month: Int, day: Int)
        let personality: String
        let strength: String
        let luckyColor: String
        let luckyNumber: Int
        let seasonalAdvice: String
        let compatibleMonthDay: (month: Int, day: Int)
    }

    // MARK: - Season and Element Traits

    private static let seasonTraits: [(season: String, element: String, qualities: [String])] = [
        ("春", "木", ["創造力", "成長", "新しい始まり", "柔軟性", "直感力"]),
        ("夏", "火", ["情熱", "エネルギー", "行動力", "リーダーシップ", "表現力"]),
        ("秋", "金", ["洞察力", "収穫", "知恵", "分析力", "完成"]),
        ("冬", "水", ["内省", "忍耐", "深い思考", "感受性", "再生"]),
    ]

    private static let luckyColors = [
        "紅色", "藍色", "若草色", "山吹色", "藤色",
        "桜色", "浅葱色", "橙色", "銀鼠色", "珊瑚色",
        "抹茶色", "瑠璃色",
    ]

    private static let monthPersonalities: [String] = [
        "直感力に優れ、新しいことを始める力があります",        // 1月
        "繊細な感受性を持ち、人の心に寄り添える方です",        // 2月
        "冒険心に溢れ、変化を楽しむ柔軟な心を持っています",    // 3月
        "安定感があり、周囲に安心感を与える存在です",          // 4月
        "コミュニケーション力に優れ、人と人を繋ぐ架け橋になれます", // 5月
        "愛情深く、大切な人を守る強さを持っています",          // 6月
        "リーダーシップがあり、情熱を持って道を切り開けます",    // 7月
        "創造力に満ち、独自のアイデアで世界を彩ります",        // 8月
        "分析力に優れ、物事の本質を見抜く目を持っています",    // 9月
        "バランス感覚に優れ、調和のとれた関係を築けます",      // 10月
        "変革の力を持ち、深い洞察で真実を追求できます",        // 11月
        "理想を形にする力があり、大きなビジョンを描けます",    // 12月
    ]

    private static let dayStrengths: [String] = [
        "粘り強さ", "適応力", "表現力", "安定感", "好奇心",
        "共感力", "分析力", "決断力", "想像力", "実行力",
    ]

    // MARK: - Public API

    /// Generate a birthday personality profile from a date.
    static func profile(from date: Date) -> BirthdayProfile {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let personality = monthPersonalities[month - 1]
        let strengthIndex = (month + day) % dayStrengths.count
        let strength = dayStrengths[strengthIndex]
        let colorIndex = (month - 1) % luckyColors.count
        let luckyColor = luckyColors[colorIndex]
        let luckyNumber = ((month * day) % 9) + 1

        let seasonIndex: Int
        switch month {
        case 3...5: seasonIndex = 0
        case 6...8: seasonIndex = 1
        case 9...11: seasonIndex = 2
        default: seasonIndex = 3
        }
        let season = seasonTraits[seasonIndex]
        let qualityIndex = day % season.qualities.count
        let seasonalAdvice = "\(season.season)生まれのあなたは\(season.element)のエネルギーを持ち、\(season.qualities[qualityIndex])を大切にすると良い流れに乗れるでしょう"

        // Compatible date: 6 months + some days offset
        let compatMonth = ((month + 5) % 12) + 1
        let compatDay = min(day, 28) // Safe day for all months

        return BirthdayProfile(
            monthDay: (month, day),
            personality: personality,
            strength: strength,
            luckyColor: luckyColor,
            luckyNumber: luckyNumber,
            seasonalAdvice: seasonalAdvice,
            compatibleMonthDay: (compatMonth, compatDay)
        )
    }
}
