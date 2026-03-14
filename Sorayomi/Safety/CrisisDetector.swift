// CrisisDetector.swift
// Sorayomi
//
// Sophisticated crisis detection that goes beyond simple keyword matching.
// Uses pattern analysis, contextual signals, and severity assessment to
// provide nuanced crisis identification.

import Foundation

/// A more advanced crisis detection system that supplements `InputClassifier`
/// with pattern-based analysis and severity assessment.
///
/// While `InputClassifier` performs fast keyword-based pre-flight checks,
/// `CrisisDetector` provides deeper analysis for borderline cases and
/// assigns severity levels to guide the response strategy.
struct CrisisDetector: Sendable {

    // MARK: - Types

    /// The result of a crisis detection analysis.
    struct DetectionResult: Sendable, Equatable {
        /// Whether a crisis was detected.
        let isCrisis: Bool
        /// The type of crisis, if detected.
        let crisisType: InputClassifier.CrisisType?
        /// The assessed severity level.
        let severity: Severity
        /// The specific patterns that triggered detection.
        let matchedPatterns: [String]
        /// A confidence score from 0.0 (no confidence) to 1.0 (certain).
        let confidence: Double

        /// A non-crisis result.
        static let safe = DetectionResult(
            isCrisis: false,
            crisisType: nil,
            severity: .none,
            matchedPatterns: [],
            confidence: 0.0
        )
    }

    /// Severity levels for detected crisis situations.
    enum Severity: Int, Sendable, Comparable, CaseIterable {
        /// No crisis detected.
        case none = 0
        /// Low severity: vague expressions that may or may not indicate crisis.
        case low = 1
        /// Medium severity: clear distress signals but no immediate danger indicated.
        case medium = 2
        /// High severity: immediate danger or explicit crisis statements.
        case high = 3

        static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Pattern Definitions

    /// Patterns use a struct to associate regex-like string patterns with metadata.
    private struct CrisisPattern: Sendable {
        let pattern: String
        let crisisType: InputClassifier.CrisisType
        let severity: Severity
        let description: String
    }

    /// High-severity patterns indicating immediate danger.
    private static let highSeverityPatterns: [CrisisPattern] = [
        // Suicidal -- explicit intent
        CrisisPattern(pattern: "死にたい", crisisType: .suicidal, severity: .high,
                       description: "Direct expression of wanting to die"),
        CrisisPattern(pattern: "自殺", crisisType: .suicidal, severity: .high,
                       description: "Mention of suicide"),
        CrisisPattern(pattern: "命を絶", crisisType: .suicidal, severity: .high,
                       description: "Expression of ending one's life"),
        CrisisPattern(pattern: "死ぬ方法", crisisType: .suicidal, severity: .high,
                       description: "Seeking method of death"),
        CrisisPattern(pattern: "死のう", crisisType: .suicidal, severity: .high,
                       description: "Expression of intent to die"),
        CrisisPattern(pattern: "死ぬつもり", crisisType: .suicidal, severity: .high,
                       description: "Stated plan to die"),
        CrisisPattern(pattern: "遺書", crisisType: .suicidal, severity: .high,
                       description: "Mention of suicide note"),
        CrisisPattern(pattern: "飛び降り", crisisType: .suicidal, severity: .high,
                       description: "Mention of jumping"),
        CrisisPattern(pattern: "首吊り", crisisType: .suicidal, severity: .high,
                       description: "Mention of hanging"),

        // Self-harm -- active behavior
        CrisisPattern(pattern: "リストカット", crisisType: .selfHarm, severity: .high,
                       description: "Mention of cutting"),
        CrisisPattern(pattern: "リスカ", crisisType: .selfHarm, severity: .high,
                       description: "Abbreviation for cutting"),
        CrisisPattern(pattern: "大量服薬", crisisType: .selfHarm, severity: .high,
                       description: "Mention of overdose"),
        CrisisPattern(pattern: "OD", crisisType: .selfHarm, severity: .high,
                       description: "Abbreviation for overdose"),

        // Abuse -- active danger
        CrisisPattern(pattern: "殴られ", crisisType: .abuse, severity: .high,
                       description: "Being physically assaulted"),
        CrisisPattern(pattern: "暴力を受けて", crisisType: .abuse, severity: .high,
                       description: "Experiencing violence"),
        CrisisPattern(pattern: "性的虐待", crisisType: .abuse, severity: .high,
                       description: "Sexual abuse"),
        CrisisPattern(pattern: "監禁", crisisType: .abuse, severity: .high,
                       description: "Confinement"),

        // Emergency -- immediate danger
        CrisisPattern(pattern: "殺したい", crisisType: .emergency, severity: .high,
                       description: "Homicidal ideation"),
        CrisisPattern(pattern: "殺される", crisisType: .emergency, severity: .high,
                       description: "Fear of being killed"),
        CrisisPattern(pattern: "殺されそう", crisisType: .emergency, severity: .high,
                       description: "Feeling of imminent danger"),
    ]

