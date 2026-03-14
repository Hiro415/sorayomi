import Foundation

/// Western zodiac signs with Japanese names and properties.
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

    /// Personality keywords in Japanese.
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

    /// Compute zodiac sign from a birthday.
    static func from(date: Date) -> ZodiacSign {
        return ZodiacCalculator.calculate(from: date)
    }
}

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
}

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
}
