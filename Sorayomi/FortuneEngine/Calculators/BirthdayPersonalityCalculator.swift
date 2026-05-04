import Foundation

/// 誕生日占いエンジン
/// Generates birthday-based personality insights using:
/// - 31 day-of-month archetypes (誕生日占いの日別性格)
/// - 12 month guardian elements (守護エレメント)
/// - Seasonal/elemental correspondence (陰陽五行)
/// - Numerological cross-references (数秘術連携)
/// - Today's birthday energy cycle (パーソナルデイ)
struct BirthdayPersonalityCalculator {

    // MARK: - Data Structures

    struct BirthdayProfile {
        let monthDay: (month: Int, day: Int)
        let personality: String
        let dayArchetype: DayArchetype
        let monthGuardian: MonthGuardian
        let strength: String
        let challenge: String
        let luckyColor: String
        let luckyNumber: Int
        let birthStone: String
        let birthFlower: String
        let seasonalElement: SeasonalElement
        let compatibleDays: [Int]
        let challengingDays: [Int]
    }

    struct DayArchetype {
        let dayNumber: Int
        let title: String
        let coreTraits: String
        let loveTendency: String
        let workStyle: String
        let hiddenPotential: String
    }

    struct MonthGuardian {
        let month: Int
        let guardianName: String
        let element: String
        let keyword: String
        let monthEnergy: String
    }

    struct SeasonalElement {
        let season: String
        let element: String
        let yinYang: String
        let qualities: [String]
    }

    struct TodaysBirthdayEnergy {
        let personalDay: Int
        let personalMonth: Int
        let personalYear: Int
        let dayTheme: String
        let monthTheme: String
        let yearTheme: String
        let overallEnergy: String
        let actionAdvice: String
    }

    // MARK: - 31 Day-of-Month Archetypes (誕生日占い伝統)