    /// Medium-severity patterns indicating distress but not immediate danger.
    private static let mediumSeverityPatterns: [CrisisPattern] = [
        // Suicidal ideation -- less explicit
        CrisisPattern(pattern: "消えたい", crisisType: .suicidal, severity: .medium,
                       description: "Wanting to disappear"),
        CrisisPattern(pattern: "消えてしまいたい", crisisType: .suicidal, severity: .medium,
                       description: "Wishing to vanish"),
        CrisisPattern(pattern: "いなくなりたい", crisisType: .suicidal, severity: .medium,
                       description: "Wanting to be gone"),
        CrisisPattern(pattern: "生きたくない", crisisType: .suicidal, severity: .medium,
                       description: "Not wanting to live"),
        CrisisPattern(pattern: "生きていたくない", crisisType: .suicidal, severity: .medium,
                       description: "Not wanting to be alive"),
        CrisisPattern(pattern: "生きる意味がない", crisisType: .suicidal, severity: .medium,
                       description: "No meaning in living"),
        CrisisPattern(pattern: "死んだほうがいい", crisisType: .suicidal, severity: .medium,
                       description: "Better off dead"),
        CrisisPattern(pattern: "全部終わりにしたい", crisisType: .suicidal, severity: .medium,
                       description: "Wanting to end everything"),

        // Self-harm -- ideation
        CrisisPattern(pattern: "自傷", crisisType: .selfHarm, severity: .medium,
                       description: "Self-harm mention"),
        CrisisPattern(pattern: "自分を傷つけ", crisisType: .selfHarm, severity: .medium,
                       description: "Hurting oneself"),
        CrisisPattern(pattern: "切りたい", crisisType: .selfHarm, severity: .medium,
                       description: "Wanting to cut"),
        CrisisPattern(pattern: "血を見たい", crisisType: .selfHarm, severity: .medium,
                       description: "Wanting to see blood"),

        // Abuse -- ongoing situation
        CrisisPattern(pattern: "DV", crisisType: .abuse, severity: .medium,
                       description: "Domestic violence mention"),
        CrisisPattern(pattern: "虐待", crisisType: .abuse, severity: .medium,
                       description: "Abuse mention"),
        CrisisPattern(pattern: "家庭内暴力", crisisType: .abuse, severity: .medium,
                       description: "Domestic violence"),
        CrisisPattern(pattern: "ストーカー", crisisType: .abuse, severity: .medium,
                       description: "Stalking"),
        CrisisPattern(pattern: "逃げられない", crisisType: .abuse, severity: .medium,
                       description: "Cannot escape"),

        // Emergency -- distress
        CrisisPattern(pattern: "助けて", crisisType: .emergency, severity: .medium,
                       description: "Calling for help"),
    ]

    /// Low-severity patterns indicating possible distress.
    private static let lowSeverityPatterns: [CrisisPattern] = [
        CrisisPattern(pattern: "楽になりたい", crisisType: .suicidal, severity: .low,
                       description: "Wanting relief (ambiguous)"),
        CrisisPattern(pattern: "もう限界", crisisType: .suicidal, severity: .low,
                       description: "At one's limit"),
        CrisisPattern(pattern: "もう無理", crisisType: .suicidal, severity: .low,
                       description: "Cannot take it anymore"),
        CrisisPattern(pattern: "つらい", crisisType: .selfHarm, severity: .low,
                       description: "In pain (emotional)"),
        CrisisPattern(pattern: "苦しい", crisisType: .selfHarm, severity: .low,
                       description: "Suffering"),
        CrisisPattern(pattern: "誰も助けてくれない", crisisType: .suicidal, severity: .low,
                       description: "No one helps"),
        CrisisPattern(pattern: "居場所がない", crisisType: .suicidal, severity: .low,
                       description: "No place to belong"),
        CrisisPattern(pattern: "孤独", crisisType: .suicidal, severity: .low,
                       description: "Loneliness"),
    ]

