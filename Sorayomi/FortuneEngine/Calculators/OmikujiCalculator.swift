import Foundation

/// 本格おみくじ抽選エンジン
/// Draws a deterministic daily omikuji integrating real calendar data (六曜, 特殊日, 干支)
/// with traditional shrine omikuji format including waka poems and all 10 standard categories.
enum OmikujiCalculator {

    // MARK: - Traditional Probability Distribution
    // 浅草寺の伝統的確率分布に基づく: 大吉17%, 吉35%, 中吉18%, 小吉13%, 末吉10%, 凶7%

    private static let weightedRanks: [Omikuji.Rank] = [
        .daikichi, .daikichi,                           // 17%
        .kichi, .kichi, .kichi, .kichi,                 // 35%
        .chukichi, .chukichi,                           // 18%
        .shokichi, .shokichi,                           // 13% (approx)
        .suekichi,                                       // 10%
        .kyo                                             // 7%
    ]

    // MARK: - 和歌集 (Waka Poems - 伝統的おみくじの歌)

    private static let wakaPoems: [(poem: String, interpretation: String)] = [
        ("春の野に 霞たなびき しづ心なく 花のちるらむ",
         "春のように穏やかに構えていれば、自然と道が開けてきます"),
        ("秋の田の かりほの庵の 苫をあらみ わが衣手は 露にぬれつつ",
         "地道な努力の積み重ねが、やがて大きな実りをもたらします"),
        ("天つ風 雲の通ひ路 吹きとぢよ をとめの姿 しばしとどめむ",
         "美しいものとの出会いを大切に。その瞬間が幸運の種となります"),
        ("山川に 風のかけたる しがらみは 流れもあへぬ 紅葉なりけり",
         "流れに逆らわず、今ある美しさを味わう心が福を招きます"),
        ("朝ぼらけ 有明の月と 見るまでに 吉野の里に ふれる白雪",
         "夜明け前が最も暗い。辛抱の先に美しい景色が待っています"),
        ("花さそふ 嵐の庭の 雪ならで ふりゆくものは わが身なりけり",
         "変化を恐れず受け入れる心が、新たな境地を切り開きます"),
        ("瀬をはやみ 岩にせかるる 滝川の われても末に あはむとぞ思ふ",
         "離れていても想いは通じます。信じて待てば再会の時が来ます"),
        ("住の江の 岸による波 よるさへや 夢の通ひ路 人目よくらむ",
         "夢の中にも導きがあります。直感を大切にしてください"),
        ("めぐり逢ひて 見しやそれとも わかぬ間に 雲がくれにし 夜半の月かな",
         "一期一会の出会いを大切に。ご縁は予想外の形でやってきます"),
        ("わびぬれば 今はたおなじ 難波なる 身をつくしても 逢はむとぞ思ふ",
         "どんな困難があっても、志を持ち続ければ道は拓けます"),
        ("玉の緒よ 絶えなば絶えね ながらへば 忍ぶることの 弱りもぞする",
         "覚悟を決めることが力になります。潔さが新しい扉を開きます"),
        ("風そよぐ ならの小川の 夕暮れは みそぎぞ夏の しるしなりける",
         "心を清め、余計なものを手放すと、涼やかな風が吹き込みます"),
        ("みかの原 わきて流るる 泉川 いつ見きとてか 恋しかるらむ",
         "懐かしさの中に未来のヒントが隠れています。原点に立ち返って"),
        ("契りきな かたみに袖を しぼりつつ 末の松山 波こさじとは",
         "交わした約束を守り通す誠実さが、大きな信頼と幸運を呼びます"),
    ]

    // MARK: - 御言葉 (Modern Poems)

