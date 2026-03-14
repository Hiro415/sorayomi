import Foundation

/// Draws a deterministic daily omikuji so the result stays stable during the day.
enum OmikujiCalculator {
    private static let weightedRanks: [Omikuji.Rank] = [
        .daikichi, .kichi, .kichi, .chukichi, .chukichi,
        .shokichi, .shokichi, .suekichi, .kyo
    ]

    private static let poems: [String] = [
        "朝の光を受ける枝のように、素直な気持ちが運を呼び込みます。",
        "静かな水面に月が映るように、整えた心に答えが宿ります。",
        "風に揺れる稲穂のように、しなやかさが実りへとつながります。",
        "雲の切れ間から差す光のように、迷いの先で道が見えてきます。",
        "足元の小石を払うほど、遠くの景色まで澄んで見えてきます。",
        "扉をそっと開くように、今日は控えめな勇気が福を招きます。",
        "春を待つ蕾のように、目には見えない準備が明日の追い風になります。"
    ]

    private static let guidance: [String] = [
        "今日は迷いを抱え込むより、ひとつ決めて軽やかに進むほど流れが整います。",
        "急いで結論を出すより、手順を整えることで運気が味方しやすくなります。",
        "誰かのために一歩譲る場面で、思いがけない良縁が返ってきそうです。",
        "予定を詰め込みすぎず、余白をつくるほど本来の勘が冴えてきます。",
        "今日は見栄えよりも心地よさを選ぶと、自然に良い巡りが生まれます。",
        "焦るより、気配りをひとつ足すことが開運の近道になりそうです。"
    ]

    private static let directions = [
        "東", "東南", "南", "南西", "西", "北西", "北", "北東"
    ]

    private static let times = [
        "7時から9時", "9時から11時", "10時から12時", "13時から15時",
        "15時から17時", "18時から20時"
    ]

    private static let items = [
        "白い便箋", "小さな鏡", "香りの良いお茶", "お気に入りの文庫本",
        "朱色の小物", "真鍮のアクセサリー", "和紙のメモ", "手触りの良いハンカチ"
    ]

    private static let colors = [
        "朱色", "生成り", "藍色", "若草色", "琥珀色", "桜色", "薄墨色", "山吹色"
    ]

    private static let loveHints = [
        "やさしい言葉を先に差し出すほど、ご縁が深まりやすい日です。",
        "相手の反応を急がず、会話の余韻を大切にすると関係が温まります。",
        "恋の流れは静かでも、誠実さがきちんと伝わる日になりそうです。",
        "今日は駆け引きよりも、自然体の笑顔がいちばんの魅力になります。 "
    ]

    private static let workHints = [
        "最初の一手を丁寧に整えると、その後の判断が驚くほど滑らかになります。",
        "頼まれごとは無理なく線を引きつつ、得意な場面で光を放てる日です。",
        "確認を一度増やすことが、結果的に大きな信頼へつながります。",
        "今日は新しい案より、今あるものを磨き直す姿勢が評価されやすそうです。"
    ]

    private static let moneyHints = [
        "今日は増やすことより、使い道を整える姿勢が金運を支えます。",
        "大きな買い物より、日々の小さな選択を見直すことで安心感が高まります。",
        "見栄のための出費を控えると、必要なところに余裕が戻ってきます。",
        "お金の流れを記録するだけでも、福を受け取る準備が整いやすい日です。"
    ]

    static func draw(
        for date: Date = Date(),
        birthday: Date? = nil,
        bloodType: BloodType? = nil
    ) -> Omikuji {
        let seed = dailySeed(for: date, birthday: birthday, bloodType: bloodType)

        return Omikuji(
            rank: weightedRanks[index(seed, offset: 0, count: weightedRanks.count)],
            poem: poems[index(seed, offset: 1, count: poems.count)],
            guidance: guidance[index(seed, offset: 2, count: guidance.count)],
            luckyDirection: directions[index(seed, offset: 3, count: directions.count)],
            luckyTime: times[index(seed, offset: 4, count: times.count)],
            luckyItem: items[index(seed, offset: 5, count: items.count)],
            luckyColor: colors[index(seed, offset: 6, count: colors.count)],
            loveHint: loveHints[index(seed, offset: 7, count: loveHints.count)],
            workHint: workHints[index(seed, offset: 8, count: workHints.count)],
            moneyHint: moneyHints[index(seed, offset: 9, count: moneyHints.count)]
        )
    }

    private static func dailySeed(
        for date: Date,
        birthday: Date?,
        bloodType: BloodType?
    ) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        var seed = dayOfYear * 97

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
