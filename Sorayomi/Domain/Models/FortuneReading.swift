import Foundation

// MARK: - ReadingCategory

/// 占いの相談カテゴリ
enum ReadingCategory: String, Codable, CaseIterable, Identifiable {
    case love = "love"
    case career = "career"
    case health = "health"
    case wealth = "wealth"
    case relationships = "relationships"
    case personality = "personality"
    case general = "general"
    case daily = "daily"

    var id: String { rawValue }

    /// 日本語表示名
    var japaneseName: String {
        switch self {
        case .love:          return "恋愛運"
        case .career:        return "仕事運"
        case .health:        return "健康運"
        case .wealth:        return "金運"
        case .relationships: return "対人運"
        case .personality:   return "自分を知る"
        case .general:       return "総合運"
        case .daily:         return "今日の運勢"
        }
    }

    /// 会話や画面表示向けの短い表示名
    var consultationLabel: String {
        switch self {
        case .love:          return "恋愛"
        case .career:        return "仕事"
        case .health:        return "心と健康"
        case .wealth:        return "金運"
        case .relationships: return "人間関係"
        case .personality:   return "自分を知る"
        case .general:       return "自由相談"
        case .daily:         return "今日の流れ"
        }
    }

    /// SF Symbolsアイコン名
    var iconName: String {
        switch self {
        case .love:          return "heart.fill"
        case .career:        return "briefcase.fill"
        case .health:        return "leaf.fill"
        case .wealth:        return "yensign.circle.fill"
        case .relationships: return "person.2.fill"
        case .personality:   return "person.fill.questionmark"
        case .general:       return "sparkles"
        case .daily:         return "sun.max.fill"
        }
    }

    /// カテゴリの説明文
    var japaneseDescription: String {
        switch self {
        case .love:          return "恋愛や出会い、パートナーシップについて"
        case .career:        return "仕事やキャリア、転職について"
        case .health:        return "心身の健康やウェルネスについて"
        case .wealth:        return "金運や財運、投資について"
        case .relationships: return "人間関係やコミュニケーションについて"
        case .personality:   return "性格や才能、自分のリズムを知る"
        case .general:       return "全体的な運勢や人生の流れについて"
        case .daily:         return "今日一日の運勢と過ごし方のアドバイス"
        }
    }

    static func infer(from text: String?) -> ReadingCategory {
        guard let text, !text.isEmpty else {
            return .general
        }

        let normalized = text
            .lowercased()
            .replacingOccurrences(of: "　", with: " ")
            .replacingOccurrences(of: "\n", with: " ")

        if normalized.contains(anyOf: [
            "恋愛", "好きな人", "片思い", "復縁", "結婚", "婚活",
            "彼氏", "彼女", "パートナー", "出会い", "告白"
        ]) {
            return .love
        }

        if normalized.contains(anyOf: [
            "仕事", "転職", "職場", "キャリア", "就職", "昇進",
            "部署", "評価", "独立", "働き方"
        ]) {
            return .career
        }

        if normalized.contains(anyOf: [
            "健康", "体調", "メンタル", "疲れ", "ストレス",
            "睡眠", "眠れ", "生活リズム", "不調"
        ]) {
            return .health
        }

        if normalized.contains(anyOf: [
            "お金", "金運", "収入", "出費", "貯金",
            "家計", "投資", "ローン", "借金"
        ]) {
            return .wealth
        }

        if normalized.contains(anyOf: [
            "人間関係", "友人", "友達", "家族", "親",
            "兄弟", "姉妹", "夫婦", "上司", "同僚", "関係"
        ]) {
            return .relationships
        }

        if normalized.contains(anyOf: [
            "性格", "自分", "才能", "適性", "向いている",
            "長所", "短所", "リズム", "自分らしさ", "個性"
        ]) {
            return .personality
        }

        if normalized.contains(anyOf: [
            "今日", "明日", "今週", "週末", "今月",
            "予定", "一日", "流れ", "タイミング"
        ]) {
            return .daily
        }

        return .general
    }
}

// MARK: - FortuneReading

/// 一回の占い鑑定セッション
/// Represents a complete fortune reading session including system used,
/// category, messages exchanged, and cost.
struct FortuneReading: Codable, Identifiable {
    let id: String
    let userId: String
    let system: FortuneSystem
    let theme: ReadingCategory
    var messages: [ReadingMessage]
    let creditsCost: Int
    let createdAt: Date

    // MARK: - Computed Properties

    /// 鑑定結果のサマリー（最初のアシスタントメッセージ）
    var summary: String? {
        if let readingResult = messages.first(where: {
            $0.role == .assistant && $0.presentation == .readingResult
        }) {
            return readingResult.content
        }

        return messages.first(where: { $0.role == .assistant })?.content
    }

    /// メッセージ数
    var messageCount: Int {
        messages.count
    }

    /// ユーザーからの質問があるかどうか
    var hasUserQuestion: Bool {
        messages.contains(where: { $0.role == .user })
    }

    /// 鑑定の表示タイトル
    var displayTitle: String {
        "\(system.japaneseName) - \(theme.consultationLabel)"
    }

    // MARK: - Preview Mock

    /// プレビュー用モックデータ
    static let mock = FortuneReading(
        id: "reading-mock-001",
        userId: "mock-user-001",
        system: .horoscope,
        theme: .love,
        messages: [
            ReadingMessage(
                id: "msg-001",
                role: .system,
                content: "あなたは経験豊富な占い師です。星座占いに基づいて、優しく的確なアドバイスをしてください。",
                timestamp: Date().addingTimeInterval(-120)
            ),
            ReadingMessage(
                id: "msg-002",
                role: .user,
                content: "最近気になる人がいるのですが、うまくいくでしょうか？",
                timestamp: Date().addingTimeInterval(-60)
            ),
            ReadingMessage(
                id: "msg-003",
                role: .assistant,
                content: "しし座のあなたには、今素敵な出会いの星が巡ってきています。太陽と金星の調和的な配置が、あなたの魅力を一層輝かせています。気になる方との関係は、あなたの自然体の優しさが鍵となるでしょう。焦らず、自分らしくいることで、良い流れが生まれます。今月の後半に進展がありそうです。",
                timestamp: Date()
            )
        ],
        creditsCost: 0,
        createdAt: Date()
    )

    /// プレビュー用：タロット鑑定のモック
    static let tarotMock = FortuneReading(
        id: "reading-mock-002",
        userId: "mock-user-001",
        system: .tarot,
        theme: .career,
        messages: [
            ReadingMessage(
                id: "msg-004",
                role: .user,
                content: "転職を考えているのですが、今が良いタイミングでしょうか？",
                timestamp: Date().addingTimeInterval(-60)
            ),
            ReadingMessage(
                id: "msg-005",
                role: .assistant,
                content: "カードを引きました。「運命の輪」が正位置で現れています。これは大きな転換期の訪れを示しています。今のあなたには、新しい道を切り開くエネルギーが満ちています。ただし、「隠者」のカードも出ていますので、十分な情報収集と内省の時間も大切です。準備が整ったと感じた時が、最良のタイミングです。",
                timestamp: Date()
            )
        ],
        creditsCost: 1,
        createdAt: Date()
    )
}

private extension String {
    func contains(anyOf keywords: [String]) -> Bool {
        keywords.contains { contains($0) }
    }
}
