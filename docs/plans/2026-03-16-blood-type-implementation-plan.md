# Blood Type Enhancement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade blood type fortune engine from static 4-type lookup to 4-mode interactive system with reveal animations and real divination-based daily calculations.

**Architecture:** New BloodTypeMode enum drives mode selection UI (BloodTypeModePickerView), mode-specific reveal animations (BloodTypeRevealView), enhanced calculator with 16-pair compatibility matrix and composite daily fortune from existing divination engines (Rokuyo, NineStarKi, Numerology, SeasonalContext). ReadingViewModel gains blood-type-specific state management paralleling existing tarot flow.

**Tech Stack:** SwiftUI, @Observable, existing Sorayomi theme system (ColorPalette, Typography, Spacing), existing divination calculators

---

### Task 1: BloodTypeMode enum & BloodType model enhancement

**Files:**
- Create: `Sorayomi/Domain/Models/BloodTypeMode.swift`
- Modify: `Sorayomi/Domain/Models/BloodType.swift`

**Step 1: Create BloodTypeMode.swift**

```swift
import Foundation

/// 血液型占いのモード選択肢
enum BloodTypeMode: String, CaseIterable, Identifiable {
    case dailyFortune = "daily_fortune"
    case compatibility = "compatibility"
    case loveMatch = "love_match"
    case ranking = "ranking"

    var id: String { rawValue }

    var japaneseName: String {
        switch self {
        case .dailyFortune:  return "今日の運勢"
        case .compatibility: return "相性診断"
        case .loveMatch:     return "恋愛相性"
        case .ranking:       return "ランキング"
        }
    }

    var iconName: String {
        switch self {
        case .dailyFortune:  return "sun.max.fill"
        case .compatibility: return "person.2.fill"
        case .loveMatch:     return "heart.fill"
        case .ranking:       return "trophy.fill"
        }
    }

    var description: String {
        switch self {
        case .dailyFortune:  return "あなたの血液型の\n今日を詳しく鑑定"
        case .compatibility: return "2人の血液型の\n相性を深く読み解く"
        case .loveMatch:     return "恋の行方を\n血液型から読み解く"
        case .ranking:       return "今日の血液型別\nランキングを発表！"
        }
    }

    /// Whether this mode requires partner blood type selection
    var requiresPartner: Bool {
        switch self {
        case .compatibility, .loveMatch: return true
        case .dailyFortune, .ranking: return false
        }
    }

    /// Whether this mode skips the hearing stage
    var skipsHearing: Bool {
        self == .ranking
    }
}
```

**Step 2: Enhance BloodType.swift — add detailed profile properties**

Add after existing `shortDescription` property in the `BloodType` enum:

```swift
    /// 恋愛傾向
    var loveTendency: String {
        switch self {
        case .a:  return "一途で慎重。信頼関係を大切にし、ゆっくり距離を縮めるタイプ"
        case .b:  return "自分の感覚を大事にする恋愛スタイル。好きになると一直線"
        case .o:  return "包容力があり、好きな人には惜しみなく尽くすタイプ"
        case .ab: return "独自の距離感を保ちつつ、知的なつながりを大切にするタイプ"
        }
    }

    /// 仕事傾向
    var workTendency: String {
        switch self {
        case .a:  return "計画性が高く細部まで丁寧。チームの要になれる堅実派"
        case .b:  return "独創的なアイデアと集中力で突破口を開くクリエイター気質"
        case .o:  return "目標を定めたら一気に突き進む。統率力に優れたリーダー気質"
        case .ab: return "分析力と多角的視点で複雑な課題を整理できる参謀タイプ"
        }
    }

    /// 金銭感覚
    var moneySense: String {
        switch self {
        case .a:  return "堅実で計画的。無駄遣いを嫌い、コツコツと着実に蓄える"
        case .b:  return "好きなことには惜しまないが、興味のないものには財布の紐が固い"
        case .o:  return "大きな買い物も決断が早い。稼ぐ力もあるが出費も大きくなりがち"
        case .ab: return "合理的な判断で無駄を省く。情報を集めてから慎重に使う"
        }
    }

    /// 健康傾向
    var healthTendency: String {
        switch self {
        case .a:  return "ストレスを溜め込みやすい。リラックスの時間を意識的に確保することが大切"
        case .b:  return "好きなことに没頭しすぎて不規則になりがち。生活リズムの安定がカギ"
        case .o:  return "体力に自信があるが過信は禁物。定期的な休息で長期的な健康を"
        case .ab: return "繊細な面があり環境変化に敏感。睡眠の質を高めることが重要"
        }
    }

    /// 季節別傾向
    func seasonalTendency(for season: String) -> String {
        switch (self, season) {
        case (.a, "春"):  return "変化への適応が試される季節。計画を立てて一歩ずつ進むと吉"
        case (.a, "夏"):  return "人間関係が活発に。気配り上手な面が評価されやすい時期"
        case (.a, "秋"):  return "内省が深まる季節。自分を見つめ直すことで新たな発見が"
        case (.a, "冬"):  return "計画力が最も発揮される季節。来年への準備を丁寧に"
        case (.b, "春"):  return "新しいことへの好奇心が全開。直感を信じて動くと良い流れに"
        case (.b, "夏"):  return "エネルギーが最大化する季節。やりたいことに集中すると大きな成果"
        case (.b, "秋"):  return "クリエイティブな面が冴える。作品づくりや趣味に没頭すると吉"
        case (.b, "冬"):  return "マイペースが崩れやすい時期。自分のリズムを大切に"
        case (.o, "春"):  return "リーダーシップを発揮する好機。新しいプロジェクトの立ち上げに最適"
        case (.o, "夏"):  return "行動力が冴え渡る。大きな決断にも向いている時期"
        case (.o, "秋"):  return "周囲への包容力を見せる季節。感謝を伝えると運気上昇"
        case (.o, "冬"):  return "エネルギーの充電期。ゆったり過ごすことで春に大きく飛躍"
        case (.ab, "春"): return "多面的な才能が花開く季節。新しい人脈が広がりやすい"
        case (.ab, "夏"): return "知的活動が充実。学びや情報収集が成果につながる"
        case (.ab, "秋"): return "分析力が最大限に発揮される。仕事面での評価が高まりやすい"
        case (.ab, "冬"): return "感性が研ぎ澄まされる時期。芸術や文化に触れると吉"
        default:          return "自分の型の長所を活かして過ごしましょう"
        }
    }
```

