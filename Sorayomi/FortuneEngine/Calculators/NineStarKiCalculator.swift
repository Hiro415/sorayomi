import Foundation

/// 九星気学エンジン
/// Calculates Nine Star Ki stars from birthday, daily/monthly/yearly star cycles,
/// Five Element relationships, auspicious directions, and daily energy profiles.
///
/// The system assigns one of 9 stars based on birth year (本命星 Honmeisei)
/// and birth month (月命星 Getsumeisei). The year boundary is 立春 (Risshun),
/// approximately February 3-4, NOT January 1.
struct NineStarKiCalculator {

    // MARK: - Public API

    /// Calculate the Nine Star Ki profile from a birthday.
    static func calculate(from date: Date) -> NineStarKiProfile {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let risshunDay = risshunDate(for: year)
        let adjustedYear: Int
        if month < 2 || (month == 2 && day < risshunDay) {
            adjustedYear = year - 1
        } else {
            adjustedYear = year
        }

        let honmeisei = calculateHonmeisei(year: adjustedYear)

        let adjustedMonth: Int
        if day < risshunDay && month == 2 {
            adjustedMonth = 1
        } else if month == 1 {
            adjustedMonth = 1
        } else {
            adjustedMonth = month
        }

        let getsumeisei = calculateGetsumeisei(honmeisei: honmeisei, month: adjustedMonth)

        return NineStarKiProfile(
            honmeisei: honmeisei,
            getsumeisei: getsumeisei,
            birthYear: year
        )
    }

    /// Calculate today's daily star (日命星).
    /// Uses a 9-day reverse cycle anchored to a known date.
    static func dailyStar(for date: Date = Date()) -> NineStarKiStar {
        let calendar = Calendar(identifier: .gregorian)
        let anchor = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let daysBetween = calendar.dateComponents([.day], from: anchor, to: date).day ?? 0
        let index = ((9 - (daysBetween % 9)) % 9) + 1
        return NineStarKiStar(rawValue: index) ?? .ippakuSuisei
    }

    /// Calculate this month's monthly star (月命星 for the current month).
    /// Monthly star cycle: 9-month reverse cycle, starting from 立春 month.
    static func monthlyStar(for date: Date = Date()) -> NineStarKiStar {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Adjust for setsubun (approx Feb 4 boundary for monthly stars too)
        let adjustedMonth: Int
        if month == 2 && day < risshunDate(for: year) {
            adjustedMonth = 1
        } else if month == 1 {
            adjustedMonth = 1
        } else {
            adjustedMonth = month
        }

        // Monthly star is determined by the year's honmeisei group and month
        let yearlyStar = yearStar(for: date)
        let group = honmeiseiGroup(yearlyStar)
        let monthIndex = max(0, min(11, adjustedMonth - 1))
        let starNumber = monthStarTable[group][monthIndex]
        return NineStarKiStar(rawValue: starNumber) ?? .ippakuSuisei
    }

    /// Calculate this year's star (年命星 for the current year).
    static func yearStar(for date: Date = Date()) -> NineStarKiStar {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let adjustedYear: Int
        if month < 2 || (month == 2 && day < risshunDate(for: year)) {
            adjustedYear = year - 1
        } else {
            adjustedYear = year
        }
        return calculateHonmeisei(year: adjustedYear)
    }

    // MARK: - Five Element Relationship

    /// Determine the Five Element relationship between two stars.
    static func elementRelation(from star1: NineStarKiStar, to star2: NineStarKiStar) -> FiveElementRelation {
        let e1 = star1.element
        let e2 = star2.element

        if e1 == e2 { return .same }

        // 相生 cycle: 木→火→土→金→水→木
        let generatingMap: [String: String] = [
            "木": "火", "火": "土", "土": "金", "金": "水", "水": "木"
        ]

        if generatingMap[e1] == e2 { return .generating }
        if generatingMap[e2] == e1 { return .generated }

        // 相剋 cycle: 木→土→水→火→金→木
        let controllingMap: [String: String] = [
            "木": "土", "土": "水", "水": "火", "火": "金", "金": "木"
        ]

        if controllingMap[e1] == e2 { return .controlling }
        if controllingMap[e2] == e1 { return .controlled }

        return .same // fallback
    }

    // MARK: - Auspicious Directions (吉方位)

