import Foundation

/// A tarot card from the standard 78-card deck.
struct TarotCard: Codable, Identifiable, Hashable {
    let id: Int
    let arcana: TarotArcana
    let suit: TarotSuit?
    let number: Int // 0-21 for Major, 1-14 for Minor
    let englishName: String
    let japaneseName: String

    /// Asset Catalogのイメージ名
    var assetImageName: String {
        if arcana == .major {
            return String(format: "tarot_major_%02d", number)
        }
        guard let suit else { return "tarot_back" }
        return String(format: "tarot_%@_%02d", suit.rawValue, number)
    }

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

    var elementEnglish: String {
        switch self {
        case .wands:     return "Fire"
        case .cups:      return "Water"
        case .swords:    return "Air"
        case .pentacles: return "Earth"
        }
    }

    var domain: String {
        switch self {
        case .wands:     return "情熱・行動・創造性"
        case .cups:      return "感情・愛・直感"
        case .swords:    return "思考・知性・試練"
        case .pentacles: return "物質・仕事・現実"
        }
    }
}

// MARK: - Major Arcana Meanings & Correspondences

/// Rich meaning data for each major arcana card, based on established tarot traditions
/// (Rider-Waite-Smith interpretations + Golden Dawn astrological correspondences).
struct TarotMajorMeaning {
    let number: Int
    let uprightKeywords: [String]
    let reversedKeywords: [String]
    let uprightMeaning: String
    let reversedMeaning: String
    let astrologicalCorrespondence: String  // Golden Dawn attribution
    let hebrewLetter: String
    let numerologicalValue: Int
    let archetype: String
    let yesNoTendency: String  // "Yes" / "No" / "Neutral"

    static func meaning(for number: Int) -> TarotMajorMeaning {
        meanings[number] ?? meanings[0]!
    }

