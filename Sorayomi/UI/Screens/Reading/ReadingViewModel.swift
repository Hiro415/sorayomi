import Foundation

// MARK: - ReadingSessionStage

enum ReadingSessionStage {
    case idle
    case hearing
    case completed

    var inputPlaceholder: String {
        switch self {
        case .idle:
            return "相談内容を入力..."
        case .hearing:
            return "今の状況やお気持ちを、できるだけ具体的に入力してください"
        case .completed:
            return "さらに深掘り（1クレジット消費）..."
        }
    }

    var statusLabel: String {
        switch self {
        case .idle:
            return "準備中"
        case .hearing:
            return "ヒアリング中"
        case .completed:
            return "対話鑑定"
        }
    }
}

// MARK: - ReadingViewModel

/// Manages hearing-first reading sessions.
@Observable
@MainActor
final class ReadingViewModel {

    var selectedSystem: FortuneSystem?
    var selectedCategory: ReadingCategory = .general
    var messages: [ReadingMessage] = []
    var userInput: String = ""
    var isGenerating = false
    var showPaywall = false
    var showShareSheet = false
    var lastReadingText: String = ""
    var errorMessage: String?
    var sessionStage: ReadingSessionStage = .idle

    // タロット専用
    var drawnTarotCards: [DrawnTarotCard] = []
    var showTarotReveal = false

    // 血液型占い専用
    var selectedBloodTypeMode: BloodTypeMode?
    var partnerBloodType: BloodType?
    var showBloodTypeModePicker = false
    var showBloodTypeReveal = false
    var bloodTypeDailyFortune: BloodTypeDailyFortune?
    var bloodTypeRanking: BloodTypeRanking?
    var bloodTypeCompatibilityData: BloodTypeCompatibilityData?
    var bloodTypeLoveSubScores: BloodTypeLoveSubScores?

    private var hearingResponses: [String] = []