    private static let poems: [String] = [
        "朝の光を受ける枝のように、素直な気持ちが運を呼び込みます。",
        "静かな水面に月が映るように、整えた心に答えが宿ります。",
        "風に揺れる稲穂のように、しなやかさが実りへとつながります。",
        "雲の切れ間から差す光のように、迷いの先で道が見えてきます。",
        "足元の小石を払うほど、遠くの景色まで澄んで見えてきます。",
        "扉をそっと開くように、今日は控えめな勇気が福を招きます。",
        "春を待つ蕾のように、目には見えない準備が明日の追い風になります。",
        "清流の如く淀みなく進めば、やがて大海に至ります。",
        "松の根が岩をも砕くように、静かな意志が道を切り開きます。",
        "月が満ちるように、今日の小さな一歩が明日の大きな光になります。",
        "山の頂に立つ者は、まず谷を歩いた者。今の道を信じなさい。",
        "竹のように節を重ねるごとに、あなたの器は大きくなっていきます。",
    ]

    // MARK: - 指針 (Guidance)

    private static let guidance: [String] = [
        "今日は迷いを抱え込むより、ひとつ決めて軽やかに進むほど流れが整います。",
        "急いで結論を出すより、手順を整えることで運気が味方しやすくなります。",
        "誰かのために一歩譲る場面で、思いがけない良縁が返ってきそうです。",
        "予定を詰め込みすぎず、余白をつくるほど本来の勘が冴えてきます。",
        "今日は見栄えよりも心地よさを選ぶと、自然に良い巡りが生まれます。",
        "焦るより、気配りをひとつ足すことが開運の近道になりそうです。",
        "目に見える成果より、心の準備を整える一日にすると明日が変わります。",
        "古いものを手放す勇気が、新しい福を受け取るスペースを作ります。",
        "今日の善き行いは、巡り巡って大きな実りとなって返ってきます。",
        "言葉を丁寧に選ぶだけで、人間関係に清々しい風が吹き込みます。",
    ]

    // MARK: - Lucky Attributes

    private static let directions = [
        "東", "東南", "南", "南西", "西", "北西", "北", "北東",
        "吉方なし（内に留まるが吉）", "恵方"
    ]

    private static let times = [
        "早朝（5時〜7時）", "朝（7時〜9時）", "午前（9時〜11時）",
        "正午前後（11時〜13時）", "午後（13時〜15時）",
        "夕方（15時〜17時）", "宵（17時〜19時）", "夜（19時〜21時）"
    ]

    private static let items = [
        "白い便箋", "小さな鏡", "香りの良いお茶", "お気に入りの文庫本",
        "朱色の小物", "真鍮のアクセサリー", "和紙のメモ", "手触りの良いハンカチ",
        "木製の箸", "天然石のブレスレット", "白磁の湯呑み", "御守り",
        "扇子", "手帳", "清めの塩", "梅干し"
    ]

    private static let colors = [
        "朱色", "生成り", "藍色", "若草色", "琥珀色", "桜色", "薄墨色", "山吹色",
        "紫紺", "錆朱", "松葉色", "白銀"
    ]

    // MARK: - Category Fortunes (伝統的項目別運勢)

    private static let wishFortunes: [(good: String, mid: String, bad: String)] = [
        ("叶う。ただし焦らず時を待つべし", "叶うが遅し。辛抱が肝心", "今は控えよ。時を改めて吉"),
        ("大いに叶う。信じて進むべし", "半ば叶う。方針を見直すべし", "障りあり。身を慎むべし"),
        ("望み通りになる兆し。感謝を忘れずに", "思い通りにはならぬが、別の道が開ける", "今は願い事を控え、心を清めよ"),
    ]

    private static let awaitedPersonFortunes: [(good: String, mid: String, bad: String)] = [
        ("来る。思わぬ方角より", "遅れて来る。焦らず待つべし", "来ず。自ら出向くべし"),
        ("来る。嬉しい知らせも共に", "便りはあるが姿は見えず", "当分来ず。他に目を向けよ"),
        ("早く来る。良き縁を運ぶ", "来るが遅し。心静かに待て", "来ず。されど新たな出会いあり"),
    ]

