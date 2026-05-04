import Foundation

/// 本格的な神社おみくじデータモデル
/// Traditional Japanese shrine omikuji with all standard divination categories.
struct Omikuji: Codable, Equatable {

    // MARK: - Rank (運勢の段階)

    enum Rank: String, Codable, CaseIterable {
        case daikichi   // 大吉
        case kichi      // 吉
        case chukichi   // 中吉
        case shokichi   // 小吉
        case suekichi   // 末吉
        case kyo        // 凶

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

        /// 伝統的な順位 (1が最上)
        var traditionalOrder: Int {
            switch self {
            case .daikichi: return 1
            case .kichi:    return 2
            case .chukichi: return 3
            case .shokichi: return 4
            case .suekichi: return 5
            case .kyo:      return 6
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

        /// 伝統的な心得 (各運勢に対する心構え)
        var traditionalAdvice: String {
            switch self {
            case .daikichi:
                return "天の恵みに感謝し、慢心せず謙虚にお過ごしください。大きな運気は油断が禁物です"
            case .kichi:
                return "良き流れの中にあります。この勢いを活かし、前向きに行動されると更に吉"
            case .chukichi:
                return "穏やかな吉運です。急がず騒がず、着実に歩むことが福を呼びます"
            case .shokichi:
                return "小さな吉のしるし。些細な幸せに気づける目を持つと、運気が育ちます"
            case .suekichi:
                return "今は辛抱の時。末には吉に転じる相。焦らず心穏やかにお過ごしください"
            case .kyo:
                return "今は控えめに。凶は「これ以上悪くならない」の証。身を慎めば必ず好転します"
            }
        }
    }

    // MARK: - Traditional Categories (伝統的おみくじ項目)

    struct TraditionalCategories: Codable, Equatable {
        let wish: CategoryFortune       // 願望（ねがいごと）
        let awaitedPerson: CategoryFortune  // 待人（まちびと）
        let lostItem: CategoryFortune    // 失物（うせもの）
        let travel: CategoryFortune      // 旅行（たびだち）
        let study: CategoryFortune       // 学問（がくもん）
        let dispute: CategoryFortune     // 争事（あらそいごと）
        let love: CategoryFortune        // 恋愛（れんあい）
        let moving: CategoryFortune      // 転居（やどがえ）
        let illness: CategoryFortune     // 病気（やまい）
        let marriage: CategoryFortune    // 縁談（えんだん）
    }

    struct CategoryFortune: Codable, Equatable {
        let categoryName: String
        let reading: String  // 読み仮名
        let fortune: String  // 占い結果の文言
    }

    // MARK: - Properties

    let rank: Rank
    let wakaPoem: String          // 和歌（伝統的おみくじの歌）
    let wakaInterpretation: String // 和歌の解釈
    let poem: String               // 現代語の御言葉
    let guidance: String           // 本日の指針
    let traditionalCategories: TraditionalCategories
    let luckyDirection: String
    let luckyTime: String
    let luckyItem: String
    let luckyColor: String
    let loveHint: String
    let workHint: String
    let moneyHint: String
    let healthHint: String
    let calendarContext: String    // 暦との関連（六曜・特殊日）

    var headline: String {
        "本日のおみくじは「\(rank.japaneseName)」です。"
    }

    var isAuspicious: Bool {
        rank != .kyo
    }

    // MARK: - Preview

    static let preview = Omikuji(
        rank: .daikichi,
        wakaPoem: "春の野に 霞たなびき しづ心なく 花のちるらむ",
        wakaInterpretation: "春の霞のように穏やかな心でいれば、自然と福が舞い降ります",
        poem: "朝の光を受ける枝のように、素直な気持ちが運を呼び込みます。",
        guidance: "今日は迷いを抱え込むより、ひとつ決めて軽やかに進むほど流れが整います。",
        traditionalCategories: TraditionalCategories(
            wish: CategoryFortune(categoryName: "願望", reading: "ねがいごと", fortune: "叶う。ただし焦らず時を待つべし"),
            awaitedPerson: CategoryFortune(categoryName: "待人", reading: "まちびと", fortune: "来る。思わぬ方角より"),
            lostItem: CategoryFortune(categoryName: "失物", reading: "うせもの", fortune: "出る。高きところを探すべし"),
            travel: CategoryFortune(categoryName: "旅行", reading: "たびだち", fortune: "吉。東南の方角よし"),
            study: CategoryFortune(categoryName: "学問", reading: "がくもん", fortune: "努力実る。信じて進むべし"),
            dispute: CategoryFortune(categoryName: "争事", reading: "あらそいごと", fortune: "控えるが吉。和をもって尊しとなす"),
            love: CategoryFortune(categoryName: "恋愛", reading: "れんあい", fortune: "良縁あり。素直な心が吉"),
            moving: CategoryFortune(categoryName: "転居", reading: "やどがえ", fortune: "よし。新しい風が福を運ぶ"),
            illness: CategoryFortune(categoryName: "病気", reading: "やまい", fortune: "快方に向かう。養生を怠るなかれ"),
            marriage: CategoryFortune(categoryName: "縁談", reading: "えんだん", fortune: "良し。誠実さが実を結ぶ")
        ),
        luckyDirection: "東南",
        luckyTime: "10時から12時",
        luckyItem: "白い便箋",
        luckyColor: "朱色",
        loveHint: "やさしい言葉を先に差し出すほど、ご縁が深まりやすい日です。",
        workHint: "最初の一手を丁寧に整えると、その後の判断が驚くほど滑らかになります。",
        moneyHint: "今日は増やすことより、使い道を整える姿勢が金運を支えます。",
        healthHint: "深い呼吸を意識すると、身体の巡りが整いやすい日です。",
        calendarContext: "大安・一粒万倍日"
    )
}
