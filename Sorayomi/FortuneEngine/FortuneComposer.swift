import Foundation

// MARK: - ComposedDailyFortune

/// 複数の占いシステムを統合した一日の総合運勢
/// Composite daily fortune built from multiple calculators.
struct ComposedDailyFortune: Codable, Identifiable {
    let id: String
    let date: Date
    let zodiacSign: ZodiacSign?
    let rokuyo: Rokuyo
    let bloodType: BloodType?
    let numerologyDayNumber: Int?
    let nineStarDailyStar: NineStarKiStar?
    let overallScore: Int          // 1-5
    let headline: String           // Short Japanese headline
    let luckyColors: [String]      // Japanese color names
    let luckyItems: [String]       // Japanese lucky item names
    let luckyDirection: String?    // 吉方位
    let advice: String             // Short daily advice in Japanese

    /// 総合スコアの星表示（例: "★★★★☆"）
    var starDisplay: String {
        let filled = String(repeating: "★", count: overallScore)
        let empty = String(repeating: "☆", count: 5 - overallScore)
        return filled + empty
    }
}

// MARK: - FortuneComposer

/// 複数の計算エンジンを組み合わせて総合デイリー運勢を生成する
/// Composes a ComposedDailyFortune by combining results from ZodiacCalculator,
/// RokuyoCalculator, NumerologyCalculator, and BloodTypeCalculator.
struct FortuneComposer {

    /// Build a composite daily fortune for the given profile and date.
    func composeDailyFortune(profile: UserProfile, date: Date) -> ComposedDailyFortune {
        // -- Rokuyo (always available) --
        let rokuyo = RokuyoCalculator.calculate(from: date)

        // -- Zodiac (requires birthday) --
        let zodiacSign: ZodiacSign? = profile.birthday.map { ZodiacCalculator.calculate(from: $0) }

        // -- Blood Type --
        let bloodType = profile.bloodType

        // -- Numerology (requires birthday) --
        let numerologyDayNumber: Int? = profile.birthday.map {
            NumerologyCalculator.personalDayNumber(from: $0, on: date)
        }

        // -- Nine Star Ki daily star --
        let dailyStar = NineStarKiCalculator.dailyStar(for: date)

        // -- Overall Score --
        let overallScore = computeOverallScore(
            rokuyo: rokuyo,
            numerologyDay: numerologyDayNumber,
            dailyStar: dailyStar
        )

        // -- Headline --
        let headline = composeHeadline(rokuyo: rokuyo, score: overallScore)

        // -- Lucky Colors --
        let luckyColors = composeLuckyColors(
            zodiacSign: zodiacSign,
            dailyStar: dailyStar,
            date: date
        )

        // -- Lucky Items --
        let luckyItems = composeLuckyItems(
            rokuyo: rokuyo,
            zodiacSign: zodiacSign,
            date: date
        )

        // -- Lucky Direction --
        let luckyDirection = dailyStar.direction

        // -- Advice --
        let advice = composeAdvice(rokuyo: rokuyo, numerologyDay: numerologyDayNumber)

        return ComposedDailyFortune(
            id: "daily-\(Self.dateKey(date))-\(profile.id)",
            date: date,
            zodiacSign: zodiacSign,
            rokuyo: rokuyo,
            bloodType: bloodType,
            numerologyDayNumber: numerologyDayNumber,
            nineStarDailyStar: dailyStar,
            overallScore: overallScore,
            headline: headline,
            luckyColors: luckyColors,
            luckyItems: luckyItems,
            luckyDirection: luckyDirection,
            advice: advice
        )
    }

    // MARK: - Score Computation

