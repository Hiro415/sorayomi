import Foundation

/// 星座占いエンジン
/// Calculates zodiac signs, decans, planetary aspects, daily horoscope energy,
/// and inter-sign compatibility using real Western astrology principles.
struct ZodiacCalculator {

    // MARK: - Data Structures

    struct DailyHoroscope {
        let sign: ZodiacSign
        let date: Date
        let overallScore: Int          // 1-5
        let loveScore: Int             // 1-5
        let workScore: Int             // 1-5
        let moneyScore: Int            // 1-5
        let healthScore: Int           // 1-5
        let luckyColor: String
        let luckyNumber: Int
        let luckyDirection: String
        let planetaryInfluence: String // 今日の惑星の影響
        let elementHarmony: String     // エレメントの調和状態
        let advice: String
    }

    struct ZodiacCompatibility {
        let sign1: ZodiacSign
        let sign2: ZodiacSign
        let overallScore: Int          // 1-5
        let loveScore: Int
        let friendshipScore: Int
        let workScore: Int
        let description: String
        let advice: String
    }

    // MARK: - Basic Calculation

    /// Determine the zodiac sign for a given birthday.
    static func calculate(from date: Date) -> ZodiacSign {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        switch (month, day) {
        case (3, 21...31), (4, 1...19):   return .aries
        case (4, 20...30), (5, 1...20):   return .taurus
        case (5, 21...31), (6, 1...21):   return .gemini
        case (6, 22...30), (7, 1...22):   return .cancer
        case (7, 23...31), (8, 1...22):   return .leo
        case (8, 23...31), (9, 1...22):   return .virgo
        case (9, 23...30), (10, 1...23):  return .libra
        case (10, 24...31), (11, 1...22): return .scorpio
        case (11, 23...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19):  return .capricorn
        case (1, 20...31), (2, 1...18):   return .aquarius
        case (2, 19...29), (3, 1...20):   return .pisces
        default:                           return .aries
        }
    }

    /// Get the current zodiac season (what sign the sun is currently in).
    static func currentSeason(on date: Date = Date()) -> ZodiacSign {
        return calculate(from: date)
    }

    // MARK: - Decan Calculation

    /// Calculate which decan (1st, 2nd, 3rd) a birthday falls into.
    static func decan(from date: Date) -> ZodiacDecan {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Calculate approximate degree within the sign (0-29)
        let sign = calculate(from: date)
        let degree = approximateDegree(month: month, day: day, sign: sign)

        if degree < 10 {
            return .first
        } else if degree < 20 {
            return .second
        } else {
            return .third
        }
    }

    /// Sub-ruler planet for the decan
    static func decanSubRuler(sign: ZodiacSign, decan: ZodiacDecan) -> ZodiacPlanet {
        // Traditional decan rulers follow the element triplicities
        let elementSigns: [ZodiacSign]
        switch sign.element {
        case .fire:  elementSigns = [.aries, .leo, .sagittarius]
        case .earth: elementSigns = [.taurus, .virgo, .capricorn]
        case .air:   elementSigns = [.gemini, .libra, .aquarius]
        case .water: elementSigns = [.cancer, .scorpio, .pisces]
        }

        // Find position in element group
        guard let baseIndex = elementSigns.firstIndex(of: sign) else {
            return sign.rulingPlanet
        }

        let decanIndex = (baseIndex + (decan.rawValue - 1)) % 3
        return elementSigns[decanIndex].rulingPlanet
    }

    /// Description of the decan personality modifier
    static func decanDescription(sign: ZodiacSign, decan: ZodiacDecan) -> String {
        let subRuler = decanSubRuler(sign: sign, decan: decan)
        let base = sign.japaneseName

        switch decan {
        case .first:
            return "\(base)の中で最も純粋な\(sign.element.japaneseName)のエネルギーを持つ。\(sign.rulingPlanet.japaneseName)の影響が最も強い"
        case .second:
            return "\(base)に\(subRuler.japaneseName)の影響が加わり、より深みと複雑さを持つ"
        case .third:
            return "\(base)に\(subRuler.japaneseName)の知恵が融合し、成熟した表現力を発揮する"
        }
    }

