import Foundation

/// The fortune/guidance systems available in the app.
enum FortuneSystem: String, Codable, CaseIterable, Identifiable {
    case generalConsultation = "general_consultation"
    case omikuji = "omikuji"
    case horoscope = "horoscope"
    case bloodType = "blood_type"
    case birthdayPersonality = "birthday_personality"
    case rokuyo = "rokuyo"
    case tarot = "tarot"
    case numerology = "numerology"
    case nineStarKi = "nine_star_ki"
    case flowerFortune = "flower_fortune"
    case stoneFortune = "stone_fortune"

    var id: String { rawValue }

    var japaneseName: String {
        switch self {
        case .generalConsultation: return "総合相談"
        case .omikuji:             return "おみくじの導き"
        case .horoscope:           return "星座の導き"
        case .bloodType:           return "血液型の導き"
        case .birthdayPersonality: return "誕生日の導き"
        case .rokuyo:              return "六曜の導き"
        case .tarot:               return "タロットの導き"
        case .numerology:          return "数秘術の導き"
        case .nineStarKi:          return "九星気学の導き"
        case .flowerFortune:       return "花の導き"
        case .stoneFortune:        return "ストーンの導き"
        }
    }

    var japaneseDescription: String {
        switch self {
        case .generalConsultation: return "テーマを決めず、なんでも自由に相談できます"
        case .omikuji:             return "今日の運勢と開運ヒントをサクッと確認"
        case .horoscope:           return "星の動きから、今のあなたへのメッセージを届けます"
        case .bloodType:           return "血液型から読み解く、今日の運勢と相性"
        case .birthdayPersonality: return "生まれた日に宿る、あなただけの才能と魅力"
        case .rokuyo:              return "日本の暦で読む、今日の吉凶と過ごし方"
        case .tarot:               return "カードが映し出す、今のあなたに必要なメッセージ"
        case .numerology:          return "数字で紐解く、あなたの運命のリズムと転機"
        case .nineStarKi:          return "九星の巡りから、運気の流れと最適な方位を鑑定"
        case .flowerFortune:       return "誕生花と花言葉から、今日のあなたへのメッセージ"
        case .stoneFortune:        return "パワーストーンの力で、今日のあなたを守り導きます"
        }
    }

    var iconName: String {
        switch self {
        case .generalConsultation: return "bubble.left.and.bubble.right.fill"
        case .omikuji:             return "scroll.fill"
        case .horoscope:           return "star.fill"
        case .bloodType:           return "drop.fill"
        case .birthdayPersonality: return "birthday.cake.fill"
        case .rokuyo:              return "calendar"
        case .tarot:               return "rectangle.portrait.on.rectangle.portrait.fill"
        case .numerology:          return "number"
        case .nineStarKi:          return "compass.drawing"
        case .flowerFortune:       return "camera.macro"
        case .stoneFortune:        return "diamond.fill"
        }
    }

    var tier: FortuneTier {
        switch self {
        case .generalConsultation:
            return .standard
        case .omikuji, .rokuyo:
            return .daily
        case .horoscope, .bloodType, .birthdayPersonality, .tarot:
            return .standard
        case .numerology, .nineStarKi:
            return .premium
        case .flowerFortune, .stoneFortune:
            return .standard
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
    /// Omikuji and rokuyo use local calculators only (saves API costs).
    var requiresAIGeneration: Bool {
        switch self {
        case .omikuji, .rokuyo: return false
        default: return true
        }
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
        case .generalConsultation: return []
        case .omikuji:             return []
        case .horoscope:           return [.birthday]
        case .bloodType:           return [.bloodType]
        case .birthdayPersonality: return [.birthday]
        case .rokuyo:              return []
        case .tarot:               return []
        case .numerology:          return [.birthday]
        case .nineStarKi:          return [.birthday]
        case .flowerFortune:       return [.birthday]
        case .stoneFortune:        return [.birthday]
        }
    }

    var shortName: String {
        switch self {
        case .generalConsultation: return "総合相談"
        case .omikuji:             return "おみくじ"
        case .horoscope:           return "星座"
        case .bloodType:           return "血液型"
        case .birthdayPersonality: return "誕生日"
        case .rokuyo:              return "六曜"
        case .tarot:               return "タロット"
        case .numerology:          return "数秘術"
        case .nineStarKi:          return "九星気学"
        case .flowerFortune:       return "花占い"
        case .stoneFortune:        return "ストーン占い"
        }
    }

    var highlightLabel: String {
        switch self {
        case .generalConsultation: return "自由相談"
        case .omikuji:             return "毎日無料"
        case .tarot:               return "人気No.1"
        case .nineStarKi:          return "本格派"
        case .rokuyo:              return "毎日無料"
        case .horoscope:           return "定番"
        case .bloodType:           return "盛り上がる"
        case .birthdayPersonality: return "自分発見"
        case .numerology:          return "深掘り"
        case .flowerFortune:       return "癒し系"
        case .stoneFortune:        return "お守り"
        }
    }

    /// Showcase order for system selection (general consultation is separate, not shown in picker)
    static var showcaseOrder: [FortuneSystem] {
        [
            .omikuji,
            .horoscope,
            .tarot,
            .nineStarKi,
            .bloodType,
            .birthdayPersonality,
            .numerology,
            .flowerFortune,
            .stoneFortune,
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