    private static let dayArchetypes: [DayArchetype] = [
        DayArchetype(dayNumber: 1, title: "開拓者", coreTraits: "独立心が強く、リーダーシップを発揮する先駆者タイプ", loveTendency: "一途で情熱的。自分からリードしたい", workStyle: "新しいプロジェクトの立ち上げに強い", hiddenPotential: "周囲を巻き込む力"),
        DayArchetype(dayNumber: 2, title: "調和の使者", coreTraits: "協調性に優れ、人と人を繋ぐ橋渡し役", loveTendency: "相手に寄り添い、穏やかな関係を好む", workStyle: "チームワークで力を発揮する", hiddenPotential: "繊細な感受性による察知力"),
        DayArchetype(dayNumber: 3, title: "表現の星", coreTraits: "創造力豊かで、自己表現に長けた華やかな存在", loveTendency: "楽しさを大切にし、明るい恋愛を好む", workStyle: "クリエイティブな仕事で才能が開花", hiddenPotential: "言葉で人の心を動かす力"),
        DayArchetype(dayNumber: 4, title: "堅実の柱", coreTraits: "努力家で安定志向。着実に積み上げていく実務家", loveTendency: "誠実で安定した関係を築く", workStyle: "計画的で緻密な仕事ぶり", hiddenPotential: "逆境に負けない忍耐力"),
        DayArchetype(dayNumber: 5, title: "冒険の風", coreTraits: "自由を愛し、変化を恐れない行動派", loveTendency: "刺激的で自由な恋愛を好む", workStyle: "多様な経験が糧になる", hiddenPotential: "変化の中で最良の道を見つける直感"),
        DayArchetype(dayNumber: 6, title: "愛の守護者", coreTraits: "愛情深く、家庭や大切な人を守る温かい心の持ち主", loveTendency: "深い愛情と献身で相手を包む", workStyle: "人のために尽くす仕事に適性", hiddenPotential: "美的感覚と調和の創造力"),
        DayArchetype(dayNumber: 7, title: "探究の賢者", coreTraits: "知的好奇心が旺盛で、真理を追い求める思索家", loveTendency: "精神的な繋がりを重視する", workStyle: "専門性を極める研究肌", hiddenPotential: "直感と分析を融合する洞察力"),
        DayArchetype(dayNumber: 8, title: "成功の導き手", coreTraits: "目標達成力に優れ、豊かさを引き寄せるパワフルな人", loveTendency: "頼りがいがあり、パートナーを支える", workStyle: "ビジネスセンスと統率力が武器", hiddenPotential: "ピンチをチャンスに変える力"),
        DayArchetype(dayNumber: 9, title: "慈愛の光", coreTraits: "博愛精神に溢れ、広い視野で世界を見つめる理想家", loveTendency: "無条件の愛を注ぎ、理想の関係を求める", workStyle: "社会貢献やグローバルな仕事に適性", hiddenPotential: "人生の完成と新たな始まりを導く力"),
        DayArchetype(dayNumber: 10, title: "独立の輝き", coreTraits: "1の開拓精神と0の無限性を併せ持つ万能タイプ", loveTendency: "自立しつつも深い絆を求める", workStyle: "独自の道を切り開くパイオニア", hiddenPotential: "ゼロから何かを生み出す創造力"),
        DayArchetype(dayNumber: 11, title: "直感の灯台", coreTraits: "鋭い直感と霊感を持つ、マスターナンバー11の感性", loveTendency: "運命的な出会いを引き寄せる", workStyle: "インスピレーションを活かす仕事", hiddenPotential: "高次の直感で道を照らす力"),
        DayArchetype(dayNumber: 12, title: "社交の太陽", coreTraits: "明るく社交的で、周囲を元気にする太陽のような存在", loveTendency: "楽しく華やかな恋愛を楽しむ", workStyle: "人脈を活かしたコミュニケーション職", hiddenPotential: "どんな場でも輝ける適応力"),
        DayArchetype(dayNumber: 13, title: "変革の鍛冶師", coreTraits: "困難を糧にして自らを鍛え上げる、変容の力を持つ人", loveTendency: "深い絆を通じてお互いを成長させる", workStyle: "困難なプロジェクトをやり遂げる力", hiddenPotential: "逆境を味方につける不屈の精神"),
        DayArchetype(dayNumber: 14, title: "自由の翼", coreTraits: "多才で好奇心旺盛、自由を追い求める冒険者", loveTendency: "束縛を嫌い、対等な関係を望む", workStyle: "変化の多い環境で真価を発揮", hiddenPotential: "多様な経験を統合する力"),
        DayArchetype(dayNumber: 15, title: "磁力の魅惑", coreTraits: "人を惹きつける魅力があり、愛と美に縁がある人", loveTendency: "深い愛情で相手を包み込む", workStyle: "美意識を活かしたクリエイティブ職", hiddenPotential: "家庭と仕事を両立する調和力"),
        DayArchetype(dayNumber: 16, title: "再生の塔", coreTraits: "既存の殻を破り、新たな自分に生まれ変わる力を持つ人", loveTendency: "深い変容を経て本物の愛に辿り着く", workStyle: "専門分野で革新を起こす", hiddenPotential: "崩壊の後に真の強さを見出す力"),
        DayArchetype(dayNumber: 17, title: "星の導き", coreTraits: "高い理想と実行力を兼ね備えた、希望の星のような存在", loveTendency: "精神的にも現実的にも充実した関係", workStyle: "ビジョンを現実化する企画力", hiddenPotential: "直感と論理を融合する力"),
        DayArchetype(dayNumber: 18, title: "月の知恵", coreTraits: "感受性が豊かで、見えない世界を感じ取る力がある人", loveTendency: "繊細で相手の本心を見抜く", workStyle: "カウンセリングや芸術分野に適性", hiddenPotential: "無意識からの導きを受け取る力"),
        DayArchetype(dayNumber: 19, title: "太陽の戦士", coreTraits: "力強い独立心と、人を導くカリスマ性の持ち主", loveTendency: "情熱的で包容力のある愛情", workStyle: "リーダーとして組織を率いる", hiddenPotential: "困難を乗り越え輝きを増す力"),
        DayArchetype(dayNumber: 20, title: "静寂の審判", coreTraits: "穏やかで協調性に優れ、深い判断力を持つ調停者", loveTendency: "相手を受け入れる包容力がある", workStyle: "調整役・仲裁役で力を発揮", hiddenPotential: "忍耐の先に大きな覚醒を迎える力"),
        DayArchetype(dayNumber: 21, title: "世界の完成者", coreTraits: "バランス感覚に優れ、物事を完成に導く統合力の持ち主", loveTendency: "成熟した関係を築ける", workStyle: "プロジェクトの仕上げに強い", hiddenPotential: "多くの人と協力して大きな成果を出す力"),
        DayArchetype(dayNumber: 22, title: "マスタービルダー", coreTraits: "マスターナンバー22の壮大なビジョンを形にする稀有な人", loveTendency: "パートナーと共に大きな夢を実現する", workStyle: "大規模な事業を成功に導く", hiddenPotential: "理想を現実の形に落とし込む力"),
        DayArchetype(dayNumber: 23, title: "変化の伝道師", coreTraits: "コミュニケーション力と適応力で、変化を味方にする人", loveTendency: "楽しさと自由を大切にする恋愛", workStyle: "マーケティングやメディアに適性", hiddenPotential: "言葉で世界を変える力"),
        DayArchetype(dayNumber: 24, title: "家庭の守り神", coreTraits: "深い愛情と責任感で、周囲を温かく守る人", loveTendency: "家庭的で献身的な愛情を注ぐ", workStyle: "教育・医療・福祉に適性", hiddenPotential: "無条件の愛で人を癒す力"),
        DayArchetype(dayNumber: 25, title: "内省の哲学者", coreTraits: "深い内省力と分析力で、物事の本質に迫る思索家", loveTendency: "知的な繋がりを求め、深い関係を好む", workStyle: "研究・分析・コンサルティングに強い", hiddenPotential: "孤独の中で真理を見出す力"),
        DayArchetype(dayNumber: 26, title: "繁栄の錬金術師", coreTraits: "実務能力と野心で、物質的な成功を引き寄せる力がある人", loveTendency: "パートナーと共に豊かさを築く", workStyle: "経営・金融・不動産に適性", hiddenPotential: "責任感が生む信頼と繁栄"),
        DayArchetype(dayNumber: 27, title: "慈悲の指導者", coreTraits: "広い視野と深い慈悲で、人々を導くカリスマ性の持ち主", loveTendency: "献身的でスケールの大きな愛", workStyle: "教育・指導・国際的な仕事に適性", hiddenPotential: "個人を超えた使命に目覚める力"),
        DayArchetype(dayNumber: 28, title: "独立の先導者", coreTraits: "強い意志と独立心で、自らの道を切り開く先導者", loveTendency: "対等で刺激的なパートナーシップを好む", workStyle: "起業・フリーランスに向く", hiddenPotential: "始めたことを最後まで成し遂げる力"),
        DayArchetype(dayNumber: 29, title: "夢見の架け橋", coreTraits: "直感力に優れ、理想と現実を繋ぐ架け橋となる人", loveTendency: "ロマンチックで精神的な絆を重視", workStyle: "芸術・カウンセリング・スピリチュアル分野", hiddenPotential: "高い感受性で人を癒す力"),
        DayArchetype(dayNumber: 30, title: "創造の万華鏡", coreTraits: "豊かな表現力と社交性で、多彩な才能を発揮する人", loveTendency: "明るく楽しい恋愛を楽しむ", workStyle: "芸能・デザイン・エンタメに適性", hiddenPotential: "想像力で新しい世界を創り出す力"),
        DayArchetype(dayNumber: 31, title: "地の礎", coreTraits: "堅実さと実行力で、確かな成果を積み上げていく建設者", loveTendency: "安定感のある信頼できるパートナー", workStyle: "建設・不動産・管理職に適性", hiddenPotential: "コツコツと積み上げた努力が大輪の花を咲かせる力"),
    ]