    private let minimumInterviewResponses = 2
    /// ヒアリング入力の最低文字数（句読点・空白除去後）
    private let minimumMeaningfulLength = 6
    private let vagueHearingReplies: Set<String> = [
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

    /// Whether this session is using the one-time free trial.
    private var isUsingFreeTrial = false

    func startReading(system: FortuneSystem, env: AppEnvironment) async {
        guard !isGenerating else { return }

        // Check if free trial applies (first paid consultation ever)
        let trialAvailable = system.creditCost > 0 && env.freeTrialManager.shouldGrantFreeTrial()
        isUsingFreeTrial = trialAvailable

        if system.creditCost > 0 && !trialAvailable && !env.creditWalletService.canAfford(system.creditCost) {
            showPaywall = true
            return
        }

        selectedSystem = system

        // 血液型はモード選択画面を先に表示
        if system == .bloodType {
            showBloodTypeModePicker = true
            selectedBloodTypeMode = nil
            partnerBloodType = nil
            bloodTypeDailyFortune = nil
            bloodTypeRanking = nil
            bloodTypeCompatibilityData = nil
            bloodTypeLoveSubScores = nil
            return
        }

        messages = []
        userInput = ""
        errorMessage = nil
        isGenerating = false
        sessionStage = .hearing
        hearingResponses = []

        env.analyticsService.track(.readingStarted(
            system: system.rawValue,
            category: selectedCategory.rawValue
        ))

        messages.append(.assistantMessage(openingInterviewPrompt(for: system)))
    }

    func sendFollowUp(env: AppEnvironment) async {
        let text = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let system = selectedSystem else { return }

        let classifier = InputClassifier()
        let classification = classifier.classify(text)
        guard classification == .safe else {
            let safeResponse = SafeResponseProvider().response(for: classification)
            messages.append(.userMessage(text))
            messages.append(.assistantMessage(safeResponse.message))
            userInput = ""

            env.analyticsService.track(.readingSafetyBlocked(
                classification: String(describing: classification)
            ))
            return
        }

        messages.append(.userMessage(text))
        userInput = ""
        errorMessage = nil

        if sessionStage == .hearing {
            if !isMeaningfulHearingResponse(text) {
                messages.append(.assistantMessage(insufficientDetailPrompt(for: system)))
                return
            }

            if hearingResponses.isEmpty || selectedCategory == .general {
                refreshSelectedCategory(with: text)
            }

            hearingResponses.append(text)

            if hearingResponses.count < minimumInterviewResponses {
                messages.append(.assistantMessage(followUpInterviewPrompt(for: system)))
                return
            }

            await generateDetailedReading(system: system, env: env)
            return
        }

        // 鑑定完了後の深掘りは追加クレジットが必要
        if sessionStage == .completed {
            let followUpCost = 1
            if !env.creditWalletService.canAfford(followUpCost) && !env.storeKitManager.isSubscribed {
                showPaywall = true
                // 入力を復元
                userInput = text
                messages.removeLast() // ユーザーメッセージを戻す
                return
            }
            if !env.storeKitManager.isSubscribed {
                try? await env.creditWalletService.deductCredits(followUpCost)
            }
        }

        await sendConversationFollowUp(text: text, system: system)
    }

    var inputPlaceholder: String {
        sessionStage.inputPlaceholder
    }

    /// タロットの場合、カードリビール後にこのメソッドを呼ぶ
    func completeTarotReveal(env: AppEnvironment) async {
        guard let system = selectedSystem, system == .tarot else { return }
        showTarotReveal = false
        await generateDetailedReading(system: system, env: env)
    }

    // MARK: - 血液型占いフロー

    func selectBloodTypeMode(_ mode: BloodTypeMode, env: AppEnvironment) {
        selectedBloodTypeMode = mode
        showBloodTypeModePicker = false

        let profile = env.userProfileService.currentProfile
        let userBloodType = profile?.bloodType ?? .a

        if mode == .ranking {
            // ランキングはヒアリング不要 → 即座にReveal
            bloodTypeRanking = BloodTypeCompatibility.dailyRanking()
            bloodTypeDailyFortune = BloodTypeCompatibility.dailyFortune(for: userBloodType)
            showBloodTypeReveal = true
            return
        }

        if mode == .dailyFortune {
            bloodTypeDailyFortune = BloodTypeCompatibility.dailyFortune(for: userBloodType)
        }

        // ヒアリング開始
        messages = []
        userInput = ""
        errorMessage = nil
        isGenerating = false
        sessionStage = .hearing
        hearingResponses = []

        messages.append(.assistantMessage(openingPromptForBloodTypeMode(mode, bloodType: userBloodType)))
    }

    func setPartnerBloodType(_ type: BloodType, env: AppEnvironment) {
        partnerBloodType = type
        let profile = env.userProfileService.currentProfile
        let userBloodType = profile?.bloodType ?? .a

        // 相性データを計算
        bloodTypeCompatibilityData = BloodTypeCompatibility.compatibility(between: userBloodType, and: type)
        bloodTypeLoveSubScores = BloodTypeCompatibility.loveSubScores(between: userBloodType, and: type)

        // ユーザーの選択をチャットに反映
        messages.append(.userMessage("\(type.japaneseName)"))

        // フォローアップ質問
        let followUp: String
        if selectedBloodTypeMode == .loveMatch {
            followUp = "\(userBloodType.japaneseName)と\(type.japaneseName)の恋の相性を見てまいります。お相手との今の関係や、どんな未来を望んでいるかを聞かせてください。"
        } else {
            followUp = "\(userBloodType.japaneseName)と\(type.japaneseName)の相性ですね。お二人の関係や、いま気になっていることを教えてください。"
        }
        messages.append(.assistantMessage(followUp))
    }

    func completeBloodTypeReveal(env: AppEnvironment) async {
        guard let system = selectedSystem, system == .bloodType else { return }
        showBloodTypeReveal = false
        await generateDetailedReading(system: system, env: env)
    }

    private func openingPromptForBloodTypeMode(_ mode: BloodTypeMode, bloodType: BloodType) -> String {
        switch mode {
        case .dailyFortune:
            return """
            \(bloodType.japaneseName)のあなたの今日を見立てます。

            今いちばん気になっていること、あるいは今日の予定を聞かせてください。お話を土台にして、今日の過ごし方を丁寧に読み解いていきます。
            """
        case .compatibility:
            return "相手の方の血液型を教えてください。"
        case .loveMatch:
            return "恋のお相手の血液型を教えてください。"
        case .ranking:
            return "" // rankingはヒアリングなし
        }
    }

    private func generateDetailedReading(system: FortuneSystem, env: AppEnvironment) async {
        // タロットの場合：先にカードをドローしてリビール画面を表示
        if system == .tarot && drawnTarotCards.isEmpty {
            let cardCount = hearingResponses.count >= 3 ? 5 : 3
            drawnTarotCards = TarotDrawEngine.draw(count: cardCount)
            showTarotReveal = true
            // リビール完了後に completeTarotReveal → 再度この関数が呼ばれる
            return
        }

        // 血液型の場合：RevealViewを表示（ランキング以外）
        if system == .bloodType, let mode = selectedBloodTypeMode, !showBloodTypeReveal {
            let profile = env.userProfileService.currentProfile
            let userBloodType = profile?.bloodType ?? .a

            switch mode {
            case .dailyFortune:
                if bloodTypeDailyFortune == nil {
                    bloodTypeDailyFortune = BloodTypeCompatibility.dailyFortune(for: userBloodType)
                }
                showBloodTypeReveal = true
                return
            case .compatibility, .loveMatch:
                if let partner = partnerBloodType {
                    if bloodTypeCompatibilityData == nil {
                        bloodTypeCompatibilityData = BloodTypeCompatibility.compatibility(between: userBloodType, and: partner)
                    }
                    if bloodTypeLoveSubScores == nil {
                        bloodTypeLoveSubScores = BloodTypeCompatibility.loveSubScores(between: userBloodType, and: partner)
                    }
                }
                showBloodTypeReveal = true
                return
            case .ranking:
                // ランキングは selectBloodTypeMode() で既にReveal済み → そのまま進行
                break
            }
        }

        isGenerating = true

        let profile = env.userProfileService.currentProfile
        let systemPrompt = SystemPromptBuilder.build(system: system, depth: .deep)
        let userPrompt = buildDetailedReadingPrompt(system: system, profile: profile)

        messages.append(.systemMessage(userPrompt))

        do {
            if system.creditCost > 0 && !isUsingFreeTrial {
                try await env.creditWalletService.deductCredits(system.creditCost)
            }

            let startTime = Date()

            let response = try await CloudFunctionClient.shared.generateReading(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                system: system
            )

            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = AppConstants.minimumLoadingDuration - elapsed
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }

            messages.append(.assistantMessage(response, presentation: .readingResult))
            lastReadingText = response
            sessionStage = .completed

            // Consume the free trial after successful reading generation
            let wasFreeTrialUsed = isUsingFreeTrial
            if isUsingFreeTrial {
                env.freeTrialManager.consumeFreeTrial()
                isUsingFreeTrial = false
            }

            // 鑑定結果を履歴に保存
            saveReadingToHistory(system: system, wasFree: wasFreeTrialUsed, env: env)

            env.analyticsService.track(.readingCompleted(
                system: system.rawValue,
                category: selectedCategory.rawValue,
                creditsCost: wasFreeTrialUsed ? 0 : system.creditCost
            ))
        } catch {
            #if DEBUG
            errorMessage = "鑑定エラー: \(error.localizedDescription)"
            print("[ReadingViewModel] generateDetailedReading error: \(error)")
            #else
            errorMessage = "鑑定の生成に失敗しました。もう一度お試しください。"
            #endif
            env.analyticsService.track(.readingError(
                system: system.rawValue,
                errorDescription: error.localizedDescription
            ))
        }

        isGenerating = false
    }

