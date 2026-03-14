import Foundation

/// Exhaustive list of Firebase Remote Config keys used by the app.
///
/// Centralizing keys here prevents typos and makes it easy to audit
/// which values are remotely configurable.  Group names mirror the
/// Remote Config conditions / parameter groups on the Firebase console.
enum RemoteConfigKey: String, CaseIterable, Sendable {

    // MARK: - Pricing

    /// Number of credits in the small pack (default 4).
    case pricingCreditsPack4       = "pricing_credits_pack_4"

    /// Number of credits in the medium pack (default 12).
    case pricingCreditsPack12      = "pricing_credits_pack_12"

    /// Number of credits in the large pack (default 24).
    case pricingCreditsPack24      = "pricing_credits_pack_24"

    /// Credit cost for a horoscope reading.
    case pricingCostHoroscope      = "pricing_cost_horoscope"

    /// Credit cost for a tarot reading.
    case pricingCostTarot          = "pricing_cost_tarot"

    /// Credit cost for a numerology reading.
    case pricingCostNumerology     = "pricing_cost_numerology"

    /// Credit cost for a Nine Star Ki reading.
    case pricingCostNineStarKi     = "pricing_cost_nine_star_ki"

    /// Number of free credits given on first launch.
    case pricingFreeCreditsInitial = "pricing_free_credits_initial"

    // MARK: - Features

    /// Whether tarot readings are enabled.
    case featureTarotEnabled       = "feature_tarot_enabled"

    /// Whether numerology readings are enabled.
    case featureNumerologyEnabled   = "feature_numerology_enabled"

    /// Whether Nine Star Ki readings are enabled.
    case featureNineStarKiEnabled   = "feature_nine_star_ki_enabled"

    /// Whether combined multi-system reading is enabled.
    case featureCombinedEnabled     = "feature_combined_reading_enabled"

    /// Whether subscription tier is enabled.
    case featureSubscriptionEnabled = "feature_subscription_enabled"

    /// Whether the credit store is enabled.
    case featureCreditStoreEnabled  = "feature_credit_store_enabled"

    /// Animated reveal vs. instant result.
    case featureAnimatedReveal      = "feature_animated_reveal"

    // MARK: - Copy / Messaging

    /// Safety disclaimer text override.
    case copySafetyDisclaimer       = "copy_safety_disclaimer"

    /// Generic error message override.
    case copyGenericError           = "copy_generic_error"

    /// Loading message override.
    case copyLoadingMessage         = "copy_loading_message"

    /// Copy variant: "safe" or "engaging".
    case copyVariant                = "copy_variant"

    // MARK: - AI / Model

    /// OpenAI model identifier (e.g. "gpt-4o").
    case aiModelName                = "ai_model_name"

    /// Maximum tokens for a single reading response.
    case aiMaxTokens                = "ai_max_tokens"

    /// Temperature for reading generation (0.0 - 2.0).
    case aiTemperature              = "ai_temperature"

    // MARK: - Rate Limiting

    /// Max readings per hour (client-side guard).
    case rateLimitMaxPerHour        = "rate_limit_max_per_hour"

    /// Cooldown seconds between consecutive readings.
    case rateLimitCooldownSeconds   = "rate_limit_cooldown_seconds"

    // MARK: - Operational

    /// Global maintenance mode flag.
    case maintenanceMode            = "maintenance_mode"

    /// Maintenance message shown to users.
    case maintenanceMessage         = "maintenance_message"

    // MARK: - Convenience

    /// The raw string value used as the Remote Config parameter name.
    var stringValue: String { rawValue }
}
