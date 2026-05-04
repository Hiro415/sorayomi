// InputClassifier.swift
// Sorayomi
//
// Pre-flight safety gate that operates entirely on-device.
// Only blocks EXPLICIT crisis expressions and inappropriate content.
// All nuanced topics (health, relationships, money, career) are delegated
// to the AI, which has context-aware safety rules in its system prompt.

import Foundation

/// Classifies user input into safety categories to determine whether
/// the request should proceed to AI generation or be intercepted.
///
/// Design Philosophy:
/// On-device keyword matching can only reliably detect unambiguous signals.
/// Explicit crisis expressions ("死にたい", "自殺") are dangerous regardless
/// of context. But ambiguous expressions ("もう限界", "つらい", "楽になりたい")
/// depend entirely on context — "仕事がもう限界で転職したい" is a legitimate
/// fortune consultation, not a crisis.
///
/// Therefore this classifier only blocks:
/// 1. **Explicit crisis** (~20 keywords that are unambiguous)
/// 2. **Inappropriate content** (adult, weapons, drugs, hacking)
///
/// Everything else — including health topics (妊娠, うつ), legal topics (離婚),
/// financial topics (借金, 投資), and ambiguous distress — passes through to
/// the AI, which has full context and nuanced safety instructions.
struct InputClassifier: Sendable {

    // MARK: - Classification Result

    /// The safety classification of a user input string.
    enum Classification: Sendable, Equatable {
        /// The input is safe to process through the AI pipeline.
        case safe
        /// The input indicates a crisis situation requiring immediate resources.
        case crisis(CrisisType)
        /// The input contains inappropriate or out-of-scope content.
        case inappropriate
    }

    /// Types of crisis situations detected in user input.
    enum CrisisType: String, Sendable, Equatable, CaseIterable {
        /// Expressions of suicidal ideation.
        case suicidal
        /// Self-harm behaviors or intentions.
        case selfHarm
        /// Abuse situations (sexual abuse, confinement).
        case abuse
        /// Homicidal ideation or immediate danger to others.
        case emergency
    }

    // MARK: - Explicit Crisis Keywords (High Severity Only)
    // Only keywords that are UNAMBIGUOUS regardless of context.
    // Ambiguous expressions (消えたい, 楽になりたい, もう限界, つらい, etc.)
    // are intentionally excluded — the AI handles these with context.

    /// Explicit suicidal expressions — unambiguous in any context.
    private static let suicidalKeywords: Set<String> = [
        "死にたい", "自殺", "自殺したい", "命を絶ちたい",
        "死のうと思う", "死ぬつもり", "死ぬ方法",
        "死んだほうがいい", "死んだ方がいい",
        "飛び降り", "首吊り", "練炭", "睡眠薬で死",
        "遺書",
    ]

    /// Explicit self-harm expressions — unambiguous in any context.
    private static let selfHarmKeywords: Set<String> = [
        "リストカット", "リスカ",
        "大量服薬", "過量服薬", "OD", "オーバードーズ",
    ]

    /// Explicit abuse expressions — unambiguous in any context.
    private static let abuseKeywords: Set<String> = [
        "性的虐待", "性暴力", "レイプ", "強姦",
        "監禁",
    ]

    /// Explicit violence/homicidal expressions — unambiguous in any context.
    private static let emergencyKeywords: Set<String> = [
        "殺したい", "殺してやる", "殺す",
    ]

    // MARK: - Inappropriate Keywords (Always Block)

    /// Keywords and phrases indicating inappropriate content.
    private static let inappropriateKeywords: Set<String> = [
        "アダルト", "ポルノ", "エロ",
        "ヌード", "性行為",
        "出会い系", "援助交際",
        "爆弾の作り方", "武器の作り方",
        "違法薬物", "覚醒剤", "大麻の入手",
        "ハッキング方法", "不正アクセス",
    ]

    // MARK: - Classification

    /// Classifies the given user input text.
    ///
    /// Priority order:
    /// 1. Explicit crisis (highest priority — unambiguous keywords only)
    /// 2. Inappropriate content
    /// 3. Safe (default — includes all life topics like health, legal, financial)
    ///
    /// - Parameter input: The raw user input text to classify.
    /// - Returns: The safety classification for this input.
    func classify(_ input: String) -> Classification {
        let normalizedInput = input.lowercased()

        // 1. Explicit crisis detection (unambiguous keywords only)
        if let crisisType = detectCrisis(in: normalizedInput) {
            return .crisis(crisisType)
        }

        // 2. Inappropriate content
        if containsKeyword(from: Self.inappropriateKeywords, in: normalizedInput) {
            return .inappropriate
        }

        return .safe
    }

    // MARK: - Private Helpers

    /// Checks explicit crisis keywords: suicidal > selfHarm > abuse > emergency.
    private func detectCrisis(in text: String) -> CrisisType? {
        if containsKeyword(from: Self.suicidalKeywords, in: text) {
            return .suicidal
        }
        if containsKeyword(from: Self.selfHarmKeywords, in: text) {
            return .selfHarm
        }
        if containsKeyword(from: Self.abuseKeywords, in: text) {
            return .abuse
        }
        if containsKeyword(from: Self.emergencyKeywords, in: text) {
            return .emergency
        }
        return nil
    }

    /// Returns `true` if any keyword from the set is found in the text.
    private func containsKeyword(from keywords: Set<String>, in text: String) -> Bool {
        for keyword in keywords {
            if text.contains(keyword.lowercased()) {
                return true
            }
        }
        return false
    }
}