    // swiftlint:disable function_body_length
    private static let meanings: [Int: TarotMajorMeaning] = [
        0: TarotMajorMeaning(
            number: 0, uprightKeywords: ["新しい始まり", "自由", "冒険", "無邪気"],
            reversedKeywords: ["無謀", "無計画", "恐れ", "停滞"],
            uprightMeaning: "新しい旅の始まり。未知への飛躍を示し、可能性は無限大。恐れを手放し、直感に従って一歩を踏み出す時",
            reversedMeaning: "準備不足のまま飛び出す危険。立ち止まって計画を見直す必要あり。恐れに支配されて動けない状態",
            astrologicalCorrespondence: "天王星", hebrewLetter: "アレフ", numerologicalValue: 0,
            archetype: "永遠の旅人", yesNoTendency: "Yes"
        ),
        1: TarotMajorMeaning(
            number: 1, uprightKeywords: ["意志力", "創造", "スキル", "集中"],
            reversedKeywords: ["詐欺", "未熟", "操作", "才能の浪費"],
            uprightMeaning: "持っている全てのツールを使いこなす力。意志と行動が一致し、目標を実現できる状態。今こそ動く時",
            reversedMeaning: "能力はあるが活かせていない。他者を操ろうとする傾向や、自信のなさが妨げになっている",
            astrologicalCorrespondence: "水星", hebrewLetter: "ベート", numerologicalValue: 1,
            archetype: "錬金術師", yesNoTendency: "Yes"
        ),
        2: TarotMajorMeaning(
            number: 2, uprightKeywords: ["直感", "神秘", "内なる声", "潜在意識"],
            reversedKeywords: ["秘密", "感情の抑圧", "直感の無視", "表面的"],
            uprightMeaning: "直感と内なる知恵が高まる時。表面に見えないものを感じ取る力。静かに待ち、内なる声に耳を傾けて",
            reversedMeaning: "直感を無視している状態。表面的な判断に頼りすぎ。隠された真実が明るみに出る前兆",
            astrologicalCorrespondence: "月", hebrewLetter: "ギメル", numerologicalValue: 2,
            archetype: "神秘の守護者", yesNoTendency: "Neutral"
        ),
        3: TarotMajorMeaning(
            number: 3, uprightKeywords: ["豊穣", "母性", "美", "自然"],
            reversedKeywords: ["依存", "過保護", "創造力の枯渇", "停滞"],
            uprightMeaning: "豊かさと創造力に満ちた時期。愛情や美しいものに恵まれ、物事が実を結ぶ。自然体で過ごすことが吉",
            reversedMeaning: "創造力の行き詰まり。他者への過干渉や依存。自分の中の豊かさに気づけていない状態",
            astrologicalCorrespondence: "金星", hebrewLetter: "ダレット", numerologicalValue: 3,
            archetype: "大地の母", yesNoTendency: "Yes"
        ),
        4: TarotMajorMeaning(
            number: 4, uprightKeywords: ["権威", "構造", "安定", "父性"],
            reversedKeywords: ["支配", "頑固", "柔軟性の欠如", "暴君"],
            uprightMeaning: "安定した基盤と秩序の確立。リーダーシップを発揮し、計画を実行に移す力。規律が成功を呼ぶ",
            reversedMeaning: "過度な支配欲や頑固さ。ルールに縛られすぎて柔軟性を失っている。権力の乱用に注意",
            astrologicalCorrespondence: "牡羊座", hebrewLetter: "ヘー", numerologicalValue: 4,
            archetype: "統治者", yesNoTendency: "Yes"
        ),
        5: TarotMajorMeaning(
            number: 5, uprightKeywords: ["伝統", "教え", "信念", "精神的導き"],
            reversedKeywords: ["形骸化", "反抗", "非伝統", "新しい道"],
            uprightMeaning: "伝統的な知恵や師の教えが助けになる時期。組織やコミュニティの中で学びを得る。信頼できる助言者を見つけて",
            reversedMeaning: "古い価値観に疑問を感じている。独自の道を模索する時。形だけの信仰やルールからの解放",
            astrologicalCorrespondence: "牡牛座", hebrewLetter: "ヴァヴ", numerologicalValue: 5,
            archetype: "導師", yesNoTendency: "Neutral"
        ),
        6: TarotMajorMeaning(
            number: 6, uprightKeywords: ["愛", "調和", "選択", "パートナーシップ"],
            reversedKeywords: ["不調和", "価値観の不一致", "優柔不断", "誘惑"],
            uprightMeaning: "大切な選択の時。愛と調和に導かれた決断が幸運を呼ぶ。パートナーシップの深まりや、価値観の一致を確認する好機",
            reversedMeaning: "価値観の不一致による葛藤。優柔不断な状態。誘惑に惑わされず、本心を見つめる必要あり",
            astrologicalCorrespondence: "双子座", hebrewLetter: "ザイン", numerologicalValue: 6,
            archetype: "恋人たち", yesNoTendency: "Yes"
        ),
        7: TarotMajorMeaning(
            number: 7, uprightKeywords: ["勝利", "意志", "前進", "自信"],
            reversedKeywords: ["暴走", "方向喪失", "攻撃性", "自己中心"],
            uprightMeaning: "困難を乗り越えて前進する力。強い意志と自信が勝利を引き寄せる。行動力と決断力が試される時",
            reversedMeaning: "方向性を見失い暴走している状態。力任せに進んでも壁にぶつかる。一度立ち止まって方向を確認して",
            astrologicalCorrespondence: "蟹座", hebrewLetter: "ヘット", numerologicalValue: 7,
            archetype: "凱旋者", yesNoTendency: "Yes"
        ),
        8: TarotMajorMeaning(
            number: 8, uprightKeywords: ["内なる力", "勇気", "忍耐", "慈悲"],
            reversedKeywords: ["弱さ", "自己不信", "衝動", "怒り"],
            uprightMeaning: "外的な力ではなく、内なる強さが試される時。優しさと忍耐が困難を乗り越える鍵。感情をコントロールする力",
            reversedMeaning: "自己不信や弱さを感じている。衝動的な行動や怒りのコントロールが課題。自分の内なる力を信じて",
            astrologicalCorrespondence: "獅子座", hebrewLetter: "テット", numerologicalValue: 8,
            archetype: "獅子使い", yesNoTendency: "Yes"
        ),
        9: TarotMajorMeaning(
            number: 9, uprightKeywords: ["内省", "孤独", "知恵", "探求"],
            reversedKeywords: ["孤立", "引きこもり", "不信", "偏屈"],
            uprightMeaning: "一人の時間を通じて深い気づきを得る時。内面を見つめ、本当に大切なものを見極める。知恵ある助言者の存在",
            reversedMeaning: "必要以上の孤立や引きこもり。他者への不信感が成長を妨げている。心を開く勇気が必要",
            astrologicalCorrespondence: "乙女座", hebrewLetter: "ヨッド", numerologicalValue: 9,
            archetype: "賢者", yesNoTendency: "Neutral"
        ),
        10: TarotMajorMeaning(
            number: 10, uprightKeywords: ["転機", "運命", "チャンス", "循環"],
            reversedKeywords: ["悪運", "抵抗", "停滞", "変化への恐れ"],
            uprightMeaning: "運命の転換点。良い変化の波が来ている。チャンスを掴むタイミング。流れに身を任せることが吉",
            reversedMeaning: "変化に抵抗している状態。悪循環にはまっている可能性。流れを変えるには自ら動くことが必要",
            astrologicalCorrespondence: "木星", hebrewLetter: "カフ", numerologicalValue: 10,
            archetype: "運命の車輪", yesNoTendency: "Yes"
        ),
        11: TarotMajorMeaning(
            number: 11, uprightKeywords: ["公正", "真実", "因果", "バランス"],
            reversedKeywords: ["不公正", "偏見", "責任逃れ", "不均衡"],
            uprightMeaning: "公正な判断が求められる時。因果応報の法則が働き、正しい行いが報われる。バランスを取ることが重要",
            reversedMeaning: "不公正な状況や偏った判断。自分の責任から逃げている可能性。正直に向き合う必要あり",
            astrologicalCorrespondence: "天秤座", hebrewLetter: "ラメド", numerologicalValue: 11,
            archetype: "裁定者", yesNoTendency: "Neutral"
        ),
        12: TarotMajorMeaning(
            number: 12, uprightKeywords: ["犠牲", "新たな視点", "手放し", "待機"],
            reversedKeywords: ["犠牲の拒否", "停滞", "無駄な抵抗", "利己"],
            uprightMeaning: "立ち止まり、視点を変える時。一時的な犠牲が大きな成長をもたらす。逆さまの世界から見える新しい真実",
            reversedMeaning: "必要な変化を拒んでいる。犠牲を嫌がって同じ場所に留まり続けている。手放すことで先に進める",
            astrologicalCorrespondence: "海王星", hebrewLetter: "メム", numerologicalValue: 12,
            archetype: "殉教者", yesNoTendency: "Neutral"
        ),
        13: TarotMajorMeaning(
            number: 13, uprightKeywords: ["終わりと始まり", "変容", "清算", "再生"],
            reversedKeywords: ["変化への恐れ", "執着", "停滞", "回避"],
            uprightMeaning: "何かが終わり、新しいものが始まる。物理的な死ではなく変容のカード。古いものを手放すことで再生する",
            reversedMeaning: "必要な終わりを受け入れられない。過去への執着が未来を閉ざしている。変化を恐れず受け入れて",
            astrologicalCorrespondence: "蠍座", hebrewLetter: "ヌン", numerologicalValue: 13,
            archetype: "変容者", yesNoTendency: "Neutral"
        ),
        14: TarotMajorMeaning(
            number: 14, uprightKeywords: ["バランス", "節度", "忍耐", "調和"],
            reversedKeywords: ["不均衡", "極端", "焦り", "過剰"],
            uprightMeaning: "バランスと調和が鍵。極端を避け、中庸を保つことで望む結果に近づく。忍耐強く、流れに身を任せて",
            reversedMeaning: "バランスを崩している状態。極端な行動や焦りが問題を悪化させている。一息ついて中心を取り戻して",
            astrologicalCorrespondence: "射手座", hebrewLetter: "サメク", numerologicalValue: 14,
            archetype: "錬金の天使", yesNoTendency: "Yes"
        ),
        15: TarotMajorMeaning(
            number: 15, uprightKeywords: ["束縛", "誘惑", "執着", "影"],
            reversedKeywords: ["解放", "束縛からの脱出", "回復", "自覚"],
            uprightMeaning: "何かに束縛されている状態。物質的な誘惑、依存、不健全な関係性。しかし鎖は自分で外せる",
            reversedMeaning: "束縛からの解放の兆し。依存や悪習慣から抜け出す力が湧いている。自由を取り戻す好機",
            astrologicalCorrespondence: "山羊座", hebrewLetter: "アイン", numerologicalValue: 15,
            archetype: "誘惑者", yesNoTendency: "No"
        ),
        16: TarotMajorMeaning(
            number: 16, uprightKeywords: ["崩壊", "衝撃", "解放", "真実の露呈"],
            reversedKeywords: ["回避", "延期", "恐怖", "最悪は免れる"],
            uprightMeaning: "突然の崩壊や衝撃的な変化。しかしそれは偽りの安定が壊れること。真実が明らかになり、真の再建が始まる",
            reversedMeaning: "大きな衝撃は回避されるが、根本的な問題は残っている。先延ばしにしている崩壊。いずれ向き合う必要あり",
            astrologicalCorrespondence: "火星", hebrewLetter: "ペー", numerologicalValue: 16,
            archetype: "破壊と解放の雷", yesNoTendency: "No"
        ),
        17: TarotMajorMeaning(
            number: 17, uprightKeywords: ["希望", "インスピレーション", "平穏", "癒し"],
            reversedKeywords: ["絶望", "信仰の喪失", "不安", "断絶"],
            uprightMeaning: "嵐の後の静けさ。希望と癒しの時期。直感とインスピレーションに導かれ、未来への信頼が生まれる",
            reversedMeaning: "希望を見失っている状態。不安や絶望に囚われている。しかし星は常にそこにある。信じる心を取り戻して",
            astrologicalCorrespondence: "水瓶座", hebrewLetter: "ツァディ", numerologicalValue: 17,
            archetype: "希望の星", yesNoTendency: "Yes"
        ),
        18: TarotMajorMeaning(
            number: 18, uprightKeywords: ["幻想", "不安", "潜在意識", "直感"],
            reversedKeywords: ["恐怖の克服", "真実の露呈", "混乱の終わり", "明晰"],
            uprightMeaning: "物事がはっきり見えない時期。幻想や不安に惑わされやすい。しかし直感を信じれば闇の中にも道が見える",
            reversedMeaning: "霧が晴れ始めている。恐怖や幻想から目覚める時。真実が明らかになり、混乱が収まっていく兆し",
            astrologicalCorrespondence: "魚座", hebrewLetter: "コフ", numerologicalValue: 18,
            archetype: "夢の門番", yesNoTendency: "No"
        ),
        19: TarotMajorMeaning(
            number: 19, uprightKeywords: ["成功", "喜び", "活力", "達成"],
            reversedKeywords: ["遅延", "過信", "燃え尽き", "子供っぽさ"],
            uprightMeaning: "最も幸運なカード。成功と喜びに満ちた時期。活力に溢れ、物事が順調に進む。自信を持って前進を",
            reversedMeaning: "成功は来るがやや遅れる。過信や傲慢さに注意。エネルギーを使いすぎず、楽しみながら進むことが大切",
            astrologicalCorrespondence: "太陽", hebrewLetter: "レーシュ", numerologicalValue: 19,
            archetype: "輝く子供", yesNoTendency: "Yes"
        ),
        20: TarotMajorMeaning(
            number: 20, uprightKeywords: ["覚醒", "再生", "清算", "天命"],
            reversedKeywords: ["自己批判", "逃避", "後悔", "呼びかけの無視"],
            uprightMeaning: "内なる呼びかけに目覚める時。過去の清算と新しいステージへの移行。自分の本当の使命に気づく瞬間",
            reversedMeaning: "内なる声を無視している。過去の後悔に囚われ前に進めない。自己批判を手放し、許しと再生を",
            astrologicalCorrespondence: "冥王星", hebrewLetter: "シン", numerologicalValue: 20,
            archetype: "目覚めのラッパ", yesNoTendency: "Yes"
        ),
        21: TarotMajorMeaning(
            number: 21, uprightKeywords: ["完成", "統合", "達成", "旅の完了"],
            reversedKeywords: ["未完成", "近道", "達成の遅れ", "最後の一歩"],
            uprightMeaning: "全てが一つにまとまる完成の時。長い旅の目的地に到達。人生の一つのサイクルが美しく閉じ、次のステージへ",
            reversedMeaning: "完成まであと一歩。近道をしようとして遠回りに。最後までやり遂げる忍耐が必要",
            astrologicalCorrespondence: "土星", hebrewLetter: "タヴ", numerologicalValue: 21,
            archetype: "宇宙の踊り子", yesNoTendency: "Yes"
        ),
    ]
}