**Step 3: Add to Xcode project and build**

Run: `cd "/Users/hiroyukigoto/Desktop/Experimental Projects/Fortune Telling App/Sorayomi" && python3 generate_xcodeproj.py`
Run: `xcodebuild build -scheme Sorayomi -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' 2>&1 | grep -E '(error:|BUILD)'`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Sorayomi/Domain/Models/BloodTypeMode.swift Sorayomi/Domain/Models/BloodType.swift
git commit -m "feat(blood-type): add BloodTypeMode enum and enhance BloodType model"
```

---

### Task 2: Compatibility matrix & daily composite fortune engine

**Files:**
- Create: `Sorayomi/FortuneEngine/Calculators/BloodTypeCompatibility.swift`
- Modify: `Sorayomi/FortuneEngine/Calculators/BloodTypeCalculator.swift`

**Step 1: Create BloodTypeCompatibility.swift**

Contains the 16-pair compatibility matrix (能見正比古 based), love sub-scores (4 categories × 16 pairs = 64 data points), and daily composite fortune calculation.

```swift
import Foundation

// MARK: - Compatibility Data

/// 血液型の相性データ（能見正比古『血液型人間学』準拠）
struct BloodTypeCompatibilityData {
    let score: Int // 1-5
    let description: String
    let loveDescription: String
}

/// 恋愛相性のサブスコア
struct BloodTypeLoveSubScores {
    let communication: Int    // コミュニケーション (1-5)
    let values: Int           // 価値観の一致 (1-5)
    let passion: Int          // 情熱度 (1-5)
    let stability: Int        // 長期安定度 (1-5)

    var overall: Int {
        let avg = Double(communication + values + passion + stability) / 4.0
        return Int(avg.rounded())
    }
}

/// 日替わり運勢（実在占術の複合判定結果）
struct BloodTypeDailyFortune {
    let overall: Int   // 1-5
    let love: Int      // 1-5
    let work: Int      // 1-5
    let money: Int     // 1-5
    let luckyColor: String
    let luckyDirection: String
    let oneLiner: String
    let rokuyo: Rokuyo
    let dailyStar: NineStarKiStar
    let solarTerm: String
    let universalDay: Int
}

/// 日替わりランキング結果
struct BloodTypeRanking {
    struct Entry: Identifiable {
        let id = UUID()
        let bloodType: BloodType
        let score: Int   // 1-5
        let oneLiner: String
        let rank: Int    // 1-4
    }
    let entries: [Entry] // sorted by rank (1st to 4th)
    let date: Date
}

// MARK: - BloodTypeCompatibility

enum BloodTypeCompatibility {

    /// Get compatibility data for a pair of blood types.
    static func compatibility(between type1: BloodType, and type2: BloodType) -> BloodTypeCompatibilityData {
        let key = pairKey(type1, type2)
        return compatibilityMatrix[key]!
    }

    /// Get love sub-scores for a pair of blood types.
    static func loveSubScores(between type1: BloodType, and type2: BloodType) -> BloodTypeLoveSubScores {
        let key = pairKey(type1, type2)
        return loveMatrix[key]!
    }

    /// Calculate daily fortune for a blood type using composite divination.
    static func dailyFortune(for bloodType: BloodType, on date: Date = Date()) -> BloodTypeDailyFortune {
        let rokuyo = RokuyoCalculator.calculate(from: date)
        let dailyStar = NineStarKiCalculator.dailyStar(for: date)
        let seasonal = SeasonalContext.from(date: date)
        let universalDay = calculateUniversalDay(date)

        // Composite score calculation from real divination data
        let rokuyoInfluence = rokuyoAffinity(rokuyo: rokuyo, bloodType: bloodType)
        let starInfluence = starAffinity(star: dailyStar, bloodType: bloodType)
        let seasonInfluence = seasonAffinity(season: seasonal.season, bloodType: bloodType)
        let numberInfluence = numberAffinity(universalDay: universalDay, bloodType: bloodType)

        let overall = clampScore(rokuyoInfluence.overall + starInfluence.overall + seasonInfluence + numberInfluence.overall)
        let love = clampScore(rokuyoInfluence.love + starInfluence.love + seasonInfluence + numberInfluence.love)
        let work = clampScore(rokuyoInfluence.work + starInfluence.work + seasonInfluence + numberInfluence.work)
        let money = clampScore(rokuyoInfluence.money + starInfluence.money + seasonInfluence + numberInfluence.money)

        let luckyColor = dailyLuckyColor(star: dailyStar, bloodType: bloodType)
        let luckyDirection = dailyStar.direction

        let oneLiner = dailyOneLiner(overall: overall, bloodType: bloodType, star: dailyStar)

        return BloodTypeDailyFortune(
            overall: overall, love: love, work: work, money: money,
            luckyColor: luckyColor, luckyDirection: luckyDirection,
            oneLiner: oneLiner, rokuyo: rokuyo, dailyStar: dailyStar,
            solarTerm: seasonal.solarTerm, universalDay: universalDay
        )
    }

