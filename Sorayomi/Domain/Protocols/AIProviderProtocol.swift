import Foundation

// MARK: - AIProviderError

/// AI プロバイダーのエラー型
enum AIProviderError: LocalizedError {
    case networkError(underlying: Error)
    case rateLimitExceeded
    case invalidResponse
    case contentFiltered
    case serviceUnavailable
    case timeout
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークエラーが発生しました。接続を確認してもう一度お試しください。"
        case .rateLimitExceeded:
            return "リクエストが多すぎます。しばらく待ってからもう一度お試しください。"
        case .invalidResponse:
            return "応答の解析に失敗しました。もう一度お試しください。"
        case .contentFiltered:
            return "コンテンツフィルターにより応答がブロックされました。質問を変えてお試しください。"
        case .serviceUnavailable:
            return "サービスが一時的に利用できません。しばらく待ってからもう一度お試しください。"
        case .timeout:
            return "リクエストがタイムアウトしました。もう一度お試しください。"
        case .unknown(let message):
            return "予期しないエラーが発生しました: \(message)"
        }
    }

    /// ユーザーに表示する短いエラーメッセージ
    var userFacingMessage: String {
        switch self {
        case .networkError:
            return "通信エラー"
        case .rateLimitExceeded:
            return "利用制限中"
        case .invalidResponse:
            return "応答エラー"
        case .contentFiltered:
            return "内容制限"
        case .serviceUnavailable:
            return "サービス停止中"
        case .timeout:
            return "タイムアウト"
        case .unknown:
            return "エラー"
        }
    }

    /// リトライ可能かどうか
    var isRetryable: Bool {
        switch self {
        case .networkError, .rateLimitExceeded, .serviceUnavailable, .timeout:
            return true
        case .invalidResponse, .contentFiltered, .unknown:
            return false
        }
    }
}

// MARK: - AIProvider Protocol

/// AI 鑑定生成プロバイダーのプロトコル
/// Defines the interface for AI-powered fortune reading generation.
/// Implementations may use OpenAI, Claude, or other LLM services.
protocol AIProvider {
    /// 鑑定テキストを生成する
    /// - Parameters:
    ///   - systemPrompt: AI の役割・振る舞いを定義するシステムプロンプト
    ///   - userPrompt: ユーザーの質問やコンテキスト
    /// - Returns: 生成された鑑定テキスト
    /// - Throws: `AIProviderError` if generation fails
    func generateReading(systemPrompt: String, userPrompt: String) async throws -> String
}

// MARK: - MockAIProvider

/// テスト・プレビュー用のモックAIプロバイダー
/// Returns pre-defined Japanese fortune readings without making actual API calls.
final class MockAIProvider: AIProvider {

    /// レスポンスの遅延（秒）。リアルなUX体験のシミュレーション用
    var simulatedDelay: TimeInterval = 1.0

    /// 強制的にエラーを発生させるかどうか（テスト用）
    var shouldFail: Bool = false

    /// 強制エラーの種類
    var errorToThrow: AIProviderError = .serviceUnavailable

    /// カスタムレスポンス（設定されている場合、サンプルの代わりに返す）
    var customResponse: String?

    func generateReading(systemPrompt: String, userPrompt: String) async throws -> String {
        // 遅延シミュレーション
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        // エラーシミュレーション
        if shouldFail {
            throw errorToThrow
        }

        // カスタムレスポンスがあればそれを返す
        if let customResponse {
            return customResponse
        }

        // ユーザープロンプトの内容に基づいてサンプル鑑定を返す
        return selectSampleReading(for: userPrompt)
    }

    // MARK: - Sample Readings

    private func selectSampleReading(for prompt: String) -> String {
        if prompt.contains("恋愛") || prompt.contains("恋") || prompt.contains("愛") {
            return sampleLoveReading
        } else if prompt.contains("仕事") || prompt.contains("キャリア") || prompt.contains("転職") {
            return sampleCareerReading
        } else if prompt.contains("健康") || prompt.contains("体調") {
            return sampleHealthReading
        } else if prompt.contains("金運") || prompt.contains("お金") || prompt.contains("財") {
            return sampleWealthReading
        } else if prompt.contains("タロット") || prompt.contains("カード") {
            return sampleTarotReading
        } else {
            return sampleGeneralReading
        }
    }

