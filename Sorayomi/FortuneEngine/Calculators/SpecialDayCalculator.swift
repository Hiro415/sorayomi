import Foundation

/// 暦注の選日（特別な日）を計算するエンジン
/// Calculates traditional Japanese calendar special days from actual almanac rules.
struct SpecialDayCalculator {

    // MARK: - Data Structures

    struct SpecialDay: Identifiable {
        let id = UUID()
        let name: String
        let reading: String
        let isAuspicious: Bool
        let description: String
        let suitableFor: [String]
        let avoidFor: [String]
    }

    // MARK: - Public API

    /// 指定日の全ての特別な日を検出
    static func specialDays(for date: Date) -> [SpecialDay] {
        var results: [SpecialDay] = []

        if isTenshaби(date) { results.append(tenshabiEntry) }
        if isIchiryuManbaiBi(date) { results.append(ichiryuManbaiBiEntry) }
        if isFujoujuBi(date) { results.append(fujoujuBiEntry(date)) }
        if isToraNoHi(date) { results.append(toraNoHiEntry) }
        if isMiNoHi(date) { results.append(miNoHiEntry) }
        if isTenichijin(date) { results.append(tenichijinEntry) }
        if isSanrinbou(date) { results.append(sanrinbouEntry) }

        return results
    }

    /// 今日の特別な日
    static func today() -> [SpecialDay] {
        specialDays(for: Date())
    }

    // MARK: - 天赦日（最上の吉日）

    /// 天赦日: 年に5-6回だけの最上の大吉日
    /// 春(立春〜): 戊寅の日, 夏(立夏〜): 甲午の日, 秋(立秋〜): 戊申の日, 冬(立冬〜): 甲子の日
    static func isTenshaби(_ date: Date) -> Bool {
        let (stem, branch) = sexagenaryCycle(for: date)
        let season = calendarSeason(for: date)

        switch season {
        case .spring: return stem == 4 && branch == 2   // 戊寅
        case .summer: return stem == 0 && branch == 6   // 甲午
        case .autumn: return stem == 4 && branch == 8   // 戊申
        case .winter: return stem == 0 && branch == 0   // 甲子
        }
    }

    private static let tenshabiEntry = SpecialDay(
        name: "天赦日", reading: "てんしゃにち／てんしゃび",
        isAuspicious: true,
        description: "暦の上で最上の大吉日。天が万物の罪を赦す日とされ、年に5〜6回しか巡ってこない。何を始めても成功するとされる最高の開運日。",
        suitableFor: ["結婚", "入籍", "開業", "引越し", "財布の新調", "告白", "転職", "新規事業", "あらゆる新しいスタート"],
        avoidFor: []
    )

    // MARK: - 一粒万倍日

    /// 一粒万倍日: 一粒の籾が万倍に実る日。月に4-6回
    /// 各月の十二支と日の組み合わせで決まる
    static func isIchiryuManbaiBi(_ date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let (_, branch) = sexagenaryCycle(for: date)

        // 月ごとの一粒万倍日の十二支
        // 1月:丑・午, 2月:酉・寅, 3月:子・卯, 4月:卯・辰, 5月:巳・午
        // 6月:酉・午, 7月:子・未, 8月:卯・申, 9月:酉・午, 10月:酉・戌
        // 11月:亥・子, 12月:卯・子
        let branches: [Int: [Int]] = [
            1: [1, 6],    // 丑・午
            2: [8, 2],    // 酉・寅
            3: [0, 3],    // 子・卯
            4: [3, 4],    // 卯・辰
            5: [5, 6],    // 巳・午
            6: [8, 6],    // 酉・午
            7: [0, 7],    // 子・未
            8: [3, 8],    // 卯・申
            9: [8, 6],    // 酉・午
            10: [8, 10],  // 酉・戌
            11: [11, 0],  // 亥・子
            12: [3, 0],   // 卯・子
        ]

        return branches[month]?.contains(branch) ?? false
    }

    private static let ichiryuManbaiBiEntry = SpecialDay(
        name: "一粒万倍日", reading: "いちりゅうまんばいび",
        isAuspicious: true,
        description: "一粒の籾が万倍に実るとされる吉日。この日に始めたことは大きく発展するとされる。ただし借金など負の事柄も万倍になるため注意。",
        suitableFor: ["開業", "投資", "種まき", "新しい習慣", "貯金開始", "告白", "入籍", "仕事始め"],
        avoidFor: ["借金", "ローン契約", "保証人", "人から借りる"]
    )

    // MARK: - 不成就日

    /// 不成就日: 何事も成就しない日。月に4回
    /// 各月の特定の日（旧暦ベースだが、現在は新暦で近似的に適用）
    static func isFujoujuBi(_ date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // 不成就日: 月の干支グループごとの日にち
        // 1,7月: 3,11,19,27日  2,8月: 2,10,18,26日
        // 3,9月: 1,9,17,25日  4,10月: 4,12,20,28日
        // 5,11月: 5,13,21,29日  6,12月: 6,14,22,30日
        let days: [Int: [Int]] = [
            1: [3, 11, 19, 27],   7: [3, 11, 19, 27],
            2: [2, 10, 18, 26],   8: [2, 10, 18, 26],
            3: [1, 9, 17, 25],    9: [1, 9, 17, 25],
            4: [4, 12, 20, 28],   10: [4, 12, 20, 28],
            5: [5, 13, 21, 29],   11: [5, 13, 21, 29],
            6: [6, 14, 22, 30],   12: [6, 14, 22, 30],
        ]

        return days[month]?.contains(day) ?? false
    }

