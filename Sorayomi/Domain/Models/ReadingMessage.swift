import Foundation

// MARK: - MessageRole

/// メッセージの送信者ロール
enum MessageRole: String, Codable, CaseIterable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"

    /// 日本語表示名
    var japaneseName: String {
        switch self {
        case .user:      return "あなた"
        case .assistant: return "占い師"
        case .system:    return "システム"
        }
    }

    /// 表示上ユーザーに見せるべきかどうか
    var isVisibleToUser: Bool {
        switch self {
        case .user, .assistant: return true
        case .system:           return false
        }
    }
}

enum ReadingMessagePresentation: String, Codable {
    case standard
    case readingResult
}

// MARK: - ReadingMessage

/// 占い鑑定セッション内の個々のメッセージ
/// Represents a single message within a fortune reading conversation,
/// following the standard user/assistant/system role pattern.
struct ReadingMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    let presentation: ReadingMessagePresentation

    init(
        id: String,
        role: MessageRole,
        content: String,
        timestamp: Date,
        presentation: ReadingMessagePresentation = .standard
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.presentation = presentation
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case timestamp
        case presentation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(MessageRole.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        presentation = try container.decodeIfPresent(ReadingMessagePresentation.self, forKey: .presentation) ?? .standard
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(presentation, forKey: .presentation)
    }

    // MARK: - Computed Properties

    /// メッセージの先頭プレビュー（一覧表示用）
    var preview: String {
        let maxLength = 50
        if content.count <= maxLength {
            return content
        }
        let index = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<index]) + "..."
    }

    /// メッセージの文字数
    var characterCount: Int {
        content.count
    }

    /// 空メッセージかどうか
    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Factory Methods

    /// ユーザーメッセージを作成
    static func userMessage(_ content: String) -> ReadingMessage {
        ReadingMessage(
            id: UUID().uuidString,
            role: .user,
            content: content,
            timestamp: Date()
        )
    }

    /// アシスタント（占い師）メッセージを作成
    static func assistantMessage(
        _ content: String,
        presentation: ReadingMessagePresentation = .standard
    ) -> ReadingMessage {
        ReadingMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: content,
            timestamp: Date(),
            presentation: presentation
        )
    }

    /// システムプロンプトメッセージを作成
    static func systemMessage(_ content: String) -> ReadingMessage {
        ReadingMessage(
            id: UUID().uuidString,
            role: .system,
            content: content,
            timestamp: Date()
        )
    }

    // MARK: - Preview Mocks

    /// プレビュー用：ユーザーメッセージ
    static let mockUser = ReadingMessage(
        id: "msg-mock-user",
        role: .user,
        content: "今月の恋愛運を教えてください",
        timestamp: Date().addingTimeInterval(-60)
    )

    /// プレビュー用：アシスタントメッセージ
    static let mockAssistant = ReadingMessage(
        id: "msg-mock-assistant",
        role: .assistant,
        content: "今月のあなたの恋愛運は上昇傾向にあります。特に月の後半、素敵な出会いや進展が期待できるでしょう。自分の気持ちに正直になることが、幸運を引き寄せる鍵となります。",
        timestamp: Date(),
        presentation: .readingResult
    )
}
