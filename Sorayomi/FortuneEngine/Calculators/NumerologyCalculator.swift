import Foundation

/// Calculates numerology numbers from birthday using Pythagorean method.
/// Includes Life Path, Birthday, Personal cycles (Year/Month/Day),
/// Universal cycles, Pinnacle & Challenge stages, daily energy profiles,
/// and number compatibility — all based on established numerological systems.
struct NumerologyCalculator {

    // MARK: - Core Numbers

    /// Calculate the Life Path Number from a birthday.
    /// Reduces month + day + year digits to a single digit (or master number 11, 22, 33).
    static func lifePathNumber(from date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let monthReduced = reduceToSingle(month)
        let dayReduced = reduceToSingle(day)
        let yearReduced = reduceToSingle(year)

        return reduceToSingle(monthReduced + dayReduced + yearReduced)
    }

    /// Calculate the Birthday Number (just the day reduced).
    static func birthdayNumber(from date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: date)
        return reduceToSingle(day)
    }

    // MARK: - Personal Cycles

    /// Calculate the Personal Year Number for a given year.
    /// Personal Year = reduce(birth month + birth day + current year)
    static func personalYearNumber(from birthday: Date, year: Int) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)
        return reduceToSingle(month + day + reduceToSingle(year))
    }

    /// Calculate the Personal Month Number.
    static func personalMonthNumber(from birthday: Date, year: Int, month: Int) -> Int {
        let personalYear = personalYearNumber(from: birthday, year: year)
        return reduceToSingle(personalYear + month)
    }

    /// Calculate the Personal Day Number.
    static func personalDayNumber(from birthday: Date, on date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let personalMonth = personalMonthNumber(from: birthday, year: year, month: month)
        return reduceToSingle(personalMonth + day)
    }

    // MARK: - Universal Cycles

    /// Universal Day Number — the cosmic energy of today, shared by everyone.
    static func universalDayNumber(for date: Date = Date()) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return reduceToSingle(reduceToSingle(year) + reduceToSingle(month) + reduceToSingle(day))
    }

    /// Universal Month Number.
    static func universalMonthNumber(for date: Date = Date()) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return reduceToSingle(reduceToSingle(year) + reduceToSingle(month))
    }

    /// Universal Year Number.
    static func universalYearNumber(for date: Date = Date()) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        return reduceToSingle(year)
    }

    // MARK: - Pinnacle & Challenge Numbers

    /// Calculate the four Pinnacle Numbers (人生の転換期).
    /// Pinnacle 1: month + day (birth ~ 36 - LP)
    /// Pinnacle 2: day + year (next 9 years)
    /// Pinnacle 3: P1 + P2 (next 9 years)
    /// Pinnacle 4: month + year (rest of life)
    static func pinnacles(from birthday: Date) -> [NumerologyProfile.LifeStage] {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: birthday)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)
        let lp = lifePathNumber(from: birthday)

        let p1 = reduceToSingle(month + day)
        let p2 = reduceToSingle(day + reduceToSingle(year))
        let p3 = reduceToSingle(p1 + p2)
        let p4 = reduceToSingle(month + reduceToSingle(year))

        // First pinnacle ends at age 36 - LP (or max(27, 36-LP))
        let lpBase = (lp == 11 || lp == 22 || lp == 33) ? reduceToSingleStrict(lp) : lp
        let firstEnd = max(27, 36 - lpBase)
        let secondEnd = firstEnd + 9
        let thirdEnd = secondEnd + 9

        return [
            NumerologyProfile.LifeStage(
                name: "第一転換期",
                number: p1,
                ageRange: "0〜\(firstEnd)歳",
                description: pinnacleDescription(p1, stage: 1)
            ),
            NumerologyProfile.LifeStage(
                name: "第二転換期",
                number: p2,
                ageRange: "\(firstEnd + 1)〜\(secondEnd)歳",
                description: pinnacleDescription(p2, stage: 2)
            ),
            NumerologyProfile.LifeStage(
                name: "第三転換期",
                number: p3,
                ageRange: "\(secondEnd + 1)〜\(thirdEnd)歳",
                description: pinnacleDescription(p3, stage: 3)
            ),
            NumerologyProfile.LifeStage(
                name: "第四転換期",
                number: p4,
                ageRange: "\(thirdEnd + 1)歳〜",
                description: pinnacleDescription(p4, stage: 4)
            ),
        ]
    }

    /// Calculate the three Challenge Numbers (人生の課題).
    /// Challenge 1: |month - day|
    /// Challenge 2: |day - year|
    /// Challenge 3: |C1 - C2|
    static func challenges(from birthday: Date) -> [NumerologyProfile.LifeStage] {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: birthday)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)

        let mr = reduceToSingle(month)
        let dr = reduceToSingle(day)
        let yr = reduceToSingle(year)

        let c1 = reduceToSingle(abs(mr - dr))
        let c2 = reduceToSingle(abs(dr - yr))
        let c3 = reduceToSingle(abs(c1 - c2))

        return [
            NumerologyProfile.LifeStage(
                name: "第一の課題",
                number: c1,
                ageRange: "人生前半",
                description: challengeDescription(c1)
            ),
            NumerologyProfile.LifeStage(
                name: "第二の課題",
                number: c2,
                ageRange: "人生中盤",
                description: challengeDescription(c2)
            ),
            NumerologyProfile.LifeStage(
                name: "生涯の課題",
                number: c3,
                ageRange: "生涯を通じて",
                description: challengeDescription(c3)
            ),
        ]
    }

    // MARK: - Current Pinnacle Stage

    /// Determine which pinnacle stage the person is currently in.
    static func currentPinnacleIndex(birthday: Date, currentDate: Date = Date()) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let birthYear = calendar.component(.year, from: birthday)
        let currentYear = calendar.component(.year, from: currentDate)
        let age = currentYear - birthYear

        let lp = lifePathNumber(from: birthday)
        let lpBase = (lp == 11 || lp == 22 || lp == 33) ? reduceToSingleStrict(lp) : lp
        let firstEnd = max(27, 36 - lpBase)

        if age <= firstEnd { return 0 }
        if age <= firstEnd + 9 { return 1 }
        if age <= firstEnd + 18 { return 2 }
        return 3
    }

    // MARK: - Daily Energy Profile

    /// Comprehensive daily numerology energy profile.
    struct DailyNumerologyEnergy {
        let personalDay: Int
        let personalMonth: Int
        let personalYear: Int
        let universalDay: Int
        let universalMonth: Int
        let universalYear: Int
        let lifePathNumber: Int
        let birthdayNumber: Int
        let overallScore: Int          // 1-5
        let personalUniversalHarmony: NumberHarmony
        let lifePathDayHarmony: NumberHarmony
        let cyclePhase: CyclePhase
        let currentPinnacle: NumerologyProfile.LifeStage
        let currentChallenge: NumerologyProfile.LifeStage
        let luckyHours: [String]
        let advice: String
    }

    enum NumberHarmony: String {
        case perfect = "完全調和"     // same number
        case strong = "強い調和"      // compatible numbers
        case moderate = "普通"        // neutral
        case tension = "緊張"         // challenging
        case masterBoost = "マスター増幅" // master number involved

        var score: Int {
            switch self {
            case .perfect: return 5
            case .strong: return 4
            case .masterBoost: return 4
            case .moderate: return 3
            case .tension: return 2
            }
        }

        var description: String {
            switch self {
            case .perfect: return "パーソナルナンバーとユニバーサルナンバーが完全に共鳴しています"
            case .strong: return "数字のエネルギーが相互に支え合い、追い風が吹いています"
            case .moderate: return "穏やかなエネルギーの日。自分のペースで過ごせます"
            case .tension: return "異なるエネルギーがぶつかる日。柔軟な姿勢が試されます"
            case .masterBoost: return "マスターナンバーの特別な波動が加わり、直感が冴えています"
            }
        }
    }

    enum CyclePhase: String {
        case seedling = "種まき期"     // PY 1-2
        case growth = "成長期"          // PY 3-4
        case turning = "転換期"         // PY 5
        case harvest = "収穫期"         // PY 6-8
        case completion = "完成期"      // PY 9

        var description: String {
            switch self {
            case .seedling: return "新しいものを始め、基盤を育てる時期"
            case .growth: return "創造力を発揮し、根を深く張る時期"
            case .turning: return "変化を受け入れ、新しい方向を模索する時期"
            case .harvest: return "努力の成果を受け取り、豊かさを享受する時期"
            case .completion: return "サイクルを締めくくり、次の準備をする時期"
            }
        }
    }

    /// Generate a comprehensive daily energy profile.
    static func dailyEnergy(birthday: Date, on date: Date = Date()) -> DailyNumerologyEnergy {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        let lp = lifePathNumber(from: birthday)
        let bd = birthdayNumber(from: birthday)
        let pd = personalDayNumber(from: birthday, on: date)
        let pm = personalMonthNumber(from: birthday, year: year, month: month)
        let py = personalYearNumber(from: birthday, year: year)
        let ud = universalDayNumber(for: date)
        let um = universalMonthNumber(for: date)
        let uy = universalYearNumber(for: date)

        let puHarmony = harmony(between: pd, and: ud)
        let lpHarmony = harmony(between: lp, and: pd)

        let baseScore = (puHarmony.score + lpHarmony.score) / 2
        let masterBonus = isMasterNumber(pd) || isMasterNumber(ud) ? 1 : 0
        let overallScore = max(1, min(5, baseScore + masterBonus))

        let phase = cyclePhase(for: py)

        let pins = pinnacles(from: birthday)
        let pinIdx = currentPinnacleIndex(birthday: birthday, currentDate: date)
        let currentPin = pins[pinIdx]

        let chals = challenges(from: birthday)
        let chalIdx = min(chals.count - 1, pinIdx < 2 ? 0 : pinIdx < 3 ? 1 : 2)
        let currentChal = chals[chalIdx]

        let lucky = luckyHours(personalDay: pd, universalDay: ud)

        let advice = dailyAdvice(
            lifePath: lp,
            personalDay: pd,
            universalDay: ud,
            harmony: puHarmony,
            phase: phase
        )

        return DailyNumerologyEnergy(
            personalDay: pd,
            personalMonth: pm,
            personalYear: py,
            universalDay: ud,
            universalMonth: um,
            universalYear: uy,
            lifePathNumber: lp,
            birthdayNumber: bd,
            overallScore: overallScore,
            personalUniversalHarmony: puHarmony,
            lifePathDayHarmony: lpHarmony,
            cyclePhase: phase,
            currentPinnacle: currentPin,
            currentChallenge: currentChal,
            luckyHours: lucky,
            advice: advice
        )
    }

    // MARK: - Number Compatibility

    /// Compatibility between two Life Path numbers (0-100).
    static func compatibility(between num1: Int, and num2: Int) -> (score: Int, description: String) {
        let n1 = baseSingle(num1)
        let n2 = baseSingle(num2)

        if n1 == n2 { return (85, "同じ数字の共鳴。深い理解と強い絆が生まれますが、似すぎて刺激が足りなくなることも") }

        let arch1 = NumerologyProfile.archetype(for: num1)
        if arch1.compatibleNumbers.contains(n2) {
            return (80, "\(num1)と\(num2)は相性の良い数字の組み合わせ。互いのエネルギーが補い合い、自然な調和が生まれます")
        }
        if arch1.challengingNumbers.contains(n2) {
            return (45, "\(num1)と\(num2)は成長を促す緊張の関係。困難はありますが、乗り越えることで互いに大きく成長できます")
        }

        return (65, "\(num1)と\(num2)は穏やかな中立の関係。互いの違いを認め合うことで、新たな視点が生まれます")
    }

    // MARK: - Profile Builder

    /// Build a full numerology profile.
    static func profile(from birthday: Date, currentDate: Date = Date()) -> NumerologyProfile {
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)

        return NumerologyProfile(
            lifePathNumber: lifePathNumber(from: birthday),
            birthdayNumber: birthdayNumber(from: birthday),
            personalYearNumber: personalYearNumber(from: birthday, year: currentYear),
            personalMonthNumber: personalMonthNumber(from: birthday, year: currentYear, month: currentMonth),
            personalDayNumber: personalDayNumber(from: birthday, on: currentDate)
        )
    }

    // MARK: - Digit Reduction

    /// Reduce a number to a single digit, preserving master numbers (11, 22, 33).
    static func reduceToSingle(_ number: Int) -> Int {
        var n = abs(number)
        while n > 9 && n != 11 && n != 22 && n != 33 {
            n = digitSum(n)
        }
        return n
    }

    /// Reduce strictly to single digit (no master preservation).
    static func reduceToSingleStrict(_ number: Int) -> Int {
        var n = abs(number)
        while n > 9 {
            n = digitSum(n)
        }
        return n
    }

    static func isMasterNumber(_ number: Int) -> Bool {
        number == 11 || number == 22 || number == 33
    }

    // MARK: - Private Helpers

    private static func digitSum(_ number: Int) -> Int {
        var sum = 0
        var n = abs(number)
        while n > 0 {
            sum += n % 10
            n /= 10
        }
        return sum
    }

    private static func baseSingle(_ number: Int) -> Int {
        reduceToSingleStrict(number)
    }

    /// Determine the harmony between two numbers.
    private static func harmony(between n1: Int, and n2: Int) -> NumberHarmony {
        if isMasterNumber(n1) || isMasterNumber(n2) {
            return .masterBoost
        }
        let b1 = baseSingle(n1)
        let b2 = baseSingle(n2)

        if b1 == b2 { return .perfect }

        let arch = NumerologyProfile.archetype(for: n1)
        if arch.compatibleNumbers.contains(b2) { return .strong }
        if arch.challengingNumbers.contains(b2) { return .tension }
        return .moderate
    }

    /// Map personal year to cycle phase.
    private static func cyclePhase(for personalYear: Int) -> CyclePhase {
        let base = baseSingle(personalYear)
        switch base {
        case 1, 2: return .seedling
        case 3, 4: return .growth
        case 5:    return .turning
        case 6, 7, 8: return .harvest
        case 9:    return .completion
        default:   return .growth
        }
    }

    /// Calculate lucky hours based on personal and universal day.
    private static func luckyHours(personalDay: Int, universalDay: Int) -> [String] {
        let pdBase = baseSingle(personalDay)
        let udBase = baseSingle(universalDay)

        // Each number resonates with specific hours (rough Chaldean correspondence)
        let pdHours: [Int]
        switch pdBase {
        case 1: pdHours = [7, 10, 19]
        case 2: pdHours = [8, 14, 20]
        case 3: pdHours = [9, 12, 15]
        case 4: pdHours = [6, 13, 18]
        case 5: pdHours = [11, 14, 17]
        case 6: pdHours = [9, 15, 21]
        case 7: pdHours = [7, 16, 22]
        case 8: pdHours = [8, 10, 16]
        case 9: pdHours = [9, 11, 18]
        default: pdHours = [10, 14, 18]
        }

        // Boost hours where PD and UD align
        let sharedHour = (pdBase + udBase) % 12 + 8
        var hours = Set(pdHours)
        hours.insert(min(23, sharedHour))

        return hours.sorted().map { h in
            let formatted = String(format: "%d:00", h)
            return formatted
        }
    }

    /// Generate daily advice.
    private static func dailyAdvice(
        lifePath: Int,
        personalDay: Int,
        universalDay: Int,
        harmony: NumberHarmony,
        phase: CyclePhase
    ) -> String {
        let lpArch = NumerologyProfile.archetype(for: lifePath)
        let pdArch = NumerologyProfile.archetype(for: personalDay)

        switch harmony {
        case .perfect:
            return "パーソナルデイ\(personalDay)とユニバーサルデイ\(universalDay)が完全共鳴。\(lpArch.title)のあなたにとって、\(pdArch.keyword)のエネルギーが最大限に活きる一日。自信を持って行動してください"
        case .strong:
            return "\(pdArch.title)のエネルギーが\(lpArch.title)のあなたを後押しする好調日。\(phase.description)の流れに乗って、\(pdArch.keyword)を意識して過ごすと吉"
        case .masterBoost:
            return "マスターナンバーの特別な波動が流れる日。\(lpArch.title)のあなたの直感が冴え、普段は見えないものが見える特別なタイミング。重要な決断に向いています"
        case .moderate:
            return "穏やかなエネルギーの日。\(lpArch.title)のあなたは\(pdArch.keyword)のテーマを意識しつつ、マイペースで過ごすのが吉。\(phase.description)"
        case .tension:
            return "\(pdArch.title)のエネルギーが\(lpArch.title)のあなたに新たな視点をもたらす挑戦の日。柔軟さを持って対応すれば、大きな気づきと成長が得られます"
        }
    }

    private static func pinnacleDescription(_ number: Int, stage: Int) -> String {
        let arch = NumerologyProfile.archetype(for: number)
        let stageContext: String
        switch stage {
        case 1: stageContext = "人生の基盤が形成される時期"
        case 2: stageContext = "社会との関わりが深まる時期"
        case 3: stageContext = "人生の実りを迎える時期"
        case 4: stageContext = "叡智を活かし円熟する時期"
        default: stageContext = ""
        }
        return "\(stageContext)。\(arch.keyword)のエネルギーが人生を導き、\(arch.title)としての才能が試されます"
    }

    private static func challengeDescription(_ number: Int) -> String {
        switch number {
        case 0: return "全ての課題を内包する特別な数。人生で遭遇するあらゆる挑戦に対応する万能性を養う使命"
        case 1: return "自立心と主体性を培う課題。他者に依存せず自分の足で立つことが求められます"
        case 2: return "協調性と感受性の課題。自分の意見を主張しつつ他者との調和を学びます"
        case 3: return "自己表現と集中力の課題。才能を散漫にせず、一つの形にまとめる力を養います"
        case 4: return "忍耐力と柔軟性の課題。安定を求めつつも変化を受け入れる姿勢が成長の鍵"
        case 5: return "自由と責任のバランスの課題。変化を楽しみながらもコミットメントを学びます"
        case 6: return "愛と自立の課題。他者を助けすぎず、自分も他者も尊重する境界線を学びます"
        case 7: return "信頼と開放の課題。心を開くことへの恐れを乗り越え、深い絆を築く力を養います"
        case 8: return "権力と謙虚さの課題。物質的成功と精神的充足のバランスを取ることが求められます"
        case 9: return "執着と手放しの課題。過去にしがみつかず、流れに身を任せる知恵を学びます"
        default: return "独自の課題を通じて成長する使命を持っています"
        }
    }
}
