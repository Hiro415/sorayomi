// InputClassifier.swift
// Sorayomi
//
// Classifies user input text to detect safety-sensitive topics before
// the input is sent to the AI backend. This is a pre-flight safety gate
// that operates entirely on-device using keyword matching.

import Foundation

/// Classifies user input into safety categories to determine whether
/// the request should proceed to AI generation or be intercepted with
/// a safe response.
///
/// The classifier runs synchronously on-device with no network dependency.
/// It is the first line of defense in the safety pipeline, applied before
/// any API call is made.
struct InputClassifier: Sendable {

    // MARK: - Classification Result

    /// The safety classification of a user input string.
    enum Classification: Sendable, Equatable {
        /// The input is safe to process through the AI pipeline.
        case safe
        /// The input indicates a crisis situation requiring immediate resources.
        case crisis(CrisisType)
        /// The input requests medical information or advice.
        case medical
        /// The input requests legal information or advice.
        case legal
        /// The input requests financial or investment advice.
        case financial
        /// The input contains inappropriate or out-of-scope content.
        case inappropriate
    }

    /// Types of crisis situations detected in user input.
    enum CrisisType: String, Sendable, Equatable, CaseIterable {
        /// Expressions of suicidal ideation.
        case suicidal
        /// Self-harm behaviors or intentions.
        case selfHarm
        /// Abuse situations (domestic violence, child abuse, etc.).
        case abuse
        /// General emergency situations.
        case emergency
    }

    // MARK: - Keyword Sets

    /// Keywords and phrases indicating suicidal ideation.
    private static let suicidalKeywords: Set<String> = [
        "死にたい", "自殺", "自殺したい", "命を絶ちたい",
        "消えたい", "消えてしまいたい", "いなくなりたい",
        "生きたくない", "生きていたくない", "生きる意味がない",
        "生きてる意味", "死んだほうがいい", "死んだ方がいい",
        "死のうと思う", "死ぬつもり", "死ぬ方法",
        "楽になりたい", "もう終わりにしたい", "全部終わりにしたい",
        "飛び降り", "首吊り", "練炭", "睡眠薬で死",
        "遺書", "身辺整理"
    ]

    /// Keywords and phrases indicating self-harm behavior.
    private static let selfHarmKeywords: Set<String> = [
        "リストカット", "リスカ", "自傷", "自傷行為",
        "切りたい", "腕を切る", "血を見たい",
        "傷つけたい", "自分を傷つけ", "自分を痛めつけ",
        "アームカット", "レッグカット", "OD", "オーバードーズ",
        "大量服薬", "過量服薬"
    ]

    /// Keywords and phrases indicating abuse situations.
    private static let abuseKeywords: Set<String> = [
        "虐待", "DV", "ドメスティックバイオレンス",
        "暴力を受けて", "暴力を振るわれ", "殴られ",
        "家庭内暴力", "児童虐待", "ネグレクト",
        "性的虐待", "性暴力", "レイプ", "強姦",
        "パワハラ", "セクハラ", "モラハラ",
        "ストーカー", "つきまとい", "脅迫されて",
        "監禁", "束縛", "逃げられない"
    ]

    /// Keywords and phrases indicating emergency situations.
    private static let emergencyKeywords: Set<String> = [
        "殺したい", "殺してやる", "殺す",
        "殺される", "殺されそう", "命を狙われ",
        "助けて", "緊急", "今すぐ助け",
        "火事", "事故", "地震", "津波"
    ]

    /// Keywords and phrases indicating medical topics.
    private static let medicalKeywords: Set<String> = [
        "病気", "薬", "処方", "処方箋",
        "診断", "症状", "治療", "手術",
        "うつ", "うつ病", "鬱", "鬱病",
        "精神科", "心療内科", "病院",
        "癌", "がん", "ガン", "腫瘍",
        "妊娠", "流産", "不妊",
        "アレルギー", "喘息", "糖尿病",
        "高血圧", "心臓病", "脳卒中",
        "パニック障害", "統合失調症", "双極性障害",
        "摂食障害", "拒食症", "過食症",
        "不眠症", "睡眠障害", "PTSD",
        "発達障害", "ADHD", "自閉症",
        "認知症", "介護",
        "何科に行けば", "医者に行くべき",
        "薬を飲んで", "服薬"
    ]

    /// Keywords and phrases indicating legal topics.
    private static let legalKeywords: Set<String> = [
        "裁判", "訴訟", "弁護士", "法律相談",
        "逮捕", "違法", "犯罪", "被害届",
        "慰謝料", "損害賠償", "示談",
        "離婚", "親権", "養育費",
        "遺産", "相続", "遺言",
        "労働基準", "解雇", "不当解雇",
        "契約違反", "詐欺", "横領",
        "著作権", "特許", "商標",
        "告訴", "告発", "起訴",
        "刑事事件", "民事事件",
        "法テラス", "司法書士",
        "交通事故の過失", "過失割合"
    ]

    /// Keywords and phrases indicating financial topics.
    private static let financialKeywords: Set<String> = [
        "投資", "株", "株式", "FX",
        "仮想通貨", "暗号通貨", "ビットコイン",
        "借金", "ローン", "破産", "自己破産",
        "融資", "消費者金融", "闇金",
        "資産運用", "ポートフォリオ",
        "NISAどう", "iDeCo", "積立",
        "不動産投資", "マンション投資",
        "先物取引", "信用取引", "レバレッジ",
        "節税", "確定申告の投資",
        "老後の資金", "年金どうすれば",
        "保険に入るべき", "保険の見直し",
        "債務整理", "過払い金", "多重債務",
        "ギャンブル依存", "パチンコ借金"
    ]

    /// Keywords and phrases indicating inappropriate content.
    private static let inappropriateKeywords: Set<String> = [
        "アダルト", "ポルノ", "エロ",
        "ヌード", "裸", "性行為",
        "出会い系", "援助交際",
        "爆弾の作り方", "武器の作り方",
        "違法薬物", "覚醒剤", "大麻の入手",
        "ハッキング方法", "不正アクセス"
    ]

    // MARK: - Classification

    /// Classifies the given user input text.
    ///
    /// The classifier checks categories in priority order:
    /// 1. Crisis (highest priority -- must trigger immediate safe response)
    /// 2. Medical
    /// 3. Legal
    /// 4. Financial
    /// 5. Inappropriate
    /// 6. Safe (default)
    ///
    /// - Parameter input: The raw user input text to classify.
    /// - Returns: The safety classification for this input.
    func classify(_ input: String) -> Classification {
        let normalizedInput = input.lowercased()

        // 1. Crisis detection (highest priority)
        if let crisisType = detectCrisis(in: normalizedInput) {
            return .crisis(crisisType)
        }

        // 2. Medical
        if containsKeyword(from: Self.medicalKeywords, in: normalizedInput) {
            return .medical
        }

        // 3. Legal
        if containsKeyword(from: Self.legalKeywords, in: normalizedInput) {
            return .legal
        }

        // 4. Financial
        if containsKeyword(from: Self.financialKeywords, in: normalizedInput) {
            return .financial
        }

        // 5. Inappropriate
        if containsKeyword(from: Self.inappropriateKeywords, in: normalizedInput) {
            return .inappropriate
        }

        return .safe
    }

    // MARK: - Private Helpers

    /// Checks crisis keywords in priority sub-order: suicidal > selfHarm > abuse > emergency.
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
