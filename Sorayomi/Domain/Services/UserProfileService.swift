import Foundation

// MARK: - UserProfileService

/// ユーザープロフィール管理サービス
/// プロフィールの読み込み、保存、更新を統括する。
/// 認証済みユーザーID に紐づくプロフィールを UserRepository 経由で管理。
@Observable
@MainActor
final class UserProfileService {

    // MARK: - Properties

    /// 現在読み込まれているプロフィール
    private(set) var currentProfile: UserProfile?

    /// 読み込み中かどうか
    private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private let repository: UserRepository
    private let authService: FirebaseAuthService

    // MARK: - Init

    init(
        repository: UserRepository = .shared,
        authService: FirebaseAuthService = .shared
    ) {
        self.repository = repository
        self.authService = authService
    }

    // MARK: - Load

    /// 認証済みユーザーのプロフィールを読み込む
    func loadProfile() {
        guard let userId = authService.currentUserId else {
            #if DEBUG
            print("[UserProfileService] No authenticated user, skipping load")
            #endif
            return
        }

        isLoading = true
        currentProfile = repository.get(userId: userId)
        isLoading = false

        #if DEBUG
        if let profile = currentProfile {
            print("[UserProfileService] Loaded profile: \(profile.displayName)")
        } else {
            print("[UserProfileService] No profile found for user: \(userId)")
        }
        #endif
    }

    // MARK: - Save

    /// プロフィールを保存
    func saveProfile(_ profile: UserProfile) {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        repository.save(updatedProfile)
        currentProfile = updatedProfile

        #if DEBUG
        print("[UserProfileService] Saved profile: \(updatedProfile.displayName)")
        #endif
    }

    // MARK: - Updates

    /// 誕生日を更新
    func updateBirthday(_ birthday: Date) {
        guard let userId = authService.currentUserId else { return }

        if var profile = currentProfile {
            profile.birthday = birthday
            profile.updatedAt = Date()
            repository.save(profile)
            currentProfile = profile
        } else {
            // プロフィールが存在しない場合は新規作成
            let newProfile = UserProfile(
                id: userId,
                nickname: nil,
                birthday: birthday,
                bloodType: nil,
                themeInterests: [],
                hasConsentedToAI: false,
                consentTimestamp: nil,
                profilePhotoData: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            repository.save(newProfile)
            currentProfile = newProfile
        }

        #if DEBUG
        print("[UserProfileService] Updated birthday")
        #endif
    }

    /// 血液型を更新
    func updateBloodType(_ bloodType: BloodType) {
        guard let userId = authService.currentUserId else { return }

        if var profile = currentProfile {
            profile.bloodType = bloodType
            profile.updatedAt = Date()
            repository.save(profile)
            currentProfile = profile
        } else {
            let newProfile = UserProfile(
                id: userId,
                nickname: nil,
                birthday: nil,
                bloodType: bloodType,
                themeInterests: [],
                hasConsentedToAI: false,
                consentTimestamp: nil,
                profilePhotoData: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            repository.save(newProfile)
            currentProfile = newProfile
        }

        #if DEBUG
        print("[UserProfileService] Updated blood type to \(bloodType.rawValue)")
        #endif
    }

    /// AI同意を付与
    func grantAIConsent() {
        guard let userId = authService.currentUserId else { return }

        if var profile = currentProfile {
            profile.hasConsentedToAI = true
            profile.consentTimestamp = Date()
            profile.updatedAt = Date()
            repository.save(profile)
            currentProfile = profile
        } else {
            let newProfile = UserProfile(
                id: userId,
                nickname: nil,
                birthday: nil,
                bloodType: nil,
                themeInterests: [],
                hasConsentedToAI: true,
                consentTimestamp: Date(),
                profilePhotoData: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            repository.save(newProfile)
            currentProfile = newProfile
        }

        #if DEBUG
        print("[UserProfileService] AI consent granted")
        #endif
    }

    // MARK: - Helpers

    /// プロフィールが存在するかどうか
    var hasProfile: Bool {
        currentProfile != nil
    }

    /// プロフィールが完成しているかどうか
    var isProfileComplete: Bool {
        currentProfile?.isProfileComplete ?? false
    }
}