    /// Calculate today's auspicious and inauspicious directions based on
    /// the user's honmeisei and the current yearly/monthly/daily stars.
    static func directions(
        honmeisei: NineStarKiStar,
        on date: Date = Date()
    ) -> (auspicious: [String], inauspicious: [String]) {
        let daily = dailyStar(for: date)
        let monthly = monthlyStar(for: date)

        // Basic rule: directions of stars that generate your element are auspicious
        var auspicious: [String] = []
        var inauspicious: [String] = []

        for star in NineStarKiStar.allCases where star != .goouDosei {
            let relation = elementRelation(from: honmeisei, to: star)
            switch relation {
            case .generated:
                auspicious.append(star.direction)
            case .generating, .same:
                // Neutral - check if daily star supports
                let dailyRelation = elementRelation(from: daily, to: star)
                if dailyRelation == .generated || dailyRelation == .same {
                    auspicious.append(star.direction)
                }
            case .controlled:
                inauspicious.append(star.direction)
            case .controlling:
                // Check monthly star for nuance
                let monthlyRelation = elementRelation(from: monthly, to: star)
                if monthlyRelation == .controlled {
                    inauspicious.append(star.direction)
                }
            }
        }

        // 五黄殺（五黄土星の方位は常に凶）
        let yearlyGoou = goouDirection(for: date)
        if !inauspicious.contains(yearlyGoou) && yearlyGoou != "中央" {
            inauspicious.append(yearlyGoou + "（五黄殺）")
        }

        // Deduplicate
        let uniqueAuspicious = Array(Set(auspicious)).sorted()
        let uniqueInauspicious = Array(Set(inauspicious)).sorted()

        return (
            auspicious: uniqueAuspicious.isEmpty ? ["方位に吉凶なし"] : uniqueAuspicious,
            inauspicious: uniqueInauspicious.isEmpty ? ["特になし"] : uniqueInauspicious
        )
    }

    // MARK: - Daily Energy Profile

    /// Generate comprehensive daily energy profile combining all star interactions.
    static func dailyEnergy(
        profile: NineStarKiProfile,
        on date: Date = Date()
    ) -> NineStarKiDailyEnergy {
        let daily = dailyStar(for: date)
        let monthly = monthlyStar(for: date)
        let yearly = yearStar(for: date)

        let relation = elementRelation(from: profile.honmeisei, to: daily)
        let dirs = directions(honmeisei: profile.honmeisei, on: date)

        // Score: base from honmeisei×daily relation, modified by monthly
        let baseScore = relation.score
        let monthlyRelation = elementRelation(from: profile.honmeisei, to: monthly)
        let monthlyBonus: Int
        switch monthlyRelation {
        case .generated: monthlyBonus = 1
        case .generating, .same: monthlyBonus = 0
        case .controlling, .controlled: monthlyBonus = -1
        }
        let overall = max(1, min(5, baseScore + monthlyBonus))

        let advice = dailyAdvice(
            honmeisei: profile.honmeisei,
            daily: daily,
            relation: relation,
            score: overall
        )

        return NineStarKiDailyEnergy(
            dailyStar: daily,
            monthlyStar: monthly,
            yearlyStar: yearly,
            honmeiseiRelation: relation,
            auspiciousDirections: dirs.auspicious,
            inauspiciousDirections: dirs.inauspicious,
            overallScore: overall,
            advice: advice
        )
    }

    // MARK: - 九宮格 (Ki Grid) Position

    /// Calculate where a given star sits in today's nine-palace grid.
    /// Returns the palace number (1-9) where the star currently resides.
    /// In the default grid (後天定位盤): each star sits at its own number.
    /// Stars rotate through the grid in a fixed pattern based on the central star.
    static func gridPosition(of star: NineStarKiStar, centralStar: NineStarKiStar) -> Int {
        // The magic square order: 2,7,6,1,5,9,8,3,4 (Luo Shu)
        // When centralStar occupies position 5, other stars shift accordingly
        let offset = 5 - centralStar.rawValue
        var pos = star.rawValue + offset
        if pos > 9 { pos -= 9 }
        if pos < 1 { pos += 9 }
        return pos
    }

    /// Direction name for a grid position (1-9)
    static func directionForPosition(_ position: Int) -> String {
        switch position {
        case 1: return "北（坎宮）"
        case 2: return "南西（坤宮）"
        case 3: return "東（震宮）"
        case 4: return "南東（巽宮）"
        case 5: return "中央（中宮）"
        case 6: return "北西（乾宮）"
        case 7: return "西（兌宮）"
        case 8: return "北東（艮宮）"
        case 9: return "南（離宮）"
        default: return "不明"
        }
    }

