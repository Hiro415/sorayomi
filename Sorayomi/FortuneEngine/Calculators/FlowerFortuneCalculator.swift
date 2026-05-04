import Foundation

/// 花占いの計算エンジン — 誕生花と今日の花の共鳴を算出する
struct FlowerFortuneCalculator {

    // MARK: - Public API

    /// 誕生日から花プロフィールを生成
    static func profile(from birthday: Date) -> FlowerProfile {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)

        let monthFlower = monthFlowers[month] ?? monthFlowers[1]!
        let dayFlower = dayFlowers[day] ?? dayFlowers[1]!

        let primaryHanakotoba = monthFlower.hanakotoba.first ?? "美"
        let personality = personalityFromFlower(monthFlower, dayFlower: dayFlower)

        return FlowerProfile(
            birthMonthFlower: monthFlower,
            birthDayFlower: dayFlower,
            primaryHanakotoba: primaryHanakotoba,
            personalityTraits: personality
        )
    }

    /// 今日の花エネルギーを算出
    static func dailyEnergy(birthday: Date, on date: Date = Date()) -> DailyFlowerEnergy {
        let profile = profile(from: birthday)
        let today = todaysFlower(for: date)
        return buildDailyEnergy(birthFlower: profile.birthMonthFlower, todaysFlower: today, date: date)
    }

    /// 今日の花を決定論的に取得
    static func todaysFlower(for date: Date = Date()) -> Flower {
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let seed = dayOfYear + year * 7
        let index = seed % allFlowers.count
        return allFlowers[index]
    }

    /// 誕生日未設定時のフォールバックプロフィール
    static func fallbackProfile(flower: Flower) -> FlowerProfile {
        FlowerProfile(
            birthMonthFlower: flower,
            birthDayFlower: flower,
            primaryHanakotoba: flower.hanakotoba.first ?? "美",
            personalityTraits: "花の持つ自然な美しさと調和の力が、あなたの本質に寄り添います"
        )
    }

    /// 誕生日未設定時のフォールバックデイリーエネルギー
    static func fallbackDailyEnergy(flower: Flower) -> DailyFlowerEnergy {
        DailyFlowerEnergy(
            todaysFlower: flower,
            todaysHanakotoba: flower.hanakotoba.first ?? "美",
            resonanceScore: 3,
            resonanceDescription: "今日の花が、あなたに穏やかなメッセージを届けています",
            combinedMessage: "「\(flower.hanakotoba.first ?? "美")」の花言葉が示す通り、今日は自然体で過ごすのが吉",
            luckyFlowerAction: "花に触れる時間を作ると、心が整います"
        )
    }

    // MARK: - Private Logic

    private static func buildDailyEnergy(birthFlower: Flower, todaysFlower: Flower, date: Date) -> DailyFlowerEnergy {
        // 元素相性スコア
        var score = FlowerElement.resonance(between: birthFlower.element, and: todaysFlower.element)

        // 季節一致ボーナス
        let currentSeason = FlowerSeason.current(for: date)
        if todaysFlower.season == currentSeason {
            score = min(score + 1, 5)
        }

        let resonanceDesc = resonanceDescription(birth: birthFlower, today: todaysFlower, score: score)
        let combined = combinedMessage(birth: birthFlower, today: todaysFlower)
        let action = luckyAction(todaysFlower: todaysFlower, score: score)

        return DailyFlowerEnergy(
            todaysFlower: todaysFlower,
            todaysHanakotoba: todaysFlower.hanakotoba.first ?? "美",
            resonanceScore: score,
            resonanceDescription: resonanceDesc,
            combinedMessage: combined,
            luckyFlowerAction: action
        )
    }

    private static func resonanceDescription(birth: Flower, today: Flower, score: Int) -> String {
        let birthElement = birth.element.rawValue
        let todayElement = today.element.rawValue
        switch score {
        case 5:
            return "\(birth.japaneseName)と\(today.japaneseName)は同じ\(birthElement)の力を持ち、深い共鳴が生まれています"
        case 4:
            return "\(birthElement)と\(todayElement)の花が出会い、互いの力を高め合う好相性です"
        case 3:
            return "\(birth.japaneseName)の\(birthElement)と\(today.japaneseName)の\(todayElement)が穏やかに調和しています"
        case 2:
            return "\(birthElement)と\(todayElement)は対照的な力。意識的なバランスが今日の鍵です"
        default:
            return "\(birth.japaneseName)と\(today.japaneseName)の間に、静かな対話が生まれています"
        }
    }

    private static func combinedMessage(birth: Flower, today: Flower) -> String {
        let birthWord = birth.hanakotoba.first ?? "美"
        let todayWord = today.hanakotoba.first ?? "希望"
        return "「\(birthWord)」を持つあなたに、今日は「\(todayWord)」の花が寄り添います。二つの花言葉が重なるとき、新しい気づきが芽生えるでしょう"
    }

    private static func luckyAction(todaysFlower: Flower, score: Int) -> String {
        switch score {
        case 5: return "\(todaysFlower.japaneseName)の色を身につけると、花との共鳴がさらに高まります"
        case 4: return "窓辺に花を飾ると、今日のエネルギーが巡りやすくなります"
        case 3: return "花の香りを意識すると、穏やかな気持ちで過ごせます"
        case 2: return "自然の中を歩くと、花のバランスが心に届きやすくなります"
        default: return "花に触れる時間を作ると、心が整います"
        }
    }

    private static func personalityFromFlower(_ monthFlower: Flower, dayFlower: Flower) -> String {
        let monthWord = monthFlower.hanakotoba.first ?? "美"
        let dayWord = dayFlower.hanakotoba.first ?? "誠実"
        return "「\(monthWord)」の\(monthFlower.japaneseName)と「\(dayWord)」の\(dayFlower.japaneseName)を持つあなたは、内に静かな強さと繊細な感性を兼ね備えています"
    }

    // MARK: - Flower Database

    /// 誕生月の花（12ヶ月）
    static let monthFlowers: [Int: Flower] = [
        1: Flower(id: "suisen", japaneseName: "水仙", englishName: "Narcissus",
                  hanakotoba: ["自己愛", "神秘"], season: .winter, colorHex: "#FFFACD", element: .water),
        2: Flower(id: "ume", japaneseName: "梅", englishName: "Plum Blossom",
                  hanakotoba: ["忍耐", "高潔"], season: .winter, colorHex: "#FFB7C5", element: .earth),
        3: Flower(id: "momo", japaneseName: "桃", englishName: "Peach Blossom",
                  hanakotoba: ["チャーミング", "天下無敵"], season: .spring, colorHex: "#FFB6C1", element: .fire),
        4: Flower(id: "sakura", japaneseName: "桜", englishName: "Cherry Blossom",
                  hanakotoba: ["精神の美", "優美"], season: .spring, colorHex: "#FFD1DC", element: .wind),
        5: Flower(id: "ayame", japaneseName: "菖蒲", englishName: "Iris",
                  hanakotoba: ["良い便り", "メッセージ"], season: .spring, colorHex: "#7B68EE", element: .water),
        6: Flower(id: "bara", japaneseName: "薔薇", englishName: "Rose",
                  hanakotoba: ["愛", "美"], season: .summer, colorHex: "#FF6B6B", element: .fire),
        7: Flower(id: "hasu", japaneseName: "蓮", englishName: "Lotus",
                  hanakotoba: ["清らかな心", "神聖"], season: .summer, colorHex: "#F8C8DC", element: .light),
        8: Flower(id: "himawari", japaneseName: "向日葵", englishName: "Sunflower",
                  hanakotoba: ["憧れ", "情熱"], season: .summer, colorHex: "#FFD700", element: .fire),
        9: Flower(id: "rindou", japaneseName: "竜胆", englishName: "Gentian",
                  hanakotoba: ["悲しんでるあなたを愛す", "正義"], season: .autumn, colorHex: "#4169E1", element: .water),
        10: Flower(id: "kiku", japaneseName: "菊", englishName: "Chrysanthemum",
                   hanakotoba: ["高貴", "長寿"], season: .autumn, colorHex: "#FFD700", element: .earth),
        11: Flower(id: "tsubaki", japaneseName: "椿", englishName: "Camellia",
                   hanakotoba: ["控えめな素晴らしさ", "謙虚"], season: .autumn, colorHex: "#DC143C", element: .wind),
        12: Flower(id: "hiiragi", japaneseName: "柊", englishName: "Holly",
                   hanakotoba: ["先見の明", "用心"], season: .winter, colorHex: "#228B22", element: .earth),
    ]

    /// 誕生日の花（1〜31日）
    static let dayFlowers: [Int: Flower] = [
        1: Flower(id: "sumire", japaneseName: "すみれ", englishName: "Violet",
                  hanakotoba: ["謙虚", "誠実"], season: .spring, colorHex: "#8A2BE2", element: .water),
        2: Flower(id: "tanpopo", japaneseName: "たんぽぽ", englishName: "Dandelion",
                  hanakotoba: ["真心の愛", "幸福"], season: .spring, colorHex: "#FFD700", element: .light),
        3: Flower(id: "ajisai", japaneseName: "あじさい", englishName: "Hydrangea",
                  hanakotoba: ["移り気", "辛抱強い愛"], season: .summer, colorHex: "#6495ED", element: .water),
        4: Flower(id: "lavender", japaneseName: "ラベンダー", englishName: "Lavender",
                  hanakotoba: ["沈黙", "期待"], season: .summer, colorHex: "#B57EDC", element: .wind),
        5: Flower(id: "cosmos", japaneseName: "コスモス", englishName: "Cosmos",
                  hanakotoba: ["調和", "乙女の真心"], season: .autumn, colorHex: "#FF69B4", element: .wind),
        6: Flower(id: "nadeshiko", japaneseName: "撫子", englishName: "Pink",
                  hanakotoba: ["大胆", "純愛"], season: .summer, colorHex: "#FF6EB4", element: .fire),
        7: Flower(id: "asagao", japaneseName: "朝顔", englishName: "Morning Glory",
                  hanakotoba: ["はかない恋", "固い絆"], season: .summer, colorHex: "#4B0082", element: .water),
        8: Flower(id: "yuuri", japaneseName: "百合", englishName: "Lily",
                  hanakotoba: ["純粋", "威厳"], season: .summer, colorHex: "#FFFFF0", element: .light),
        9: Flower(id: "kinmokusei", japaneseName: "金木犀", englishName: "Osmanthus",
                  hanakotoba: ["謙虚", "真実"], season: .autumn, colorHex: "#FFA500", element: .earth),
        10: Flower(id: "gerbera", japaneseName: "ガーベラ", englishName: "Gerbera",
                   hanakotoba: ["希望", "前進"], season: .spring, colorHex: "#FF4500", element: .fire),
        11: Flower(id: "fuji", japaneseName: "藤", englishName: "Wisteria",
                   hanakotoba: ["優しさ", "歓迎"], season: .spring, colorHex: "#8674A1", element: .wind),
        12: Flower(id: "suzuran", japaneseName: "鈴蘭", englishName: "Lily of the Valley",
                   hanakotoba: ["再び幸せが訪れる", "純粋"], season: .spring, colorHex: "#F5F5F5", element: .light),
        13: Flower(id: "carnation", japaneseName: "カーネーション", englishName: "Carnation",
                   hanakotoba: ["無垢で深い愛", "感謝"], season: .spring, colorHex: "#FF69B4", element: .fire),
        14: Flower(id: "anemone", japaneseName: "アネモネ", englishName: "Anemone",
                   hanakotoba: ["はかない恋", "期待"], season: .spring, colorHex: "#DC143C", element: .wind),
        15: Flower(id: "tulip", japaneseName: "チューリップ", englishName: "Tulip",
                   hanakotoba: ["思いやり", "博愛"], season: .spring, colorHex: "#FF6347", element: .earth),
        16: Flower(id: "higanbana", japaneseName: "彼岸花", englishName: "Spider Lily",
                   hanakotoba: ["悲しき思い出", "再会"], season: .autumn, colorHex: "#FF0000", element: .fire),
        17: Flower(id: "sakurasou", japaneseName: "桜草", englishName: "Primrose",
                   hanakotoba: ["初恋", "憧れ"], season: .spring, colorHex: "#FFB6C1", element: .water),
        18: Flower(id: "freesia", japaneseName: "フリージア", englishName: "Freesia",
                   hanakotoba: ["あどけなさ", "親愛の情"], season: .spring, colorHex: "#FFFF99", element: .light),
        19: Flower(id: "cattleya", japaneseName: "カトレア", englishName: "Cattleya",
                   hanakotoba: ["優美な貴婦人", "魅力"], season: .winter, colorHex: "#DA70D6", element: .fire),
        20: Flower(id: "pansy", japaneseName: "パンジー", englishName: "Pansy",
                   hanakotoba: ["物思い", "思い出"], season: .spring, colorHex: "#7F00FF", element: .earth),
        21: Flower(id: "plumeria", japaneseName: "プルメリア", englishName: "Plumeria",
                   hanakotoba: ["気品", "恵まれた人"], season: .summer, colorHex: "#FAFAD2", element: .light),
        22: Flower(id: "marguerite", japaneseName: "マーガレット", englishName: "Marguerite",
                   hanakotoba: ["恋占い", "真実の愛"], season: .spring, colorHex: "#FFFAFA", element: .wind),
        23: Flower(id: "dahlia", japaneseName: "ダリア", englishName: "Dahlia",
                   hanakotoba: ["華麗", "感謝"], season: .summer, colorHex: "#B22222", element: .fire),
        24: Flower(id: "wasurenagusa", japaneseName: "勿忘草", englishName: "Forget-me-not",
                   hanakotoba: ["真実の愛", "私を忘れないで"], season: .spring, colorHex: "#87CEEB", element: .water),
        25: Flower(id: "peony", japaneseName: "牡丹", englishName: "Peony",
                   hanakotoba: ["王者の風格", "富貴"], season: .spring, colorHex: "#FF1493", element: .earth),
        26: Flower(id: "orchid", japaneseName: "蘭", englishName: "Orchid",
                   hanakotoba: ["優雅", "美しい淑女"], season: .spring, colorHex: "#DA70D6", element: .light),
        27: Flower(id: "clematis", japaneseName: "クレマチス", englishName: "Clematis",
                   hanakotoba: ["精神の美", "旅人の喜び"], season: .spring, colorHex: "#9370DB", element: .wind),
        28: Flower(id: "camellia_sasanqua", japaneseName: "山茶花", englishName: "Sasanqua",
                   hanakotoba: ["困難に打ち勝つ", "ひたむきさ"], season: .winter, colorHex: "#FF69B4", element: .earth),
        29: Flower(id: "olive", japaneseName: "オリーブ", englishName: "Olive",
                   hanakotoba: ["平和", "知恵"], season: .autumn, colorHex: "#808000", element: .earth),
        30: Flower(id: "lotus_blue", japaneseName: "睡蓮", englishName: "Water Lily",
                   hanakotoba: ["清純な心", "信仰"], season: .summer, colorHex: "#ADD8E6", element: .water),
        31: Flower(id: "wintersweet", japaneseName: "蝋梅", englishName: "Wintersweet",
                   hanakotoba: ["慈しみ", "先導"], season: .winter, colorHex: "#FFFF99", element: .light),
    ]

    /// 全花プール（月花 + 日花）
    static let allFlowers: [Flower] = {
        var flowers: [Flower] = []
        for month in 1...12 {
            if let f = monthFlowers[month] { flowers.append(f) }
        }
        for day in 1...31 {
            if let f = dayFlowers[day] { flowers.append(f) }
        }
        return flowers
    }()
}
