import Foundation

// MARK: - TarotPrompt

/// タロット占い用のユーザープロンプトを構築する
/// Builds the tarot-specific section of the user prompt by drawing cards
/// using TarotDrawEngine and formatting them for the AI to interpret.
/// Card count varies by reading depth: 1 (snapshot), 3 (standard), 5 (deep).
struct TarotPrompt {

    // MARK: - Public API

    /// Build the tarot context block for the user prompt.
    /// - Parameters:
    ///   - category: The reading category to tailor the prompt.
    ///   - depth: The reading depth, which determines how many cards to draw.
    /// - Returns: A formatted Japanese tarot context string with drawn cards.
    static func build(category: ReadingCategory, depth: ReadingDepth) -> String {
        let cardCount = cardCount(for: depth)
        let drawnCards = TarotDrawEngine.draw(count: cardCount)

        var lines: [String] = []

        lines.append("【タロット占いデータ】")
        lines.append("・展開法：\(spreadName(for: depth))")
        lines.append("・引いたカード数：\(cardCount)枚")
        lines.append("")

        for (index, drawn) in drawnCards.enumerated() {
            let orientation = drawn.isReversed ? "逆位置" : "正位置"
            let arcanaLabel = drawn.card.arcana.japaneseName

            lines.append("カード\(index + 1)【\(drawn.position.japaneseName)】")
            lines.append("  ・名前：\(drawn.card.japaneseName)（\(drawn.card.englishName)）")
            lines.append("  ・向き：\(orientation)")
            lines.append("  ・アルカナ：\(arcanaLabel)")

            if let suit = drawn.card.suit {
                lines.append("  ・スート：\(suit.japaneseName)（\(suit.element)のエレメント）")
            }

            if index < drawnCards.count - 1 {
                lines.append("")
            }
        }

        lines.append("")
        lines.append("上記のカード展開を踏まえて、\(category.japaneseName)について鑑定してください。")
        lines.append("各カードの位置（\(positionListString(for: drawnCards))）における意味と、")
        lines.append("カード同士の関連性を織り交ぜて解釈してください。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Determine the number of cards to draw based on reading depth.
    private static func cardCount(for depth: ReadingDepth) -> Int {
        switch depth {
        case .snapshot: return 1
        case .standard: return 3
        case .deep:     return 5
        }
    }

    /// Name of the spread used at each depth.
    private static func spreadName(for depth: ReadingDepth) -> String {
        switch depth {
        case .snapshot: return "ワンオラクル（一枚引き）"
        case .standard: return "スリーカードスプレッド（過去・現在・未来）"
        case .deep:     return "ファイブカードスプレッド（詳細展開）"
        }
    }

    /// Build a comma-separated list of position names from drawn cards.
    private static func positionListString(for cards: [DrawnTarotCard]) -> String {
        cards.map { $0.position.japaneseName }.joined(separator: "・")
    }
}
