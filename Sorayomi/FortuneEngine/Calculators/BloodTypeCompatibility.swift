import Foundation

// MARK: - Data Structures

struct BloodTypeCompatibilityData {
    let score: Int // 1-5
    let description: String
    let loveDescription: String
}

struct BloodTypeLoveSubScores {
    let communication: Int    // 1-5
    let values: Int           // 1-5
    let passion: Int          // 1-5
    let stability: Int        // 1-5

    var overall: Int {
        let avg = Double(communication + values + passion + stability) / 4.0
        return Int(avg.rounded())
    }
}

struct BloodTypeDailyFortune {
    let overall: Int   // 1-5
    let love: Int      // 1-5
    let work: Int      // 1-5
    let money: Int     // 1-5
    let luckyColor: String
    let luckyDirection: String
    let oneLiner: String
    let rokuyo: Rokuyo
    let dailyStar: NineStarKiStar
    let solarTerm: String
    let universalDay: Int
}

struct BloodTypeRanking {
    struct Entry: Identifiable {
        let id = UUID()
        let bloodType: BloodType
        let score: Int
        let oneLiner: String
        let rank: Int
    }
    let entries: [Entry]
    let date: Date
}

// MARK: - BloodTypeCompatibility

enum BloodTypeCompatibility {

    static func compatibility(between type1: BloodType, and type2: BloodType) -> BloodTypeCompatibilityData {
        let key = pairKey(type1, type2)
        return compatibilityMatrix[key]!
    }

    static func loveSubScores(between type1: BloodType, and type2: BloodType) -> BloodTypeLoveSubScores {
        let key = pairKey(type1, type2)
        return loveMatrix[key]!
    }

    static func dailyFortune(for bloodType: BloodType, on date: Date = Date()) -> BloodTypeDailyFortune {
        let rokuyo = RokuyoCalculator.calculate(from: date)
        let dailyStar = NineStarKiCalculator.dailyStar(for: date)
        let seasonal = SeasonalContext.from(date: date)
        let universalDay = calculateUniversalDay(date)

        let rokuyoScores = rokuyoAffinity(rokuyo: rokuyo, bloodType: bloodType)
        let starScores = starAffinity(star: dailyStar, bloodType: bloodType)
        let seasonMod = seasonAffinity(season: seasonal.season, bloodType: bloodType)
        let numberScores = numberAffinity(universalDay: universalDay, bloodType: bloodType)

        let overall = clampScore(rokuyoScores.overall + starScores.overall + seasonMod + numberScores.overall)
        let love = clampScore(rokuyoScores.love + starScores.love + seasonMod + numberScores.love)
        let work = clampScore(rokuyoScores.work + starScores.work + seasonMod + numberScores.work)
        let money = clampScore(rokuyoScores.money + starScores.money + seasonMod + numberScores.money)

        let luckyColor = dailyLuckyColor(star: dailyStar, bloodType: bloodType)
        let luckyDirection = dailyStar.direction
        let oneLiner = dailyOneLiner(overall: overall, bloodType: bloodType)

        return BloodTypeDailyFortune(
            overall: overall, love: love, work: work, money: money,
            luckyColor: luckyColor, luckyDirection: luckyDirection,
            oneLiner: oneLiner, rokuyo: rokuyo, dailyStar: dailyStar,
            solarTerm: seasonal.solarTerm, universalDay: universalDay
        )
    }

    static func dailyRanking(on date: Date = Date()) -> BloodTypeRanking {
        let fortunes = BloodType.allCases.map { type in
            (type: type, fortune: dailyFortune(for: type, on: date))
        }
        let sorted = fortunes.sorted { $0.fortune.overall > $1.fortune.overall }
        let entries = sorted.enumerated().map { index, item in
            BloodTypeRanking.Entry(
                bloodType: item.type,
                score: item.fortune.overall,
                oneLiner: item.fortune.oneLiner,
                rank: index + 1
            )
        }
        return BloodTypeRanking(entries: entries, date: date)
    }

    // MARK: - Composite Helpers

    private struct CategoryScores {
        var overall: Int; var love: Int; var work: Int; var money: Int
    }