    private static let lostItemFortunes: [(good: String, mid: String, bad: String)] = [
        ("出る。高きところを探すべし", "出るが時間かかる。諦めるなかれ", "出がたし。執着を手放すべし"),
        ("出る。人の手を借りると早い", "忘れた頃に見つかる", "見つからず。代わりに良きものを得る"),
        ("すぐに出る。身近なところにあり", "出るが損じている恐れあり", "出ず。新しいものとの縁と思え"),
    ]

    private static let travelFortunes: [(good: String, mid: String, bad: String)] = [
        ("吉。東南の方角よし", "行くは良し。されど帰りに注意", "控えるが無難。近場で過ごすべし"),
        ("大吉。良き出会いと発見あり", "差し支えなし。荷は軽くせよ", "延期するが吉。急ぎの旅は凶"),
        ("吉。水辺が特に良し", "天候に注意。余裕を持って", "遠出は控えよ。地元に福あり"),
    ]

    private static let studyFortunes: [(good: String, mid: String, bad: String)] = [
        ("努力実る。信じて進むべし", "中途にて迷いあり。初心に返れ", "気が散りやすし。環境を整えよ"),
        ("大いに伸びる。集中力冴える", "進むも退くも半々。基礎を固めよ", "今は無理をするなかれ。休息も学び"),
        ("吉。新しい分野に挑戦すべし", "焦らず一歩ずつ。急がば回れ", "方向転換を考えよ。道は一つにあらず"),
    ]

    private static let disputeFortunes: [(good: String, mid: String, bad: String)] = [
        ("和をもって尊しとなす。譲りて吉", "勝ちても後味悪し。和解を探れ", "争えば双方傷つく。引くが上策"),
        ("理あれば通る。ただし言葉を選べ", "長引く恐れあり。第三者に相談せよ", "絶対に争うなかれ。大凶を招く"),
        ("穏やかに主張すれば認められる", "五分五分。妥協点を見つけよ", "今は耐えよ。時が解決する"),
    ]

    private static let loveFortunes: [(good: String, mid: String, bad: String)] = [
        ("良縁あり。素直な心が吉", "縁はあるが急がぬこと", "今は自分を磨く時。焦りは禁物"),
        ("思いが通じる。行動に移すべし", "片想いはもう少し時を待て", "高望みは控えよ。身近に真の縁あり"),
        ("運命の出会いの予感。心を開いて", "気持ちのすれ違いに注意。対話を大切に", "執着を手放せば新たな縁が生まれる"),
    ]

    private static let movingFortunes: [(good: String, mid: String, bad: String)] = [
        ("よし。新しい風が福を運ぶ", "急がぬが吉。準備万端で", "今は動くなかれ。来年を待て"),
        ("吉。方角を選べば大吉", "時期をずらすと良い。慌てるなかれ", "留まるが吉。根を深く張る時"),
        ("好機。環境を変えると運気上昇", "良し悪し半々。よく吟味せよ", "不向きな時期。今の場所で花を咲かせよ"),
    ]

    private static let illnessFortunes: [(good: String, mid: String, bad: String)] = [
        ("快方に向かう。養生を怠るなかれ", "長引く恐れあり。専門家に相談を", "油断大敵。早めの手当てを"),
        ("心配なし。日々の健康管理を続けよ", "気の緩みに注意。生活習慣を見直せ", "無理は禁物。十分な休息を取れ"),
        ("回復の兆し。食事と睡眠を整えよ", "小さな不調を見逃すなかれ", "身体の声に耳を傾けよ。過信は禁物"),
    ]

    private static let marriageFortunes: [(good: String, mid: String, bad: String)] = [
        ("良し。誠実さが実を結ぶ", "急がぬが吉。じっくりと", "今は時期ではない。心を磨く時"),
        ("大吉。良き縁談の兆し", "障りあるも乗り越えられる", "見送るが賢明。焦りは禁物"),
        ("早く進めると吉。吉日を選べ", "仲立ちの人を頼ると良し", "一度見合わせ、改めて吉"),
    ]

    // MARK: - Hint Pools

