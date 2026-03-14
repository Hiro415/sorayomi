import Foundation

/// Controls feature visibility across the app.
///
/// For the MVP every flag defaults to a sensible local value.
/// Once Firebase Remote Config is integrated, call `syncFromRemoteConfig()`
/// on launch to override local defaults with server-driven values.
///
/// Usage:
/// ```swift
/// if appEnvironment.featureFlags.isTarotEnabled {
///     TarotSection()
/// }
/// ```
@Observable
@MainActor
final class FeatureFlagManager {

    // MARK: - Reading Types

    /// Western horoscope readings (always on for MVP).
    var isHoroscopeEnabled: Bool = true

    /// Tarot card readings.
    var isTarotEnabled: Bool = true

    /// Numerology readings.
    var isNumerologyEnabled: Bool = true

    /// Nine Star Ki (九星気学) readings.
    var isNineStarKiEnabled: Bool = true

    /// Combined multi-system reading (disabled for MVP; requires all engines).
    var isCombinedReadingEnabled: Bool = false

    // MARK: - Monetization

    /// In-app subscription tier (disabled until backend & StoreKit are ready).
    var isSubscriptionEnabled: Bool = false

    /// Credit store availability.
    var isCreditStoreEnabled: Bool = true

    // MARK: - Operational

    /// When `true` the app shows a maintenance banner and disables readings.
    var maintenanceMode: Bool = false

    /// Message displayed during maintenance.
    var maintenanceMessage: String = "現在メンテナンス中です。しばらくお待ちください。"

    // MARK: - Experimental / A-B Tests

    /// Show the animated fortune reveal (vs. instant display).
    var isAnimatedRevealEnabled: Bool = true

    /// Show daily fortune push notification prompt.
    var isDailyNotificationPromptEnabled: Bool = false

    // MARK: - Remote Config Sync

    /// Refreshes flags from Firebase Remote Config.
    /// TODO: Implement once FirebaseRemoteConfig is added as a dependency.
    func syncFromRemoteConfig() async {
        // TODO: Fetch and apply remote values.
        // Example:
        // let rc = RemoteConfig.remoteConfig()
        // try? await rc.fetchAndActivate()
        // isTarotEnabled = rc[RemoteConfigKey.featureTarotEnabled.stringValue].boolValue
        // ...
    }
}
