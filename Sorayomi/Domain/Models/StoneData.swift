import Foundation

// MARK: - Stone Fortune Data Models

/// パワーストーンの情報
struct PowerStone: Codable, Identifiable {
    let id: String
    let japaneseName: String
    let englishName: String
    let colorHex: String
    let element: StoneElement
    let chakra: Chakra
    let properties: [String]
    let healingAspect: String
    let protectionAspect: String
    let luckAspect: String
}

/// 石の元素（五大ベース）
enum StoneElement: String, Codable, CaseIterable {
    case fire = "火"
    case water = "水"
    case earth = "地"
    case wind = "風"
    case void = "空"

    /// 二つの元素の相性スコア (1-5)
    static func resonance(between a: StoneElement, and b: StoneElement) -> Int {
        if a == b { return 5 }
        switch (a, b) {
        case (.fire, .wind), (.wind, .fire):   return 4
        case (.water, .earth), (.earth, .water): return 4
        case (.void, _), (_, .void):            return 3
        case (.fire, .water), (.water, .fire):  return 2
        case (.wind, .earth), (.earth, .wind):  return 2
        default:                                return 3
        }
    }
}

/// チャクラ
enum Chakra: String, Codable, CaseIterable {
    case root = "第1チャクラ"
    case sacral = "第2チャクラ"
    case solar = "第3チャクラ"
    case heart = "第4チャクラ"
    case throat = "第5チャクラ"
    case thirdEye = "第6チャクラ"
    case crown = "第7チャクラ"

    /// チャクラの日本語名
    var japaneseName: String {
        switch self {
        case .root:     return "ルート"
        case .sacral:   return "セイクラル"
        case .solar:    return "ソーラー"
        case .heart:    return "ハート"
        case .throat:   return "スロート"
        case .thirdEye: return "サードアイ"
        case .crown:    return "クラウン"
        }
    }

    /// チャクラ間の距離スコア (0=同じ, 6=最遠)
    static func distance(between a: Chakra, and b: Chakra) -> Int {
        let allCases = Chakra.allCases
        guard let indexA = allCases.firstIndex(of: a),
              let indexB = allCases.firstIndex(of: b) else { return 3 }
        return abs(indexA - indexB)
    }
}

/// 誕生石から導かれるプロフィール
struct StoneProfile: Codable {
    let birthstone: PowerStone
    let birthstoneMessage: String
    let personalityFromStone: String
}

/// 今日のパワーストーンのエネルギーと誕生石との共鳴
struct DailyStoneEnergy: Codable {
    let todaysStone: PowerStone
    let resonanceScore: Int
    let resonanceDescription: String
    let elementInteraction: String
    let chakraAlignment: String
    let recommendedAction: String
}
