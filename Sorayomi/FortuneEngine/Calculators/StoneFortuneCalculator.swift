import Foundation

/// ストーン占いの計算エンジン — 誕生石と今日のパワーストーンの共鳴を算出する
struct StoneFortuneCalculator {

    // MARK: - Public API

    /// 誕生日から石プロフィールを生成
    static func profile(from birthday: Date) -> StoneProfile {
        let month = Calendar(identifier: .gregorian).component(.month, from: birthday)
        let stone = birthstones[month] ?? birthstones[1]!

        let message = birthstoneMessage(for: stone)
        let personality = personalityFromStone(stone)

        return StoneProfile(
            birthstone: stone,
            birthstoneMessage: message,
            personalityFromStone: personality
        )
    }

    /// 今日のストーンエネルギーを算出
    static func dailyEnergy(birthday: Date, on date: Date = Date()) -> DailyStoneEnergy {
        let stoneProfile = profile(from: birthday)
        let today = todaysStone(for: date)
        return buildDailyEnergy(birthstone: stoneProfile.birthstone, todaysStone: today)
    }

    /// 今日のパワーストーンを決定論的に取得
    static func todaysStone(for date: Date = Date()) -> PowerStone {
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let seed = dayOfYear + year * 13
        let index = seed % dailyStonePool.count
        return dailyStonePool[index]
    }

    /// 誕生日未設定時のフォールバック
    static func fallbackProfile(stone: PowerStone) -> StoneProfile {
        StoneProfile(
            birthstone: stone,
            birthstoneMessage: "今日のパワーストーンが、あなたを静かに守り導きます",
            personalityFromStone: "石の持つ安定した力が、あなたの本質に寄り添います"
        )
    }

    static func fallbackDailyEnergy(stone: PowerStone) -> DailyStoneEnergy {
        DailyStoneEnergy(
            todaysStone: stone,
            resonanceScore: 3,
            resonanceDescription: "今日のパワーストーンが、穏やかなエネルギーを届けています",
            elementInteraction: "\(stone.element.rawValue)の力が安定した流れを作っています",
            chakraAlignment: "\(stone.chakra.rawValue)が活性化し、心身のバランスを整えます",
            recommendedAction: "パワーストーンの色を意識すると、石との共鳴が高まります"
        )
    }

    // MARK: - Private Logic

    private static func buildDailyEnergy(birthstone: PowerStone, todaysStone: PowerStone) -> DailyStoneEnergy {
        // 元素相性スコア (1-5)
        let elementScore = StoneElement.resonance(between: birthstone.element, and: todaysStone.element)

        // チャクラ距離ボーナス (近いほど高い: 距離0=+2, 1=+1, 2=0, 3以上=-1)
        let chakraDistance = Chakra.distance(between: birthstone.chakra, and: todaysStone.chakra)
        let chakraBonus: Int
        switch chakraDistance {
        case 0:    chakraBonus = 2
        case 1:    chakraBonus = 1
        case 2:    chakraBonus = 0
        default:   chakraBonus = -1
        }

        let score = max(1, min(5, (elementScore + chakraBonus + 1) / 2 + 1))

        let resonanceDesc = resonanceDescription(birth: birthstone, today: todaysStone, score: score)
        let elementInteraction = elementInteractionText(birth: birthstone, today: todaysStone)
        let chakraAlignment = chakraAlignmentText(birth: birthstone, today: todaysStone)
        let action = recommendedAction(todaysStone: todaysStone, score: score)

        return DailyStoneEnergy(
            todaysStone: todaysStone,
            resonanceScore: score,
            resonanceDescription: resonanceDesc,
            elementInteraction: elementInteraction,
            chakraAlignment: chakraAlignment,
            recommendedAction: action
        )
    }

    private static func resonanceDescription(birth: PowerStone, today: PowerStone, score: Int) -> String {
        switch score {
        case 5:
            return "\(birth.japaneseName)と\(today.japaneseName)が深い共鳴を起こし、強い守護の力が生まれています"
        case 4:
            return "\(birth.japaneseName)と\(today.japaneseName)のエネルギーが調和し、心地よい流れを作っています"
        case 3:
            return "\(birth.japaneseName)と\(today.japaneseName)の間に穏やかな共鳴が生まれています"
        case 2:
            return "\(birth.japaneseName)と\(today.japaneseName)は異なる波動。意識的な調和がポイントです"
        default:
            return "\(birth.japaneseName)と\(today.japaneseName)の間に静かな対話が始まっています"
        }
    }