    private static let loveHints = [
        "やさしい言葉を先に差し出すほど、ご縁が深まりやすい日です。",
        "相手の反応を急がず、会話の余韻を大切にすると関係が温まります。",
        "恋の流れは静かでも、誠実さがきちんと伝わる日になりそうです。",
        "今日は駆け引きよりも、自然体の笑顔がいちばんの魅力になります。",
        "思い出の場所を訪れると、恋愛運に追い風が吹きそうです。",
        "感謝の気持ちを素直に伝えると、絆がぐっと深まる日です。",
        "一歩引いて相手を立てる姿勢が、実は最も愛される秘訣です。",
        "今日の出会いが未来の大切なご縁に繋がる予感。心を開いて。",
    ]

    private static let workHints = [
        "最初の一手を丁寧に整えると、その後の判断が驚くほど滑らかになります。",
        "頼まれごとは無理なく線を引きつつ、得意な場面で光を放てる日です。",
        "確認を一度増やすことが、結果的に大きな信頼へつながります。",
        "今日は新しい案より、今あるものを磨き直す姿勢が評価されやすそうです。",
        "朝一番の決断が一日の流れを作ります。直感を信じて。",
        "チームへの感謝を言葉にすると、仕事の空気が一変する日です。",
        "完璧を求めるより、まず形にすることで流れが生まれます。",
        "午前中に重要な仕事を片付けると、午後は追い風に乗れそうです。",
    ]

    private static let moneyHints = [
        "今日は増やすことより、使い道を整える姿勢が金運を支えます。",
        "大きな買い物より、日々の小さな選択を見直すことで安心感が高まります。",
        "見栄のための出費を控えると、必要なところに余裕が戻ってきます。",
        "お金の流れを記録するだけでも、福を受け取る準備が整いやすい日です。",
        "人のために使うお金が、巡り巡って大きくなって返ってきそうです。",
        "思い切った投資より、堅実な貯蓄が金運を育てる日です。",
        "古いものを処分すると、新しい豊かさのスペースが生まれます。",
        "感謝の気持ちでお金を使うと、金運の循環が良くなります。",
    ]

    private static let healthHints = [
        "深い呼吸を意識すると、身体の巡りが整いやすい日です。",
        "いつもより多めに水を飲むと、体調が安定しやすくなります。",
        "軽いストレッチで身体をほぐすと、気の流れが良くなります。",
        "今日は早めの就寝が明日の活力を生みます。夜更かしは控えめに。",
        "旬の食べ物を取り入れると、身体が自然と整っていきます。",
        "歩く速度をいつもより少しゆっくりにすると、心身が安らぎます。",
        "日光を浴びる時間を作ると、身体のリズムが整いやすい日です。",
        "今日は温かい飲み物が身体を内側から守ってくれます。",
    ]

    // MARK: - Public API

    /// 強制ランクでおみくじを生成（ドラッグ操作で選択されたランクを使う）。
    /// ランク以外のコンテンツ（和歌・指針・開運アイテム等）は通常の seed に基づく。
    static func draw(
        forcedRank: Omikuji.Rank,
        for date: Date = Date(),
        birthday: Date? = nil,
        bloodType: BloodType? = nil
    ) -> Omikuji {
        let seed = dailySeed(for: date, birthday: birthday, bloodType: bloodType)
        let rank = forcedRank

        let wakaIndex = index(seed, offset: 20, count: wakaPoems.count)
        let waka = wakaPoems[wakaIndex]
        let categories = buildTraditionalCategories(rank: rank, seed: seed)
        let calendarContext = buildCalendarContext(for: date)

        return Omikuji(
            rank: rank,
            wakaPoem: waka.poem,
            wakaInterpretation: waka.interpretation,
            poem: poems[index(seed, offset: 1, count: poems.count)],
            guidance: guidance[index(seed, offset: 2, count: guidance.count)],
            traditionalCategories: categories,
            luckyDirection: determineLuckyDirection(date: date, seed: seed),
            luckyTime: times[index(seed, offset: 4, count: times.count)],
            luckyItem: items[index(seed, offset: 5, count: items.count)],
            luckyColor: colors[index(seed, offset: 6, count: colors.count)],
            loveHint: loveHints[index(seed, offset: 7, count: loveHints.count)],
            workHint: workHints[index(seed, offset: 8, count: workHints.count)],
            moneyHint: moneyHints[index(seed, offset: 9, count: moneyHints.count)],
            healthHint: healthHints[index(seed, offset: 10, count: healthHints.count)],
            calendarContext: calendarContext
        )
    }

