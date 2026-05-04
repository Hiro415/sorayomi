import Foundation

// MARK: - Flower Fortune Data Models

/// 花占いに使用する花の情報
struct Flower: Codable, Identifiable {
    let id: String
    let japaneseName: String
    let englishName: String
    let hanakotoba: [String]
    let season: FlowerSeason
    let colorHex: String
    let element: FlowerElement
}

/// 花の季節
enum FlowerSeason: String, Codable, CaseIterable {
    case spring = "春"
    case summer = "夏"
    case autumn = "秋"
    case winter = "冬"

    /// 現在の実季節を返す
    static func current(for date: Date = Date()) -> FlowerSeason {
        let month = Calendar(identifier: .gregorian).component(.month, from: date)
        switch month {
        case 3...5:  return .spring
        case 6...8:  return .summer
        case 9...11: return .autumn
        default:     return .winter
        }
    }
}

/// 花の元素（五行ベース + 光）
enum FlowerElement: String, Codable, CaseIterable {
    case fire = "火"
    case water = "水"
    case earth = "地"
    case wind = "風"
    case light = "光"

    /// 二つの元素の相性スコア (1-5)
    static func resonance(between a: FlowerElement, and b: FlowerElement) -> Int {
        if a == b { return 5 }
        switch (a, b) {
        case (.fire, .wind), (.wind, .fire):   return 4
        case (.water, .earth), (.earth, .water): return 4
        case (.light, _), (_, .light):          return 3
        case (.fire, .water), (.water, .fire):  return 2
        case (.wind, .earth), (.earth, .wind):  return 2
        default:                                return 3
        }
    }
}

/// 誕生花から導かれるプロフィール
struct FlowerProfile: Codable {
    let birthMonthFlower: Flower
    let birthDayFlower: Flower
    let primaryHanakotoba: String
    let personalityTraits: String
}

/// 今日の花のエネルギーと誕生花との共鳴
struct DailyFlowerEnergy: Codable {
    let todaysFlower: Flower
    let todaysHanakotoba: String
    let resonanceScore: Int
    let resonanceDescription: String
    let combinedMessage: String
    let luckyFlowerAction: String
}