    // MARK: - 12 Month Guardians (月の守護エネルギー)

    private static let monthGuardians: [MonthGuardian] = [
        MonthGuardian(month: 1, guardianName: "初陽の守護", element: "水", keyword: "始まり", monthEnergy: "新しい年の始まりのエネルギーを宿す。潜在力が高く、静かな決意から大きな変革を生む"),
        MonthGuardian(month: 2, guardianName: "雪解けの守護", element: "水", keyword: "感受性", monthEnergy: "繊細な感受性と深い共感力を持つ。表面は穏やかでも内面に強い意志を秘める"),
        MonthGuardian(month: 3, guardianName: "芽吹きの守護", element: "木", keyword: "成長", monthEnergy: "春の息吹と共に成長する力強さ。冒険心と柔軟性で新しい世界を切り開く"),
        MonthGuardian(month: 4, guardianName: "花咲きの守護", element: "木", keyword: "安定", monthEnergy: "満開の桜のように華やかでありながら根は強い。安定感と美意識の共存"),
        MonthGuardian(month: 5, guardianName: "薫風の守護", element: "火", keyword: "交流", monthEnergy: "爽やかな風のように人と人を繋ぐ力。コミュニケーションの達人"),
        MonthGuardian(month: 6, guardianName: "恵雨の守護", element: "火", keyword: "慈愛", monthEnergy: "梅雨の恵みのように深い愛情で周囲を潤す。守り育てる力が強い"),
        MonthGuardian(month: 7, guardianName: "盛夏の守護", element: "火", keyword: "情熱", monthEnergy: "真夏の太陽のような圧倒的なエネルギー。リーダーシップと行動力の象徴"),
        MonthGuardian(month: 8, guardianName: "創造の守護", element: "土", keyword: "創造", monthEnergy: "大地の恵みを受けた豊かな創造力。独自のアイデアで世界を彩る力"),
        MonthGuardian(month: 9, guardianName: "実りの守護", element: "金", keyword: "洞察", monthEnergy: "秋の実りのように知恵と洞察力が結実。物事の本質を見抜く鋭い目"),
        MonthGuardian(month: 10, guardianName: "均衡の守護", element: "金", keyword: "調和", monthEnergy: "天秤のようなバランス感覚。美しさと正義を重んじる調和の力"),
        MonthGuardian(month: 11, guardianName: "変容の守護", element: "水", keyword: "変革", monthEnergy: "晩秋の深まりのように内面を探求する力。変容と再生のエネルギー"),
        MonthGuardian(month: 12, guardianName: "終焉と再生の守護", element: "水", keyword: "完成", monthEnergy: "一年の総括と来年への種蒔き。理想を形にし、次のサイクルを準備する力"),
    ]

