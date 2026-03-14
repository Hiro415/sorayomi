import Foundation

// MARK: - BasePromptContext

/// AIプロンプト生成に必要な基本コンテキスト情報
/// Contains all contextual data needed to build a fortune reading prompt,
/// including date, seasonal context, rokuyo, user question, and reading parameters.
struct BasePromptContext {
    /// 鑑定日
    let date: Date
    /// 季節のコンテキスト（季節、二十四節気、季節のイメージ）
    let season: SeasonalContext
    /// 六曜
    let rokuyo: Rokuyo
    /// ユーザーからの質問（任意）
    let userQuestion: String?
    /// 鑑定カテゴリ
    let category: ReadingCategory
    /// 鑑定の深さ
    let depth: ReadingDepth

    // MARK: - Factory

    /// 指定日付からコンテキストを自動構築する
    static func build(
        date: Date = Date(),
        userQuestion: String? = nil,
        category: ReadingCategory = .general,
        depth: ReadingDepth = .standard
    ) -> BasePromptContext {
        BasePromptContext(
            date: date,
            season: SeasonalContext.from(date: date),
            rokuyo: RokuyoCalculator.calculate(from: date),
            userQuestion: userQuestion,
            category: category,
            depth: depth
        )
    }

    // MARK: - Context Block Generation

    /// AIプロンプトに挿入する日本語コンテキストブロックを構築する
    /// Returns a formatted Japanese context section for inclusion in prompts.
    func buildContextBlock() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（EEEE）"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateString = formatter.string(from: date)

        var lines: [String] = []

        lines.append("【日時と暦の情報】")
        lines.append("・日付：\(dateString)")
        lines.append("・季節：\(season.season)（\(season.solarTerm)）")
        lines.append("・季節の趣：\(season.seasonalImagery)")
        lines.append("・六曜：\(rokuyo.japaneseName)（\(rokuyo.briefGuidance)）")
        lines.append("・吉時間帯：\(rokuyo.luckyTimeOfDay)")

        lines.append("")
        lines.append("【鑑定設定】")
        lines.append("・カテゴリ：\(category.japaneseName)")
        lines.append("・深さ：\(depth.japaneseName)")

        if let question = userQuestion, !question.isEmpty {
            lines.append("")
            lines.append("【ご質問】")
            lines.append(question)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Date Formatting Helpers

    /// 日付を短いフォーマットで返す（例: "3月10日"）
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }

    /// 曜日を返す（例: "月曜日"）
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "EEEE"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
}
