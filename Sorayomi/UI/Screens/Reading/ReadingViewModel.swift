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
            return "追加で聞きたいことを入力..."
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

    private var hearingResponses: [String] = []

    private let minimumInterviewResponses = 2
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

    func startReading(system: FortuneSystem, env: AppEnvironment) async {
        guard !isGenerating else { return }

        if system.creditCost > 0 && !env.creditWalletService.canAfford(system.creditCost, isSubscribed: env.storeKitManager.isSubscribed) {
            showPaywall = true
            return
        }

        selectedSystem = system
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

        await sendConversationFollowUp(text: text, system: system)
    }

    var inputPlaceholder: String {
        sessionStage.inputPlaceholder
    }

    private func generateDetailedReading(system: FortuneSystem, env: AppEnvironment) async {
        isGenerating = true

        let profile = env.userProfileService.currentProfile
        let systemPrompt = SystemPromptBuilder.build(system: system, depth: .deep)
        let userPrompt = buildDetailedReadingPrompt(system: system, profile: profile)

        messages.append(.systemMessage(userPrompt))

        do {
            if system.creditCost > 0 {
                try await env.creditWalletService.deductCredits(system.creditCost, isSubscribed: env.storeKitManager.isSubscribed)
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

            env.analyticsService.track(.readingCompleted(
                system: system.rawValue,
                category: selectedCategory.rawValue,
                creditsCost: system.creditCost
            ))
        } catch {
            errorMessage = "鑑定の生成に失敗しました。もう一度お試しください。"
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
        """
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
        let basePrompt = PromptTemplateEngine.buildUserPrompt(
            system: system,
            profile: profile,
            category: selectedCategory,
            depth: .deep,
            userQuestion: hearingResponses.joined(separator: "\n")
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

        if vagueHearingReplies.contains(normalized) {
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
        ありがとうございます。ですが、現時点では「\(system.shortName)で個別に見立てるための材料」がまだ足りません。

        「特になし」のまま断定的な鑑定を出すと、聞いていない事情まで作ってしまうため、ここでは読み切ったふりはしません。
        \(categoryHint)

        一つだけでも具体的な状況やお気持ちが分かれば、その内容を土台に丁寧に読み解きます。
        """
    }

    private func refreshSelectedCategory(with text: String) {
        let inferred = ReadingCategory.infer(from: text)
        guard inferred != .general else { return }
        selectedCategory = inferred
    }
}
