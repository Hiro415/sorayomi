import SwiftUI
import Foundation

/// Western zodiac signs with comprehensive astrological properties.
enum ZodiacSign: String, Codable, CaseIterable, Identifiable {
    case aries = "aries"
    case taurus = "taurus"
    case gemini = "gemini"
    case cancer = "cancer"
    case leo = "leo"
    case virgo = "virgo"
    case libra = "libra"
    case scorpio = "scorpio"
    case sagittarius = "sagittarius"
    case capricorn = "capricorn"
    case aquarius = "aquarius"
    case pisces = "pisces"

    var id: String { rawValue }

    // MARK: - Basic Properties

    var japaneseName: String {
        switch self {
        case .aries:       return "おひつじ座"
        case .taurus:      return "おうし座"
        case .gemini:      return "ふたご座"
        case .cancer:      return "かに座"
        case .leo:         return "しし座"
        case .virgo:       return "おとめ座"
        case .libra:       return "てんびん座"
        case .scorpio:     return "さそり座"
        case .sagittarius: return "いて座"
        case .capricorn:   return "やぎ座"
        case .aquarius:    return "みずがめ座"
        case .pisces:      return "うお座"
        }
    }

    var emoji: String {
        switch self {
        case .aries:       return "♈"
        case .taurus:      return "♉"
        case .gemini:      return "♊"
        case .cancer:      return "♋"
        case .leo:         return "♌"
        case .virgo:       return "♍"
        case .libra:       return "♎"
        case .scorpio:     return "♏"
        case .sagittarius: return "♐"
        case .capricorn:   return "♑"
        case .aquarius:    return "♒"
        case .pisces:      return "♓"
        }
    }

    /// Constellation symbol for UI display
    var constellationSymbol: String {
        switch self {
        case .aries:       return "aries"
        case .taurus:      return "taurus"
        case .gemini:      return "gemini"
        case .cancer:      return "cancer"
        case .leo:         return "leo"
        case .virgo:       return "virgo"
        case .libra:       return "libra"
        case .scorpio:     return "scorpio"
        case .sagittarius: return "sagittarius"
        case .capricorn:   return "capricorn"
        case .aquarius:    return "aquarius"
        case .pisces:      return "pisces"
        }
    }

    var element: ZodiacElement {
        switch self {
        case .aries, .leo, .sagittarius:       return .fire
        case .taurus, .virgo, .capricorn:      return .earth
        case .gemini, .libra, .aquarius:       return .air
        case .cancer, .scorpio, .pisces:       return .water
        }
    }

    var modality: ZodiacModality {
        switch self {
        case .aries, .cancer, .libra, .capricorn:         return .cardinal
        case .taurus, .leo, .scorpio, .aquarius:           return .fixed
        case .gemini, .virgo, .sagittarius, .pisces:       return .mutable
        }
    }

    var dateRange: String {
        switch self {
        case .aries:       return "3/21 - 4/19"
        case .taurus:      return "4/20 - 5/20"
        case .gemini:      return "5/21 - 6/21"
        case .cancer:      return "6/22 - 7/22"
        case .leo:         return "7/23 - 8/22"
        case .virgo:       return "8/23 - 9/22"
        case .libra:       return "9/23 - 10/23"
        case .scorpio:     return "10/24 - 11/22"
        case .sagittarius: return "11/23 - 12/21"
        case .capricorn:   return "12/22 - 1/19"
        case .aquarius:    return "1/20 - 2/18"
        case .pisces:      return "2/19 - 3/20"
        }
    }

    // MARK: - Ruling Planets (支配星)

    var rulingPlanet: ZodiacPlanet {
        switch self {
        case .aries:       return .mars
        case .taurus:      return .venus
        case .gemini:      return .mercury
        case .cancer:      return .moon
        case .leo:         return .sun
        case .virgo:       return .mercury
        case .libra:       return .venus
        case .scorpio:     return .pluto
        case .sagittarius: return .jupiter
        case .capricorn:   return .saturn
        case .aquarius:    return .uranus
        case .pisces:      return .neptune
        }
    }

    // MARK: - Personality

