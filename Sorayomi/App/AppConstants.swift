import Foundation

/// Static, compile-time constants used across the Sorayomi app.
///
/// Values here do **not** change at runtime.  For values that can be
/// remotely updated see `PricingConfig` and `FeatureFlagManager`.
enum AppConstants {

    // MARK: - Credits

    /// Number of free credits granted on first launch.
    static let initialFreeCredits: Int = 3

    /// Maximum number of readings any user can perform in a rolling 1-hour window.
    /// This is a client-side guard; the backend enforces its own rate limit.
    static let maxReadingsPerHour: Int = 20

    // MARK: - Copy

    /// Default copy variant used until Remote Config delivers a value.
    static let defaultCopyVariant: CopyVariant = .safe

    // MARK: - Support & Legal

    static let privacyPolicyURL: URL = URL(string: "https://hiro415.github.io/sorayomi/privacy/")!

    static let termsURL: URL = URL(string: "https://hiro415.github.io/sorayomi/terms/")!

    // MARK: - App Metadata

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    static let appName: String = "宙よみ"

    static let appDisplayName: String = "宙よみ Sorayomi"

    // MARK: - Animation

    static let standardAnimationDuration: Double = 0.35

    static let longAnimationDuration: Double = 0.6

    // MARK: - Firebase Cloud Functions

    /// Firebase Cloud Functions のベースURL
    /// Cloud Run の完全なURLを設定する（関数名を含まない）。
    /// 空文字の場合はモック応答にフォールバック（開発用）。
    static let cloudFunctionBaseURL: String = "https://generatereading-xrup2mbsaa-uc.a.run.app"

    /// Cloud Function 名（URLパスに追加される）
    /// Cloud Run の場合、関数名はURLに含まれているため空文字にする。
    static let cloudFunctionName: String = ""

    /// 鑑定ローディング最低表示時間（秒）
    static let minimumLoadingDuration: TimeInterval = 5.0

    /// AI API タイムアウト（秒）
    static let aiRequestTimeout: TimeInterval = 60.0

    // MARK: - Persistence Keys Prefix

    /// All UserDefaults keys should be prefixed to avoid collisions.
    static let userDefaultsPrefix: String = "sorayomi_"
}