    /// Description of a star's palace position meaning
    static func palaceInfluence(position: Int) -> String {
        switch position {
        case 1: return "北の坎宮。水の気が流れ、内省と準備の時期。新しい計画を温める好機"
        case 2: return "南西の坤宮。大地の気が満ち、人間関係と協力が鍵。周囲との調和を大切に"
        case 3: return "東の震宮。雷のエネルギーが湧き、新しいスタートに最適。行動力が増す時期"
        case 4: return "南東の巽宮。風の気が吹き、人との縁や信用が広がる好機。商売繁盛の気"
        case 5: return "中央の中宮。全ての気が集まる帝王の座。力が強まるが、自重も必要"
        case 6: return "北西の乾宮。天の気が満ち、目上からの引き立てあり。リーダーシップ発揮の時"
        case 7: return "西の兌宮。金の気が実り、楽しみと収穫の時期。社交が幸運を呼ぶ"
        case 8: return "北東の艮宮。山の気が立ち、変化と蓄積の時期。不動産運・蓄財運が高まる"
        case 9: return "南の離宮。火の気が輝き、知名度と評価が上がる時期。表舞台で活躍の好機"
        default: return ""
        }
    }

    // MARK: - Core Calculations

    private static func calculateHonmeisei(year: Int) -> NineStarKiStar {
        var digitSum = year
        while digitSum > 9 {
            digitSum = String(digitSum).compactMap { $0.wholeNumberValue }.reduce(0, +)
        }
        var starNumber = 11 - digitSum
        if starNumber > 9 {
            starNumber -= 9
        }
        return NineStarKiStar(rawValue: starNumber) ?? .ippakuSuisei
    }

    private static func calculateGetsumeisei(honmeisei: NineStarKiStar, month: Int) -> NineStarKiStar {
        let group = honmeiseiGroup(honmeisei)
        let monthIndex = max(0, min(11, month - 1))
        let starNumber = monthStarTable[group][monthIndex]
        return NineStarKiStar(rawValue: starNumber) ?? .ippakuSuisei
    }

    private static func honmeiseiGroup(_ star: NineStarKiStar) -> Int {
        switch star.rawValue {
        case 1, 4, 7: return 0
        case 3, 6, 9: return 1
        case 2, 5, 8: return 2
        default: return 0
        }
    }

    private static let monthStarTable: [[Int]] = [
        [8, 7, 6, 5, 4, 3, 2, 1, 9, 8, 7, 6],
        [2, 1, 9, 8, 7, 6, 5, 4, 3, 2, 1, 9],
        [5, 4, 3, 2, 1, 9, 8, 7, 6, 5, 4, 3],
    ]

    private static func risshunDate(for year: Int) -> Int {
        return 4
    }

    // MARK: - Direction Helpers

    /// Find where 五黄土星 sits this year (to mark as 五黄殺)
    private static func goouDirection(for date: Date) -> String {
        let yearly = yearStar(for: date)
        let pos = gridPosition(of: .goouDosei, centralStar: yearly)
        switch pos {
        case 1: return "北"
        case 2: return "南西"
        case 3: return "東"
        case 4: return "南東"
        case 5: return "中央"
        case 6: return "北西"
        case 7: return "西"
        case 8: return "北東"
        case 9: return "南"
        default: return "中央"
        }
    }

    // MARK: - Advice Generator

    private static func dailyAdvice(
        honmeisei: NineStarKiStar,
        daily: NineStarKiStar,
        relation: FiveElementRelation,
        score: Int
    ) -> String {
        let starName = honmeisei.shortName
        let dailyName = daily.shortName

        switch relation {
        case .generated:
            return "\(dailyName)の\(daily.element)の気が\(starName)のあなたを育む日。周囲からの支援を素直に受け取ると大きく伸びます。感謝の気持ちを言葉にすると更に吉"
        case .generating:
            return "\(starName)のあなたの\(honmeisei.element)の気が\(dailyName)を生む日。人のために動くことが巡り巡って自分に返ります。教える・助ける場面で力を発揮"
        case .same:
            return "\(starName)と\(dailyName)は同じ\(honmeisei.element)の気。穏やかな共鳴の日。自分のペースを大切に、焦らず着実に進むと吉"
        case .controlling:
            return "\(starName)のあなたの\(honmeisei.element)が\(dailyName)の\(daily.element)を剋す日。リーダーシップを発揮しやすい反面、押しが強くなりすぎないよう注意"
        case .controlled:
            return "\(dailyName)の\(daily.element)の気が\(starName)のあなたを試す日。無理をせず守りの姿勢が吉。大きな決断は別の日に回すのが賢明"
        }
    }
}