    var personalityKeywords: [String] {
        switch self {
        case .aries:       return ["情熱的", "行動力", "開拓者精神"]
        case .taurus:      return ["安定志向", "忍耐力", "感覚的"]
        case .gemini:      return ["知的好奇心", "適応力", "社交的"]
        case .cancer:      return ["共感力", "家庭的", "直感的"]
        case .leo:         return ["リーダーシップ", "創造力", "寛大"]
        case .virgo:       return ["分析力", "几帳面", "奉仕精神"]
        case .libra:       return ["調和", "美意識", "外交的"]
        case .scorpio:     return ["洞察力", "集中力", "探究心"]
        case .sagittarius: return ["冒険心", "楽観的", "哲学的"]
        case .capricorn:   return ["責任感", "実直", "向上心"]
        case .aquarius:    return ["独創性", "博愛精神", "革新的"]
        case .pisces:      return ["感受性", "想像力", "慈悲深い"]
        }
    }

    /// Detailed personality description
    var personalityDescription: String {
        switch self {
        case .aries:       return "火の先鋒として、誰よりも早く行動を起こす開拓者。情熱と勇気で道を切り開き、周囲にエネルギーを与える存在"
        case .taurus:      return "大地に根を張る安定の象徴。五感に優れ、美しいものや心地よいものを大切にする。一度決めたら揺るがない信念の持ち主"
        case .gemini:      return "風のように自由に知識を運ぶ知性の星。二つの顔を持ち、多面的な才能でどんな場にも適応する万能型"
        case .cancer:      return "月に守られた感受性の星。深い愛情と直感力で大切な人を包み込む。記憶と感情の宝庫"
        case .leo:         return "太陽を支配星に持つ王者の星。生まれながらのカリスマ性と創造力で、人々の中心で輝く存在"
        case .virgo:       return "水星の精緻な知性を宿す完璧主義者。細部への目配りと奉仕の心で、世界を整えていく"
        case .libra:       return "金星の美と調和を司る外交官。あらゆる関係のバランスを取り、美しさと公正さを追求する"
        case .scorpio:     return "冥王星の変容の力を宿す探究者。表面の下に秘めた強烈な情熱と洞察力で、真実を見抜く"
        case .sagittarius: return "木星の拡大と冒険の力を持つ哲学者。自由を愛し、広い世界に知恵と楽観を広げていく"
        case .capricorn:   return "土星の規律と忍耐を宿す大器。時間をかけて確実に頂を目指し、揺るぎない実績を築く"
        case .aquarius:    return "天王星の革新の光を持つ先駆者。独自の視点で未来を見通し、誰もが自由になれる世界を描く"
        case .pisces:      return "海王星の神秘と慈悲を宿す夢見る魚。境界を超えた共感力と想像力で、見えない世界を感じ取る"
        }
    }

    // MARK: - Love Tendency (恋愛傾向)

    var loveTendency: String {
        switch self {
        case .aries:       return "情熱的に猛アタック。恋に落ちるのは一瞬、駆け引きは苦手"
        case .taurus:      return "じっくり時間をかけて関係を育む。一途で独占欲も強め"
        case .gemini:      return "知的な会話が恋の入口。飽きっぽいが、理解者には深く惹かれる"
        case .cancer:      return "母性的な深い愛情。家庭を大切にし、相手を包み込むように愛する"
        case .leo:         return "ドラマチックな恋愛を好む。愛情表現が豊かで、相手を特別扱いする"
        case .virgo:       return "控えめだが確実。細かな気遣いで愛を示し、相手の健康まで気にかける"
        case .libra:       return "パートナーシップを最も重視。美しい関係を追求し、一人でいるのが苦手"
        case .scorpio:     return "深く激しい愛。嫉妬深いが、一度愛した相手には絶対的な忠誠を誓う"
        case .sagittarius: return "自由な恋愛を好む。束縛は苦手だが、共に冒険できる相手を求める"
        case .capricorn:   return "慎重に相手を見極める。結婚前提の真剣な交際を重視する"
        case .aquarius:    return "友情から始まる恋。独自の距離感を持ち、精神的な繋がりを重視する"
        case .pisces:      return "ロマンチストで自己犠牲的。理想の恋を夢見て、相手に尽くす"
        }
    }

