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
    /// お気に入り占術の rawValue リスト。Codable 互換のため String 配列で保持。
    var favoriteSystemIDs: [String]
    var hasConsentedToAI: Bool
    var consentTimestamp: Date?
    var profilePhotoData: Data?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Codable (custom init for backward-compat with pre-favorites data)

    enum CodingKeys: String, CodingKey {
        case id, nickname, birthday, bloodType, themeInterests
        case favoriteSystemIDs
        case hasConsentedToAI, consentTimestamp, profilePhotoData, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                = try c.decode(String.self,                  forKey: .id)
        nickname          = try c.decodeIfPresent(String.self,         forKey: .nickname)
        birthday          = try c.decodeIfPresent(Date.self,           forKey: .birthday)
        bloodType         = try c.decodeIfPresent(BloodType.self,      forKey: .bloodType)
        themeInterests    = try c.decodeIfPresent([ThemeInterest].self, forKey: .themeInterests) ?? []
        favoriteSystemIDs = try c.decodeIfPresent([String].self,       forKey: .favoriteSystemIDs) ?? []
        hasConsentedToAI  = try c.decode(Bool.self,                    forKey: .hasConsentedToAI)
        consentTimestamp  = try c.decodeIfPresent(Date.self,           forKey: .consentTimestamp)
        profilePhotoData  = try c.decodeIfPresent(Data.self,           forKey: .profilePhotoData)
        createdAt         = try c.decode(Date.self,                    forKey: .createdAt)
        updatedAt         = try c.decode(Date.self,                    forKey: .updatedAt)
    }

    // Memberwise init (used by the rest of the codebase)
    init(
        id: String,
        nickname: String? = nil,
        birthday: Date? = nil,
        bloodType: BloodType? = nil,
        themeInterests: [ThemeInterest] = [],
        favoriteSystemIDs: [String] = [],
        hasConsentedToAI: Bool = false,
        consentTimestamp: Date? = nil,
        profilePhotoData: Data? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id                = id
        self.nickname          = nickname
        self.birthday          = birthday
        self.bloodType         = bloodType
        self.themeInterests    = themeInterests
        self.favoriteSystemIDs = favoriteSystemIDs
        self.hasConsentedToAI  = hasConsentedToAI
        self.consentTimestamp  = consentTimestamp
        self.profilePhotoData  = profilePhotoData
        self.createdAt         = createdAt
        self.updatedAt         = updatedAt
    }

    // MARK: - Computed Properties

    /// お気に入り占術（FortuneSystem に変換済み）
    var favoriteSystems: [FortuneSystem] {
        favoriteSystemIDs.compactMap { FortuneSystem(rawValue: $0) }
    }

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
        themeInterests: [],
        favoriteSystemIDs: [],
        hasConsentedToAI: false,
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
            favoriteSystemIDs: [FortuneSystem.tarot.rawValue, FortuneSystem.nineStarKi.rawValue],
            hasConsentedToAI: true,
            consentTimestamp: Date(),
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