    private static func elementInteractionText(birth: PowerStone, today: PowerStone) -> String {
        let b = birth.element.rawValue
        let t = today.element.rawValue
        if birth.element == today.element {
            return "同じ\(b)の力が重なり、石のエネルギーがいつもより強く感じられます"
        }
        return "\(b)の\(birth.japaneseName)と\(t)の\(today.japaneseName)が出会い、新しいエネルギーの流れが生まれます"
    }

    private static func chakraAlignmentText(birth: PowerStone, today: PowerStone) -> String {
        let distance = Chakra.distance(between: birth.chakra, and: today.chakra)
        if distance == 0 {
            return "\(birth.chakra.rawValue)に集中した強いエネルギーが流れています。心身の深い安定が期待できます"
        } else if distance <= 2 {
            return "\(birth.chakra.rawValue)と\(today.chakra.rawValue)が連携し、エネルギーの流れがスムーズです"
        } else {
            return "\(birth.chakra.rawValue)から\(today.chakra.rawValue)まで広い範囲にエネルギーが巡り、全体的なバランスを整えます"
        }
    }

    private static func recommendedAction(todaysStone: PowerStone, score: Int) -> String {
        switch score {
        case 5: return "\(todaysStone.japaneseName)を身につけると、今日の守護力が最大限に発揮されます"
        case 4: return "\(todaysStone.japaneseName)の色を意識して過ごすと、石との共鳴が高まります"
        case 3: return "パワーストーンに触れる時間を作ると、心が落ち着きます"
        case 2: return "深呼吸しながら石のイメージを思い浮かべると、エネルギーが整います"
        default: return "静かな場所で石の存在を感じると、穏やかな力が届きます"
        }
    }

    private static func birthstoneMessage(for stone: PowerStone) -> String {
        let props = stone.properties.joined(separator: "・")
        return "\(stone.japaneseName)は「\(props)」の力を持つあなたの守護石。生まれ持ったエネルギーの源です"
    }

    private static func personalityFromStone(_ stone: PowerStone) -> String {
        let mainProp = stone.properties.first ?? "安定"
        return "\(stone.japaneseName)に守られたあなたは、「\(mainProp)」を軸に持つ芯の通った人。\(stone.healingAspect)の力が、日々の支えになっています"
    }

    // MARK: - Stone Database

    /// 誕生石（12ヶ月）
    static let birthstones: [Int: PowerStone] = [
        1: PowerStone(id: "garnet", japaneseName: "ガーネット", englishName: "Garnet",
                      colorHex: "#8B0000", element: .fire, chakra: .root,
                      properties: ["情熱", "実り", "真実"],
                      healingAspect: "心身の活力を高める", protectionAspect: "困難からの守護", luckAspect: "目標達成の運"),
        2: PowerStone(id: "amethyst", japaneseName: "アメジスト", englishName: "Amethyst",
                      colorHex: "#9966CC", element: .void, chakra: .crown,
                      properties: ["直感", "浄化", "高貴"],
                      healingAspect: "心の平穏をもたらす", protectionAspect: "邪気からの浄化", luckAspect: "知恵と直感の開花"),
        3: PowerStone(id: "aquamarine", japaneseName: "アクアマリン", englishName: "Aquamarine",
                      colorHex: "#7FFFD4", element: .water, chakra: .throat,
                      properties: ["勇気", "幸福", "聡明"],
                      healingAspect: "コミュニケーション力の向上", protectionAspect: "旅の安全", luckAspect: "幸福な人間関係"),
        4: PowerStone(id: "diamond", japaneseName: "ダイヤモンド", englishName: "Diamond",
                      colorHex: "#F0F0FF", element: .wind, chakra: .crown,
                      properties: ["永遠の絆", "純潔", "勝利"],
                      healingAspect: "精神の明晰さ", protectionAspect: "あらゆる邪念からの守護", luckAspect: "不変の成功"),
        5: PowerStone(id: "emerald", japaneseName: "エメラルド", englishName: "Emerald",
                      colorHex: "#50C878", element: .earth, chakra: .heart,
                      properties: ["幸運", "愛", "叡智"],
                      healingAspect: "感情の癒し", protectionAspect: "人間関係の守護", luckAspect: "豊かさと繁栄"),
        6: PowerStone(id: "moonstone", japaneseName: "ムーンストーン", englishName: "Moonstone",
                      colorHex: "#C4C4E0", element: .water, chakra: .thirdEye,
                      properties: ["直感", "恋の予感", "癒し"],
                      healingAspect: "感受性の調整", protectionAspect: "月の光による浄化", luckAspect: "恋愛運の向上"),
        7: PowerStone(id: "ruby", japaneseName: "ルビー", englishName: "Ruby",
                      colorHex: "#E0115F", element: .fire, chakra: .heart,
                      properties: ["情熱", "勝利", "威厳"],
                      healingAspect: "生命力の活性化", protectionAspect: "災いからの守護", luckAspect: "勝負運の上昇"),
        8: PowerStone(id: "peridot", japaneseName: "ペリドット", englishName: "Peridot",
                      colorHex: "#9ACD32", element: .earth, chakra: .solar,
                      properties: ["夫婦の幸福", "希望", "太陽"],
                      healingAspect: "ストレス軽減", protectionAspect: "ネガティブエネルギーの浄化", luckAspect: "家庭の幸福"),
        9: PowerStone(id: "sapphire", japaneseName: "サファイア", englishName: "Sapphire",
                      colorHex: "#0F52BA", element: .water, chakra: .throat,
                      properties: ["誠実", "慈愛", "真理"],
                      healingAspect: "心の安定", protectionAspect: "真実の守護", luckAspect: "知的成長"),
        10: PowerStone(id: "opal", japaneseName: "オパール", englishName: "Opal",
                       colorHex: "#A8C8F0", element: .wind, chakra: .sacral,
                       properties: ["創造", "希望", "無邪気"],
                       healingAspect: "創造力の解放", protectionAspect: "感情の安定", luckAspect: "芸術的才能の開花"),
        11: PowerStone(id: "topaz", japaneseName: "トパーズ", englishName: "Topaz",
                       colorHex: "#FFC87C", element: .wind, chakra: .solar,
                       properties: ["友情", "潔白", "希望"],
                       healingAspect: "自信の回復", protectionAspect: "悪意からの守護", luckAspect: "社交運の向上"),
        12: PowerStone(id: "turquoise", japaneseName: "ターコイズ", englishName: "Turquoise",
                       colorHex: "#40E0D0", element: .earth, chakra: .throat,
                       properties: ["成功", "旅の安全", "冒険"],
                       healingAspect: "心身の疲労回復", protectionAspect: "旅と冒険の守護", luckAspect: "新しい出会い"),
    ]