    /// Calculate today's ranking for all 4 blood types.
    static func dailyRanking(on date: Date = Date()) -> BloodTypeRanking {
        let fortunes = BloodType.allCases.map { type in
            (type: type, fortune: dailyFortune(for: type, on: date))
        }

        let sorted = fortunes.sorted { $0.fortune.overall > $1.fortune.overall }

        let entries = sorted.enumerated().map { index, item in
            BloodTypeRanking.Entry(
                bloodType: item.type,
                score: item.fortune.overall,
                oneLiner: item.fortune.oneLiner,
                rank: index + 1
            )
        }

        return BloodTypeRanking(entries: entries, date: date)
    }

    // MARK: - Composite Calculation Helpers

    private struct CategoryScores {
        var overall: Int
        var love: Int
        var work: Int
        var money: Int
    }

    /// 六曜 × 血液型の相性
    private static func rokuyoAffinity(rokuyo: Rokuyo, bloodType: BloodType) -> CategoryScores {
        // A型: 大安・友引で安心して力を発揮 / B型: 先勝の午前に直感が冴える
        // O型: 大安のおおらかさと相性抜群 / AB型: 赤口の「正午のみ吉」に集中力発揮
        let base = rokuyo.auspiciousnessScore // 1-5
        let modifier: Int
        switch (bloodType, rokuyo) {
        case (.a, .taian), (.a, .tomobiki):     modifier = 1
        case (.a, .butsumetsu):                  modifier = -1
        case (.b, .senshou):                     modifier = 1
        case (.b, .senbu):                       modifier = -1
        case (.o, .taian):                       modifier = 1
        case (.o, .shakkou):                     modifier = -1
        case (.ab, .shakkou):                    modifier = 1  // AB型は赤口の集中時間を活かせる
        case (.ab, .butsumetsu):                 modifier = 0  // AB型は仏滅でも内省で活用
        default:                                 modifier = 0
        }
        let adjusted = max(1, min(5, base + modifier))
        // Category variation based on rokuyo timing
        let loveModifier = rokuyo == .tomobiki ? 1 : 0   // 友引は人との縁に吉
        let workModifier = rokuyo == .senshou ? 1 : 0     // 先勝は仕事の着手に吉
        let moneyModifier = rokuyo == .taian ? 1 : 0      // 大安は金運にも吉

        return CategoryScores(
            overall: adjusted,
            love: max(1, min(5, adjusted + loveModifier)),
            work: max(1, min(5, adjusted + workModifier)),
            money: max(1, min(5, adjusted + moneyModifier))
        )
    }

    /// 九星日命星 × 血液型の相性（五行の相生/相剋で判定）
    private static func starAffinity(star: NineStarKiStar, bloodType: BloodType) -> CategoryScores {
        // 血液型と五行の対応: A型=木(几帳面・成長), B型=火(自由・情熱), O型=土(包容・安定), AB型=金(知性・鋭さ)
        let bloodElement: String
        switch bloodType {
        case .a:  bloodElement = "木"
        case .b:  bloodElement = "火"
        case .o:  bloodElement = "土"
        case .ab: bloodElement = "金"
        }

        let starElement = star.element

        // 相生(生む関係)=+2, 比和(同じ)=+1, 相剋(剋す/剋される)=-1
        let relationship = elementRelationship(from: starElement, to: bloodElement)

        let base = 3 + relationship  // base 3 ± modifier → range 1-5

        // 九星の方位による金運への影響
        let moneyBoost = (star == .roppakuKinsei || star == .shichisekiKinsei) ? 1 : 0
        // 九星の社交性による恋愛への影響
        let loveBoost = (star == .shichisekiKinsei || star == .shirokuMokusei) ? 1 : 0
        // 仕事は五行の相生で判断
        let workBoost = relationship > 0 ? 1 : 0

        return CategoryScores(
            overall: max(1, min(5, base)),
            love: max(1, min(5, base + loveBoost)),
            work: max(1, min(5, base + workBoost)),
            money: max(1, min(5, base + moneyBoost))
        )
    }