// MARK: - Minor Arcana Number Meanings

/// Meanings for minor arcana by number (shared across all suits).
struct TarotMinorNumberMeaning {
    let number: Int
    let theme: String
    let uprightEssence: String
    let reversedEssence: String

    static func meaning(for number: Int) -> TarotMinorNumberMeaning {
        meanings[number] ?? meanings[1]!
    }

    private static let meanings: [Int: TarotMinorNumberMeaning] = [
        1: TarotMinorNumberMeaning(number: 1, theme: "始まり",
            uprightEssence: "新しい可能性の種。純粋なエネルギーの発現。チャンスの到来",
            reversedEssence: "機会の見逃し。新しい始まりへの抵抗。エネルギーの空回り"),
        2: TarotMinorNumberMeaning(number: 2, theme: "二元性",
            uprightEssence: "選択とバランス。パートナーシップ。二つの力の調和",
            reversedEssence: "優柔不断。バランスの崩壊。対立の発生"),
        3: TarotMinorNumberMeaning(number: 3, theme: "創造",
            uprightEssence: "最初の実り。成長と拡大。グループでの協力",
            reversedEssence: "表現の行き詰まり。散漫。期待はずれの結果"),
        4: TarotMinorNumberMeaning(number: 4, theme: "安定",
            uprightEssence: "基盤の確立。安定と秩序。休息と充電",
            reversedEssence: "停滞。退屈。安定への固執が成長を妨げる"),
        5: TarotMinorNumberMeaning(number: 5, theme: "試練",
            uprightEssence: "変化と挑戦。困難を通じた成長。衝突と学び",
            reversedEssence: "試練の終わり。妥協。衝突の回避"),
        6: TarotMinorNumberMeaning(number: 6, theme: "調和",
            uprightEssence: "バランスの回復。与えること。協力と交流",
            reversedEssence: "不均衡。一方的な関係。報われない努力"),
        7: TarotMinorNumberMeaning(number: 7, theme: "内省",
            uprightEssence: "評価と見直し。信念の試練。内面との対話",
            reversedEssence: "混乱。自己欺瞞。選択肢に圧倒される"),
        8: TarotMinorNumberMeaning(number: 8, theme: "変容",
            uprightEssence: "動きと変化。行動の結果。速い展開",
            reversedEssence: "遅延。抵抗。変化への恐れ"),
        9: TarotMinorNumberMeaning(number: 9, theme: "完成間近",
            uprightEssence: "サイクルの終盤。蓄積された知恵。最後の試練",
            reversedEssence: "未完成。過去の問題の再浮上。手放しの必要"),
        10: TarotMinorNumberMeaning(number: 10, theme: "完了",
            uprightEssence: "サイクルの完成。過剰。次のステージへの移行",
            reversedEssence: "重荷を下ろす。過剰からの解放。新しいサイクルの予感"),
        11: TarotMinorNumberMeaning(number: 11, theme: "探求者",
            uprightEssence: "好奇心。学びの始まり。メッセージの到来",
            reversedEssence: "未熟。浅い理解。良くない知らせ"),
        12: TarotMinorNumberMeaning(number: 12, theme: "行動者",
            uprightEssence: "急速な展開。情熱的な行動。変化の推進力",
            reversedEssence: "焦り。方向性のない行動。衝動的"),
        13: TarotMinorNumberMeaning(number: 13, theme: "育成者",
            uprightEssence: "思いやり。実践的な知恵。創造的な育み",
            reversedEssence: "自己犠牲。操作。感情的な不安定"),
        14: TarotMinorNumberMeaning(number: 14, theme: "完成者",
            uprightEssence: "熟達。権威。リーダーシップの発揮",
            reversedEssence: "独裁。柔軟性の欠如。責任からの逃避"),
    ]
}