    /// 日替わりパワーストーンプール（20種）
    static let dailyStonePool: [PowerStone] = [
        PowerStone(id: "rose_quartz", japaneseName: "ローズクォーツ", englishName: "Rose Quartz",
                   colorHex: "#F7CAC9", element: .water, chakra: .heart,
                   properties: ["恋愛", "癒し", "優しさ"],
                   healingAspect: "心の傷の癒し", protectionAspect: "愛の守護", luckAspect: "恋愛運の上昇"),
        PowerStone(id: "tiger_eye", japaneseName: "タイガーアイ", englishName: "Tiger's Eye",
                   colorHex: "#B8860B", element: .earth, chakra: .solar,
                   properties: ["洞察", "決断", "金運"],
                   healingAspect: "集中力の向上", protectionAspect: "邪気からの守護", luckAspect: "金運・仕事運"),
        PowerStone(id: "lapis_lazuli", japaneseName: "ラピスラズリ", englishName: "Lapis Lazuli",
                   colorHex: "#26619C", element: .void, chakra: .thirdEye,
                   properties: ["真実", "知恵", "幸運"],
                   healingAspect: "精神の浄化", protectionAspect: "真実を見抜く力", luckAspect: "幸運の到来"),
        PowerStone(id: "citrine", japaneseName: "シトリン", englishName: "Citrine",
                   colorHex: "#E4D00A", element: .fire, chakra: .solar,
                   properties: ["繁栄", "商売繁盛", "明るさ"],
                   healingAspect: "ポジティブ思考", protectionAspect: "ネガティブの浄化", luckAspect: "金運の向上"),
        PowerStone(id: "carnelian", japaneseName: "カーネリアン", englishName: "Carnelian",
                   colorHex: "#B31B1B", element: .fire, chakra: .sacral,
                   properties: ["勇気", "行動力", "活力"],
                   healingAspect: "エネルギーの回復", protectionAspect: "恐れからの解放", luckAspect: "新しい挑戦の成功"),
        PowerStone(id: "malachite", japaneseName: "マラカイト", englishName: "Malachite",
                   colorHex: "#0BDA51", element: .earth, chakra: .heart,
                   properties: ["癒し", "浄化", "洞察"],
                   healingAspect: "深い心の癒し", protectionAspect: "災いの回避", luckAspect: "成長の促進"),
        PowerStone(id: "hematite", japaneseName: "ヘマタイト", englishName: "Hematite",
                   colorHex: "#5A5A5A", element: .earth, chakra: .root,
                   properties: ["勝利", "自信", "グラウンディング"],
                   healingAspect: "肉体の安定", protectionAspect: "ネガティブエネルギーの反射", luckAspect: "勝負運"),
        PowerStone(id: "fluorite", japaneseName: "フローライト", englishName: "Fluorite",
                   colorHex: "#7CFC00", element: .wind, chakra: .thirdEye,
                   properties: ["集中", "明晰", "調和"],
                   healingAspect: "精神的な明晰さ", protectionAspect: "精神の安定", luckAspect: "学業・仕事の成功"),
        PowerStone(id: "obsidian", japaneseName: "オブシディアン", englishName: "Obsidian",
                   colorHex: "#1C1C1C", element: .void, chakra: .root,
                   properties: ["守護", "真実", "浄化"],
                   healingAspect: "深層心理の癒し", protectionAspect: "強力な魔除け", luckAspect: "自己発見"),
        PowerStone(id: "aventurine", japaneseName: "アベンチュリン", englishName: "Aventurine",
                   colorHex: "#568203", element: .earth, chakra: .heart,
                   properties: ["癒し", "安心", "繁栄"],
                   healingAspect: "心の安らぎ", protectionAspect: "ストレスからの守護", luckAspect: "幸運の引き寄せ"),
        PowerStone(id: "onyx", japaneseName: "オニキス", englishName: "Onyx",
                   colorHex: "#353839", element: .void, chakra: .root,
                   properties: ["忍耐", "自己防衛", "意志"],
                   healingAspect: "精神力の強化", protectionAspect: "悪縁からの守護", luckAspect: "目標達成"),
        PowerStone(id: "labradorite", japaneseName: "ラブラドライト", englishName: "Labradorite",
                   colorHex: "#6E7F80", element: .void, chakra: .thirdEye,
                   properties: ["直感", "変容", "覚醒"],
                   healingAspect: "意識の拡大", protectionAspect: "オーラの浄化", luckAspect: "直感力の向上"),
        PowerStone(id: "amazonite", japaneseName: "アマゾナイト", englishName: "Amazonite",
                   colorHex: "#00C5CD", element: .water, chakra: .heart,
                   properties: ["希望", "信頼", "調和"],
                   healingAspect: "心のバランス", protectionAspect: "不安の軽減", luckAspect: "人間関係の改善"),
        PowerStone(id: "sodalite", japaneseName: "ソーダライト", englishName: "Sodalite",
                   colorHex: "#2A3756", element: .water, chakra: .throat,
                   properties: ["知性", "直感", "冷静"],
                   healingAspect: "思考の整理", protectionAspect: "パニックからの守護", luckAspect: "コミュニケーション運"),
        PowerStone(id: "sunstone", japaneseName: "サンストーン", englishName: "Sunstone",
                   colorHex: "#FF6633", element: .fire, chakra: .sacral,
                   properties: ["自信", "リーダーシップ", "喜び"],
                   healingAspect: "自己肯定感の向上", protectionAspect: "依存からの解放", luckAspect: "リーダー運"),
        PowerStone(id: "chrysocolla", japaneseName: "クリソコラ", englishName: "Chrysocolla",
                   colorHex: "#1CA9C9", element: .water, chakra: .throat,
                   properties: ["表現", "女性性", "癒し"],
                   healingAspect: "感情の浄化", protectionAspect: "心の安定", luckAspect: "表現力の開花"),
        PowerStone(id: "rhodonite", japaneseName: "ロードナイト", englishName: "Rhodonite",
                   colorHex: "#E75480", element: .fire, chakra: .heart,
                   properties: ["友愛", "寛容", "回復"],
                   healingAspect: "傷ついた心の修復", protectionAspect: "感情的な安定", luckAspect: "人間関係の修復"),
        PowerStone(id: "jade", japaneseName: "翡翠", englishName: "Jade",
                   colorHex: "#00A86B", element: .earth, chakra: .heart,
                   properties: ["長寿", "繁栄", "調和"],
                   healingAspect: "心身の調和", protectionAspect: "魔除け", luckAspect: "健康運・金運"),
        PowerStone(id: "clear_quartz", japaneseName: "水晶", englishName: "Clear Quartz",
                   colorHex: "#F5F5F5", element: .wind, chakra: .crown,
                   properties: ["浄化", "増幅", "万能"],
                   healingAspect: "エネルギーの浄化と増幅", protectionAspect: "あらゆるネガティブの浄化", luckAspect: "総合運の上昇"),
        PowerStone(id: "agate", japaneseName: "アゲート", englishName: "Agate",
                   colorHex: "#B87333", element: .earth, chakra: .root,
                   properties: ["安定", "勇気", "結束"],
                   healingAspect: "心身の安定", protectionAspect: "家庭の守護", luckAspect: "対人運の向上"),
    ]
}