    // MARK: - Birth Stones (誕生石 - 日本ジュエリー協会準拠)

    private static let birthStones: [String] = [
        "ガーネット",      // 1月
        "アメシスト",      // 2月
        "アクアマリン",    // 3月
        "ダイヤモンド",    // 4月
        "エメラルド",      // 5月
        "パール",          // 6月
        "ルビー",          // 7月
        "ペリドット",      // 8月
        "サファイア",      // 9月
        "オパール",        // 10月
        "トパーズ",        // 11月
        "タンザナイト",    // 12月
    ]

    // MARK: - Birth Flowers (誕生花)

    private static let birthFlowers: [String] = [
        "スイセン",        // 1月
        "ウメ",            // 2月
        "チューリップ",    // 3月
        "サクラ",          // 4月
        "スズラン",        // 5月
        "バラ",            // 6月
        "ユリ",            // 7月
        "ヒマワリ",        // 8月
        "リンドウ",        // 9月
        "コスモス",        // 10月
        "キク",            // 11月
        "ポインセチア",    // 12月
    ]

    // MARK: - Lucky Colors (日本の伝統色)

    private static let luckyColors: [String] = [
        "紅白（こうはく）",      // 1月
        "藤紫（ふじむらさき）",  // 2月
        "若草色（わかくさいろ）", // 3月
        "桜色（さくらいろ）",    // 4月
        "萌黄色（もえぎいろ）",  // 5月
        "露草色（つゆくさいろ）", // 6月
        "紅蓮（ぐれん）",       // 7月
        "向日葵色（ひまわりいろ）", // 8月
        "瑠璃色（るりいろ）",    // 9月
        "黄金色（こがねいろ）",  // 10月
        "深緋（こきあけ）",      // 11月
        "銀鼠色（ぎんねずいろ）", // 12月
    ]

