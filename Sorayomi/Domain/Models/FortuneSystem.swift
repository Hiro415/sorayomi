import Foundation

/// The fortune/guidance systems available in the app.
enum FortuneSystem: String, Codable, CaseIterable, Identifiable {
    case omikuji = "omikuji"
    case horoscope = "horoscope"
    case bloodType = "blood_type"
    case birthdayPersonality = "birthday_personality"
    case rokuyo = "rokuyo"
    case tarot = "tarot"
    case numerology = "numerology"
    case nineStarKi = "nine_star_ki"

    var id: String { rawValue }

    var japaneseName: String {
        switch self {
        case .omikuji:             return "おみくじの導き"
        case .horoscope:           return "星座の導き"
        case .bloodType:           return "血液型の導き"
        case .birthdayPersonality: return "誕生日の導き"
        case .rokuyo:              return "六曜の導き"
        case .tarot:               return "タロットの導き"
        case .numerology:          return "数秘術の導き"
        case .nineStarKi:          return "九星気学の導き"
        }
    }

    var japaneseDescription: String {
        switch self {
        case .omikuji:             return "神社のおみくじのように、今日の流れと開運のヒントを受け取る"
        case .horoscope:           return "星座から読み解く、今のあなたへのメッセージ"
        case .bloodType:           return "血液型が示す、あなたの性格と今日の傾向"
        case .birthdayPersonality: return "生まれた日が語る、あなただけの特別な資質"
        case .rokuyo:              return "日本の暦が教える、今日の吉凶と過ごし方"
        case .tarot:               return "カードが映し出す、今のあなたへの導き"
        case .numerology:          return "数字が紐解く、あなたの人生のリズム"
        case .nineStarKi:          return "九つの星が示す、あなたの運気と方位"
        }
    }

    var iconName: String {
        switch self {
        case .omikuji:             return "scroll.fill"
        case .horoscope:           return "star.fill"
        case .bloodType:           return "drop.fill"
        case .birthdayPersonality: return "birthday.cake.fill"
        case .rokuyo:              return "calendar"
        case .tarot:               return "rectangle.portrait.on.rectangle.portrait.fill"
        case .numerology:          return "number"
        case .nineStarKi:          return "compass.drawing"
        }
    }

    var tier: FortuneTier {
        switch self {
        case .omikuji, .horoscope, .bloodType, .birthdayPersonality, .rokuyo:
            return .daily
        case .tarot:
            return .standard
        case .numerology, .nineStarKi:
            return .premium
        }
    }

    var creditCost: Int {
        switch tier {
        case .daily:    return 0
        case .standard: return 1
        case .premium:  return 2
        }
    }

    /// Whether this system requires AI generation for a full reading.
    var requiresAIGeneration: Bool {
        true
    }

    /// Whether this system is available as a free daily snapshot on the home screen.
    var hasDailySnapshot: Bool {
        switch self {
        case .omikuji, .horoscope, .bloodType, .rokuyo: return true
        default: return false
        }
    }

    /// Required user profile fields for this system.
    var requiredInputs: [RequiredInput] {
        switch self {
        case .omikuji:             return []
        case .horoscope:           return [.birthday]
        case .bloodType:           return [.bloodType]
        case .birthdayPersonality: return [.birthday]
        case .rokuyo:              return []
        case .tarot:               return []
        case .numerology:          return [.birthday]
        case .nineStarKi:          return [.birthday]
        }
    }

    var shortName: String {
        switch self {
        case .omikuji:             return "おみくじ"
        case .horoscope:           return "星座"
        case .bloodType:           return "血液型"
        case .birthdayPersonality: return "誕生日"
        case .rokuyo:              return "六曜"
        case .tarot:               return "タロット"
        case .numerology:          return "数秘術"
        case .nineStarKi:          return "九星気学"
        }
    }

    var highlightLabel: String {
        switch self {
        case .omikuji:             return "毎日無料"
        case .tarot:               return "人気"
        case .nineStarKi:          return "本格派"
        case .rokuyo:              return "和暦"
        case .horoscope:           return "定番"
        case .bloodType:           return "会話で話題"
        case .birthdayPersonality: return "自分らしさ"
        case .numerology:          return "深掘り"
        }
    }

    static var showcaseOrder: [FortuneSystem] {
        [
            .omikuji,
            .horoscope,
            .tarot,
            .nineStarKi,
            .bloodType,
            .birthdayPersonality,
            .numerology,
            .rokuyo
        ]
    }
}

enum FortuneTier: String, Codable {
    case daily    // Free daily content
    case standard // 1 credit per reading
    case premium  // 2 credits per reading

    var japaneseName: String {
        switch self {
        case .daily:    return "デイリー"
        case .standard: return "スタンダード"
        case .premium:  return "プレミアム"
        }
    }
}

enum RequiredInput: String, Codable {
    case birthday
    case bloodType
    case question
}