    private static func rokuyoAffinity(rokuyo: Rokuyo, bloodType: BloodType) -> CategoryScores {
        let base = rokuyo.auspiciousnessScore
        let modifier: Int
        switch (bloodType, rokuyo) {
        case (.a, .taian), (.a, .tomobiki):   modifier = 1
        case (.a, .butsumetsu):                modifier = -1
        case (.b, .senshou):                   modifier = 1
        case (.b, .senbu):                     modifier = -1
        case (.o, .taian):                     modifier = 1
        case (.o, .shakkou):                   modifier = -1
        case (.ab, .shakkou):                  modifier = 1
        case (.ab, .butsumetsu):               modifier = 0
        default:                               modifier = 0
        }
        let adjusted = max(1, min(5, base + modifier))
        let loveMod = rokuyo == .tomobiki ? 1 : 0
        let workMod = rokuyo == .senshou ? 1 : 0
        let moneyMod = rokuyo == .taian ? 1 : 0
        return CategoryScores(
            overall: adjusted,
            love: max(1, min(5, adjusted + loveMod)),
            work: max(1, min(5, adjusted + workMod)),
            money: max(1, min(5, adjusted + moneyMod))
        )
    }

    private static func starAffinity(star: NineStarKiStar, bloodType: BloodType) -> CategoryScores {
        let bloodElement: String
        switch bloodType {
        case .a: bloodElement = "木"; case .b: bloodElement = "火"
        case .o: bloodElement = "土"; case .ab: bloodElement = "金"
        }
        let relationship = elementRelationship(from: star.element, to: bloodElement)
        let base = 3 + relationship
        let moneyBoost = (star == .roppakuKinsei || star == .shichisekiKinsei) ? 1 : 0
        let loveBoost = (star == .shichisekiKinsei || star == .shirokuMokusei) ? 1 : 0
        let workBoost = relationship > 0 ? 1 : 0
        return CategoryScores(
            overall: max(1, min(5, base)),
            love: max(1, min(5, base + loveBoost)),
            work: max(1, min(5, base + workBoost)),
            money: max(1, min(5, base + moneyBoost))
        )
    }

    private static func elementRelationship(from e1: String, to e2: String) -> Int {
        let generating = [("木","火"),("火","土"),("土","金"),("金","水"),("水","木")]
        let controlling = [("木","土"),("土","水"),("水","火"),("火","金"),("金","木")]
        if e1 == e2 { return 1 }
        if generating.contains(where: { $0.0 == e1 && $0.1 == e2 }) { return 2 }
        if generating.contains(where: { $0.0 == e2 && $0.1 == e1 }) { return 1 }
        if controlling.contains(where: { $0.0 == e1 && $0.1 == e2 }) { return -1 }
        if controlling.contains(where: { $0.0 == e2 && $0.1 == e1 }) { return -1 }
        return 0
    }

    private static func seasonAffinity(season: String, bloodType: BloodType) -> Int {
        switch (bloodType, season) {
        case (.a, "秋"), (.a, "冬"): return 1
        case (.b, "春"), (.b, "夏"): return 1
        case (.o, "夏"), (.o, "春"): return 1
        case (.ab, "秋"), (.ab, "冬"): return 1
        default: return 0
        }
    }

    private static func numberAffinity(universalDay: Int, bloodType: BloodType) -> CategoryScores {
        let affinity: Int
        switch (bloodType, universalDay) {
        case (.a, 4), (.a, 6), (.a, 2):     affinity = 1
        case (.b, 5), (.b, 3), (.b, 1):     affinity = 1
        case (.o, 1), (.o, 8), (.o, 9):     affinity = 1
        case (.ab, 7), (.ab, 11), (.ab, 2): affinity = 1
        default:                              affinity = 0
        }
        let loveFavor = [2, 6].contains(universalDay) ? 1 : 0
        let workFavor = [1, 4, 8].contains(universalDay) ? 1 : 0
        let moneyFavor = [8, 4].contains(universalDay) ? 1 : 0
        return CategoryScores(
            overall: affinity,
            love: affinity + loveFavor,
            work: affinity + workFavor,
            money: affinity + moneyFavor
        )
    }

    static func calculateUniversalDay(_ date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return NumerologyCalculator.reduceToSingle(year + month + day)
    }

    private static func clampScore(_ rawSum: Int) -> Int {
        return max(1, min(5, Int((Double(rawSum) / 2.0).rounded())))
    }