    /// 五行の関係を判定: +2(相生で生む), +1(比和), 0(無関係), -1(相剋)
    private static func elementRelationship(from element1: String, to element2: String) -> Int {
        // 相生: 木→火→土→金→水→木
        let generatingCycle: [(String, String)] = [
            ("木", "火"), ("火", "土"), ("土", "金"), ("金", "水"), ("水", "木")
        ]
        // 相剋: 木→土, 土→水, 水→火, 火→金, 金→木
        let controllingCycle: [(String, String)] = [
            ("木", "土"), ("土", "水"), ("水", "火"), ("火", "金"), ("金", "木")
        ]

        if element1 == element2 { return 1 } // 比和
        if generatingCycle.contains(where: { $0.0 == element1 && $0.1 == element2 }) { return 2 } // 生む
        if generatingCycle.contains(where: { $0.0 == element2 && $0.1 == element1 }) { return 1 } // 生まれる
        if controllingCycle.contains(where: { $0.0 == element1 && $0.1 == element2 }) { return -1 }
        if controllingCycle.contains(where: { $0.0 == element2 && $0.1 == element1 }) { return -1 }
        return 0
    }

    /// 季節 × 血液型
    private static func seasonAffinity(season: String, bloodType: BloodType) -> Int {
        // 各型が最も力を発揮しやすい季節
        switch (bloodType, season) {
        case (.a, "秋"), (.a, "冬"):   return 1  // A型は内省・計画の季節に強い
        case (.b, "春"), (.b, "夏"):   return 1  // B型は活動的な季節に強い
        case (.o, "夏"), (.o, "春"):   return 1  // O型は行動の季節に強い
        case (.ab, "秋"), (.ab, "冬"): return 1  // AB型は知的活動の季節に強い
        default:                        return 0
        }
    }

    /// 数秘ユニバーサルデイ × 血液型
    private static func numberAffinity(universalDay: Int, bloodType: BloodType) -> CategoryScores {
        // 各数字のエネルギーと血液型の親和性
        let affinity: Int
        switch (bloodType, universalDay) {
        case (.a, 4), (.a, 6), (.a, 2):    affinity = 1  // A型: 安定(4), 奉仕(6), 協調(2)と相性良
        case (.b, 5), (.b, 3), (.b, 1):    affinity = 1  // B型: 自由(5), 創造(3), 独立(1)と相性良
        case (.o, 1), (.o, 8), (.o, 9):    affinity = 1  // O型: リーダー(1), 達成(8), 博愛(9)と相性良
        case (.ab, 7), (.ab, 11), (.ab, 2): affinity = 1 // AB型: 分析(7), 直感(11), 調和(2)と相性良
        default:                             affinity = 0
        }

        // 数字ごとのカテゴリ傾向
        let loveFavor = [2, 6].contains(universalDay) ? 1 : 0
        let workFavor = [1, 4, 8].contains(universalDay) ? 1 : 0
        let moneyFavor = [8, 4].contains(universalDay) ? 1 : 0

        return CategoryScores(
            overall: affinity,
            love: affinity + loveFavor,
            work: affinity + workFavor,
            money: affinity + moneyFavor
        )
    }

    /// 数秘術ユニバーサルデイの計算
    static func calculateUniversalDay(_ date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return NumerologyCalculator.reduceToSingle(year + month + day)
    }

    private static func clampScore(_ rawSum: Int) -> Int {
        // rawSum is typically 3-8 range from composite. Normalize to 1-5.
        return max(1, min(5, Int((Double(rawSum) / 2.0).rounded())))
    }

    private static func dailyLuckyColor(star: NineStarKiStar, bloodType: BloodType) -> String {
        // 九星の色 × 血液型の好む色調を組み合わせ
        let starColors: [NineStarKiStar: [String]] = [
            .ippakuSuisei:     ["銀白", "水色", "淡い青"],
            .jikokuDosei:      ["黒", "焦茶", "深緑"],
            .sanpekiMokusei:   ["碧", "若草色", "ミントグリーン"],
            .shirokuMokusei:   ["緑", "エメラルド", "若竹色"],
            .goouDosei:        ["黄", "山吹色", "ゴールド"],
            .roppakuKinsei:    ["白銀", "プラチナ", "アイスブルー"],
            .shichisekiKinsei: ["赤", "ローズ", "珊瑚色"],
            .happakuDosei:     ["白", "クリーム", "象牙色"],
            .kyushiKasei:      ["紫", "ラベンダー", "藤色"],
        ]
        let colors = starColors[star] ?? ["白"]
        let index: Int
        switch bloodType {
        case .a:  index = 0
        case .b:  index = min(1, colors.count - 1)
        case .o:  index = min(2, colors.count - 1)
        case .ab: index = min(1, colors.count - 1)
        }
        return colors[index]
    }

    private static func dailyOneLiner(overall: Int, bloodType: BloodType, star: NineStarKiStar) -> String {
        switch (bloodType, overall) {
        case (.a, 5):  return "計画通りに進む最高の日。自信を持って"
        case (.a, 4):  return "丁寧さが評価される好調な日"
        case (.a, 3):  return "慎重さが吉と出る日。焦らずに"
        case (.a, 2):  return "無理せず自分のペースを守ると◎"
        case (.a, 1):  return "静かに英気を養う日。明日に備えて"
        case (.b, 5):  return "直感が冴え渡る最高の日。思い切って"
        case (.b, 4):  return "好奇心が良い出会いを呼ぶ日"
        case (.b, 3):  return "マイペースが功を奏する日"
        case (.b, 2):  return "ペースを守れば大丈夫"
        case (.b, 1):  return "周囲との足並みを意識すると◎"
        case (.o, 5):  return "リーダーシップ全開の最高の日"
        case (.o, 4):  return "行動力が成果を引き寄せる日"
        case (.o, 3):  return "おおらかさが周囲を和ませる日"
        case (.o, 2):  return "細部にも目を配ると吉"
        case (.o, 1):  return "エネルギー充電日。ゆったりと"
        case (.ab, 5): return "知性と感性が最高に噛み合う日"
        case (.ab, 4): return "分析力を活かせる好調な日"
        case (.ab, 3): return "バランス感覚が光る日"
        case (.ab, 2): return "感情の波に注意。冷静さがカギ"
        case (.ab, 1): return "一人の時間で感性を充電する日"
        default:       return "自分の型の長所を信じて過ごしましょう"
        }
    }