    static func draw(
        for date: Date = Date(),
        birthday: Date? = nil,
        bloodType: BloodType? = nil
    ) -> Omikuji {
        let seed = dailySeed(for: date, birthday: birthday, bloodType: bloodType)
        let calendarBonus = calendarInfluence(for: date)
        let rank = determineRank(seed: seed, calendarBonus: calendarBonus)

        // Select waka based on seed
        let wakaIndex = index(seed, offset: 20, count: wakaPoems.count)
        let waka = wakaPoems[wakaIndex]

        // Build traditional categories based on rank and seed
        let categories = buildTraditionalCategories(rank: rank, seed: seed)

        // Build calendar context string
        let calendarContext = buildCalendarContext(for: date)

        return Omikuji(
            rank: rank,
            wakaPoem: waka.poem,
            wakaInterpretation: waka.interpretation,
            poem: poems[index(seed, offset: 1, count: poems.count)],
            guidance: guidance[index(seed, offset: 2, count: guidance.count)],
            traditionalCategories: categories,
            luckyDirection: determineLuckyDirection(date: date, seed: seed),
            luckyTime: times[index(seed, offset: 4, count: times.count)],
            luckyItem: items[index(seed, offset: 5, count: items.count)],
            luckyColor: colors[index(seed, offset: 6, count: colors.count)],
            loveHint: loveHints[index(seed, offset: 7, count: loveHints.count)],
            workHint: workHints[index(seed, offset: 8, count: workHints.count)],
            moneyHint: moneyHints[index(seed, offset: 9, count: moneyHints.count)],
            healthHint: healthHints[index(seed, offset: 10, count: healthHints.count)],
            calendarContext: calendarContext
        )
    }

    // MARK: - Calendar Integration

    /// 六曜と特殊日から運勢補正値を算出
    private static func calendarInfluence(for date: Date) -> Int {
        var bonus = 0

        // 六曜の影響
        let rokuyo = RokuyoCalculator.calculate(from: date)
        switch rokuyo {
        case .taian:      bonus += 2
        case .senshou:    bonus += 1
        case .senbu:      bonus += 1
        case .tomobiki:   bonus += 0
        case .shakkou:    bonus -= 1
        case .butsumetsu: bonus -= 1
        }

        // 特殊日の影響
        let specialDays = SpecialDayCalculator.specialDays(for: date)
        for day in specialDays {
            if day.isAuspicious {
                bonus += 1
            } else {
                bonus -= 1
            }
        }

        return bonus
    }

    /// 暦の補正を加味した運勢ランク決定
    private static func determineRank(seed: Int, calendarBonus: Int) -> Omikuji.Rank {
        let baseIndex = index(seed, offset: 0, count: weightedRanks.count)
        let baseRank = weightedRanks[baseIndex]

        // Calendar bonus can shift rank up/down
        let adjustedOrder = max(1, min(6, baseRank.traditionalOrder - calendarBonus))
        return Omikuji.Rank.allCases.first { $0.traditionalOrder == adjustedOrder } ?? baseRank
    }

    /// 恵方を含む吉方位決定
    private static func determineLuckyDirection(date: Date, seed: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)

        // 恵方は年の十干で決まる (実際の恵方計算)
        let eho: String
        switch year % 10 {
        case 4, 9:    eho = "東北東"  // 甲・己
        case 0, 5:    eho = "西南西"  // 庚・乙 (adjusted for modern)
        case 1, 3, 6, 8: eho = "南南東"  // 辛・癸・丙・戊
        case 2, 7:    eho = "北北西"  // 壬・丁
        default:      eho = "南南東"
        }