    private static func dailyLuckyColor(star: NineStarKiStar, bloodType: BloodType) -> String {
        let starColors: [NineStarKiStar: [String]] = [
            .ippakuSuisei: ["銀白", "水色", "淡い青"],
            .jikokuDosei: ["黒", "焦茶", "深緑"],
            .sanpekiMokusei: ["碧", "若草色", "ミントグリーン"],
            .shirokuMokusei: ["緑", "エメラルド", "若竹色"],
            .goouDosei: ["黄", "山吹色", "ゴールド"],
            .roppakuKinsei: ["白銀", "プラチナ", "アイスブルー"],
            .shichisekiKinsei: ["赤", "ローズ", "珊瑚色"],
            .happakuDosei: ["白", "クリーム", "象牙色"],
            .kyushiKasei: ["紫", "ラベンダー", "藤色"],
        ]
        let colors = starColors[star] ?? ["白"]
        let index: Int
        switch bloodType {
        case .a: index = 0; case .b: index = min(1, colors.count - 1)
        case .o: index = min(2, colors.count - 1); case .ab: index = min(1, colors.count - 1)
        }
        return colors[index]
    }

    private static func dailyOneLiner(overall: Int, bloodType: BloodType) -> String {
        switch (bloodType, overall) {
        case (.a, 5):  return "計画通りに進む最高の日。自信を持って"
        case (.a, 4):  return "丁寧さが評価される好調な日"
        case (.a, 3):  return "慎重さが吉と出る日。焦らずに"
        case (.a, 2):  return "無理せず自分のペースを守ると◎"
        case (.a, 1):  return "静かに英気を養う日。明日に備えて"
        case (.b, 5):  return "直感が冴え渡る最高の日。思い切って"
        case (.b, 4):  return "好奇心が良い出会いを呼ぶ日"
        case (.b, 3):  return "マイペースが功を奏する日"
        case (.b, 2):  return "ペースを守れば大丈夫"
        case (.b, 1):  return "周囲との足並みを意識すると◎"
        case (.o, 5):  return "リーダーシップ全開の最高の日"
        case (.o, 4):  return "行動力が成果を引き寄せる日"
        case (.o, 3):  return "おおらかさが周囲を和ませる日"
        case (.o, 2):  return "細部にも目を配ると吉"
        case (.o, 1):  return "エネルギー充電日。ゆったりと"
        case (.ab, 5): return "知性と感性が最高に噛み合う日"
        case (.ab, 4): return "分析力を活かせる好調な日"
        case (.ab, 3): return "バランス感覚が光る日"
        case (.ab, 2): return "感情の波に注意。冷静さがカギ"
        case (.ab, 1): return "一人の時間で感性を充電する日"
        default:       return "自分の型の長所を信じて過ごしましょう"
        }
    }

    private static func pairKey(_ t1: BloodType, _ t2: BloodType) -> String {
        "\(t1.rawValue)_\(t2.rawValue)"
    }

    // MARK: - Compatibility Matrix