    // MARK: - Seasonal Elements

    private static let seasonalElements: [SeasonalElement] = [
        SeasonalElement(season: "春", element: "木", yinYang: "陽", qualities: ["成長", "発展", "創造", "柔軟性", "新しい始まり"]),
        SeasonalElement(season: "夏", element: "火", yinYang: "大陽", qualities: ["情熱", "活力", "行動力", "表現", "リーダーシップ"]),
        SeasonalElement(season: "秋", element: "金", yinYang: "陰", qualities: ["収穫", "洞察", "分析", "完成", "知恵"]),
        SeasonalElement(season: "冬", element: "水", yinYang: "大陰", qualities: ["内省", "忍耐", "蓄え", "再生", "深い思考"]),
    ]

    // MARK: - Public API

    /// Generate a comprehensive birthday personality profile.
    static func profile(from date: Date) -> BirthdayProfile {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let archetype = dayArchetypes[day - 1]
        let guardian = monthGuardians[month - 1]
        let seasonalElement = seasonalElement(for: month)

        let luckyColor = luckyColors[month - 1]
        let luckyNumber = NumerologyCalculator.birthdayNumber(from: date)
        let birthStone = birthStones[month - 1]
        let birthFlower = birthFlowers[month - 1]

        // Compatible days: numerological harmony (same reduced number, or complementary)
        let compatible = compatibleDays(for: day)
        let challenging = challengingDays(for: day)

        // Combined personality from month + day
        let personality = "\(guardian.monthEnergy)。日の数「\(day)」が示す\(archetype.title)の資質により、\(archetype.coreTraits)"

        return BirthdayProfile(
            monthDay: (month, day),
            personality: personality,
            dayArchetype: archetype,
            monthGuardian: guardian,
            strength: archetype.hiddenPotential,
            challenge: dayChallenge(for: day),
            luckyColor: luckyColor,
            luckyNumber: luckyNumber,
            birthStone: birthStone,
            birthFlower: birthFlower,
            seasonalElement: seasonalElement,
            compatibleDays: compatible,
            challengingDays: challenging
        )
    }

    /// Calculate today's birthday energy using numerology personal cycles.
    static func todaysEnergy(birthday: Date, today: Date = Date()) -> TodaysBirthdayEnergy {
        let numProfile = NumerologyCalculator.profile(from: birthday, currentDate: today)

        let dayTheme = personalDayTheme(numProfile.personalDayNumber)
        let monthTheme = personalMonthTheme(numProfile.personalMonthNumber)
        let yearTheme = personalYearTheme(numProfile.personalYearNumber)

        let overallEnergy = synthesizeEnergy(
            day: numProfile.personalDayNumber,
            month: numProfile.personalMonthNumber,
            year: numProfile.personalYearNumber
        )

        let actionAdvice = actionAdvice(
            personalDay: numProfile.personalDayNumber,
            personalMonth: numProfile.personalMonthNumber
        )

        return TodaysBirthdayEnergy(
            personalDay: numProfile.personalDayNumber,
            personalMonth: numProfile.personalMonthNumber,
            personalYear: numProfile.personalYearNumber,
            dayTheme: dayTheme,
            monthTheme: monthTheme,
            yearTheme: yearTheme,
            overallEnergy: overallEnergy,
            actionAdvice: actionAdvice
        )
    }

    // MARK: - Private Helpers

    private static func seasonalElement(for month: Int) -> SeasonalElement {
        switch month {
        case 3...5: return seasonalElements[0]
        case 6...8: return seasonalElements[1]
        case 9...11: return seasonalElements[2]
        default: return seasonalElements[3]
        }
    }