    private func computeOverallScore(
        rokuyo: Rokuyo,
        numerologyDay: Int?,
        dailyStar: NineStarKiStar
    ) -> Int {
        // Base from Rokuyo auspiciousness (1-5)
        var total = Double(rokuyo.auspiciousnessScore)
        var count = 1.0

        // Numerology day energy bonus
        if let dayNum = numerologyDay {
            let numerologyScore: Double
            switch dayNum {
            case 1, 8:        numerologyScore = 5.0  // High energy days
            case 3, 9:        numerologyScore = 4.0  // Creative / completion days
            case 5, 11, 22:   numerologyScore = 4.0  // Change / master numbers
            case 2, 6:        numerologyScore = 3.5  // Cooperation days
            case 4, 7:        numerologyScore = 3.0  // Steady / contemplative
            case 33:          numerologyScore = 5.0  // Master number
            default:          numerologyScore = 3.0
            }
            total += numerologyScore
            count += 1.0
        }

        // Nine Star Ki daily energy
        let starScore: Double
        switch dailyStar {
        case .goouDosei:      starScore = 4.5  // Center star - powerful
        case .kyushiKasei:    starScore = 4.0  // Fire - passionate
        case .ippakuSuisei:   starScore = 3.5  // Water - flowing
        default:              starScore = 3.0
        }
        total += starScore
        count += 1.0

        let average = total / count
        return max(1, min(5, Int(average.rounded())))
    }

    // MARK: - Headline

    private func composeHeadline(rokuyo: Rokuyo, score: Int) -> String {
        switch score {
        case 5:  return "素晴らしい一日の予感！運気が最高潮です"
        case 4:  return "穏やかな良い流れの日。前向きに過ごしましょう"
        case 3:  return "バランスの取れた一日。丁寧に過ごすことが鍵"
        case 2:  return "慎重に過ごしたい日。無理せずマイペースで"
        default: return "静かに内省する日。心を整える時間を大切に"
        }
    }

    // MARK: - Lucky Colors

    private func composeLuckyColors(
        zodiacSign: ZodiacSign?,
        dailyStar: NineStarKiStar,
        date: Date
    ) -> [String] {
        var colors: [String] = []

        // Nine Star Ki star color
        colors.append(dailyStar.color)

        // Zodiac element color
        if let sign = zodiacSign {
            switch sign.element {
            case .fire:  colors.append("紅色")
            case .earth: colors.append("山吹色")
            case .air:   colors.append("若草色")
            case .water: colors.append("藍色")
            }
        }

        // Seasonal color
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let seasonalColors = [
            "桜色", "藤色", "若葉色", "紫陽花色",
            "浅葱色", "向日葵色", "珊瑚色", "撫子色",
            "紅葉色", "銀杏色", "柿色", "雪色"
        ]
        let seasonalColor = seasonalColors[(month - 1) % seasonalColors.count]
        if !colors.contains(seasonalColor) {
            colors.append(seasonalColor)
        }

        return Array(colors.prefix(3))
    }

    // MARK: - Lucky Items

    private func composeLuckyItems(
        rokuyo: Rokuyo,
        zodiacSign: ZodiacSign?,
        date: Date
    ) -> [String] {
        var items: [String] = []

        // Rokuyo-based item
        switch rokuyo {
        case .taian:      items.append("新しいノート")
        case .tomobiki:   items.append("友人からの手紙")
        case .senshou:    items.append("朝のコーヒー")
        case .senbu:      items.append("お気に入りの本")
        case .shakkou:    items.append("赤い小物")
        case .butsumetsu: items.append("お香")
        }

        // Zodiac element item
        if let sign = zodiacSign {
            switch sign.element {
            case .fire:  items.append("キャンドル")
            case .earth: items.append("天然石のアクセサリー")
            case .air:   items.append("風鈴")
            case .water: items.append("ハーブティー")
            }
        }

        // Day-of-week item
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: date)
        let weekdayItems = [
            "日記帳", "植物", "音楽",
            "ハンカチ", "写真", "花", "和菓子"
        ]
        let dayItem = weekdayItems[(weekday - 1) % weekdayItems.count]
        if !items.contains(dayItem) {
            items.append(dayItem)
        }

        return Array(items.prefix(3))
    }

    // MARK: - Advice

    private func composeAdvice(rokuyo: Rokuyo, numerologyDay: Int?) -> String {
        var advice = rokuyo.briefGuidance

        if let dayNum = numerologyDay {
            let dayAdvice = NumerologyProfile.dayGuidance(for: dayNum)
            advice += "。数秘術の視点からは、\(dayAdvice)"
        }

        return advice
    }

    // MARK: - Helpers

    private static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
}
