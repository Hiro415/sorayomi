// OutputFilter.swift
// Sorayomi
//
// Post-processing filter applied to AI-generated responses before
// they are displayed to the user. Detects and flags prohibited
// patterns, and ensures required disclaimers are present.

import Foundation

/// Flags that can be raised when problematic content is detected
/// in an AI-generated response.
enum SafetyFlag: String, Sendable, CaseIterable {
    /// The response contains absolute predictions or guarantees.
    case prohibitedPrediction
    /// The response contains medical advice or diagnosis.
    case medicalAdvice
    /// The response contains legal advice or opinions.
    case legalAdvice
    /// The response contains financial or investment advice.
    case financialAdvice
    /// The response uses manipulative or coercive language.
    case manipulativeLanguage
}

/// The result of filtering an AI-generated response.
struct FilteredResponse: Sendable, Equatable {
    /// The (potentially modified) content to display.
    let content: String
    /// Safety flags raised during filtering.
    let flags: [SafetyFlag]
    /// Whether the content was modified by the filter.
    let wasModified: Bool

    /// Convenience: `true` if any flags were raised.
    var hasSafetyFlags: Bool { !flags.isEmpty }
}

/// Filters AI-generated responses for prohibited content patterns
/// and ensures compliance disclaimers are appended.
///
/// This is the second line of defense, applied after the AI response
/// is received but before it is shown to the user.
struct OutputFilter: Sendable {

    // MARK: - Prohibited Pattern Definitions

    /// Patterns indicating absolute predictions or guarantees.
    private static let prohibitedPredictionPatterns: [String] = [
        "必ず", "絶対に", "確実に", "間違いなく",
        "100%", "百パーセント",
        "運命です", "宿命です", "決まっています",
        "必ず叶います", "必ず成功します", "必ず実現します",
        "確実に起こります", "確実に訪れます",
        "保証します", "約束します",
        "絶対にうまくいきます", "絶対に大丈夫",
        "間違いありません",
        "必ずお金が", "必ず結婚", "必ず合格",
        "確実に儲かる", "確実に治る",
    ]

    /// Patterns indicating medical advice.
    private static let medicalAdvicePatterns: [String] = [
        "この薬を飲んで", "処方します", "診断します",
        "治療法として", "治療をお勧め",
        "病気の可能性が高い", "病気でしょう",
        "医学的に見て", "医学的な観点から",
        "服用してください", "投薬", "処方",
        "手術をお勧め", "手術が必要",
        "症状から判断すると",
        "うつ病です", "がんです", "糖尿病です",
    ]

    /// Patterns indicating legal advice.
    private static let legalAdvicePatterns: [String] = [
        "法的に", "法律上は", "判例では",
        "訴えるべき", "訴訟を起こ",
        "慰謝料は", "賠償金は",
        "違法です", "合法です",
        "法的責任が", "法的義務",
        "弁護士として", "法的見解",
        "契約上は", "権利があります",
        "告訴すべき", "裁判で勝てます",
    ]

    /// Patterns indicating financial advice.
    private static let financialAdvicePatterns: [String] = [
        "投資すべき", "投資をお勧め",
        "この株を買", "株を売るべき",
        "儲かります", "利益が出ます",
        "資産運用として", "ポートフォリオ",
        "NISAに入るべき", "iDeCoに入るべき",
        "保険に入るべき", "この保険がお勧め",
        "借りるべき", "ローンを組むべき",
        "金融商品として", "運用利回り",
        "確実に増える", "損はしません",
    ]

    /// Patterns indicating manipulative or coercive language.
    private static let manipulativePatterns: [String] = [
        "今すぐ行動しないと", "今日中に決めないと",
        "このチャンスを逃すと", "二度とない機会",
        "運命に逆らうと", "従わないと不幸に",
        "言うとおりにしないと", "必ず後悔します",
        "あなたを救えるのは", "私だけが",
        "他の人には相談しないで", "秘密にして",
        "お金を払わないと", "課金しないと不幸",
        "信じないと罰が", "バチが当たる",
    ]