    private static func dayChallenge(for day: Int) -> String {
        let reduced = NumerologyCalculator.reduceToSingle(day)
        switch reduced {
        case 1: return "頑固になりすぎず、他者の意見にも耳を傾けること"
        case 2: return "優柔不断にならず、自分の意思を明確にすること"
        case 3: return "散漫にならず、一つのことに集中すること"
        case 4: return "柔軟性を持ち、変化を受け入れること"
        case 5: return "落ち着きを持ち、一貫性を大切にすること"
        case 6: return "自己犠牲しすぎず、自分自身も大切にすること"
        case 7: return "孤立しすぎず、人との繋がりを保つこと"
        case 8: return "支配的にならず、他者の自主性を尊重すること"
        case 9: return "理想と現実のバランスを取ること"
        case 11: return "高い感受性をコントロールし、地に足をつけること"
        case 22: return "壮大なビジョンと日常の現実を両立させること"
        default: return "バランスを大切にすること"
        }
    }

    /// Numerological compatibility: days that reduce to harmonious numbers
    private static func compatibleDays(for day: Int) -> [Int] {
        let reduced = NumerologyCalculator.reduceToSingle(day)
        let harmonious: [Int]
        switch reduced {
        case 1: harmonious = [3, 5, 9]
        case 2: harmonious = [4, 6, 8]
        case 3: harmonious = [1, 5, 9]
        case 4: harmonious = [2, 6, 8]
        case 5: harmonious = [1, 3, 7]
        case 6: harmonious = [2, 4, 9]
        case 7: harmonious = [5, 3, 9]
        case 8: harmonious = [2, 4, 6]
        case 9: harmonious = [1, 3, 6]
        case 11: harmonious = [2, 4, 6]
        case 22: harmonious = [4, 6, 8]
        default: harmonious = [1, 5, 9]
        }
        // Return example days that reduce to harmonious numbers
        return harmonious.map { n in
            (1...31).filter { NumerologyCalculator.reduceToSingle($0) == n }.first ?? n
        }
    }

    private static func challengingDays(for day: Int) -> [Int] {
        let reduced = NumerologyCalculator.reduceToSingle(day)
        let challenging: [Int]
        switch reduced {
        case 1: challenging = [4, 8]
        case 2: challenging = [5, 7]
        case 3: challenging = [4, 8]
        case 4: challenging = [1, 3]
        case 5: challenging = [2, 4]
        case 6: challenging = [5, 7]
        case 7: challenging = [2, 6]
        case 8: challenging = [1, 3]
        case 9: challenging = [4, 5]
        case 11: challenging = [5, 8]
        case 22: challenging = [1, 5]
        default: challenging = [4, 8]
        }
        return challenging.map { n in
            (1...31).filter { NumerologyCalculator.reduceToSingle($0) == n }.first ?? n
        }
    }

    // MARK: - Personal Cycle Themes (数秘術パーソナルサイクル)

    private static func personalDayTheme(_ number: Int) -> String {
        switch number {
        case 1: return "新しい行動を起こす日。積極的に動いて吉"
        case 2: return "協力と調和の日。人間関係を大切に"
        case 3: return "自己表現と創造の日。楽しむことが開運の鍵"
        case 4: return "基盤固めの日。地道な作業が実を結ぶ"
        case 5: return "変化と冒険の日。新しい経験に飛び込んで"
        case 6: return "愛と奉仕の日。大切な人との時間を"
        case 7: return "内省と学びの日。知識を深める好機"
        case 8: return "達成と繁栄の日。目標に向かって大きく動ける"
        case 9: return "完成と手放しの日。不要なものを整理して"
        case 11: return "直感が冴える特別な日。インスピレーションを信じて"
        case 22: return "大きなビジョンが動く日。壮大な計画を前進させて"
        case 33: return "無条件の愛が流れる日。周囲への奉仕が大きな実りに"
        default: return "バランスを意識する日"
        }
    }