    // MARK: - Compound Pattern Detection

    /// Compound signals: when multiple low-severity terms co-occur, escalate severity.
    private static let escalationCombinations: [(terms: [String], escalatedSeverity: Severity)] = [
        (["もう限界", "誰にも"], .medium),
        (["つらい", "消えたい"], .high),
        (["苦しい", "楽になりたい"], .high),
        (["孤独", "生きる意味"], .high),
        (["もう無理", "終わりにしたい"], .high),
        (["居場所がない", "つらい"], .medium),
        (["誰も助けてくれない", "もう限界"], .high),
    ]

    // MARK: - Public API

    /// Performs comprehensive crisis detection on the given text.
    ///
    /// - Parameter text: The user input text to analyze.
    /// - Returns: A `DetectionResult` with crisis type, severity, and matched patterns.
    func detect(in text: String) -> DetectionResult {
        let normalized = text.lowercased()

        var matchedPatterns: [String] = []
        var highestSeverity: Severity = .none
        var detectedType: InputClassifier.CrisisType?
        var totalConfidence: Double = 0.0

        // Check all pattern tiers (high first for priority)
        let allPatterns = Self.highSeverityPatterns
            + Self.mediumSeverityPatterns
            + Self.lowSeverityPatterns

        for crisisPattern in allPatterns {
            if normalized.contains(crisisPattern.pattern.lowercased()) {
                matchedPatterns.append(crisisPattern.pattern)

                if crisisPattern.severity > highestSeverity {
                    highestSeverity = crisisPattern.severity
                    detectedType = crisisPattern.crisisType
                }

                // Accumulate confidence based on severity tier
                switch crisisPattern.severity {
                case .high:
                    totalConfidence += 0.5
                case .medium:
                    totalConfidence += 0.3
                case .low:
                    totalConfidence += 0.15
                case .none:
                    break
                }
            }
        }

        // Check compound escalation patterns
        for combination in Self.escalationCombinations {
            let allPresent = combination.terms.allSatisfy { term in
                normalized.contains(term.lowercased())
            }
            if allPresent && combination.escalatedSeverity > highestSeverity {
                highestSeverity = combination.escalatedSeverity
                totalConfidence += 0.2
            }
        }

        // Clamp confidence to [0, 1]
        let confidence = min(totalConfidence, 1.0)

        // Only report as crisis if we have at least low severity
        guard highestSeverity > .none else {
            return .safe
        }

        return DetectionResult(
            isCrisis: true,
            crisisType: detectedType,
            severity: highestSeverity,
            matchedPatterns: matchedPatterns,
            confidence: confidence
        )
    }

    /// Quick check for whether the text contains any crisis indicators.
    /// More efficient than full `detect` when only a boolean is needed.
    ///
    /// - Parameter text: The user input text.
    /// - Returns: `true` if any crisis pattern is detected.
    func containsCrisisIndicators(in text: String) -> Bool {
        let normalized = text.lowercased()
        let allPatterns = Self.highSeverityPatterns
            + Self.mediumSeverityPatterns

        return allPatterns.contains { pattern in
            normalized.contains(pattern.pattern.lowercased())
        }
    }

    /// Returns `true` if the detected crisis requires showing crisis resources
    /// (helpline numbers, etc.) rather than just a soft refusal.
    ///
    /// - Parameter result: A detection result from `detect(in:)`.
    /// - Returns: `true` if crisis resources should be displayed.
    func shouldShowCrisisResources(for result: DetectionResult) -> Bool {
        guard result.isCrisis else { return false }

        switch result.severity {
        case .high:
            return true
        case .medium:
            // Show resources for suicidal/selfHarm at medium, not for other types
            return result.crisisType == .suicidal || result.crisisType == .selfHarm
        case .low, .none:
            return false
        }
    }
}
