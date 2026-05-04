import Foundation

// MARK: - SettingsViewModel

/// 設定画面の ViewModel
/// アプリ設定の読み込みと操作を提供する。
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - State

    /// 通知を受け取るかどうか（将来の機能に予約）
    var notificationsEnabled: Bool = false

    /// アプリバージョン
    let appVersion: String = AppConstants.appVersion

    /// アプリ表示名
    let appDisplayName: String = AppConstants.appDisplayName

    // MARK: - Load

    /// 設定を読み込み
    func loadSettings(env: AppEnvironment) {
        #if DEBUG
        print("[SettingsViewModel] Loaded settings")
        #endif
    }

}