    private static func pairKey(_ t1: BloodType, _ t2: BloodType) -> String {
        return "\(t1.rawValue)_\(t2.rawValue)"
    }

    // MARK: - Compatibility Matrix (能見正比古準拠)

    private static let compatibilityMatrix: [String: BloodTypeCompatibilityData] = [
        "A_A":  BloodTypeCompatibilityData(score: 3, description: "価値観が近く安心感がある。ただし互いに気を遣いすぎて疲れることも", loveDescription: "同じ几帳面さゆえに理解し合えるが、どちらも受け身になりやすい。時には思い切った行動を"),
        "A_B":  BloodTypeCompatibilityData(score: 2, description: "正反対の性質が新鮮だが、すれ違いが起きやすい組み合わせ", loveDescription: "A型の繊細さとB型の自由さがぶつかりやすい。互いの「違い」を魅力と捉える心の余裕が鍵"),
        "A_O":  BloodTypeCompatibilityData(score: 4, description: "O型のおおらかさがA型の繊細さを包み込む。補い合える良い関係", loveDescription: "O型の包容力にA型が安心して心を開ける。自然体でいられる心地よい関係が築きやすい"),
        "A_AB": BloodTypeCompatibilityData(score: 4, description: "AB型がA型の几帳面さを理解し尊重できる。知的な結びつきが強い", loveDescription: "AB型の多面性がA型の真面目さに新しい風を送る。知的な会話が二人の絆を深める"),
        "B_A":  BloodTypeCompatibilityData(score: 2, description: "自由を愛するB型と秩序を重んじるA型。歩み寄りの努力が必要", loveDescription: "B型の奔放さにA型が振り回されがち。B型が少し歩調を合わせるだけで関係が大きく改善"),
        "B_B":  BloodTypeCompatibilityData(score: 3, description: "互いの自由を尊重し合える気楽な関係。ただしすれ違いも起きやすい", loveDescription: "お互いにマイペースで心地よいが、どちらも自分の世界を優先しがち。共有の時間を意識して"),
        "B_O":  BloodTypeCompatibilityData(score: 5, description: "最高の相性。O型の包容力がB型の自由さを受け止め、互いに高め合える", loveDescription: "O型がB型の個性をまるごと受け入れ、B型はO型の優しさに安心する。最も自然体でいられる組み合わせ"),
        "B_AB": BloodTypeCompatibilityData(score: 4, description: "AB型の多面性がB型の個性を受け入れる。意外と波長が合う", loveDescription: "互いの個性を面白がれる関係。AB型の知性とB型の直感が化学反応を起こす"),
        "O_A":  BloodTypeCompatibilityData(score: 4, description: "O型が頼れるリーダーシップを発揮し、A型が細やかにサポートする好バランス", loveDescription: "O型の力強さにA型が惹かれ、A型の誠実さにO型が信頼を寄せる。王道のカップル"),
        "O_B":  BloodTypeCompatibilityData(score: 5, description: "O型の寛容さがB型の自由を最大限に活かす。最高の組み合わせの一つ", loveDescription: "B型の予測不能な魅力にO型が夢中に。O型の安定感がB型に安心を与える理想的な関係"),
        "O_O":  BloodTypeCompatibilityData(score: 3, description: "リーダー同士で意見がぶつかることも。互いの領域を尊重すると◎", loveDescription: "パワフルな二人だからこそ火花が散ることも。主導権争いを避け、対等なパートナーシップを"),
        "O_AB": BloodTypeCompatibilityData(score: 2, description: "O型の直球とAB型の複雑さが噛み合いにくい。理解に時間がかかる", loveDescription: "O型のストレートな愛情表現にAB型が戸惑うことも。距離感のすり合わせが大切"),
        "AB_A": BloodTypeCompatibilityData(score: 4, description: "AB型の知性とA型の誠実さが調和。穏やかで深い関係を築ける", loveDescription: "静かだが確かな絆が生まれやすい。言葉にしなくても通じ合える安心感がある"),
        "AB_B": BloodTypeCompatibilityData(score: 4, description: "互いの個性を認め合える。AB型がB型の自由さを知的に楽しめる", loveDescription: "B型の情熱にAB型が新鮮な刺激を受ける。互いの世界観を広げ合える関係"),
        "AB_O": BloodTypeCompatibilityData(score: 2, description: "思考パターンの違いが大きい。歩み寄りの意識が特に重要", loveDescription: "O型の直球愛とAB型のクール愛。温度差を感じやすいが、理解が深まれば強い絆に"),
        "AB_AB": BloodTypeCompatibilityData(score: 3, description: "高い知性で通じ合えるが、互いに踏み込まず距離感が生まれやすい", loveDescription: "知的な会話は最高に楽しいが、感情表現が控えめになりがち。想いは言葉にして伝えて"),
    ]

