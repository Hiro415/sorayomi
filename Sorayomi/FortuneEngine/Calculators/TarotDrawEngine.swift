import Foundation

/// Engine for drawing tarot cards with proper shuffling and reversal logic.
struct TarotDrawEngine {

    /// Draw a specified number of cards from a shuffled deck.
    /// Each card has a 50% chance of being reversed.
    static func draw(count: Int, seed: UInt64? = nil) -> [DrawnTarotCard] {
        var rng: RandomNumberGenerator = seed.map { SeededRandomNumberGenerator(seed: $0) } ?? SystemRandomNumberGenerator() as RandomNumberGenerator
        return drawWith(count: count, rng: &rng)
    }

    private static func drawWith(count: Int, rng: inout some RandomNumberGenerator) -> [DrawnTarotCard] {
        var deck = TarotCard.fullDeck
        // Fisher-Yates shuffle
        for i in stride(from: deck.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i, using: &rng)
            deck.swapAt(i, j)
        }

        let selected = Array(deck.prefix(min(count, deck.count)))
        return selected.enumerated().map { index, card in
            let isReversed = Bool.random(using: &rng)
            let position = SpreadPosition.position(for: index, totalCards: count)
            return DrawnTarotCard(
                card: card,
                isReversed: isReversed,
                position: position
            )
        }
    }

    /// Draw a single card for daily guidance.
    static func dailyCard(for date: Date = Date()) -> DrawnTarotCard {
        // Use date as seed for consistent daily draw per device
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let seed = UInt64(components.year! * 10000 + components.month! * 100 + components.day!)
        let drawn = draw(count: 1, seed: seed)
        return drawn[0]
    }
}

/// A tarot card that has been drawn with position and reversal state.
struct DrawnTarotCard: Identifiable, Codable {
    var id: String { "\(card.id)_\(position.rawValue)_\(isReversed)" }
    let card: TarotCard
    let isReversed: Bool
    let position: SpreadPosition

    var displayName: String {
        let name = card.japaneseName
        return isReversed ? "\(name)（逆位置）" : "\(name)（正位置）"
    }
}

/// Positions in a tarot spread.
enum SpreadPosition: String, Codable, CaseIterable {
    case single = "single"
    case past = "past"
    case present = "present"
    case future = "future"
    case situation = "situation"
    case challenge = "challenge"
    case foundation = "foundation"
    case recentPast = "recent_past"
    case bestOutcome = "best_outcome"
    case nearFuture = "near_future"

    var japaneseName: String {
        switch self {
        case .single:     return "今日の一枚"
        case .past:       return "過去"
        case .present:    return "現在"
        case .future:     return "未来"
        case .situation:  return "現状"
        case .challenge:  return "課題"
        case .foundation: return "基盤"
        case .recentPast: return "近い過去"
        case .bestOutcome: return "最良の結果"
        case .nearFuture: return "近い未来"
        }
    }

    static func position(for index: Int, totalCards: Int) -> SpreadPosition {
        switch totalCards {
        case 1: return .single
        case 3:
            switch index {
            case 0: return .past
            case 1: return .present
            case 2: return .future
            default: return .single
            }
        default:
            let allPositions: [SpreadPosition] = [.situation, .challenge, .foundation, .recentPast, .bestOutcome, .nearFuture, .past, .present, .future, .single]
            return index < allPositions.count ? allPositions[index] : .single
        }
    }
}

/// Simple seeded random number generator for reproducible draws.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
