import Foundation

// MARK: - TarotPrompt

/// タロット占い用のユーザープロンプトを構築する
/// Builds a rich tarot context including card meanings (upright/reversed),
/// astrological correspondences, elemental dignity between cards,
/// spread position deep meanings, and card combination significance.
struct TarotPrompt {

    // MARK: - Public API

    /// Build the tarot context block for the user prompt.
    static func build(
        category: ReadingCategory,
        depth: ReadingDepth,
        preDrawnCards: [DrawnTarotCard]? = nil
    ) -> String {
        let drawnCards: [DrawnTarotCard]
        if let pre = preDrawnCards, !pre.isEmpty {
            drawnCards = pre
        } else {
            let count = cardCount(for: depth)
            drawnCards = TarotDrawEngine.draw(count: count)
        }

        var lines: [String] = []

        lines.append("【タロット占いデータ】")
        lines.append("・展開法：\(spreadName(for: drawnCards.count))")
        lines.append("・引いたカード数：\(drawnCards.count)枚")
        lines.append("")

        // ── 各カードの詳細 ──
        for (index, drawn) in drawnCards.enumerated() {
            let orientation = drawn.isReversed ? "逆位置" : "正位置"
            let arcanaLabel = drawn.card.arcana.japaneseName

            lines.append("━━━ カード\(index + 1)【\(drawn.position.japaneseName)】━━━")
            lines.append("  名前：\(drawn.card.japaneseName)（\(drawn.card.englishName)）")
            lines.append("  向き：\(orientation)")
            lines.append("  アルカナ：\(arcanaLabel)")

            if let suit = drawn.card.suit {
                lines.append("  スート：\(suit.japaneseName)（\(suit.element)のエレメント）")
                lines.append("  領域：\(suit.domain)")
            }

            // Card-specific meanings
            if drawn.card.arcana == .major {
                let meaning = TarotMajorMeaning.meaning(for: drawn.card.number)
                if drawn.isReversed {
                    lines.append("  キーワード：\(meaning.reversedKeywords.joined(separator: "・"))")
                    lines.append("  解釈の方向：\(meaning.reversedMeaning)")
                } else {
                    lines.append("  キーワード：\(meaning.uprightKeywords.joined(separator: "・"))")
                    lines.append("  解釈の方向：\(meaning.uprightMeaning)")
                }
                lines.append("  占星術対応：\(meaning.astrologicalCorrespondence)")
                lines.append("  元型：\(meaning.archetype)")
            } else {
                let numMeaning = TarotMinorNumberMeaning.meaning(for: drawn.card.number)
                lines.append("  数字テーマ：\(numMeaning.theme)")
                if drawn.isReversed {
                    lines.append("  解釈の方向：\(numMeaning.reversedEssence)")
                } else {
                    lines.append("  解釈の方向：\(numMeaning.uprightEssence)")
                }
            }

            // Position meaning
            lines.append("  ポジション意味：\(positionDeepMeaning(drawn.position))")
            lines.append("")
        }

        // ── エレメンタルディグニティ（元素の調和/対立）──
        let dignityAnalysis = TarotElementalDignity.analyzeSpread(drawnCards)
        if !dignityAnalysis.isEmpty {
            lines.append("【エレメンタルディグニティ（元素間の関係性）】")
            lines.append(dignityAnalysis)
            lines.append("")
        }

        // ── スプレッド全体の傾向分析 ──
        lines.append("【スプレッド傾向】")
        lines.append(spreadTendency(drawnCards))
        lines.append("")

        // ── AI指示 ──
        lines.append("【鑑定指示】")
        lines.append("① 上記のカードが実際に引かれています。このカードの組み合わせに基づいて\(category.japaneseName)について鑑定してください")
        lines.append("② 各カードの「解釈の方向」を参考にしつつ、ポジションの意味と組み合わせてオリジナルの解釈を展開してください")
        lines.append("③ エレメンタルディグニティ（元素の親和・対立）をカード間の関係性解釈に反映してください")
        lines.append("④ 大アルカナが出ている場合はその占星術対応と元型の象徴性を深読みしてください")
        lines.append("⑤ 正位置・逆位置の差異を明確に反映し、「逆位置＝悪い」という単純化は避けてください")
        lines.append("⑥ 上記以外のカード名に言及しないでください")
        lines.append("⑦ スプレッド全体を一つの物語として読み、カード間のストーリーラインを描いてください")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private static func cardCount(for depth: ReadingDepth) -> Int {
        switch depth {
        case .snapshot: return 1
        case .standard: return 3
        case .deep:     return 5
        }
    }

    private static func spreadName(for count: Int) -> String {
        switch count {
        case 1: return "ワンオラクル（一枚引き）— 核心を一枚に凝縮"
        case 3: return "スリーカードスプレッド（過去・現在・未来）— 時間軸で読む"
        default: return "ファイブカードスプレッド（詳細展開）— 状況を多角的に読む"
        }
    }

    /// Deep meaning for each spread position.
    private static func positionDeepMeaning(_ position: SpreadPosition) -> String {
        switch position {
        case .single:
            return "今この瞬間の核心。相談の本質を一枚が映し出す"
        case .past:
            return "現在に至るまでの流れ。過去の選択や経験が今にどう繋がっているか"
        case .present:
            return "今まさに相談者が立っている場所。現在の状況のエネルギーと本質"
        case .future:
            return "現在の流れが続いた場合に向かう方向。可能性であり確定ではない"
        case .situation:
            return "相談の核心にある状況。表面的な問題の奥にある本質的なテーマ"
        case .challenge:
            return "乗り越えるべき課題。成長のために向き合う必要があるもの"
        case .foundation:
            return "状況の土台にあるもの。意識していないが全体を支える深層の要素"
        case .recentPast:
            return "最近の出来事や影響。現在に直接繋がる直近の流れ"
        case .bestOutcome:
            return "最良のシナリオ。他のカードの助言に従った場合に到達しうる地点"
        case .nearFuture:
            return "近い将来に訪れる変化やエネルギーの転換点"
        }
    }

    /// Analyze overall spread tendencies.
    private static func spreadTendency(_ cards: [DrawnTarotCard]) -> String {
        var tendencies: [String] = []

        // Major/Minor ratio
        let majorCount = cards.filter { $0.card.arcana == .major }.count
        if majorCount == cards.count {
            tendencies.append("全て大アルカナ — 人生の大きな転機。運命レベルの出来事が動いている")
        } else if majorCount >= cards.count / 2 + 1 {
            tendencies.append("大アルカナ多数（\(majorCount)/\(cards.count)枚）— 人生の大きなテーマに関わる相談")
        } else if majorCount == 0 && cards.count >= 3 {
            tendencies.append("全て小アルカナ — 日常レベルの具体的な問題。実践的なアドバイスが有効")
        }

        // Reversed ratio
        let reversedCount = cards.filter { $0.isReversed }.count
        if reversedCount == cards.count {
            tendencies.append("全て逆位置 — 内面的なブロックや停滞。内省と見直しが必要")
        } else if reversedCount == 0 && cards.count >= 3 {
            tendencies.append("全て正位置 — エネルギーがスムーズに流れている。順調な展開")
        } else if reversedCount > cards.count / 2 {
            tendencies.append("逆位置多め（\(reversedCount)/\(cards.count)枚）— 何かがスムーズに流れていない暗示")
        }

        // Dominant suit
        let suitCounts = Dictionary(grouping: cards.compactMap { $0.card.suit }, by: { $0 })
        if let dominant = suitCounts.max(by: { $0.value.count < $1.value.count }),
           dominant.value.count >= 2 {
            tendencies.append("\(dominant.key.japaneseName)（\(dominant.key.element)）のエネルギーが支配的 — \(dominant.key.domain)がテーマの中心")
        }

        // Number patterns
        let numbers = cards.map { $0.card.number }
        let uniqueNumbers = Set(numbers)
        if numbers.count != uniqueNumbers.count {
            let duplicates = numbers.filter { n in numbers.filter { $0 == n }.count > 1 }
            if let dupNum = duplicates.first {
                let numMeaning = TarotMinorNumberMeaning.meaning(for: dupNum)
                tendencies.append("同じ数字（\(dupNum)）が複数 — 「\(numMeaning.theme)」のテーマが強調されている")
            }
        }

        return tendencies.isEmpty
            ? "バランスの取れたスプレッド。各カードが独自のメッセージを持つ"
            : tendencies.joined(separator: "\n")
    }
}