// MARK: - Elemental Dignity

/// Elemental dignity system — how elements interact when cards appear together.
/// Based on Golden Dawn tradition.
struct TarotElementalDignity {
    enum Relationship: String {
        case friendly = "親和"       // same element or complementary
        case neutral = "中立"        // elements don't strongly interact
        case hostile = "対立"        // opposing elements weaken each other

        var description: String {
            switch self {
            case .friendly: return "エネルギーが相互に強め合い、カードの意味が増幅される"
            case .neutral: return "互いに影響せず、それぞれ独立した意味を持つ"
            case .hostile: return "エネルギーがぶつかり合い、カードの力が弱まるか変容する"
            }
        }

        var score: Int {
            switch self {
            case .friendly: return 2
            case .neutral: return 0
            case .hostile: return -1
            }
        }
    }

    /// Determine the elemental relationship between two suits.
    /// Fire-Air are friendly (active). Water-Earth are friendly (passive).
    /// Fire-Water and Air-Earth are hostile (opposing).
    static func relationship(between s1: TarotSuit?, and s2: TarotSuit?) -> Relationship {
        guard let s1, let s2 else { return .neutral } // major arcana = neutral with everything
        if s1 == s2 { return .friendly }

        switch (s1, s2) {
        case (.wands, .swords), (.swords, .wands):     return .friendly  // Fire + Air
        case (.cups, .pentacles), (.pentacles, .cups):  return .friendly  // Water + Earth
        case (.wands, .cups), (.cups, .wands):          return .hostile   // Fire vs Water
        case (.swords, .pentacles), (.pentacles, .swords): return .hostile // Air vs Earth
        default:                                         return .neutral
        }
    }

