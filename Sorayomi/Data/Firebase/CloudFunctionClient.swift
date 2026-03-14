import Foundation

// MARK: - CloudFunctionError

/// Cloud Function / AI API 呼び出し時のエラー
enum CloudFunctionError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case rateLimited
    case serverError(String)
    case notAvailable
    case apiKeyMissing
    case timeout

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .invalidResponse:
            return "サーバーからの応答が不正です"
        case .rateLimited:
            return "リクエスト上限に達しました。しばらくお待ちください"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .notAvailable:
            return "サービスが一時的に利用できません"
        case .apiKeyMissing:
            return "APIキーが設定されていません"
        case .timeout:
            return "リクエストがタイムアウトしました"
        }
    }
}

// MARK: - CloudFunctionClient

/// Anthropic Claude API を呼び出す AI 鑑定生成クライアント
///
/// APIキーが設定されている場合は Anthropic Messages API を直接呼び出し、
/// 設定されていない場合はモック応答にフォールバックする。
///
/// ⚠️ 本番では Firebase Cloud Functions 経由に移行すること。
/// アプリバイナリへの直接 API キー埋め込みはセキュリティリスクです。
final class CloudFunctionClient: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = CloudFunctionClient()

    // MARK: - Properties

    private let session: URLSession

    /// APIキーが設定されているかどうか
    var isAPIConfigured: Bool {
        !AppConstants.anthropicAPIKey.isEmpty
    }

    // MARK: - Init

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.aiRequestTimeout
        config.timeoutIntervalForResource = AppConstants.aiRequestTimeout + 10
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// AI による鑑定テキストを生成
    /// - Parameters:
    ///   - systemPrompt: システムプロンプト（占い師の設定）
    ///   - userPrompt: ユーザーの質問や文脈情報
    ///   - system: 占いシステムの種類
    ///   - conversationHistory: フォローアップ時の過去メッセージ履歴
    /// - Returns: 生成された鑑定テキスト（日本語）
    func generateReading(
        systemPrompt: String,
        userPrompt: String,
        system: FortuneSystem,
        conversationHistory: [(role: String, content: String)] = []
    ) async throws -> String {
        // APIキーが設定されている場合は実APIを呼び出す
        if isAPIConfigured {
            return try await callAnthropicAPI(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                conversationHistory: conversationHistory
            )
        }

        // APIキー未設定時はモック応答にフォールバック
        let delay = Double.random(in: 2.0...4.0)
        try await Task.sleep(for: .seconds(delay))
        return selectMockReading(
            for: system,
            userPrompt: userPrompt,
            conversationHistory: conversationHistory
        )
    }

    // MARK: - Anthropic API Call

    /// Anthropic Messages API を直接呼び出す
    private func callAnthropicAPI(
        systemPrompt: String,
        userPrompt: String,
        conversationHistory: [(role: String, content: String)]
    ) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw CloudFunctionError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(AppConstants.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        // メッセージ配列を構築
        var messages: [[String: String]] = []

        // 過去の会話履歴がある場合（フォローアップ）
        for entry in conversationHistory {
            messages.append([
                "role": entry.role,
                "content": entry.content
            ])
        }

        // 今回のユーザーメッセージ
        messages.append([
            "role": "user",
            "content": userPrompt
        ])

        let body: [String: Any] = [
            "model": AppConstants.anthropicModel,
            "max_tokens": AppConstants.anthropicMaxTokens,
            "system": systemPrompt,
            "messages": messages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw CloudFunctionError.timeout
        } catch {
            throw CloudFunctionError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudFunctionError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 401:
            throw CloudFunctionError.apiKeyMissing
        case 429:
            throw CloudFunctionError.rateLimited
        case 500...599:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw CloudFunctionError.serverError(errorBody)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CloudFunctionError.serverError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        // レスポンスからテキストを抽出
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw CloudFunctionError.invalidResponse
        }

        return text
    }

    // MARK: - Mock Responses

    /// 占いシステムごとのモック応答を選択
    private func selectMockReading(
        for system: FortuneSystem,
        userPrompt: String,
        conversationHistory: [(role: String, content: String)]
    ) -> String {
        if !conversationHistory.isEmpty {
            return buildMockFollowUpResponse(
                system: system,
                userPrompt: userPrompt,
                conversationHistory: conversationHistory
            )
        }

        return buildStructuredMockReading(system: system, userPrompt: userPrompt)
    }

    private func buildStructuredMockReading(system: FortuneSystem, userPrompt: String) -> String {
        let sections = extractSections(from: userPrompt)
        let category = sections["相談カテゴリ"] ?? "総合運"
        let hearing = sections["ヒアリング内容"] ?? sections["相談内容"] ?? "今の流れを丁寧に見てほしい"

        guard containsMeaningfulHearingDetail(hearing) else {
            return buildInsufficientHearingResponse(system: system, category: category)
        }

        let focus = summarize(hearing)
        let seed = stableSeed(for: system.rawValue + userPrompt)
        let overallScore = 3 + (seed % 3)
        let loveScore = adjustedScore(base: overallScore, favored: category.contains("恋愛"))
        let workScore = adjustedScore(base: overallScore, favored: category.contains("仕事"))
        let moneyScore = adjustedScore(base: overallScore, favored: category.contains("金"))

        let luckyItems = ["白いハンカチ", "和紙のメモ", "小さな鏡", "温かい緑茶", "真鍮のアクセサリー", "革の手帳"]
        let luckyColors = ["藍色", "朱色", "生成り", "山吹色", "若草色", "桜色"]

        let item = luckyItems[seed % luckyItems.count]
        let color = luckyColors[(seed / 3) % luckyColors.count]

        return """
        【見立て】
        お話をうかがうと、\(focus)という点が、今回のご相談の中心にあるようです。\(system.shortName)の流れでは、結果を急ぐよりも、まず今の状況の意味を丁寧に読み解くことが大切だと出ています。

        【総合運】\(stars(overallScore))
        今は流れそのものが弱いというより、心の置きどころで見え方が大きく変わりやすい時期です。\(systemNarrative(for: system))を踏まえると、無理に答えをひとつに絞るより、あなたが本当に守りたい軸を確認するほど運が整っていきます。焦りよりも整理が開運につながる流れです。

        【恋愛運】\(stars(loveScore))
        恋愛や人間関係では、相手の反応を読むこと以上に、あなた自身が何を望んでいるかを明確にすることが鍵です。関係を進めるにしても距離を測るにしても、曖昧さを少しずつ言葉にすると流れが変わりやすくなります。いまは感情を抑え込むより、温度を整えて伝える姿勢が吉です。

        【仕事運】\(stars(workScore))
        仕事面では、いきなり大きく動くよりも、現状の役割や優先順位を見直すことが実力を生かす近道になります。もし迷いが続いているなら、それは直感が鈍っているのではなく、判断材料を整理すべき時期に入っているサインです。今週は一人で抱え込まず、必要な確認を増やすほど流れが安定します。

        【金運】\(stars(moneyScore))
        金運は派手な追い風というより、使い方を整えることで底力がついてくる流れです。将来の不安があるときほど、大きな結論よりも「何に安心を感じるか」を言語化すると金運が安定します。見栄のための出費を控え、納得感のある使い方を選ぶことが開運の鍵です。

        【転機】
        流れが変わりやすいのは、あなたが受け身のまま様子を見るのをやめ、「私はこうしたい」と小さくても意思表示したときです。今の時期は、出来事そのものよりも、向き合い方を変えることで景色が動きやすくなっています。

        【開運の鍵】
        1. いま抱えている不安を一つだけ紙に書き出し、事実と気持ちを分けてみてください。
        2. すぐに答えを出すより、次の一手を一つだけ決めることを優先してください。
        3. 今日の会話や判断では、背伸びした言葉より本音に近い表現を選んでください。

        【ラッキーアイテム】
        \(item)

        【ラッキーカラー】
        \(color)

        【メッセージ】
        今回のご相談は、運そのものより「どう受け止め、どう選ぶか」で結果が変わりやすい流れでした。この鑑定はエンターテインメントとして受け取りつつ、最後はあなた自身がしっくりくる選択を大切にしてみてください。
        """
    }

    private func buildMockFollowUpResponse(
        system: FortuneSystem,
        userPrompt: String,
        conversationHistory: [(role: String, content: String)]
    ) -> String {
        guard containsMeaningfulHearingDetail(userPrompt) else {
            return """
            追加のお話としては、まだ新しい材料が少ないようです。聞いていない背景を補ってしまわないため、ここでは無理に解釈を広げません。

            もし深掘りするなら、「いちばん気になる相手や場面」「最近あった具体的な出来事」「どうなれば理想か」のどれか一つだけでも教えてください。
            """
        }

        let lastTheme = summarize(userPrompt)

        return """
        追加でうかがった内容を踏まえると、先ほどの見立ての中でも「\(lastTheme)」の部分が特に重要だと感じます。\(system.shortName)の流れでは、今は結論を急ぐよりも、あなたが何に納得したいのかを一段深く確かめるほど判断がぶれにくくなります。

        もし次の一歩を選ぶなら、今日すぐに白黒をつけるより、「確認すべきことを一つ増やす」「本音を一度だけ丁寧に伝える」など、動きやすい単位に分けるのがおすすめです。大切な決断は占いだけで決めず、現実の状況や信頼できる相手の意見とも合わせて見ていってください。
        """
    }

    private func extractSections(from text: String) -> [String: String] {
        let pattern = /【(.+?)】(.*?)(?=【|$)/
        var sections: [String: String] = [:]

        for match in text.matches(of: pattern) {
            let title = String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines)
            let content = String(match.output.2).trimmingCharacters(in: .whitespacesAndNewlines)
            sections[title] = content
        }

        return sections
    }

    private func containsMeaningfulHearingDetail(_ text: String) -> Bool {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: "、", with: "")
            .replacingOccurrences(of: "！", with: "")
            .replacingOccurrences(of: "？", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            return false
        }

        let vagueReplies: Set<String> = [
            "なし",
            "ない",
            "ないです",
            "なしです",
            "ありません",
            "特になし",
            "特にない",
            "特にないです",
            "特にありません",
            "とくになし",
            "とくにない",
            "わからない",
            "分からない",
            "よくわからない",
            "まだわからない",
            "思いつかない",
            "特に思いつかない",
            "普通",
            "ふつう",
            "任せます",
            "お任せします",
            "おまかせ",
            "何でも",
            "なんでも",
            "秘密"
        ]

        return !vagueReplies.contains(normalized)
    }

    private func buildInsufficientHearingResponse(system: FortuneSystem, category: String) -> String {
        let categoryHint: String
        if category.contains("恋愛") {
            categoryHint = "恋愛なら、相手がいるかどうか、距離を縮めたいのか、迷っている点は何かのうち一つだけでも十分です。"
        } else if category.contains("仕事") {
            categoryHint = "仕事なら、転職・評価・人間関係のどこが気になるかを一つだけでも教えてください。"
        } else if category.contains("金") {
            categoryHint = "金運なら、出費・収入・将来不安のどれが中心かを一つだけでも教えてください。"
        } else {
            categoryHint = "恋愛・仕事・人間関係など、どのテーマを中心に見てほしいかだけでも大丈夫です。"
        }

        return """
        まだ個別の鑑定に必要なヒアリング材料が足りないため、ここで具体的な事情を読み切ったふりはしません。

        \(categoryHint)
        一つでも具体的なお話があれば、その内容を土台にして見立てを深めます。
        """
    }

    private func summarize(_ text: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "・", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            return "今の状況を丁寧に整理したいお気持ち"
        }

        let clipped = String(normalized.prefix(52))
        return clipped.hasSuffix("。") ? clipped : clipped + "…"
    }

    private func stableSeed(for text: String) -> Int {
        text.unicodeScalars.reduce(0) { partial, scalar in
            partial + Int(scalar.value)
        }
    }

    private func adjustedScore(base: Int, favored: Bool) -> Int {
        let value = favored ? min(base + 1, 5) : max(base - 1, 2)
        return min(max(value, 1), 5)
    }

    private func stars(_ score: Int) -> String {
        let clamped = min(max(score, 1), 5)
        return String(repeating: "★", count: clamped) + String(repeating: "☆", count: 5 - clamped)
    }

    private func systemNarrative(for system: FortuneSystem) -> String {
        switch system {
        case .omikuji:
            return "おみくじでは、今の運は偶然の吉凶よりも心構えで開きやすい"
        case .horoscope:
            return "星の配置では、内面の整理が行動の質に直結しやすい"
        case .bloodType:
            return "血液型の気質傾向では、あなた本来のリズムを取り戻すほど力が出やすい"
        case .birthdayPersonality:
            return "誕生日が示す資質では、生まれ持った強みを使う場面が近づいている"
        case .rokuyo:
            return "六曜の流れでは、タイミングを整えることで手応えが変わりやすい"
        case .tarot:
            return "カードの象徴では、迷いの裏にある本心を見抜くことが重要"
        case .numerology:
            return "数秘術では、今は流れの転換点を静かに見極める時期"
        case .nineStarKi:
            return "九星気学では、気の向きを整えることで選択の精度が上がりやすい"
        }
    }

    // MARK: - Mock Response Data

    private static let horoscopeResponses: [String] = [
        """
        今、あなたの星座には金星の優しい光が注がれています。\
        これは人間関係に温かさと調和をもたらす配置です。\
        特に今週は、周囲の人との絆が深まる出来事がありそうです。\
        自分の気持ちに素直になることで、良い流れが生まれるでしょう。\
        \n\n大切なのは、完璧を求めすぎないこと。\
        あなたの自然な優しさが、最大の魅力です。\
        心を開いて、今の流れに身を委ねてみてください。
        """,
        """
        月の満ち欠けがあなたに内省の時間を促しています。\
        最近少し疲れを感じていませんか？\
        星の配置は、自分自身を労わることの大切さを伝えています。\
        \n\n今は無理をせず、好きなことに時間を使ってみてください。\
        心が満たされると、自然と良いアイデアや出会いが訪れます。\
        来週以降、再びエネルギーが高まる時期が巡ってきます。
        """
    ]

    private static let omikujiResponses: [String] = [
        """
        【総合運】★★★★☆
        本日のおみくじは「吉」です。今日は大きく動くよりも、心を整えながら一歩ずつ進むほど良い流れに乗れそうです。

        【恋愛運】★★★★☆
        会話の温度を少しだけ柔らかくすると、相手との距離が自然に縮まりやすい日です。

        【仕事運】★★★☆☆
        まずは足元のタスクを丁寧に整えることで、次のチャンスを受け取りやすくなります。

        【金運】★★★☆☆
        今日は増やすことより、使い道を整える意識が金運を支えてくれます。

        【ラッキーアイテム】
        白いハンカチ

        【ラッキーカラー】
        朱色

        【メッセージ】
        神社で一枚引いたおみくじのように、今日の言葉を軽やかな指針として受け取ってみてください。
        """,
        """
        【総合運】★★★☆☆
        本日のおみくじは「小吉」です。目立つ追い風よりも、小さな整え直しが運を育てる一日になりそうです。

        【恋愛運】★★★☆☆
        駆け引きよりも、思いやりのある一言が関係をやわらかくしてくれます。

        【仕事運】★★★★☆
        焦らず段取りを見直すことで、午後から流れがすっと軽くなりそうです。

        【金運】★★★☆☆
        必要なものと心地よいものの線引きを意識すると、安心感のある使い方ができます。

        【ラッキーアイテム】
        和紙のメモ

        【ラッキーカラー】
        生成り

        【メッセージ】
        福は大きな出来事だけでなく、今日の身のこなしの中にも静かに宿っています。
        """
    ]

    private static let bloodTypeResponses: [String] = [
        """
        あなたの血液型が持つ繊細さと誠実さは、今とても良い方向に働いています。\
        周囲の人があなたの気配りに感謝していることに、気づいていますか？\
        \n\n今日は自分の直感を信じて行動してみてください。\
        あなたの持つ温かさが、周りの人を笑顔にします。
        """,
        """
        血液型の特性として、あなたには自由な発想力があります。\
        今の時期は、その独創性が特に輝く時です。\
        \n\n「自分らしさ」を大切にしながら、\
        新しいことにチャレンジしてみると良い結果が生まれそうです。
        """
    ]

    private static let birthdayResponses: [String] = [
        """
        あなたが生まれた日には、特別なエネルギーが宿っています。\
        その日の星の配置は、創造力と直感力を授けてくれました。\
        \n\n今、その生まれ持った才能が花開く時期を迎えています。\
        日々の中で感じるインスピレーションを大切にしてください。
        """,
        """
        誕生日の数字が示すのは、あなたの中に眠る強さです。\
        普段は穏やかに見えるあなたですが、\
        いざという時に発揮する芯の強さは、周囲を驚かせるほど。\
        \n\n今は、その内なる力を信じて前に進む時です。
        """
    ]

    private static let tarotResponses: [String] = [
        """
        カードが伝えているのは「変化の中にある希望」です。\
        今、あなたの周りで起きている変化に戸惑いを感じるかもしれませんが、\
        それは新しいステージへの扉が開いている証です。\
        \n\n過去に執着せず、流れに身を委ねることで、\
        思いもよらない良い展開が待っています。
        """,
        """
        カードが示しているのは「豊かさと実り」のエネルギーです。\
        これまであなたが積み重ねてきた努力が、\
        形となって現れ始める時期が近づいています。\
        \n\n特に対人関係において、嬉しい進展がありそうです。
        """
    ]

    private static let numerologyResponses: [String] = [
        """
        あなたの数字が語るのは「調和とバランス」のメッセージです。\
        今、仕事とプライベートのバランスを見直す良い機会が訪れています。\
        \n\n数秘術の観点から、今月は特に「2」のエネルギーが強まる時期。\
        協力と調和を意識することで、物事がスムーズに進みます。
        """,
        """
        あなたのライフパスナンバーは、深い洞察力と直感力を示しています。\
        今この瞬間も、あなたの中の知恵が\
        正しい方向を指し示しているはずです。\
        \n\n数字のメッセージは「自分を信じること」。
        """
    ]

    private static let nineStarKiResponses: [String] = [
        """
        あなたの本命星の気が、今月は好転の兆しを見せています。\
        特に吉方位への移動や行動が、\
        良いエネルギーを引き寄せるきっかけになります。\
        \n\n九星気学では、自然の流れに沿った行動が\
        最も大きな成果をもたらすとされています。
        """,
        """
        九星の巡りから見ると、今は「蓄え」の時期にあたります。\
        目に見える成果が出にくい時期かもしれませんが、\
        内面的な成長は着実に進んでいます。\
        \n\n今蓄えているエネルギーは、次の飛躍期に\
        大きな力となって発揮されます。
        """
    ]

    private static let generalResponses: [String] = [
        """
        今日は穏やかなエネルギーに包まれる一日になりそうです。\
        特に午後からは良い流れが生まれやすいので、\
        大切な予定はできれば午後に回すと良いでしょう。\
        心穏やかに過ごすことが、運気アップの鍵です。
        """
    ]
}
