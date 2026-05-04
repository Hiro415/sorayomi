import SwiftUI

// MARK: - ReadingShareService

/// 鑑定結果の共有テキストを生成するサービス
enum ReadingShareService {

    /// 鑑定結果からシェア用テキストを生成（全文・装飾付き）
    /// - Parameters:
    ///   - systemName: 占術名（例: "タロット"）
    ///   - readingText: 鑑定結果テキスト
    /// - Returns: SNS等で共有可能なテキスト
    static func shareText(systemName: String, readingText: String) -> String {
        return """
        ✧ \(AppConstants.appName) — \(systemName) ✧

        \(readingText)

        ✨ \(AppConstants.appName)で自分だけの占いを体験
        #宙よみ #Sorayomi #占い
        """
    }

    /// ShareLink用のシェアアイテムを生成
    static func shareItem(systemName: String, readingText: String) -> String {
        shareText(systemName: systemName, readingText: readingText)
    }
}
