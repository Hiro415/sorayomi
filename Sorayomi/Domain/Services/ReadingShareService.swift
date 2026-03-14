import SwiftUI

// MARK: - ReadingShareService

/// 鑑定結果の共有テキスト・画像を生成するサービス
enum ReadingShareService {

    /// 鑑定結果からシェア用テキストを生成
    /// - Parameters:
    ///   - systemName: 占術名（例: "タロット"）
    ///   - readingText: 鑑定結果テキスト
    /// - Returns: SNS等で共有可能なテキスト
    static func shareText(systemName: String, readingText: String) -> String {
        // 長すぎるテキストは省略
        let maxLength = 200
        let truncated: String
        if readingText.count > maxLength {
            let index = readingText.index(readingText.startIndex, offsetBy: maxLength)
            truncated = String(readingText[..<index]) + "…"
        } else {
            truncated = readingText
        }

        return """
        【\(AppConstants.appName) - \(systemName)】

        \(truncated)

        \(AppConstants.appName)で自分だけの宙よみを体験 ✨
        #宙よみ #Sorayomi #占い
        """
    }

    /// ShareLink用のシェアアイテムを生成
    static func shareItem(systemName: String, readingText: String) -> String {
        shareText(systemName: systemName, readingText: readingText)
    }
}
