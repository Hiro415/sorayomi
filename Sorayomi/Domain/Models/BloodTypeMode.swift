import Foundation

/// 血液型占いのモード選択肢
enum BloodTypeMode: String, CaseIterable, Identifiable {
    case dailyFortune = "daily_fortune"
    case compatibility = "compatibility"
    case loveMatch = "love_match"
    case ranking = "ranking"

    var id: String { rawValue }

    var japaneseName: String {
        switch self {
        case .dailyFortune:  return "今日の運勢"
        case .compatibility: return "相性診断"
        case .loveMatch:     return "恋愛相性"
        case .ranking:       return "ランキング"
        }
    }

    var iconName: String {
        switch self {
        case .dailyFortune:  return "sun.max.fill"
        case .compatibility: return "person.2.fill"
        case .loveMatch:     return "heart.fill"
        case .ranking:       return "trophy.fill"
        }
    }

    var description: String {
        switch self {
        case .dailyFortune:  return "今日の運勢を\n血液型から読み解く"
        case .compatibility: return "気になる相手との\n相性をチェック"
        case .loveMatch:     return "恋の行方を\n血液型で占う"
        case .ranking:       return "今日いちばん\nツイてる血液型は？"
        }
    }

    var requiresPartner: Bool {
        switch self {
        case .compatibility, .loveMatch: return true
        case .dailyFortune, .ranking: return false
        }
    }

    var skipsHearing: Bool {
        self == .ranking
    }
}