        // 恵方を織り込むか通常方角か
        let useEho = index(seed, offset: 3, count: 4) == 0
        if useEho {
            return "恵方（\(eho)）"
        }
        return directions[index(seed, offset: 3, count: 8)]
    }

    /// 暦コンテキスト文字列を生成
    private static func buildCalendarContext(for date: Date) -> String {
        var parts: [String] = []

        let rokuyo = RokuyoCalculator.calculate(from: date)
        parts.append(rokuyo.japaneseName)

        let specialDays = SpecialDayCalculator.specialDays(for: date)
        for day in specialDays {
            parts.append(day.name)
        }

        if parts.count == 1 {
            return parts[0]
        }
        return parts.joined(separator: "・")
    }

    // MARK: - Traditional Categories Builder

    private static func buildTraditionalCategories(rank: Omikuji.Rank, seed: Int) -> Omikuji.TraditionalCategories {
        return Omikuji.TraditionalCategories(
            wish: selectCategoryFortune("願望", "ねがいごと", pool: wishFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 11)),
            awaitedPerson: selectCategoryFortune("待人", "まちびと", pool: awaitedPersonFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 12)),
            lostItem: selectCategoryFortune("失物", "うせもの", pool: lostItemFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 13)),
            travel: selectCategoryFortune("旅行", "たびだち", pool: travelFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 14)),
            study: selectCategoryFortune("学問", "がくもん", pool: studyFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 15)),
            dispute: selectCategoryFortune("争事", "あらそいごと", pool: disputeFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 16)),
            love: selectCategoryFortune("恋愛", "れんあい", pool: loveFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 17)),
            moving: selectCategoryFortune("転居", "やどがえ", pool: movingFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 18)),
            illness: selectCategoryFortune("病気", "やまい", pool: illnessFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 19)),
            marriage: selectCategoryFortune("縁談", "えんだん", pool: marriageFortunes, level: categoryFortuneLevel(rank: rank, seed: seed, offset: 20))
        )
    }

    /// Determine fortune level per category (good/mid/bad) influenced by overall rank
    private static func categoryFortuneLevel(rank: Omikuji.Rank, seed: Int, offset: Int) -> Int {
        let variation = index(seed, offset: offset, count: 3)
        switch rank {
        case .daikichi:
            return 0 // always good
        case .kichi, .chukichi:
            return variation == 2 ? 1 : 0 // mostly good, some mid
        case .shokichi:
            return variation == 0 ? 0 : 1 // mostly mid, some good
        case .suekichi:
            return variation == 0 ? 1 : (variation == 1 ? 1 : 2) // mostly mid, some bad
        case .kyo:
            return variation == 0 ? 1 : 2 // mostly bad, some mid
        }
    }

    private static func selectCategoryFortune(
        _ name: String,
        _ reading: String,
        pool: [(good: String, mid: String, bad: String)],
        level: Int
    ) -> Omikuji.CategoryFortune {
        let entry = pool[level % pool.count]
        let fortune: String
        switch level {
        case 0: fortune = entry.good
        case 1: fortune = entry.mid
        default: fortune = entry.bad
        }
        return Omikuji.CategoryFortune(categoryName: name, reading: reading, fortune: fortune)
    }

    // MARK: - Seed Generation

    private static func dailySeed(
        for date: Date,
        birthday: Date?,
        bloodType: BloodType?
    ) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        var seed = (dayOfYear * 97) + (year * 13)

        if let birthday {
            let month = calendar.component(.month, from: birthday)
            let day = calendar.component(.day, from: birthday)
            seed += (month * 31) + day
        }

        if let bloodType {
            seed += bloodTypeWeight(bloodType)
        }

        return seed
    }

    private static func bloodTypeWeight(_ bloodType: BloodType) -> Int {
        switch bloodType {
        case .a:  return 11
        case .b:  return 17
        case .o:  return 23
        case .ab: return 29
        }
    }

    private static func index(_ seed: Int, offset: Int, count: Int) -> Int {
        let raw = seed + (offset * 37)
        return ((raw % count) + count) % count
    }

}
