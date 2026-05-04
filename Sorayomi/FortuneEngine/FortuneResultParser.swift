import Foundation

// MARK: - FortuneResult

/// パース済み鑑定結果
/// AI応答テキストを構造化データに変換したもの。
struct FortuneResult {
    let sections: [FortuneSection]
    let luckyItem: String?
    let luckyColor: String?
    let closingMessage: String?
    let rawText: String

    /// パースが成功したかどうか（最低3セクションあれば成功とみなす）
    var isValid: Bool {
        sections.count >= 3
    }
}

// MARK: - FortuneSection

/// Parsed section from a structured fortune response.
struct FortuneSection: Identifiable {
    let id = UUID()
    let category: FortuneSectionCategory
    let score: Int // 0-5
    let body: String
}

// MARK: - FortuneSectionCategory

/// 運勢カテゴリ
enum FortuneSectionCategory: String, CaseIterable {
    // 共通
    case assessment = "見立て"
    case keyAction = "開運の鍵"

    // 標準フォーマット（運勢占い用）
    case overall = "総合運"
    case love = "恋愛運"
    case work = "仕事運"
    case money = "金運"
    case turningPoint = "転機"

    // 総合相談フォーマット（コンサルティング用）
    case divinationReading = "占術の読み"
    case coreInsight = "核心"
    case pathway = "道筋"
    case caution = "注意点"
    case turningSign = "転機のサイン"

    // タロット専用
    case omen = "予兆"

    var iconName: String {
        switch self {
        case .assessment:         return "ear.fill"
        case .overall:            return "sun.max.fill"
        case .love:               return "heart.fill"
        case .work:               return "briefcase.fill"
        case .money:              return "yensign.circle.fill"
        case .turningPoint:       return "arrow.trianglehead.2.clockwise.rotate.90"
        case .keyAction:          return "key.fill"
        case .divinationReading:  return "books.vertical.fill"
        case .coreInsight:        return "eye.fill"
        case .pathway:            return "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .caution:            return "exclamationmark.triangle.fill"
        case .turningSign:        return "arrow.triangle.branch"
        case .omen:               return "moon.stars.fill"
        }
    }

    var usesRating: Bool {
        switch self {
        case .assessment, .turningPoint, .keyAction,
             .divinationReading, .coreInsight, .pathway, .caution, .turningSign,
             .omen:
            return false
        case .overall, .love, .work, .money:
            return true
        }
    }

    var gradientColors: (start: (Double, Double, Double), end: (Double, Double, Double)) {
        switch self {
        case .assessment:         return ((0.58, 0.18, 0.86), (0.62, 0.22, 0.68))
        case .overall:            return ((0.12, 0.5, 0.9), (0.08, 0.6, 0.8))   // ゴールド
        case .love:               return ((0.95, 0.6, 0.7), (0.90, 0.5, 0.6))   // ピンク
        case .work:               return ((0.58, 0.5, 0.7), (0.62, 0.4, 0.6))   // ブルー
        case .money:              return ((0.15, 0.6, 0.8), (0.10, 0.5, 0.7))   // グリーンゴールド
        case .turningPoint:       return ((0.08, 0.55, 0.82), (0.12, 0.60, 0.68))
        case .keyAction:          return ((0.15, 0.45, 0.82), (0.11, 0.50, 0.68))
        case .divinationReading:  return ((0.55, 0.40, 0.85), (0.60, 0.35, 0.70))  // パープル
        case .coreInsight:        return ((0.82, 0.50, 0.80), (0.78, 0.45, 0.65))  // ディープローズ
        case .pathway:            return ((0.42, 0.55, 0.78), (0.38, 0.48, 0.62))  // ティール
        case .caution:            return ((0.06, 0.50, 0.75), (0.08, 0.45, 0.60))  // アンバー
        case .turningSign:        return ((0.72, 0.40, 0.82), (0.68, 0.35, 0.68))  // インディゴ
        case .omen:               return ((0.65, 0.50, 0.60), (0.68, 0.42, 0.45))  // ディープネイビー
        }
    }
}

// MARK: - FortuneResultParser

/// AI応答テキストから構造化された鑑定結果をパースする
struct FortuneResultParser {

    /// AI応答テキストをパースして FortuneResult を返す
    static func parse(_ text: String) -> FortuneResult {
        let rawText = text

        // セクション抽出
        var sections: [FortuneSection] = []
        var luckyItem: String?
        var luckyColor: String?
        var closingMessage: String?

        // 【】で囲まれた各セクションを抽出
        let sectionPattern = /【(.+?)】(.*?)(?=【|$)/
        let matches = text.matches(of: sectionPattern)

        for match in matches {
            let title = String(match.output.1).trimmingCharacters(in: .whitespaces)
            let content = String(match.output.2).trimmingCharacters(in: .whitespacesAndNewlines)

            if let category = FortuneSectionCategory(rawValue: title) {
                let score = category.usesRating
                    ? max(1, min(5, countStars(in: content)))
                    : 0
                let body = extractBody(from: content)
                sections.append(FortuneSection(
                    category: category,
                    score: score,
                    body: body
                ))
            } else if title == "ラッキーアイテム" {
                luckyItem = content.trimmingCharacters(in: .whitespacesAndNewlines)
                // 先頭の★行があれば除去
                if let firstLine = luckyItem?.components(separatedBy: "\n").first,
                   firstLine.contains("★") {
                    luckyItem = luckyItem?.components(separatedBy: "\n").dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if title == "ラッキーカラー" {
                luckyColor = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if let firstLine = luckyColor?.components(separatedBy: "\n").first,
                   firstLine.contains("★") {
                    luckyColor = luckyColor?.components(separatedBy: "\n").dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if title == "メッセージ" || title == "あなたへ" {
                closingMessage = content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return FortuneResult(
            sections: sections,
            luckyItem: luckyItem,
            luckyColor: luckyColor,
            closingMessage: closingMessage,
            rawText: rawText
        )
    }

    // MARK: - Helpers

    /// テキスト内の★の数をカウント
    private static func countStars(in text: String) -> Int {
        // 最初の行から★を数える
        guard let firstLine = text.components(separatedBy: "\n").first else { return 0 }
        return firstLine.filter { $0 == "★" }.count
    }

    /// ★行を除いた本文を抽出
    private static func extractBody(from text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        // 最初の行が★を含む場合はスキップ
        let bodyLines: ArraySlice<String>
        if let first = lines.first, first.contains("★") {
            bodyLines = lines.dropFirst()
        } else {
            bodyLines = lines[...]
        }
        return bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