    private static let compatibilityMatrix: [String: BloodTypeCompatibilityData] = [
        "A_A":  BloodTypeCompatibilityData(score: 3, description: "価値観が近く安心感がある。ただし互いに気を遣いすぎて疲れることも", loveDescription: "同じ几帳面さゆえに理解し合えるが、どちらも受け身になりやすい。時には思い切った行動を"),
        "A_B":  BloodTypeCompatibilityData(score: 2, description: "正反対の性質が新鮮だが、すれ違いが起きやすい組み合わせ", loveDescription: "A型の繊細さとB型の自由さがぶつかりやすい。互いの「違い」を魅力と捉える心の余裕が鍵"),
        "A_O":  BloodTypeCompatibilityData(score: 4, description: "O型のおおらかさがA型の繊細さを包み込む。補い合える良い関係", loveDescription: "O型の包容力にA型が安心して心を開ける。自然体でいられる心地よい関係が築きやすい"),
        "A_AB": BloodTypeCompatibilityData(score: 4, description: "AB型がA型の几帳面さを理解し尊重できる。知的な結びつきが強い", loveDescription: "AB型の多面性がA型の真面目さに新しい風を送る。知的な会話が二人の絆を深める"),
        "B_A":  BloodTypeCompatibilityData(score: 2, description: "自由を愛するB型と秩序を重んじるA型。歩み寄りの努力が必要", loveDescription: "B型の奔放さにA型が振り回されがち。B型が少し歩調を合わせるだけで関係が大きく改善"),
        "B_B":  BloodTypeCompatibilityData(score: 3, description: "互いの自由を尊重し合える気楽な関係。ただしすれ違いも起きやすい", loveDescription: "お互いにマイペースで心地よいが、どちらも自分の世界を優先しがち。共有の時間を意識して"),
        "B_O":  BloodTypeCompatibilityData(score: 5, description: "最高の相性。O型の包容力がB型の自由さを受け止め、互いに高め合える", loveDescription: "O型がB型の個性をまるごと受け入れ、B型はO型の優しさに安心する。最も自然体でいられる組み合わせ"),
        "B_AB": BloodTypeCompatibilityData(score: 4, description: "AB型の多面性がB型の個性を受け入れる。意外と波長が合う", loveDescription: "互いの個性を面白がれる関係。AB型の知性とB型の直感が化学反応を起こす"),
        "O_A":  BloodTypeCompatibilityData(score: 4, description: "O型が頼れるリーダーシップを発揮し、A型が細やかにサポートする好バランス", loveDescription: "O型の力強さにA型が惹かれ、A型の誠実さにO型が信頼を寄せる。王道のカップル"),
        "O_B":  BloodTypeCompatibilityData(score: 5, description: "O型の寛容さがB型の自由を最大限に活かす。最高の組み合わせの一つ", loveDescription: "B型の予測不能な魅力にO型が夢中に。O型の安定感がB型に安心を与える理想的な関係"),
        "O_O":  BloodTypeCompatibilityData(score: 3, description: "リーダー同士で意見がぶつかることも。互いの領域を尊重すると◎", loveDescription: "パワフルな二人だからこそ火花が散ることも。主導権争いを避け、対等なパートナーシップを"),
        "O_AB": BloodTypeCompatibilityData(score: 2, description: "O型の直球とAB型の複雑さが噛み合いにくい。理解に時間がかかる", loveDescription: "O型のストレートな愛情表現にAB型が戸惑うことも。距離感のすり合わせが大切"),
        "AB_A": BloodTypeCompatibilityData(score: 4, description: "AB型の知性とA型の誠実さが調和。穏やかで深い関係を築ける", loveDescription: "静かだが確かな絆が生まれやすい。言葉にしなくても通じ合える安心感がある"),
        "AB_B": BloodTypeCompatibilityData(score: 4, description: "互いの個性を認め合える。AB型がB型の自由さを知的に楽しめる", loveDescription: "B型の情熱にAB型が新鮮な刺激を受ける。互いの世界観を広げ合える関係"),
        "AB_O": BloodTypeCompatibilityData(score: 2, description: "思考パターンの違いが大きい。歩み寄りの意識が特に重要", loveDescription: "O型の直球愛とAB型のクール愛。温度差を感じやすいが、理解が深まれば強い絆に"),
        "AB_AB": BloodTypeCompatibilityData(score: 3, description: "高い知性で通じ合えるが、互いに踏み込まず距離感が生まれやすい", loveDescription: "知的な会話は最高に楽しいが、感情表現が控えめになりがち。想いは言葉にして伝えて"),
    ]

    // MARK: - Love Sub-Scores Matrix

    private static let loveMatrix: [String: BloodTypeLoveSubScores] = [
        "A_A":  BloodTypeLoveSubScores(communication: 4, values: 5, passion: 2, stability: 4),
        "A_B":  BloodTypeLoveSubScores(communication: 2, values: 2, passion: 4, stability: 2),
        "A_O":  BloodTypeLoveSubScores(communication: 4, values: 4, passion: 3, stability: 5),
        "A_AB": BloodTypeLoveSubScores(communication: 4, values: 4, passion: 3, stability: 4),
        "B_A":  BloodTypeLoveSubScores(communication: 2, values: 2, passion: 4, stability: 2),
        "B_B":  BloodTypeLoveSubScores(communication: 3, values: 3, passion: 4, stability: 2),
        "B_O":  BloodTypeLoveSubScores(communication: 4, values: 4, passion: 5, stability: 5),
        "B_AB": BloodTypeLoveSubScores(communication: 3, values: 3, passion: 4, stability: 4),
        "O_A":  BloodTypeLoveSubScores(communication: 4, values: 4, passion: 3, stability: 5),
        "O_B":  BloodTypeLoveSubScores(communication: 4, values: 4, passion: 5, stability: 5),
        "O_O":  BloodTypeLoveSubScores(communication: 3, values: 4, passion: 4, stability: 3),
        "O_AB": BloodTypeLoveSubScores(communication: 2, values: 2, passion: 3, stability: 2),
        "AB_A": BloodTypeLoveSubScores(communication: 4, values: 4, passion: 3, stability: 4),
        "AB_B": BloodTypeLoveSubScores(communication: 3, values: 3, passion: 4, stability: 4),
        "AB_O": BloodTypeLoveSubScores(communication: 2, values: 2, passion: 3, stability: 2),
        "AB_AB": BloodTypeLoveSubScores(communication: 5, values: 4, passion: 2, stability: 3),
    ]
}
