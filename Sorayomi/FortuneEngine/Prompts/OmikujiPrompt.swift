import Foundation

/// Builds a Japanese omikuji context block for AI follow-up readings.
struct OmikujiPrompt {
    static func build(profile: UserProfile?, category: ReadingCategory) -> String {
        let omikuji = OmikujiCalculator.draw(
            for: Date(),
            birthday: profile?.birthday,
            bloodType: profile?.bloodType
        )

        return """
        【おみくじデータ】
        ・本日の運勢：\(omikuji.rank.japaneseName)
        ・運の気配：\(omikuji.rank.nuance)
        ・御言葉：\(omikuji.poem)
        ・本日の指針：\(omikuji.guidance)
        ・恋愛の示唆：\(omikuji.loveHint)
        ・仕事の示唆：\(omikuji.workHint)
        ・金運の示唆：\(omikuji.moneyHint)
        ・吉方：\(omikuji.luckyDirection)
        ・吉時間：\(omikuji.luckyTime)
        ・ラッキーアイテム：\(omikuji.luckyItem)
        ・ラッキーカラー：\(omikuji.luckyColor)

        上記のおみくじを踏まえて、\(category.japaneseName)に寄り添う鑑定をしてください。
        神社で引くおみくじのように簡潔な芯を持ちつつ、現代の暮らしに活かせる助言へ広げてください。
        """
    }
}