    private func sendConversationFollowUp(text: String, system: FortuneSystem) async {
        isGenerating = true

        let systemPrompt = SystemPromptBuilder.build(system: system, depth: .deep)
        let conversationHistory = messages
            .filter { $0.role != .system }
            .dropLast()
            .map { (role: $0.role.rawValue, content: $0.content) }

        do {
            let startTime = Date()

            let response = try await CloudFunctionClient.shared.generateReading(
                systemPrompt: systemPrompt,
                userPrompt: text,
                system: system,
                conversationHistory: conversationHistory
            )

            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = 2.0 - elapsed
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }

            messages.append(.assistantMessage(response))
        } catch {
            errorMessage = "応答の生成に失敗しました。"
        }

        isGenerating = false
    }

    private func openingInterviewPrompt(for system: FortuneSystem) -> String {
        if system == .generalConsultation {
            return """
            こんにちは。占い師の「導き手」です。

            今日はどんなことが気になっていますか？恋愛、仕事、人間関係、将来のこと…テーマを決めていなくても大丈夫です。

            まずはそのまま、気になっていることを自由に話してみてください。お話をうかがいながら、一番合う見方で丁寧に読み解いていきます。
            """
        }

        return """
        こんにちは。\(system.japaneseName)で丁寧に見立てるため、まずは気になっていることをそのまま聞かせてください。

        恋愛か仕事かを最初に言い切れなくても大丈夫です。お話をうかがいながら、相談の軸も一緒に整理していきます。

        ・今いちばん気になっていること
        ・最近の状況や関係性
        ・本当はどうなっていきたいか

        この3点を、分かる範囲で具体的に教えてください。結果を先に断定するのではなく、あなたのお話を土台にして読み解いていきます。
        """
    }

    private func followUpInterviewPrompt(for system: FortuneSystem) -> String {
        let categoryPrompt: String
        switch selectedCategory {
        case .love:
            categoryPrompt = "お相手との現在の距離感や、最近あった出来事、あなたが迷っている点をもう少し詳しく教えてください。"
        case .career:
            categoryPrompt = "仕事や転機のどの場面で迷っているのか、いま置かれている状況と理想の方向を詳しく聞かせてください。"
        case .wealth:
            categoryPrompt = "金運について、出費・収入・将来の不安のうち何がいちばん気になっているかを教えてください。"
        case .relationships:
            categoryPrompt = "どなたとの関係で悩んでいるのか、その相手との距離感や最近のやり取りを具体的に教えてください。"
        case .daily:
            categoryPrompt = "今日または今週の流れの中で、特に気になっている予定や出来事があれば教えてください。"
        case .health:
            categoryPrompt = "体調そのものの判断はできませんが、生活リズムや気持ちの揺れなど、占いとして見てほしい文脈を教えてください。"
        case .general:
            categoryPrompt = "恋愛か仕事かをまだ決めなくても大丈夫です。最近引っかかっている出来事や、いちばん整理したい気持ちをもう少し詳しく教えてください。"
        }

        return """
        ありがとうございます。\(system.shortName)の読みを深めるため、もう一段だけ具体的にうかがいます。

        \(categoryPrompt)
        """
    }

    private func buildDetailedReadingPrompt(system: FortuneSystem, profile: UserProfile?) -> String {
        // タロットの場合：TarotRevealViewで表示済みのカードをそのまま渡す
        // これにより TarotPrompt.build() が新たにカードをドローせず、
        // ユーザーに表示されたカードと同一のカードでAI鑑定を行う
        let preDrawnCards: [DrawnTarotCard]? = (system == .tarot && !drawnTarotCards.isEmpty)
            ? drawnTarotCards
            : nil

        let basePrompt = PromptTemplateEngine.buildUserPrompt(
            system: system,
            profile: profile,
            category: selectedCategory,
            depth: .deep,
            userQuestion: hearingResponses.joined(separator: "\n"),
            preDrawnTarotCards: preDrawnCards
        )

        let hearingBlock = hearingResponses.enumerated()
            .map { index, response in
                "・ヒアリング\(index + 1): \(response)"
            }
            .joined(separator: "\n")

        return """
        \(basePrompt)

        【ヒアリング内容】
        \(hearingBlock)

        【鑑定方針】
        ・必ず最初に、相談内容をどう受け止めたかを簡潔に言語化してください。
        ・話されていない前提を勝手に作りすぎず、ヒアリング内容に根ざした解釈を行ってください。
        ・ヒアリングで明示されていない人物像、出来事、感情を作り足さないでください。
        ・プロの占い師が対面で見立てるように、背景、転機、行動の優先順位まで丁寧に示してください。
        ・一方的に言い切るのではなく、「今の流れ」と「選び方」を中心に導いてください。
        """
    }

    private func isMeaningfulHearingResponse(_ text: String) -> Bool {
        let normalized = normalizeHearingText(text)

        guard !normalized.isEmpty else {
            return false
        }

        // 曖昧な定型回答を排除
        if vagueHearingReplies.contains(normalized) {
            return false
        }

        // 短すぎる入力を排除（句読点除去後6文字未満）
        if normalized.count < minimumMeaningfulLength {
            return false
        }

        return true
    }

    private func normalizeHearingText(_ text: String) -> String {
        text
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
    }

    private func insufficientDetailPrompt(for system: FortuneSystem) -> String {
        let categoryHint: String
        switch selectedCategory {
        case .love:
            categoryHint = "たとえば「気になる相手がいる」「連絡頻度に迷っている」「復縁を考えている」など、恋愛のどの場面を見てほしいかを一つだけでも教えてください。"
        case .career:
            categoryHint = "たとえば「転職を迷っている」「人間関係が重い」「評価が気になる」など、仕事のどの場面かを一つだけでも教えてください。"
        case .wealth:
            categoryHint = "たとえば「出費が増えて不安」「収入を上げたい」「貯金の流れを整えたい」など、お金の悩みの芯を一つだけでも教えてください。"
        case .relationships:
            categoryHint = "たとえば「家族との距離感」「友人とのすれ違い」「職場の相手との関係」など、誰との関係かを一つだけでも教えてください。"
        case .daily:
            categoryHint = "たとえば「今日会う相手のこと」「今週の大事な予定」「気持ちの波」など、直近で気になっていることを一つだけでも教えてください。"
        case .health:
            categoryHint = "医療判断はできませんが、「生活リズムが乱れている」「気持ちが落ち着かない」など、占いとして見てほしい文脈を一つだけでも教えてください。"
        case .general:
            categoryHint = "たとえば「最近ずっと引っかかっていることがある」「相手の気持ちが気になる」「今の仕事を続けるべきか迷う」など、テーマが曖昧なままでも一つだけ状況を教えてください。"
        }

        return """
        ありがとうございます。\(system.shortName)であなただけの鑑定をお届けするために、もう少しだけ具体的なお話を聞かせてください。

        \(categoryHint)

        一つだけでも状況が分かれば、そこから丁寧に読み解いていきます。
        """
    }

    private func refreshSelectedCategory(with text: String) {
        let inferred = ReadingCategory.infer(from: text)
        guard inferred != .general else { return }
        selectedCategory = inferred
    }

    // MARK: - History Save

    private func saveReadingToHistory(system: FortuneSystem, wasFree: Bool, env: AppEnvironment) {
        let userId = FirebaseAuthService.shared.currentUserId ?? "anonymous"
        let reading = FortuneReading(
            id: UUID().uuidString,
            userId: userId,
            system: system,
            theme: selectedCategory,
            messages: messages,
            creditsCost: wasFree ? 0 : system.creditCost,
            createdAt: Date()
        )
        env.readingHistoryService.saveReading(reading)
    }
}
