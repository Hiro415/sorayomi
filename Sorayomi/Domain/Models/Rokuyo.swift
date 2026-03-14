import Foundation

/// The six-day cycle from the traditional Japanese calendar (六曜).
enum Rokuyo: Int, Codable, CaseIterable, Identifiable {
    case taian = 0      // 大安
    case shakkou = 1    // 赤口
    case senshou = 2    // 先勝
    case tomobiki = 3   // 友引
    case senbu = 4      // 先負
    case butsumetsu = 5 // 仏滅

    var id: Int { rawValue }

    var japaneseName: String {
        switch self {
        case .taian:      return "大安"
        case .shakkou:    return "赤口"
        case .senshou:    return "先勝"
        case .tomobiki:   return "友引"
        case .senbu:      return "先負"
        case .butsumetsu: return "仏滅"
        }
    }

    var reading: String {
        switch self {
        case .taian:      return "たいあん"
        case .shakkou:    return "しゃっこう"
        case .senshou:    return "せんしょう"
        case .tomobiki:   return "ともびき"
        case .senbu:      return "せんぶ"
        case .butsumetsu: return "ぶつめつ"
        }
    }

    var briefGuidance: String {
        switch self {
        case .taian:
            return "万事において吉とされる日。新しいことを始めるのに良い日です"
        case .shakkou:
            return "正午のみ吉。午前と午後は控えめに過ごすと良いでしょう"
        case .senshou:
            return "午前中が吉。急ぎの用事は午前中に済ませると良いでしょう"
        case .tomobiki:
            return "朝と夕方が吉。昼は控えめに。お祝い事には良い日です"
        case .senbu:
            return "午後が吉。午前中は静かに過ごし、午後から活動すると良いでしょう"
        case .butsumetsu:
            return "控えめに過ごす日。内省や準備の時間として活用しましょう"
        }
    }

    var luckyTimeOfDay: String {
        switch self {
        case .taian:      return "終日"
        case .shakkou:    return "正午（11:00-13:00）"
        case .senshou:    return "午前中"
        case .tomobiki:   return "朝・夕方"
        case .senbu:      return "午後"
        case .butsumetsu: return "特になし（静かに過ごす日）"
        }
    }

    var isAuspicious: Bool {
        switch self {
        case .taian, .tomobiki, .senshou: return true
        case .shakkou, .senbu, .butsumetsu: return false
        }
    }

    /// Overall auspiciousness score (1-5 stars).
    var auspiciousnessScore: Int {
        switch self {
        case .taian:      return 5
        case .tomobiki:   return 4
        case .senshou:    return 3
        case .senbu:      return 3
        case .shakkou:    return 2
        case .butsumetsu: return 1
        }
    }
}