    private var sampleLoveReading: String {
        """
        今のあなたには、素敵な出会いのエネルギーが流れています。

        星の配置を見ると、金星があなたの恋愛の宮に入っており、\
        魅力が一層輝く時期に差し掛かっています。\
        気になる方がいるなら、自然体で接することが大切です。\
        無理に自分を飾る必要はありません。

        今月の後半には、思いがけないきっかけで関係が深まる暗示があります。\
        日常の中の小さな優しさを大切にしてください。\
        それがあなたの恋を前に進める鍵となるでしょう。

        ラッキーデー: 水曜日と金曜日
        ラッキーカラー: ピンクとラベンダー
        """
    }

    private var sampleCareerReading: String {
        """
        仕事運は上昇傾向にあります。

        今のあなたには、新しい挑戦を受け入れる力が備わっています。\
        木星のエネルギーが仕事の宮に影響を与えており、\
        これまでの努力が実を結ぶ時期が近づいています。

        ただし、焦りは禁物です。一歩ずつ着実に進むことが、\
        大きな成果につながります。周囲との協力関係も大切にしましょう。\
        信頼できる仲間の存在が、あなたのキャリアを後押ししてくれます。

        特に今月は、学びの機会を積極的に取り入れると良いでしょう。\
        新しいスキルや知識が、将来の飛躍の土台となります。

        ラッキーデー: 火曜日と木曜日
        ラッキーカラー: ネイビーとゴールド
        """
    }

    private var sampleHealthReading: String {
        """
        心身のバランスに意識を向けることが大切な時期です。

        星の流れを読むと、あなたのエネルギーレベルは安定していますが、\
        疲れを溜め込みやすい傾向が見られます。\
        十分な睡眠と栄養バランスの良い食事を心がけてください。

        特に今週は、自然の中で過ごす時間を作ると、\
        心身のリフレッシュに効果的です。散歩や軽い運動もおすすめです。

        心の健康も忘れずに。信頼できる人と気持ちを分かち合うことで、\
        ストレスの軽減につながります。

        ラッキーフード: 緑黄色野菜と温かいスープ
        """
    }

    private var sampleWealthReading: String {
        """
        金運は安定期に入っています。

        今は大きな出費よりも、堅実な管理を心がけると良い時期です。\
        土星の影響により、計画的な行動が金運を高めます。

        思いがけない臨時収入の暗示もありますが、\
        衝動的な使い方は控えましょう。将来への備えに回すことで、\
        長期的な豊かさにつながります。

        今月のラッキーナンバー: 3と8
        金運アップのアドバイス: お財布の整理整頓
        """
    }

    private var sampleTarotReading: String {
        """
        カードを引かせていただきました。

        現在の位置に「星」のカードが正位置で現れています。\
        これは希望と癒しのカードです。困難な時期を乗り越え、\
        新しい可能性が開かれていることを示しています。

        過去の位置には「塔」が出ています。\
        最近、予期しない変化や試練があったかもしれません。\
        しかし、それは古い枠組みを壊し、\
        真の成長への道を開くために必要なプロセスでした。

        未来の位置には「太陽」が輝いています。\
        明るい未来が待っています。自信を持って前に進んでください。\
        あなたの内なる光が、道を照らしてくれるでしょう。
        """
    }

    private var sampleGeneralReading: String {
        """
        今のあなたの全体的な運勢をお伝えします。

        総合的に見ると、安定した運気の流れの中にいます。\
        大きな波乱はなく、日々の積み重ねが実を結ぶ時期です。

        人間関係では、周囲からの信頼が高まっています。\
        あなたの誠実さが評価され、良いご縁に恵まれるでしょう。

        心がけていただきたいのは、感謝の気持ちを忘れないこと。\
        小さな幸せに気づく心の余裕が、\
        さらなる幸運を引き寄せる力となります。

        今日のラッキーカラー: ターコイズブルー
        今日のラッキーアイテム: お気に入りのハンカチ
        今日のラッキー方位: 南東
        """
    }
}
