import Foundation

// MARK: - UserProfile

/// ユーザープロフィール情報
/// Stores user identity, preferences, and consent state for the Sorayomi app.
struct UserProfile: Codable, Identifiable {
    let id: String
    var nickname: String?
    var birthday: Date?
    var bloodType: BloodType?
    var themeInterests: [ThemeInterest]
    var hasConsentedToAI: Bool
    var consentTimestamp: Date?
    var profilePhotoData: Data?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    /// 星座（誕生日から算出）
    var zodiacSign: ZodiacSign? {
        guard let birthday else { return nil }
        return ZodiacSign.from(date: birthday)
    }

    /// プロフィールが完成しているかどうか
    var isProfileComplete: Bool {
        nickname != nil && birthday != nil && bloodType != nil
    }

    /// 表示名（ニックネームまたはデフォルト）
    var displayName: String {
        nickname ?? "ゲスト"
    }

    // MARK: - Guest

    /// ゲストユーザー（未ログイン状態）
    static let guest = UserProfile(
        id: "guest",
        nickname: nil,
        birthday: nil,
        bloodType: nil,
        themeInterests: [],
        hasConsentedToAI: false,
        consentTimestamp: nil,
        profilePhotoData: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    // MARK: - Preview Mock

    /// プレビュー用モックデータ
    static let mock: UserProfile = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let birthday = calendar.date(from: DateComponents(year: 1995, month: 7, day: 15))!
        return UserProfile(
            id: "mock-user-001",
            nickname: "宙よみ太郎",
            birthday: birthday,
            bloodType: .a,
            themeInterests: [.love, .career, .dailyFortune],
            hasConsentedToAI: true,
            consentTimestamp: Date(),
            profilePhotoData: nil,
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date()
        )
    }()
}

// MARK: - ThemeInterest

/// ユーザーが興味を持っているテーマ
enum ThemeInterest: String, Codable, CaseIterable, Identifiable {
    case love = "love"
    case career = "career"
    case relationships = "relationships"
    case future = "future"
    case dailyFortune = "daily_fortune"

    var id: String { rawValue }

    /// 日本語表示名
    var japaneseName: String {
        switch self {
        case .love:         return "恋愛"
        case .career:       return "仕事"
        case .relationships: return "人間関係"
        case .future:       return "将来"
        case .dailyFortune: return "今日の運勢"
        }
    }

    /// SF Symbolsアイコン名
    var iconName: String {
        switch self {
        case .love:         return "heart.fill"
        case .career:       return "briefcase.fill"
        case .relationships: return "person.2.fill"
        case .future:       return "sparkles"
        case .dailyFortune: return "sun.max.fill"
        }
    }

    /// テーマの説明文
    var japaneseDescription: String {
        switch self {
        case .love:         return "恋愛運や相性について知りたい"
        case .career:       return "仕事運やキャリアの方向性を探りたい"
        case .relationships: return "人間関係の改善やコミュニケーションのヒントがほしい"
        case .future:       return "将来の運勢や人生の流れを知りたい"
        case .dailyFortune: return "今日一日の運勢をチェックしたい"
        }
    }
}
