import Foundation
import PhotosUI
import SwiftUI

/// マイページ画面の ViewModel
/// UserProfileService からプロフィールを読み込み、更新操作を提供する。
@Observable
@MainActor
final class ProfileViewModel {

    // MARK: - Properties

    /// 現在のユーザープロフィール
    var profile: UserProfile?

    /// 読み込み中かどうか
    var isLoading: Bool = false

    /// プロフィール画像（UIImage）
    var profileImage: UIImage?

    /// PhotosPicker で選択された項目
    var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            if let selectedPhotoItem {
                loadPhoto(from: selectedPhotoItem)
            }
        }
    }

    // MARK: - Load

    /// プロフィールを読み込む
    func loadProfile(env: AppEnvironment) {
        isLoading = true
        env.userProfileService.loadProfile()
        profile = env.userProfileService.currentProfile
        loadProfileImage()
        isLoading = false

        #if DEBUG
        if let profile {
            print("[ProfileViewModel] Loaded profile: \(profile.displayName)")
        } else {
            print("[ProfileViewModel] No profile found")
        }
        #endif
    }

    // MARK: - Update Nickname

    /// ニックネームを更新する
    func updateNickname(env: AppEnvironment, name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if var updatedProfile = profile {
            updatedProfile.nickname = trimmedName
            updatedProfile.updatedAt = Date()
            env.userProfileService.saveProfile(updatedProfile)
            profile = updatedProfile

            #if DEBUG
            print("[ProfileViewModel] Updated nickname to: \(trimmedName)")
            #endif
        }
    }

    // MARK: - Profile Photo

    /// 保存済みのプロフィール画像を読み込む
    private func loadProfileImage() {
        guard let data = profile?.profilePhotoData,
              let image = UIImage(data: data) else {
            profileImage = nil
            return
        }
        profileImage = image
    }

    /// PhotosPicker から選択された写真を読み込んで保存
    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            guard let originalImage = UIImage(data: data) else { return }

            // リサイズ & JPEG 圧縮（最大 400x400, 品質 0.7）
            let resizedImage = resizeImage(originalImage, maxSize: 400)
            guard let jpegData = resizedImage.jpegData(compressionQuality: 0.7) else { return }

            profileImage = resizedImage

            if var updatedProfile = profile {
                updatedProfile.profilePhotoData = jpegData
                updatedProfile.updatedAt = Date()
                profile = updatedProfile
            }

            #if DEBUG
            print("[ProfileViewModel] Profile photo updated (\(jpegData.count) bytes)")
            #endif
        }
    }

    /// プロフィール写真の変更を保存
    func saveProfilePhoto(env: AppEnvironment) {
        guard let updatedProfile = profile else { return }
        env.userProfileService.saveProfile(updatedProfile)
    }

    /// 画像をリサイズ
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        if ratio >= 1.0 { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
