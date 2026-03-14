import Foundation

/// A daily omikuji draw tailored to the user's current day.
struct Omikuji: Codable, Equatable {
    enum Rank: String, Codable, CaseIterable {
        case daikichi
        case kichi
        case chukichi
        case shokichi
        case suekichi
        case kyo

        var japaneseName: String {
            switch self {
            case .daikichi: return "大吉"
            case .kichi:    return "吉"
            case .chukichi: return "中吉"
            case .shokichi: return "小吉"
            case .suekichi: return "末吉"
            case .kyo:      return "凶"
            }
        }

        var starScore: Int {
            switch self {
            case .daikichi: return 5
            case .kichi:    return 4
            case .chukichi: return 4
            case .shokichi: return 3
            case .suekichi: return 2
            case .kyo:      return 1
            }
        }

        var nuance: String {
            switch self {
            case .daikichi:
                return "勢いがのびやかに広がる日"
            case .kichi:
                return "整えた分だけ追い風を受けやすい日"
            case .chukichi:
                return "穏やかな前進を重ねたい日"
            case .shokichi:
                return "小さな選択が運を育てる日"
            case .suekichi:
                return "焦らず育てるほど実りやすい日"
            case .kyo:
                return "静かに整え直すことで流れが変わる日"
            }
        }
    }

    let rank: Rank
    let poem: String
    let guidance: String
    let luckyDirection: String
    let luckyTime: String
    let luckyItem: String
    let luckyColor: String
    let loveHint: String
    let workHint: String
    let moneyHint: String

    var headline: String {
        "本日のおみくじは「\(rank.japaneseName)」です。"
    }

    var isAuspicious: Bool {
        rank != .kyo
    }

    static let preview = Omikuji(
        rank: .daikichi,
        poem: "朝の光を受ける枝のように、素直な気持ちが運を呼び込みます。",
        guidance: "今日は迷いを抱え込むより、ひとつ決めて軽やかに進むほど流れが整います。",
        luckyDirection: "東南",
        luckyTime: "10時から12時",
        luckyItem: "白い便箋",
        luckyColor: "朱色",
        loveHint: "やさしい言葉を先に差し出すほど、ご縁が深まりやすい日です。",
        workHint: "最初の一手を丁寧に整えると、その後の判断が驚くほど滑らかになります。",
        moneyHint: "今日は増やすことより、使い道を整える姿勢が金運を支えます。"
    )
}
