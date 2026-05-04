import Foundation

/// Provides safe, empathetic Japanese responses when user input is intercepted
/// by the on-device safety gate (crisis or inappropriate content only).
struct SafeResponseProvider {

    struct SafeResponse {
        let message: String
        let action: SafeAction
        let resources: [CrisisResource]

        enum SafeAction {
            case showCrisisResources
            case none
        }
    }

    func response(for classification: InputClassifier.Classification) -> SafeResponse {
        switch classification {
        case .crisis:
            return SafeResponse(
                message: """
                あなたのお気持ちを受け止めています。

                今つらい状況にいらっしゃるなら、一人で抱え込まないでください。専門の相談窓口に話すことで、楽になることがあります。

                ▼ 今すぐ話せる無料相談窓口
                📞 いのちの電話（24時間）
                   0120-783-556

                📞 よりそいホットライン（24時間）
                   0120-279-338

                📞 こころの健康相談統一ダイヤル
                   0570-064-556

                あなたは一人ではありません。
                """,
                action: .showCrisisResources,
                resources: CrisisResource.japanese
            )

        case .inappropriate:
            return SafeResponse(
                message: """
                申し訳ありませんが、そのご質問にはお答えできません。

                別のテーマでの導きをお試しください。
                """,
                action: .none,
                resources: []
            )

        case .safe:
            return SafeResponse(message: "", action: .none, resources: [])
        }
    }
}
