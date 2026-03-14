// CopyVariant.swift
// Sorayomi
//
// Defines the compliance variant levels for all user-facing copy.
// Each variant represents a progressively stricter level of disclosure
// regarding AI-generated content and liability limitations.

import Foundation

/// Represents the compliance disclosure level applied to all user-facing copy.
///
/// The variant determines how explicitly the app communicates its AI-powered nature,
/// entertainment purpose, and liability limitations. Higher strictness levels produce
/// more explicit disclosures at the cost of conversational warmth.
///
/// - `safe`: Default production variant. Warm tone with adequate disclosure.
///   Suitable for general App Store release.
/// - `stricter`: Elevated disclosure variant. More explicit AI attribution
///   and entertainment-only framing. Used when compliance review requires
///   additional clarity.
/// - `legalReview`: Maximum disclosure variant. Full legal language with
///   explicit provider attribution and professional-advice disclaimers.
///   Used during legal/regulatory review periods.
enum CopyVariant: String, CaseIterable, Codable, Sendable {

    case safe
    case stricter
    case legalReview

    // MARK: - Display Metadata

    /// Human-readable label for internal tooling and debug displays.
    var displayName: String {
        switch self {
        case .safe:
            return "Standard"
        case .stricter:
            return "Stricter Disclosure"
        case .legalReview:
            return "Legal Review"
        }
    }

    /// Japanese label for internal tooling.
    var displayNameJA: String {
        switch self {
        case .safe:
            return "標準"
        case .stricter:
            return "厳格開示"
        case .legalReview:
            return "法務レビュー"
        }
    }

    /// Brief description of this variant's intent.
    var description: String {
        switch self {
        case .safe:
            return "Warm tone with adequate AI and entertainment disclosure."
        case .stricter:
            return "Explicit AI attribution and entertainment-only framing."
        case .legalReview:
            return "Full legal language with provider names and professional-advice disclaimers."
        }
    }

    // MARK: - Remote Config

    /// The key used to store and retrieve this variant via remote configuration.
    static let remoteConfigKey = "copy_variant"

    /// Attempts to initialize from a remote config string value.
    /// Falls back to `.safe` for unrecognized values.
    init(remoteValue: String?) {
        guard let value = remoteValue,
              let variant = CopyVariant(rawValue: value) else {
            self = .safe
            return
        }
        self = variant
    }
}