    // MARK: - Compatibility (星座相性)

    /// Best compatible signs
    var bestCompatible: [ZodiacSign] {
        switch self {
        case .aries:       return [.leo, .sagittarius, .gemini]
        case .taurus:      return [.virgo, .capricorn, .cancer]
        case .gemini:      return [.libra, .aquarius, .aries]
        case .cancer:      return [.scorpio, .pisces, .taurus]
        case .leo:         return [.aries, .sagittarius, .libra]
        case .virgo:       return [.taurus, .capricorn, .cancer]
        case .libra:       return [.gemini, .aquarius, .leo]
        case .scorpio:     return [.cancer, .pisces, .virgo]
        case .sagittarius: return [.aries, .leo, .aquarius]
        case .capricorn:   return [.taurus, .virgo, .pisces]
        case .aquarius:    return [.gemini, .libra, .sagittarius]
        case .pisces:      return [.cancer, .scorpio, .capricorn]
        }
    }

    // MARK: - Theme Colors (星座テーマカラー)

    var themeGradient: [Color] {
        switch element {
        case .fire:
            return [Color(red: 0.95, green: 0.3, blue: 0.2),
                    Color(red: 1.0, green: 0.6, blue: 0.2)]
        case .earth:
            return [Color(red: 0.4, green: 0.55, blue: 0.3),
                    Color(red: 0.7, green: 0.6, blue: 0.35)]
        case .air:
            return [Color(red: 0.35, green: 0.55, blue: 0.85),
                    Color(red: 0.6, green: 0.75, blue: 0.95)]
        case .water:
            return [Color(red: 0.2, green: 0.3, blue: 0.7),
                    Color(red: 0.4, green: 0.5, blue: 0.85)]
        }
    }

    var accentColor: Color {
        switch element {
        case .fire:  return Color(red: 1.0, green: 0.45, blue: 0.2)
        case .earth: return Color(red: 0.6, green: 0.5, blue: 0.3)
        case .air:   return Color(red: 0.5, green: 0.7, blue: 0.95)
        case .water: return Color(red: 0.3, green: 0.45, blue: 0.85)
        }
    }

    // MARK: - Lucky Properties

    var luckyNumber: Int {
        switch self {
        case .aries: return 9
        case .taurus: return 6
        case .gemini: return 5
        case .cancer: return 2
        case .leo: return 1
        case .virgo: return 5
        case .libra: return 6
        case .scorpio: return 8
        case .sagittarius: return 3
        case .capricorn: return 8
        case .aquarius: return 4
        case .pisces: return 7
        }
    }

    var luckyDay: String {
        switch self {
        case .aries: return "火曜日"
        case .taurus: return "金曜日"
        case .gemini: return "水曜日"
        case .cancer: return "月曜日"
        case .leo: return "日曜日"
        case .virgo: return "水曜日"
        case .libra: return "金曜日"
        case .scorpio: return "火曜日"
        case .sagittarius: return "木曜日"
        case .capricorn: return "土曜日"
        case .aquarius: return "土曜日"
        case .pisces: return "木曜日"
        }
    }

    var powerStone: String {
        switch self {
        case .aries: return "ルビー"
        case .taurus: return "エメラルド"
        case .gemini: return "アゲート"
        case .cancer: return "ムーンストーン"
        case .leo: return "サンストーン"
        case .virgo: return "サファイア"
        case .libra: return "ローズクォーツ"
        case .scorpio: return "ガーネット"
        case .sagittarius: return "ターコイズ"
        case .capricorn: return "オニキス"
        case .aquarius: return "アメシスト"
        case .pisces: return "アクアマリン"
        }
    }

    // MARK: - Zodiac Index (for calculation)

    var zodiacIndex: Int {
        switch self {
        case .aries: return 0
        case .taurus: return 1
        case .gemini: return 2
        case .cancer: return 3
        case .leo: return 4
        case .virgo: return 5
        case .libra: return 6
        case .scorpio: return 7
        case .sagittarius: return 8
        case .capricorn: return 9
        case .aquarius: return 10
        case .pisces: return 11
        }
    }

