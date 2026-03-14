import Foundation

/// Provides safe, empathetic Japanese responses when user input touches restricted domains.
struct SafeResponseProvider {

    struct SafeResponse {
        let message: String
        let action: SafeAction
        let resources: [CrisisResource]

        enum SafeAction {
            case showCrisisResources
            case dismissWithOption
            case none
        }
    }

    func response(for classification: InputClassifier.Classification) -> SafeResponse {
        switch classification {
        case .crisis:
            return SafeResponse(
                message: """
                あなたのお気持ちを受け止めています。

                今つらい状況にいらっしゃるなら、一人で抱え込まないでください。\
                専門の相談窓口にお話しすることをお勧めします。

                あなたは一人ではありません。
                """,
                action: .showCrisisResources,
                resources: CrisisResource.japanese
            )

        case .medical:
            return SafeResponse(
                message: """
                健康に関するご心配があるのですね。

                申し訳ありませんが、医療に関する具体的なアドバイスを\
                提供することはできません。\
                医師や医療専門家にご相談されることをお勧めいたします。

                運勢や気持ちの面での導きでしたら、お気軽にどうぞ。
                """,
                action: .dismissWithOption,
                resources: []
            )

        case .legal:
            return SafeResponse(
                message: """
                法律に関するお悩みがあるのですね。

                法的なアドバイスは専門の弁護士にご相談ください。

                運勢や人間関係についてのご質問でしたら、お手伝いできます。
                """,
                action: .dismissWithOption,
                resources: [CrisisResource.legalHotline]
            )

        case .financial:
            return SafeResponse(
                message: """
                お金に関するご質問ですね。

                投資や財務に関する具体的なアドバイスを提供することはできません。\
                ファイナンシャルプランナーや金融の専門家にご相談されることを\
                お勧めします。

                金運や仕事運の導きでしたら、お気軽にお尋ねください。
                """,
                action: .dismissWithOption,
                resources: []
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