    // MARK: - Daily Horoscope

    /// Generate today's horoscope for a given sign using real astrological calculations.
    static func dailyHoroscope(for sign: ZodiacSign, on date: Date = Date()) -> DailyHoroscope {
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let currentSeason = currentSeason(on: date)

        // Element harmony with current solar transit
        let elementHarmony = elementRelationScore(sign.element, currentSeason.element)

        // Planetary day influence (each day of week ruled by a planet)
        let weekday = calendar.component(.weekday, from: date)
        let dayPlanet = planetaryDay(weekday: weekday)
        let planetBonus = planetaryAffinity(dayPlanet: dayPlanet, signRuler: sign.rulingPlanet)

        // Base scores from deterministic seed
        let seed = (dayOfYear * 97) + (year * 13) + (sign.zodiacIndex * 41)

        let baseOverall = clampScore(3 + elementHarmony + planetBonus)
        let baseLove = clampScore(seededScore(seed, offset: 1) + (sign.element == .water ? 1 : 0))
        let baseWork = clampScore(seededScore(seed, offset: 2) + (sign.element == .earth ? 1 : 0))
        let baseMoney = clampScore(seededScore(seed, offset: 3) + planetBonus)
        let baseHealth = clampScore(seededScore(seed, offset: 4) + elementHarmony)

        let luckyColor = dailyLuckyColor(seed: seed, sign: sign)
        let luckyNumber = ((seed + sign.luckyNumber) % 9) + 1
        let luckyDirection = dailyLuckyDirection(seed: seed)

        let planetaryInfluence = "\(dayPlanet.japaneseName)の日。\(dayPlanet.influence)のエネルギーが流れる"
        let elementHarmonyDesc = elementHarmonyDescription(sign.element, currentSeason.element)

        let advice = dailyAdvice(sign: sign, overall: baseOverall, currentSeason: currentSeason)

        return DailyHoroscope(
            sign: sign,
            date: date,
            overallScore: baseOverall,
            loveScore: baseLove,
            workScore: baseWork,
            moneyScore: baseMoney,
            healthScore: baseHealth,
            luckyColor: luckyColor,
            luckyNumber: luckyNumber,
            luckyDirection: luckyDirection,
            planetaryInfluence: planetaryInfluence,
            elementHarmony: elementHarmonyDesc,
            advice: advice
        )
    }

    /// Rank all 12 signs for today
    static func dailyRanking(on date: Date = Date()) -> [(sign: ZodiacSign, score: Int)] {
        ZodiacSign.allCases
            .map { sign in
                let horoscope = dailyHoroscope(for: sign, on: date)
                return (sign: sign, score: horoscope.overallScore)
            }
            .sorted { $0.score > $1.score }
    }

    // MARK: - Compatibility

    /// Calculate compatibility between two zodiac signs
    static func compatibility(between sign1: ZodiacSign, and sign2: ZodiacSign) -> ZodiacCompatibility {
        let elementScore = elementRelationScore(sign1.element, sign2.element)
        let modalityScore = modalityRelationScore(sign1.modality, sign2.modality)

        // Angular relationship (aspect) between signs
        let angleDiff = abs(sign1.zodiacIndex - sign2.zodiacIndex)
        let aspectScore = aspectRelationScore(angleDiff)

        let overall = clampScore(3 + elementScore + aspectScore)
        let love = clampScore(3 + elementScore + (sign1.element == .water || sign2.element == .water ? 1 : 0))
        let friendship = clampScore(3 + aspectScore + modalityScore)
        let work = clampScore(3 + modalityScore + (sign1.element == .earth || sign2.element == .earth ? 1 : 0))

        let description = compatibilityDescription(sign1: sign1, sign2: sign2, score: overall)
        let advice = compatibilityAdvice(sign1: sign1, sign2: sign2, score: overall)

        return ZodiacCompatibility(
            sign1: sign1,
            sign2: sign2,
            overallScore: overall,
            loveScore: love,
            friendshipScore: friendship,
            workScore: work,
            description: description,
            advice: advice
        )
    }