    // MARK: - Love Sub-Scores Matrix (16 pairs × 4 categories)

    private static let loveMatrix: [String: BloodTypeLoveSubScores] = [
        "A_A":  BloodTypeLoveSubScores(communication: 4, values: 5, passion: 2, stability: 4),
        "A_B":  BloodTypeLoveSubScores(communication: 2, values: 2, passion: 4, stability: 2),
        "A_O":  BloodTypeLoveSubScores(communication: 4, values: 4, passion: 3, stability: 5),
        "A_AB": BloodTypeLoveSubScores(communication: 4, values: 4, passion: 3, stability: 4),
        "B_A":  BloodTypeLoveSubScores(communication: 2, values: 2, passion: 4, stability: 2),
        "B_B":  BloodTypeLoveSubScores(communication: 3, values: 3, passion: 4, stability: 2),
        "B_O":  BloodTypeLoveSubScores(communication: 4, values: 4, passion: 5, stability: 5),
        "B_AB": BloodTypeLoveSubScores(communication: 3, values: 3, passion: 4, stability: 4),
        "O_A":  BloodTypeLoveSubScores(communication: 4, values: 4, passion: 3, stability: 5),
        "O_B":  BloodTypeLoveSubScores(communication: 4, values: 4, passion: 5, stability: 5),
        "O_O":  BloodTypeLoveSubScores(communication: 3, values: 4, passion: 4, stability: 3),
        "O_AB": BloodTypeLoveSubScores(communication: 2, values: 2, passion: 3, stability: 2),
        "AB_A": BloodTypeLoveSubScores(communication: 4, values: 4, passion: 3, stability: 4),
        "AB_B": BloodTypeLoveSubScores(communication: 3, values: 3, passion: 4, stability: 4),
        "AB_O": BloodTypeLoveSubScores(communication: 2, values: 2, passion: 3, stability: 2),
        "AB_AB": BloodTypeLoveSubScores(communication: 5, values: 4, passion: 2, stability: 3),
    ]
}
```

**Step 2: Enhance BloodTypeCalculator.swift — add detailed traits**

Replace the existing `BloodTypeTraits` struct and `traits(for:)` method with expanded versions:

```swift
import Foundation

struct BloodTypeCalculator {

    struct BloodTypeTraits {
        let type: BloodType
        let personality: String
        let strengths: String
        let weaknesses: String
        let compatibility: [BloodType]
        let loveTendency: String
        let workTendency: String
        let moneySense: String
        let healthTendency: String
    }

    static func traits(for bloodType: BloodType) -> BloodTypeTraits {
        switch bloodType {
        case .a:
            return BloodTypeTraits(
                type: .a,
                personality: "几帳面で誠実、周囲に気を配る繊細な心の持ち主です",
                strengths: "責任感が強く、計画的に物事を進められます",
                weaknesses: "心配性になりやすく、ストレスを溜め込みがちです",
                compatibility: [.o, .ab],
                loveTendency: bloodType.loveTendency,
                workTendency: bloodType.workTendency,
                moneySense: bloodType.moneySense,
                healthTendency: bloodType.healthTendency
            )
        case .b:
            return BloodTypeTraits(
                type: .b,
                personality: "自由奔放でクリエイティブ、独自の道を切り開く開拓者です",
                strengths: "好奇心旺盛で、新しいことへの挑戦を恐れません",
                weaknesses: "マイペースすぎて周囲との調和に苦労することがあります",
                compatibility: [.o, .ab],
                loveTendency: bloodType.loveTendency,
                workTendency: bloodType.workTendency,
                moneySense: bloodType.moneySense,
                healthTendency: bloodType.healthTendency
            )
        case .o:
            return BloodTypeTraits(
                type: .o,
                personality: "おおらかでリーダーシップがあり、人を惹きつける魅力の持ち主です",
                strengths: "目標に向かって力強く進み、困難に立ち向かえます",
                weaknesses: "大雑把になりやすく、細かい作業が苦手な面があります",
                compatibility: [.b, .a],
                loveTendency: bloodType.loveTendency,
                workTendency: bloodType.workTendency,
                moneySense: bloodType.moneySense,
                healthTendency: bloodType.healthTendency
            )
        case .ab:
            return BloodTypeTraits(
                type: .ab,
                personality: "理知的で多面的、独特の感性を持つバランスの取れた方です",
                strengths: "分析力に優れ、複数の視点から物事を捉えられます",
                weaknesses: "気分の波があり、周囲から理解されにくいことがあります",
                compatibility: [.a, .b],
                loveTendency: bloodType.loveTendency,
                workTendency: bloodType.workTendency,
                moneySense: bloodType.moneySense,
                healthTendency: bloodType.healthTendency
            )
        }
    }
}
```

**Step 3: Add to Xcode project and build**

Run: `python3 generate_xcodeproj.py && xcodebuild build ...`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Sorayomi/FortuneEngine/Calculators/BloodTypeCompatibility.swift Sorayomi/FortuneEngine/Calculators/BloodTypeCalculator.swift
git commit -m "feat(blood-type): add compatibility matrix and composite daily fortune engine"
```

---

### Task 3: BloodTypeModePickerView

**Files:**
- Create: `Sorayomi/UI/Screens/Reading/BloodTypeModePickerView.swift`

**Step 1: Create the mode picker view**

