import Foundation

/// A tarot card from the standard 78-card deck.
struct TarotCard: Codable, Identifiable, Hashable {
    let id: Int
    let arcana: TarotArcana
    let suit: TarotSuit?
    let number: Int // 0-21 for Major, 1-14 for Minor
    let englishName: String
    let japaneseName: String

    /// Full deck of 78 cards.
    static let fullDeck: [TarotCard] = majorArcana + minorArcana

    // MARK: - Major Arcana (22 cards)

    static let majorArcana: [TarotCard] = [
        TarotCard(id: 0,  arcana: .major, suit: nil, number: 0,  englishName: "The Fool",            japaneseName: "愚者"),
        TarotCard(id: 1,  arcana: .major, suit: nil, number: 1,  englishName: "The Magician",         japaneseName: "魔術師"),
        TarotCard(id: 2,  arcana: .major, suit: nil, number: 2,  englishName: "The High Priestess",   japaneseName: "女教皇"),
        TarotCard(id: 3,  arcana: .major, suit: nil, number: 3,  englishName: "The Empress",          japaneseName: "女帝"),
        TarotCard(id: 4,  arcana: .major, suit: nil, number: 4,  englishName: "The Emperor",          japaneseName: "皇帝"),
        TarotCard(id: 5,  arcana: .major, suit: nil, number: 5,  englishName: "The Hierophant",       japaneseName: "教皇"),
        TarotCard(id: 6,  arcana: .major, suit: nil, number: 6,  englishName: "The Lovers",           japaneseName: "恋人"),
        TarotCard(id: 7,  arcana: .major, suit: nil, number: 7,  englishName: "The Chariot",          japaneseName: "戦車"),
        TarotCard(id: 8,  arcana: .major, suit: nil, number: 8,  englishName: "Strength",             japaneseName: "力"),
        TarotCard(id: 9,  arcana: .major, suit: nil, number: 9,  englishName: "The Hermit",           japaneseName: "隠者"),
        TarotCard(id: 10, arcana: .major, suit: nil, number: 10, englishName: "Wheel of Fortune",     japaneseName: "運命の輪"),
        TarotCard(id: 11, arcana: .major, suit: nil, number: 11, englishName: "Justice",              japaneseName: "正義"),
        TarotCard(id: 12, arcana: .major, suit: nil, number: 12, englishName: "The Hanged Man",       japaneseName: "吊るされた男"),
        TarotCard(id: 13, arcana: .major, suit: nil, number: 13, englishName: "Death",                japaneseName: "死神"),
        TarotCard(id: 14, arcana: .major, suit: nil, number: 14, englishName: "Temperance",           japaneseName: "節制"),
        TarotCard(id: 15, arcana: .major, suit: nil, number: 15, englishName: "The Devil",            japaneseName: "悪魔"),
        TarotCard(id: 16, arcana: .major, suit: nil, number: 16, englishName: "The Tower",            japaneseName: "塔"),
        TarotCard(id: 17, arcana: .major, suit: nil, number: 17, englishName: "The Star",             japaneseName: "星"),
        TarotCard(id: 18, arcana: .major, suit: nil, number: 18, englishName: "The Moon",             japaneseName: "月"),
        TarotCard(id: 19, arcana: .major, suit: nil, number: 19, englishName: "The Sun",              japaneseName: "太陽"),
        TarotCard(id: 20, arcana: .major, suit: nil, number: 20, englishName: "Judgement",            japaneseName: "審判"),
        TarotCard(id: 21, arcana: .major, suit: nil, number: 21, englishName: "The World",            japaneseName: "世界"),
    ]

    // MARK: - Minor Arcana (56 cards)

    static let minorArcana: [TarotCard] = {
        var cards: [TarotCard] = []
        var cardId = 22
        for suit in TarotSuit.allCases {
            for number in 1...14 {
                let name: String
                let jpName: String
                switch number {
                case 1:  name = "Ace";   jpName = "エース"
                case 11: name = "Page";  jpName = "ペイジ"
                case 12: name = "Knight"; jpName = "ナイト"
                case 13: name = "Queen"; jpName = "クイーン"
                case 14: name = "King";  jpName = "キング"
                default: name = "\(number)"; jpName = "\(number)"
                }

                cards.append(TarotCard(
                    id: cardId,
                    arcana: .minor,
                    suit: suit,
                    number: number,
                    englishName: "\(name) of \(suit.englishName)",
                    japaneseName: "\(suit.japaneseName)の\(jpName)"
                ))
                cardId += 1
            }
        }
        return cards
    }()
}

enum TarotArcana: String, Codable {
    case major = "major"
    case minor = "minor"

    var japaneseName: String {
        switch self {
        case .major: return "大アルカナ"
        case .minor: return "小アルカナ"
        }
    }
}

enum TarotSuit: String, Codable, CaseIterable {
    case wands = "wands"
    case cups = "cups"
    case swords = "swords"
    case pentacles = "pentacles"

    var englishName: String {
        switch self {
        case .wands:     return "Wands"
        case .cups:      return "Cups"
        case .swords:    return "Swords"
        case .pentacles: return "Pentacles"
        }
    }

    var japaneseName: String {
        switch self {
        case .wands:     return "ワンド"
        case .cups:      return "カップ"
        case .swords:    return "ソード"
        case .pentacles: return "ペンタクル"
        }
    }

    var element: String {
        switch self {
        case .wands:     return "火"
        case .cups:      return "水"
        case .swords:    return "風"
        case .pentacles: return "地"
        }
    }
}