    private static func fujoujuBiEntry(_ date: Date) -> SpecialDay {
        SpecialDay(
            name: "不成就日", reading: "ふじょうじゅび",
            isAuspicious: false,
            description: "何事も成就しない凶日。新しいことを始めるのは避けるべきとされる。一粒万倍日や天赦日と重なった場合はその吉が打ち消されるとする説もある。",
            suitableFor: ["内省", "計画の見直し", "準備作業"],
            avoidFor: ["結婚", "開業", "契約", "引越し", "新規事業", "告白"]
        )
    }

    // MARK: - 寅の日

    /// 寅の日: 12日に1度。金運に最良の日
    static func isToraNoHi(_ date: Date) -> Bool {
        let (_, branch) = sexagenaryCycle(for: date)
        return branch == 2  // 寅
    }

    private static let toraNoHiEntry = SpecialDay(
        name: "寅の日", reading: "とらのひ",
        isAuspicious: true,
        description: "虎は「千里行って千里帰る」とされ、お金を使っても戻ってくる金運の吉日。12日に1度巡る。財布の購入・使い始めに最適。",
        suitableFor: ["財布の購入", "財布の使い始め", "宝くじ購入", "投資", "貯金", "金運祈願"],
        avoidFor: ["結婚（虎は家に帰るため嫁入りに不向き）", "葬儀"]
    )

    // MARK: - 巳の日

    /// 巳の日: 12日に1度。弁財天の縁日で金運・芸事に吉
    static func isMiNoHi(_ date: Date) -> Bool {
        let (_, branch) = sexagenaryCycle(for: date)
        return branch == 5  // 巳
    }

    private static let miNoHiEntry = SpecialDay(
        name: "巳の日", reading: "みのひ",
        isAuspicious: true,
        description: "弁財天の使いである蛇（巳）に縁のある日。金運・財運・芸事の上達に良いとされる。己巳の日（つちのとみのひ）は特に強力。",
        suitableFor: ["金運祈願", "弁財天参拝", "芸事の始め", "銀行口座開設", "財布の使い始め"],
        avoidFor: ["結婚（蛇は嫉妬深いとされるため）"]
    )

    // MARK: - 天一天上（天一神が天に昇る16日間）

    /// 天一天上: 天一神が天に昇り、方角の障りがなくなる16日間
    /// 癸巳の日から戊申の日までの16日間
    static func isTenichijin(_ date: Date) -> Bool {
        let (stem, branch) = sexagenaryCycle(for: date)
        let dayIndex = sexagenaryIndex(stem: stem, branch: branch)
        // 癸巳(29) から 戊申(44) までの16日間
        return dayIndex >= 29 && dayIndex <= 44
    }

    private static let tenichijinEntry = SpecialDay(
        name: "天一天上", reading: "てんいちてんじょう",
        isAuspicious: true,
        description: "天一神（方角の神）が天に昇り地上にいない期間。方角の障りがなく、引越しや旅行の方角を気にしなくてよい。60日周期で16日間続く。",
        suitableFor: ["引越し", "旅行", "移転", "方位に関わる行動全般"],
        avoidFor: []
    )

    // MARK: - 三隣亡

    /// 三隣亡: 建築に関する大凶日
    /// 旧暦1,4,7,10月の亥の日、2,5,8,11月の寅の日、3,6,9,12月の午の日
    static func isSanrinbou(_ date: Date) -> Bool {
        let chineseCalendar = Calendar(identifier: .chinese)
        let components = chineseCalendar.dateComponents([.month], from: date)
        guard let lunarMonth = components.month else { return false }

        let (_, branch) = sexagenaryCycle(for: date)
        let monthGroup = ((lunarMonth - 1) % 3)

        switch monthGroup {
        case 0: return branch == 11  // 亥 (1,4,7,10月)
        case 1: return branch == 2   // 寅 (2,5,8,11月)
        case 2: return branch == 6   // 午 (3,6,9,12月)
        default: return false
        }
    }

    private static let sanrinbouEntry = SpecialDay(
        name: "三隣亡", reading: "さんりんぼう",
        isAuspicious: false,
        description: "「三軒隣まで亡ぼす」の意。建築・棟上げ・引越しの大凶日。この日に建築を行うと三軒隣まで火事になるとされる。建築関係者は今も避ける日。",
        suitableFor: [],
        avoidFor: ["建築", "棟上げ", "地鎮祭", "リフォーム", "引越し"]
    )

    // MARK: - 六十干支の計算

    private enum CalendarSeason {
        case spring, summer, autumn, winter
    }

    /// 二十四節気に基づく季節判定（立春基準）
    private static func calendarSeason(for date: Date) -> CalendarSeason {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let md = month * 100 + day

        if md >= 204 && md < 506 { return .spring }
        if md >= 506 && md < 808 { return .summer }
        if md >= 808 && md < 1107 { return .autumn }
        return .winter
    }

    /// 六十干支のインデックス (0-59) を日付から算出
    /// 基準日: 2000年1月1日 = 甲子(0)から6日目 = 庚午(6)
    /// つまり dayOffset + 6 が六十干支番号
    private static func sexagenaryCycle(for date: Date) -> (stem: Int, branch: Int) {
        let idx = sexagenaryDayIndex(for: date)
        return (stem: idx % 10, branch: idx % 12)
    }

    private static func sexagenaryIndex(stem: Int, branch: Int) -> Int {
        // 干支番号を天干地支から復元 (0-59)
        for i in 0..<60 {
            if i % 10 == stem && i % 12 == branch {
                return i
            }
        }
        return 0
    }

    private static func sexagenaryDayIndex(for date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let anchor = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let days = calendar.dateComponents([.day], from: anchor, to: date).day ?? 0
        // 2000/1/1 = 庚午 = 六十干支の6番目
        let index = (days + 6) % 60
        return index < 0 ? index + 60 : index
    }
}
