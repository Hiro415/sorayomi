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
        case .dailyFortune:  return "あなたの血液型の\n今日を詳しく鑑定"
        case .compatibility: return "2人の血液型の\n相性を深く読み解く"
        case .loveMatch:     return "恋の行方を\n血液型から読み解く"
        case .ranking:       return "今日の血液型別\nランキングを発表！"
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