A 2×2 grid of mode cards matching Sorayomi's dark mystical aesthetic. Uses existing theme system (ColorPalette, Typography, Spacing).

**Step 2: Build and verify**

Run: `python3 generate_xcodeproj.py && xcodebuild build ...`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/BloodTypeModePickerView.swift
git commit -m "feat(blood-type): add mode picker view with 4 fortune modes"
```

---

### Task 4: BloodTypeRevealView — 4 mode animations

**Files:**
- Create: `Sorayomi/UI/Screens/Reading/BloodTypeRevealView.swift`

**Step 1: Create the reveal view**

Contains 4 sub-views switched by mode:
- `DailyFortuneReveal` — blood type icon 3D rotation → score bars animate left-to-right → lucky info
- `CompatibilityReveal` — two types slide in from sides → merge with particles → ring meter fills
- `LoveMatchReveal` — heart particles + pink gradient → types merge into heart → 4 sub-scores slide in
- `RankingReveal` — 4th→1st reverse reveal with increasing drama (bronze→silver→gold glow + haptics)

Uses existing animation patterns: `.spring(response: 0.7, dampingFraction: 0.65)`, particle system, `rotation3DEffect`, radial gradients.

**Step 2: Build and verify**

Run: `python3 generate_xcodeproj.py && xcodebuild build ...`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/BloodTypeRevealView.swift
git commit -m "feat(blood-type): add reveal view with 4 animated fortune presentations"
```

---

### Task 5: ReadingViewModel — blood type state management

**Files:**
- Modify: `Sorayomi/UI/Screens/Reading/ReadingViewModel.swift`

**Step 1: Add blood type state properties**

After the existing tarot properties (line ~53), add:

```swift
    // 血液型専用
    var selectedBloodTypeMode: BloodTypeMode?
    var partnerBloodType: BloodType?
    var showBloodTypeModePicker = false
    var showBloodTypeReveal = false
    var bloodTypeDailyFortune: BloodTypeDailyFortune?
    var bloodTypeRanking: BloodTypeRanking?
    var bloodTypeCompatibilityData: BloodTypeCompatibilityData?
    var bloodTypeLoveSubScores: BloodTypeLoveSubScores?
```

**Step 2: Modify `startReading()` to intercept blood type system**

In the `startReading(system:env:)` method, before the existing hearing setup, add:

```swift
if system == .bloodType {
    selectedSystem = system
    showBloodTypeModePicker = true
    return
}
```

**Step 3: Add `selectBloodTypeMode()` method**

```swift
func selectBloodTypeMode(_ mode: BloodTypeMode, env: AppEnvironment) async {
    selectedBloodTypeMode = mode
    showBloodTypeModePicker = false

    if mode == .ranking {
        bloodTypeRanking = BloodTypeCompatibility.dailyRanking()
        showBloodTypeReveal = true
    } else if mode == .dailyFortune {
        if let bt = env.userProfileService.currentProfile?.bloodType {
            bloodTypeDailyFortune = BloodTypeCompatibility.dailyFortune(for: bt)
        }
        sessionStage = .hearing
        messages.append(.assistantMessage(bloodTypeModeOpeningPrompt(mode)))
    } else {
        // compatibility / loveMatch — need partner type first
        sessionStage = .hearing
        messages.append(.assistantMessage(bloodTypeModeOpeningPrompt(mode)))
        // Partner selection will be handled via special inline UI
    }
}
```

**Step 4: Add `selectPartnerBloodType()` method**

```swift
func selectPartnerBloodType(_ partnerType: BloodType, env: AppEnvironment) {
    partnerBloodType = partnerType
    guard let userType = env.userProfileService.currentProfile?.bloodType,
          let mode = selectedBloodTypeMode else { return }

    bloodTypeCompatibilityData = BloodTypeCompatibility.compatibility(between: userType, and: partnerType)
    if mode == .loveMatch {
        bloodTypeLoveSubScores = BloodTypeCompatibility.loveSubScores(between: userType, and: partnerType)
    }

    let typeName = partnerType.japaneseName
    messages.append(.userMessage("\(typeName)です"))
    messages.append(.assistantMessage(bloodTypePartnerSelectedPrompt(mode: mode, partnerType: partnerType)))
}
```

**Step 5: Add `completeBloodTypeReveal()` method (parallels `completeTarotReveal()`)**

```swift
func completeBloodTypeReveal(env: AppEnvironment) async {
    showBloodTypeReveal = false
    await generateDetailedReading(system: .bloodType, env: env)
}
```

**Step 6: Modify `generateDetailedReading()` — trigger reveal for daily fortune mode**

In `generateDetailedReading()`, add blood type reveal trigger similar to tarot:

```swift
if system == .bloodType, let mode = selectedBloodTypeMode {
    if mode == .dailyFortune && !showBloodTypeReveal && bloodTypeDailyFortune != nil {
        showBloodTypeReveal = true
        return
    }
    if mode.requiresPartner && partnerBloodType != nil && !showBloodTypeReveal {
        showBloodTypeReveal = true
        return
    }
}
```

**Step 7: Add helper methods for blood type prompts**

```swift
private func bloodTypeModeOpeningPrompt(_ mode: BloodTypeMode) -> String { ... }
private func bloodTypePartnerSelectedPrompt(mode: BloodTypeMode, partnerType: BloodType) -> String { ... }
```

**Step 8: Reset blood type state in `resetSession()`**

