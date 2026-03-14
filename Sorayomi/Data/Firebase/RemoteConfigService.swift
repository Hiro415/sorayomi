import Foundation

// MARK: - RemoteConfigService

/// Firebase Remote Config スタブ実装
/// MVP ではローカルのデフォルト値辞書を返す。
/// TODO: Replace with Firebase Remote Config implementation
@Observable
@MainActor
final class RemoteConfigService {

    // MARK: - Singleton

    static let shared = RemoteConfigService()

    // MARK: - Properties

    /// ローカルのデフォルト値辞書
    private var defaults: [String: Any] = [
        // Pricing
        RemoteConfigKey.pricingCreditsPack4.rawValue: 4,
        RemoteConfigKey.pricingCreditsPack12.rawValue: 12,
        RemoteConfigKey.pricingCreditsPack24.rawValue: 24,
        RemoteConfigKey.pricingCostHoroscope.rawValue: 0,
        RemoteConfigKey.pricingCostTarot.rawValue: 1,
        RemoteConfigKey.pricingCostNumerology.rawValue: 2,
        RemoteConfigKey.pricingCostNineStarKi.rawValue: 2,
        RemoteConfigKey.pricingFreeCreditsInitial.rawValue: 3,

        // Features
        RemoteConfigKey.featureTarotEnabled.rawValue: true,
        RemoteConfigKey.featureNumerologyEnabled.rawValue: true,
        RemoteConfigKey.featureNineStarKiEnabled.rawValue: true,
        RemoteConfigKey.featureCombinedEnabled.rawValue: false,
        RemoteConfigKey.featureSubscriptionEnabled.rawValue: false,
        RemoteConfigKey.featureCreditStoreEnabled.rawValue: true,
        RemoteConfigKey.featureAnimatedReveal.rawValue: true,

        // Copy
        RemoteConfigKey.copySafetyDisclaimer.rawValue: "この鑑定はエンターテインメントとしてお楽しみください。",
        RemoteConfigKey.copyGenericError.rawValue: "エラーが発生しました。もう一度お試しください。",
        RemoteConfigKey.copyLoadingMessage.rawValue: "星の導きを読み解いています…",
        RemoteConfigKey.copyVariant.rawValue: "safe",

        // AI
        RemoteConfigKey.aiModelName.rawValue: "gpt-4o",
        RemoteConfigKey.aiMaxTokens.rawValue: 500,
        RemoteConfigKey.aiTemperature.rawValue: "0.7",

        // Rate Limiting
        RemoteConfigKey.rateLimitMaxPerHour.rawValue: 20,
        RemoteConfigKey.rateLimitCooldownSeconds.rawValue: 5,

        // Operational
        RemoteConfigKey.maintenanceMode.rawValue: false,
        RemoteConfigKey.maintenanceMessage.rawValue: "現在メンテナンス中です。しばらくお待ちください。"
    ]

    /// 最終フェッチ日時
    private(set) var lastFetchDate: Date?

    // MARK: - Init

    init() {}

    // MARK: - Public API

    /// リモート設定を取得（MVP ではローカルデフォルトをそのまま使用）
    /// TODO: Replace with Firebase Remote Config fetch
    func fetch() async {
        // MVP: ネットワーク呼び出しをシミュレート
        try? await Task.sleep(for: .milliseconds(100))
        lastFetchDate = Date()

        #if DEBUG
        print("[RemoteConfigService] Fetched (using local defaults)")
        #endif
    }

    /// 文字列値を取得
    func stringValue(_ key: RemoteConfigKey) -> String? {
        defaults[key.rawValue] as? String
    }

    /// 整数値を取得
    func intValue(_ key: RemoteConfigKey) -> Int? {
        defaults[key.rawValue] as? Int
    }

    /// ブール値を取得
    func boolValue(_ key: RemoteConfigKey) -> Bool? {
        defaults[key.rawValue] as? Bool
    }

    // MARK: - Development Helpers

    /// デフォルト値を上書き（テスト・デバッグ用）
    func override(key: RemoteConfigKey, value: Any) {
        defaults[key.rawValue] = value
        #if DEBUG
        print("[RemoteConfigService] Override \(key.rawValue) = \(value)")
        #endif
    }
}