    /// Analyze elemental dignity across all drawn cards in a spread.
    static func analyzeSpread(_ cards: [DrawnTarotCard]) -> String {
        guard cards.count >= 2 else { return "" }

        var friendlyPairs: [(String, String)] = []
        var hostilePairs: [(String, String)] = []

        for i in 0..<cards.count {
            for j in (i + 1)..<cards.count {
                let rel = relationship(between: cards[i].card.suit, and: cards[j].card.suit)
                let name1 = cards[i].card.japaneseName
                let name2 = cards[j].card.japaneseName
                switch rel {
                case .friendly:
                    friendlyPairs.append((name1, name2))
                case .hostile:
                    hostilePairs.append((name1, name2))
                case .neutral:
                    break
                }
            }
        }

        var analysis: [String] = []
        if !friendlyPairs.isEmpty {
            let pairs = friendlyPairs.prefix(3).map { "\($0.0)×\($0.1)" }.joined(separator: "、")
            analysis.append("親和関係：\(pairs)（互いのエネルギーが増幅）")
        }
        if !hostilePairs.isEmpty {
            let pairs = hostilePairs.prefix(3).map { "\($0.0)×\($0.1)" }.joined(separator: "、")
            analysis.append("対立関係：\(pairs)（エネルギーの衝突・変容）")
        }

        return analysis.joined(separator: "\n")
    }
}
