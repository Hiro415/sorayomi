import Foundation

/// 本格おみくじ用AIプロンプト構築
/// Builds a comprehensive temple-style omikuji context block for AI follow-up readings,
/// integrating waka poems, all 10 traditional categories, calendar data, and health guidance.
struct OmikujiPrompt {
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        let omikuji = OmikujiCalculator.draw(
            for: Date(),
            birthday: profile?.birthday,
            bloodType: profile?.bloodType
        )

        let cat = omikuji.traditionalCategories

        var lines: [String] = []

        // 基本運勢
        lines.append("【おみくじ 〜 本日の神託】")
        lines.append("━━━━━━━━━━━━━━━━")
        lines.append("　　　\(omikuji.rank.japaneseName)")
        lines.append("━━━━━━━━━━━━━━━━")
        lines.append("")
        lines.append("・運の気配：\(omikuji.rank.nuance)")
        lines.append("・心得：\(omikuji.rank.traditionalAdvice)")

        // 和歌
        lines.append("")
        lines.append("【御歌】")
        lines.append("　\(omikuji.wakaPoem)")
        lines.append("　→ \(omikuji.wakaInterpretation)")

        // 御言葉
        lines.append("")
        lines.append("【御言葉】")
        lines.append("　\(omikuji.poem)")

        // 本日の指針
        lines.append("")
        lines.append("【本日の指針】")
        lines.append("　\(omikuji.guidance)")

        // 伝統的10項目
        lines.append("")
        lines.append("【各項の神託】")
        lines.append("・\(cat.wish.categoryName)（\(cat.wish.reading)）：\(cat.wish.fortune)")
        lines.append("・\(cat.awaitedPerson.categoryName)（\(cat.awaitedPerson.reading)）：\(cat.awaitedPerson.fortune)")
        lines.append("・\(cat.lostItem.categoryName)（\(cat.lostItem.reading)）：\(cat.lostItem.fortune)")
        lines.append("・\(cat.travel.categoryName)（\(cat.travel.reading)）：\(cat.travel.fortune)")
        lines.append("・\(cat.study.categoryName)（\(cat.study.reading)）：\(cat.study.fortune)")
        lines.append("・\(cat.dispute.categoryName)（\(cat.dispute.reading)）：\(cat.dispute.fortune)")
        lines.append("・\(cat.love.categoryName)（\(cat.love.reading)）：\(cat.love.fortune)")
        lines.append("・\(cat.moving.categoryName)（\(cat.moving.reading)）：\(cat.moving.fortune)")
        lines.append("・\(cat.illness.categoryName)（\(cat.illness.reading)）：\(cat.illness.fortune)")
        lines.append("・\(cat.marriage.categoryName)（\(cat.marriage.reading)）：\(cat.marriage.fortune)")

        // 現代の示唆
        lines.append("")
        lines.append("【現代の暮らしへの示唆】")
        lines.append("・恋愛：\(omikuji.loveHint)")
        lines.append("・仕事：\(omikuji.workHint)")
        lines.append("・金運：\(omikuji.moneyHint)")
        lines.append("・健康：\(omikuji.healthHint)")

        // 開運情報
        lines.append("")
        lines.append("【開運情報】")
        lines.append("・吉方：\(omikuji.luckyDirection)")
        lines.append("・吉時間：\(omikuji.luckyTime)")
        lines.append("・ラッキーアイテム：\(omikuji.luckyItem)")
        lines.append("・ラッキーカラー：\(omikuji.luckyColor)")

        // 暦の情報
        lines.append("")
        lines.append("【暦注】\(omikuji.calendarContext)")

        // 鑑定指示
        lines.append("")
        lines.append("【鑑定モード】おみくじ")
        lines.append("→ 上記のおみくじ結果を踏まえて、\(category.japaneseName)に寄り添う鑑定をしてください。")
        lines.append("→ 神社で引くおみくじのように、格調ある簡潔な文体で。ただし現代の暮らしに活かせる実践的助言も添えてください。")
        lines.append("→ 和歌の解釈を鑑定の導入に織り込み、歌の意味と今日の運勢を結びつけてください。")
        lines.append("→ 「\(omikuji.rank.japaneseName)」の心得（\(omikuji.rank.traditionalAdvice)）を踏まえた過ごし方の提案を。")
        lines.append("→ 暦注「\(omikuji.calendarContext)」が示す今日の性質も鑑定に反映してください。")
        lines.append("→ 伝統的項目のうち、\(category.japaneseName)に最も関連する項目を重点的に解説してください。")

        return lines.joined(separator: "\n")
    }
}