    private static func personalMonthTheme(_ number: Int) -> String {
        switch number {
        case 1: return "新しいスタートの月。種蒔きに最適"
        case 2: return "忍耐と協力の月。人との繋がりが深まる"
        case 3: return "表現と拡大の月。創造的なエネルギーが高まる"
        case 4: return "安定と建設の月。基盤を固める時期"
        case 5: return "変化と自由の月。冒険心を活かして"
        case 6: return "調和と責任の月。家庭・愛情に焦点"
        case 7: return "探求と内省の月。学びを深める時期"
        case 8: return "収穫と達成の月。努力が報われる時期"
        case 9: return "完成と浄化の月。手放しと次への準備"
        case 11: return "高い直感が働く月。スピリチュアルな気づき"
        case 22: return "大きな実現の月。壮大なプランが動く"
        case 33: return "慈愛のエネルギーに満ちた月"
        default: return "流れに乗る月"
        }
    }

    private static func personalYearTheme(_ number: Int) -> String {
        switch number {
        case 1: return "9年サイクルの始まり。新しい種を蒔く年"
        case 2: return "忍耐と協力の年。前年蒔いた種を育てる時期"
        case 3: return "拡大と表現の年。才能が花開く時期"
        case 4: return "基盤固めの年。地道な努力が未来を作る"
        case 5: return "変化と自由の年。大きな転機が訪れやすい"
        case 6: return "愛と責任の年。家庭・人間関係の充実期"
        case 7: return "内省と学びの年。精神的成長が著しい時期"
        case 8: return "収穫と達成の年。過去の努力が結実する"
        case 9: return "完成と手放しの年。次のサイクルへの準備期間"
        case 11: return "覚醒の年。高次の導きが強く働く"
        case 22: return "マスターの年。壮大なビジョンを形にする"
        case 33: return "究極の奉仕の年。大いなる愛のエネルギー"
        default: return "流れに乗る年"
        }
    }

    private static func synthesizeEnergy(day: Int, month: Int, year: Int) -> String {
        let dayScore = min(day, 9) > 5 ? "高い" : (min(day, 9) > 3 ? "普通" : "控えめ")
        let monthScore = min(month, 9) > 5 ? "追い風" : (min(month, 9) > 3 ? "平穏" : "向かい風")

        if [1, 3, 5, 8].contains(day) || day == 11 || day == 22 {
            return "今日は行動力が\(dayScore)で、月の流れも\(monthScore)。積極的に動くと良い結果に繋がりやすい日です"
        } else if [2, 6, 9].contains(day) {
            return "今日は人との関わりにエネルギーが\(dayScore)で、月の流れは\(monthScore)。人間関係を大切にする日です"
        } else {
            return "今日は内面のエネルギーが\(dayScore)で、月の流れは\(monthScore)。内省や準備に適した日です"
        }
    }

    private static func actionAdvice(personalDay: Int, personalMonth: Int) -> String {
        // Day and month energies aligned
        if personalDay == personalMonth {
            return "パーソナルデイとパーソナルマンスが同じ「\(personalDay)」で共鳴中。この数字のテーマに集中すると大きな成果が"
        }

        // Complementary energies
        let sum = NumerologyCalculator.reduceToSingle(personalDay + personalMonth)
        switch sum {
        case 1, 8: return "今日は「実行」のエネルギーが強い。具体的な行動を起こすと流れに乗れる"
        case 2, 6: return "今日は「つながり」のエネルギーが強い。大切な人との対話が開運の鍵"
        case 3, 5: return "今日は「創造」のエネルギーが強い。新しいアイデアや表現が実を結ぶ"
        case 4, 7: return "今日は「深化」のエネルギーが強い。学びや内省が大きな気づきをもたらす"
        case 9: return "今日は「完成」のエネルギーが強い。整理・浄化・感謝を意識して"
        case 11, 22, 33: return "マスターナンバーのエネルギーが流れている。直感を信じて高い理想に向かって"
        default: return "バランスの取れたエネルギーの日。自然体で過ごすと吉"
        }
    }
}