    /// Compute zodiac sign from a birthday.
    static func from(date: Date) -> ZodiacSign {
        return ZodiacCalculator.calculate(from: date)
    }
}

// MARK: - Zodiac Element

enum ZodiacElement: String, Codable {
    case fire = "fire"
    case earth = "earth"
    case air = "air"
    case water = "water"

    var japaneseName: String {
        switch self {
        case .fire:  return "火"
        case .earth: return "地"
        case .air:   return "風"
        case .water: return "水"
        }
    }

    var description: String {
        switch self {
        case .fire:  return "情熱と行動のエネルギー。創造し、導き、輝く力"
        case .earth: return "安定と現実のエネルギー。形にし、育て、守る力"
        case .air:   return "知性とコミュニケーションのエネルギー。繋ぎ、考え、広げる力"
        case .water: return "感情と直感のエネルギー。感じ、包み、癒す力"
        }
    }
}

// MARK: - Zodiac Modality

enum ZodiacModality: String, Codable {
    case cardinal = "cardinal"
    case fixed = "fixed"
    case mutable = "mutable"

    var japaneseName: String {
        switch self {
        case .cardinal: return "活動宮"
        case .fixed:    return "不動宮"
        case .mutable:  return "柔軟宮"
        }
    }

    var description: String {
        switch self {
        case .cardinal: return "季節の始まりに位置し、変化を起こす先導者"
        case .fixed:    return "季節の中心に位置し、物事を安定させる守護者"
        case .mutable:  return "季節の終わりに位置し、変化に適応する調整者"
        }
    }
}

// MARK: - Zodiac Planet (支配星)

enum ZodiacPlanet: String, Codable {
    case sun = "sun"
    case moon = "moon"
    case mercury = "mercury"
    case venus = "venus"
    case mars = "mars"
    case jupiter = "jupiter"
    case saturn = "saturn"
    case uranus = "uranus"
    case neptune = "neptune"
    case pluto = "pluto"

    var japaneseName: String {
        switch self {
        case .sun:     return "太陽"
        case .moon:    return "月"
        case .mercury: return "水星"
        case .venus:   return "金星"
        case .mars:    return "火星"
        case .jupiter: return "木星"
        case .saturn:  return "土星"
        case .uranus:  return "天王星"
        case .neptune: return "海王星"
        case .pluto:   return "冥王星"
        }
    }

    var symbolName: String {
        switch self {
        case .sun:     return "sun.max.fill"
        case .moon:    return "moon.fill"
        case .mercury: return "wind"
        case .venus:   return "heart.fill"
        case .mars:    return "flame.fill"
        case .jupiter: return "sparkles"
        case .saturn:  return "clock.fill"
        case .uranus:  return "bolt.fill"
        case .neptune: return "water.waves"
        case .pluto:   return "eye.fill"
        }
    }

    var influence: String {
        switch self {
        case .sun:     return "自我・生命力・創造性"
        case .moon:    return "感情・潜在意識・母性"
        case .mercury: return "知性・コミュニケーション・商才"
        case .venus:   return "愛・美・調和・金運"
        case .mars:    return "行動力・闘志・情熱"
        case .jupiter: return "拡大・幸運・寛容"
        case .saturn:  return "規律・試練・達成"
        case .uranus:  return "革新・自由・突発的変化"
        case .neptune: return "夢・神秘・直感"
        case .pluto:   return "変容・再生・究極の力"
        }
    }
}

// MARK: - Decan (デーカン: 各星座を3つに分割)

enum ZodiacDecan: Int, Codable {
    case first = 1   // 第1デーカン（0〜10度）
    case second = 2  // 第2デーカン（10〜20度）
    case third = 3   // 第3デーカン（20〜30度）

    var japaneseName: String {
        switch self {
        case .first:  return "第1デーカン"
        case .second: return "第2デーカン"
        case .third:  return "第3デーカン"
        }
    }
}