Add to existing resetSession():
```swift
selectedBloodTypeMode = nil
partnerBloodType = nil
showBloodTypeModePicker = false
showBloodTypeReveal = false
bloodTypeDailyFortune = nil
bloodTypeRanking = nil
bloodTypeCompatibilityData = nil
bloodTypeLoveSubScores = nil
```

**Step 9: Build and verify**

Expected: BUILD SUCCEEDED

**Step 10: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/ReadingViewModel.swift
git commit -m "feat(blood-type): add mode state management to ReadingViewModel"
```

---

### Task 6: ReadingScreen — display condition wiring

**Files:**
- Modify: `Sorayomi/UI/Screens/Reading/ReadingScreen.swift`

**Step 1: Add blood type view conditions**

In the existing conditional display chain (currently: tarot → loading → chat), insert blood type conditions:

```swift
if viewModel.showBloodTypeModePicker {
    BloodTypeModePickerView(
        userBloodType: env.userProfileService.currentProfile?.bloodType ?? .a,
        onSelect: { mode in
            Task {
                await viewModel.selectBloodTypeMode(mode, env: env)
            }
        },
        onBack: { viewModel.resetSession() }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
} else if viewModel.showBloodTypeReveal {
    BloodTypeRevealView(
        mode: viewModel.selectedBloodTypeMode ?? .dailyFortune,
        userBloodType: env.userProfileService.currentProfile?.bloodType ?? .a,
        partnerBloodType: viewModel.partnerBloodType,
        dailyFortune: viewModel.bloodTypeDailyFortune,
        ranking: viewModel.bloodTypeRanking,
        compatibilityData: viewModel.bloodTypeCompatibilityData,
        loveSubScores: viewModel.bloodTypeLoveSubScores,
        onComplete: {
            Task {
                await viewModel.completeBloodTypeReveal(env: env)
            }
        }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
} else if viewModel.showTarotReveal {
    // ... existing tarot reveal
```

**Step 2: Build and verify**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/ReadingScreen.swift
git commit -m "feat(blood-type): wire mode picker and reveal view into ReadingScreen"
```

---

### Task 7: BloodTypePrompt & PromptTemplateEngine — mode-aware prompts

**Files:**
- Modify: `Sorayomi/FortuneEngine/Prompts/BloodTypePrompt.swift`
- Modify: `Sorayomi/FortuneEngine/Prompts/PromptTemplateEngine.swift`
- Modify: `Sorayomi/FortuneEngine/Prompts/SystemPromptBuilder.swift`

**Step 1: Rewrite BloodTypePrompt.swift with mode support**

Add `mode`, `partnerBloodType`, `dailyFortune`, `ranking`, `compatibilityData`, `loveSubScores` parameters. Build mode-specific context blocks as specified in design doc Section 4.

**Step 2: Update PromptTemplateEngine.swift**

Change line 71 to pass blood type mode data:

```swift
case .bloodType:
    systemContext = BloodTypePrompt.build(
        profile: profile,
        category: category,
        mode: bloodTypeMode,
        partnerBloodType: partnerBloodType,
        dailyFortune: bloodTypeDailyFortune,
        ranking: bloodTypeRanking,
        compatibilityData: bloodTypeCompatibilityData,
        loveSubScores: bloodTypeLoveSubScores
    )
```

Add new parameters to `buildUserPrompt()` signature.

**Step 3: Update SystemPromptBuilder.swift**

Add mode-specific instructions to the blood type section of the system prompt.

**Step 4: Update ReadingViewModel.buildDetailedReadingPrompt()**

Pass blood type mode data through to `PromptTemplateEngine.buildUserPrompt()`.

**Step 5: Build and verify**

Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add Sorayomi/FortuneEngine/Prompts/BloodTypePrompt.swift \
       Sorayomi/FortuneEngine/Prompts/PromptTemplateEngine.swift \
       Sorayomi/FortuneEngine/Prompts/SystemPromptBuilder.swift \
       Sorayomi/UI/Screens/Reading/ReadingViewModel.swift
git commit -m "feat(blood-type): add mode-aware prompt generation for all 4 modes"
```

---

### Task 8: Partner blood type inline picker (chat UI)

**Files:**
- Create: `Sorayomi/UI/Screens/Reading/BloodTypePartnerPickerView.swift`
- Modify: `Sorayomi/UI/Screens/Reading/ReadingChatView.swift`

**Step 1: Create inline partner picker component**

4 blood type buttons displayed inline in the chat, styled like quick-reply chips.

**Step 2: Modify ReadingChatView to show partner picker**

When the latest assistant message requests partner blood type selection, show the inline picker instead of the text input.

**Step 3: Build and verify**

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/BloodTypePartnerPickerView.swift \
       Sorayomi/UI/Screens/Reading/ReadingChatView.swift
git commit -m "feat(blood-type): add inline partner blood type picker in chat"
```

---

### Task 9: Integration test — full build and flow verification

**Files:** None (verification only)

**Step 1: Full clean build**

```bash
xcodebuild clean build -scheme Sorayomi -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1'
```
Expected: BUILD SUCCEEDED with no errors or warnings

**Step 2: Verify all 4 mode flows compile correctly**

Check: No missing references, all types resolve, all view parameters match.

**Step 3: Commit any fixes**

```bash
git commit -m "fix(blood-type): resolve build issues from integration"
```