    // MARK: - Private Helpers

    private static func approximateDegree(month: Int, day: Int, sign: ZodiacSign) -> Int {
        // Start dates for each sign
        let startDays: [(month: Int, day: Int)] = [
            (3, 21), (4, 20), (5, 21), (6, 22), (7, 23), (8, 23),
            (9, 23), (10, 24), (11, 23), (12, 22), (1, 20), (2, 19)
        ]
        let start = startDays[sign.zodiacIndex]
        let startCal = Calendar(identifier: .gregorian)

        var components = DateComponents()
        components.year = 2024
        components.month = start.month
        components.day = start.day
        let startDate = startCal.date(from: components) ?? Date()

        components.month = month
        components.day = day
        let birthday = startCal.date(from: components) ?? Date()

        let diff = startCal.dateComponents([.day], from: startDate, to: birthday).day ?? 0
        return max(0, min(29, (diff + 30) % 30))
    }

    /// Planetary day rulers (Chaldean order)
    private static func planetaryDay(weekday: Int) -> ZodiacPlanet {
        // Sunday=1, Monday=2, ..., Saturday=7
        switch weekday {
        case 1: return .sun
        case 2: return .moon
        case 3: return .mars
        case 4: return .mercury
        case 5: return .jupiter
        case 6: return .venus
        case 7: return .saturn
        default: return .sun
        }
    }

    /// Affinity between today's planetary ruler and the sign's ruler
    private static func planetaryAffinity(dayPlanet: ZodiacPlanet, signRuler: ZodiacPlanet) -> Int {
        if dayPlanet == signRuler { return 2 }

        // Benefic planets (Jupiter, Venus) boost everyone slightly
        if dayPlanet == .jupiter || dayPlanet == .venus { return 1 }

        // Malefic planets (Saturn, Mars) challenge slightly
        if dayPlanet == .saturn || dayPlanet == .mars { return -1 }

        return 0
    }

    /// Element relationship score (-1 to +2)
    private static func elementRelationScore(_ e1: ZodiacElement, _ e2: ZodiacElement) -> Int {
        if e1 == e2 { return 2 }
        switch (e1, e2) {
        case (.fire, .air), (.air, .fire): return 1
        case (.earth, .water), (.water, .earth): return 1
        case (.fire, .water), (.water, .fire): return -1
        case (.earth, .air), (.air, .earth): return -1
        default: return 0
        }
    }

    /// Modality relationship score
    private static func modalityRelationScore(_ m1: ZodiacModality, _ m2: ZodiacModality) -> Int {
        if m1 == m2 { return 0 } // Same modality = tension (square)
        return 1 // Different modality = easier flow
    }

    /// Aspect score from angular difference (in zodiac positions, 0-11)
    private static func aspectRelationScore(_ diff: Int) -> Int {
        let normalizedDiff = min(diff, 12 - diff)
        switch normalizedDiff {
        case 0:  return 1   // Conjunction - powerful
        case 1:  return -1  // Semi-sextile - mild tension
        case 2:  return 1   // Sextile - harmonious
        case 3:  return -1  // Square - challenging
        case 4:  return 2   // Trine - most harmonious
        case 5:  return 0   // Quincunx - awkward
        case 6:  return 0   // Opposition - polar tension but attraction
        default: return 0
        }
    }

    private static func seededScore(_ seed: Int, offset: Int) -> Int {
        let raw = ((seed + offset * 37) % 5) - 2 // -2 to +2
        return raw
    }

    private static func clampScore(_ score: Int) -> Int {
        max(1, min(5, score))
    }

    private static let luckyColors = [
        "朱色", "金色", "藍色", "若草色", "琥珀色", "桜色",
        "薄墨色", "山吹色", "紫紺", "錆朱", "松葉色", "白銀",
        "珊瑚色", "藤色", "浅葱色", "瑠璃色"
    ]