    /// Standard disclaimer appended when not already present.
    private static let standardDisclaimer =
        "\n\n※ この内容はAIが生成した占いエンターテインメントです。専門的な助言ではありません。"

    /// Short disclaimer marker to check if a disclaimer is already present.
    private static let disclaimerMarkers: [String] = [
        "エンターテインメント",
        "専門的な助言ではありません",
        "専門的助言",
        "娯楽目的",
    ]

    // MARK: - Public API

    /// Filters the given AI-generated response.
    ///
    /// 1. Scans for prohibited patterns and collects flags.
    /// 2. Removes or replaces prohibited absolute language.
    /// 3. Appends a standard disclaimer if none is present.
    ///
    /// - Parameter response: The raw AI-generated response text.
    /// - Returns: A `FilteredResponse` with the processed content and any flags.
    func filter(_ response: String) -> FilteredResponse {
        var flags: [SafetyFlag] = []
        var content = response
        var wasModified = false

        // Detect prohibited predictions
        if containsAny(of: Self.prohibitedPredictionPatterns, in: content) {
            flags.append(.prohibitedPrediction)
            content = softenAbsoluteLanguage(in: content)
            wasModified = true
        }

        // Detect medical advice
        if containsAny(of: Self.medicalAdvicePatterns, in: content) {
            flags.append(.medicalAdvice)
        }

        // Detect legal advice
        if containsAny(of: Self.legalAdvicePatterns, in: content) {
            flags.append(.legalAdvice)
        }

        // Detect financial advice
        if containsAny(of: Self.financialAdvicePatterns, in: content) {
            flags.append(.financialAdvice)
        }

        // Detect manipulative language
        if containsAny(of: Self.manipulativePatterns, in: content) {
            flags.append(.manipulativeLanguage)
            content = removeManipulativeLanguage(in: content)
            wasModified = true
        }

        // Append disclaimer if not present
        if !containsDisclaimer(content) {
            content += Self.standardDisclaimer
            wasModified = true
        }

        return FilteredResponse(
            content: content,
            flags: flags,
            wasModified: wasModified
        )
    }

    /// Quick check for whether a response has any safety issues.
    /// More efficient than full `filter` when only a boolean is needed.
    func hasSafetyIssues(in response: String) -> Bool {
        let allPatterns = Self.prohibitedPredictionPatterns
            + Self.medicalAdvicePatterns
            + Self.legalAdvicePatterns
            + Self.financialAdvicePatterns
            + Self.manipulativePatterns

        return containsAny(of: allPatterns, in: response)
    }

    // MARK: - Private Helpers

    private func containsAny(of patterns: [String], in text: String) -> Bool {
        let lowered = text.lowercased()
        return patterns.contains { lowered.contains($0.lowercased()) }
    }

    private func containsDisclaimer(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return Self.disclaimerMarkers.contains { lowered.contains($0.lowercased()) }
    }

    /// Replaces absolute language with softer alternatives.
    private func softenAbsoluteLanguage(in text: String) -> String {
        var result = text

        let replacements: [(pattern: String, replacement: String)] = [
            ("必ず", "きっと"),
            ("絶対に", "おそらく"),
            ("確実に", "可能性として"),
            ("間違いなく", "きっと"),
            ("100%", "高い可能性で"),
            ("百パーセント", "高い可能性で"),
            ("保証します", "そう感じられます"),
            ("約束します", "そのような流れが見えます"),
        ]

        for (pattern, replacement) in replacements {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }

        return result
    }

    /// Removes sentences containing manipulative language.
    private func removeManipulativeLanguage(in text: String) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: "。！\n"))
        let filtered = sentences.filter { sentence in
            let lowered = sentence.lowercased()
            return !Self.manipulativePatterns.contains { lowered.contains($0.lowercased()) }
        }
        return filtered.joined(separator: "。")
    }
}
