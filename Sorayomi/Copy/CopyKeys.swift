// CopyKeys.swift
// Sorayomi
//
// Exhaustive enumeration of every localizable copy key in the Sorayomi app.
// Each key maps to a remote-config key for server-driven copy updates.

import Foundation

/// Every user-facing string in the app is represented by a `CopyKey`.
///
/// Keys are organized by feature area. Each key has a deterministic
/// `remoteConfigKey` used for server-side copy overrides via Firebase
/// Remote Config (or equivalent).
enum CopyKey: String, CaseIterable, Sendable {

    // MARK: - App Identity

    case appTitle
    case appSubtitle

    // MARK: - Onboarding

    case onboardingWelcomeTitle
    case onboardingWelcomeBody
    case onboardingValueProp
    case onboardingBirthdayTitle
    case onboardingBloodTypeTitle
    case onboardingAIConsentTitle
    case onboardingAIConsentBody
    case onboardingAIProviderName

    // MARK: - Reading (Fortune Result)

    case readingDisclaimer
    case readingPlaceholder
    case readingAIAttribution
    case readingGenerating

    // MARK: - Safety Refusals

    case safeRefusalCrisis
    case safeRefusalMedical
    case safeRefusalLegal
    case safeRefusalFinancial

    // MARK: - Store

    case storeTitle
    case storeSubtitle
    case storeConsumableNotice
    case storePack4Label
    case storePack12Label
    case storePack24Label

    // MARK: - Paywall

    case paywallTitle
    case paywallSubtitle
    case paywallCreditsNeeded

    // MARK: - Home

    case homeTitle
    case homeDailyCardTitle
    case homeQuickAccessTitle

    // MARK: - History

    case historyTitle
    case historyEmpty

    // MARK: - Profile

    case profileTitle
    case profileCreditsLabel
    case profileEditButton

    // MARK: - Settings

    case settingsTitle
    case settingsPrivacy
    case settingsTerms
    case settingsRestore
    case settingsLogout
    case settingsDataDeletion

    // MARK: - Errors

    case errorNetwork
    case errorInsufficientCredits
    case errorGeneric
    case errorTimeout
    case errorSafetyBlock

    // MARK: - Credit Badge

    case creditBadgeLabel
    case creditFreeLabel

    // MARK: - Disclaimers

    case disclaimerEntertainment
    case disclaimerNotAdvice

    // MARK: - Remote Config Key

    /// The key used for remote config lookups.
    ///
    /// Converts the Swift camelCase enum case to a snake_case string
    /// prefixed with `copy_` for namespacing in remote config.
    ///
    /// Example: `onboardingWelcomeTitle` -> `"copy_onboarding_welcome_title"`
    var remoteConfigKey: String {
        let snakeCase = rawValue.reduce(into: "") { result, character in
            if character.isUppercase {
                result += "_"
                result += character.lowercased()
            } else {
                result += String(character)
            }
        }
        return "copy_\(snakeCase)"
    }
}