    private static let luckyDirections = [
        "東", "東南", "南", "南西", "西", "北西", "北", "北東"
    ]

    private static func dailyLuckyColor(seed: Int, sign: ZodiacSign) -> String {
        let idx = ((seed + sign.zodiacIndex * 7) % luckyColors.count + luckyColors.count) % luckyColors.count
        return luckyColors[idx]
    }

    private static func dailyLuckyDirection(seed: Int) -> String {
        let idx = ((seed * 3 + 17) % luckyDirections.count + luckyDirections.count) % luckyDirections.count
        return luckyDirections[idx]
    }

    private static func elementHarmonyDescription(_ userElement: ZodiacElement, _ seasonElement: ZodiacElement) -> String {
        if userElement == seasonElement {
            return "同じ\(userElement.japaneseName)のエレメント同士。エネルギーが共鳴し、自分らしさが最も発揮しやすい時期"
        }
        switch (userElement, seasonElement) {
        case (.fire, .air), (.air, .fire):
            return "火と風の調和。アイデアが広がり、行動力が増す好調期"
        case (.earth, .water), (.water, .earth):
            return "地と水の調和。着実な成長と感受性が響き合う安定期"
        case (.fire, .water), (.water, .fire):
            return "火と水の緊張。情熱と感情のバランスを意識することで成長の機会に"
        case (.earth, .air), (.air, .earth):
            return "地と風の緊張。現実と理想の間で新しい視点を取り入れるチャンス"
        case (.fire, .earth), (.earth, .fire):
            return "火と地の組み合わせ。情熱を形にする実行力が高まる時期"
        case (.air, .water), (.water, .air):
            return "風と水の組み合わせ。知性と感性が交差し、深い洞察が得られる時期"
        default:
            return "穏やかなエネルギーの流れ"
        }
    }

    private static func dailyAdvice(sign: ZodiacSign, overall: Int, currentSeason: ZodiacSign) -> String {
        if overall >= 4 {
            return "\(sign.rulingPlanet.japaneseName)の追い風を受けて運気上昇中。\(sign.personalityKeywords.first ?? "")を活かして積極的に動くと大きな成果に繋がります"
        } else if overall >= 3 {
            return "穏やかな星の配置。\(currentSeason.japaneseName)シーズンの\(currentSeason.element.japaneseName)のエネルギーを意識しつつ、マイペースに過ごすと良い日"
        } else {
            return "\(sign.element.japaneseName)のエネルギーを内に蓄える日。無理をせず、明日への準備に充てると星の巡りが好転します"
        }
    }

    private static func compatibilityDescription(sign1: ZodiacSign, sign2: ZodiacSign, score: Int) -> String {
        if score >= 4 {
            return "\(sign1.japaneseName)と\(sign2.japaneseName)は\(sign1.element.japaneseName)と\(sign2.element.japaneseName)の素晴らしい調和。互いの長所を引き出し合える最高の組み合わせ"
        } else if score >= 3 {
            return "\(sign1.japaneseName)と\(sign2.japaneseName)はバランスの取れた関係。お互いの違いを楽しみながら成長できる良い縁"
        } else {
            return "\(sign1.japaneseName)と\(sign2.japaneseName)は\(sign1.element.japaneseName)と\(sign2.element.japaneseName)の刺激的な組み合わせ。互いの違いから学びが多い関係"
        }
    }

    private static func compatibilityAdvice(sign1: ZodiacSign, sign2: ZodiacSign, score: Int) -> String {
        if score >= 4 {
            return "自然体でいることが最良。互いの空間を尊重しつつ、共通の目標を持つとさらに絆が深まります"
        } else if score >= 3 {
            return "相手の\(sign2.modality.japaneseName)の特質を理解し、テンポを合わせることで関係がスムーズに"
        } else {
            return "相手の\(sign2.element.japaneseName)の価値観を尊重し、違いを個性として受け入れると関係が好転します"
        }
    }
}
