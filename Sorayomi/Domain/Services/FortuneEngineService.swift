import Foundation

// MARK: - FortuneEngineError

/// 占いエンジンサービスのエラー
enum FortuneEngineError: Error, LocalizedError {
    case missingBirthday
    case missingBloodType
    case aiGenerationFailed(Error)
    case safetyBlocked(InputClassifier.Classification)
    case profileIncomplete(String)

    var errorDescription: String? {
        switch self {
        case .missingBirthday:
            return "誕生日が設定されていません。設定画面から登録してください。"
        case .missingBloodType:
            return "血液型が設定されていません。設定画面から登録してください。"
        case .aiGenerationFailed(let error):
            return "鑑定の生成に失敗しました: \(error.localizedDescription)"
        case .safetyBlocked:
            return "この内容については、専門家にご相談されることをお勧めします。"
        case .profileIncomplete(let field):
            return "\(field)が必要です。プロフィールを完成させてください。"
        }
    }
}

// MARK: - FortuneEngineService

/// 占い鑑定の中核オーケストレーター
/// ローカル計算エンジン → プロンプト構築 → AI生成（CloudFunctionClient）→
/// FortuneReading 組み立てのパイプラインを管理する。
@Observable
@MainActor
final class FortuneEngineService {

    // MARK: - Properties

    /// 生成中かどうか
    private(set) var isGenerating: Bool = false

    // MARK: - Dependencies

    private let cloudClient: CloudFunctionClient
    private let inputClassifier: InputClassifier

    // MARK: - Init

    init(
        cloudClient: CloudFunctionClient = .shared,
        inputClassifier: InputClassifier = InputClassifier()
    ) {
        self.cloudClient = cloudClient
        self.inputClassifier = inputClassifier
    }

    // MARK: - Main Generation Method

    /// 占い鑑定を生成する
    /// - Parameters:
    ///   - system: 使用する占いシステム
    ///   - userQuestion: ユーザーからの質問（任意）
    ///   - profile: ユーザープロフィール
    /// - Returns: 生成された FortuneReading
    func generateReading(
        system: FortuneSystem,
        userQuestion: String? = nil,
        profile: UserProfile
    ) async throws -> FortuneReading {
        isGenerating = true
        defer { isGenerating = false }

        // Step 1: 安全性チェック（ユーザー質問がある場合）
        if let question = userQuestion, !question.isEmpty {
            let classification = inputClassifier.classify(question)
            switch classification {
            case .safe:
                break // 安全 - 続行
            case .crisis, .medical, .legal, .financial, .inappropriate:
                throw FortuneEngineError.safetyBlocked(classification)
            }
        }

        // Step 2: 必要な入力の検証
        try validateRequiredInputs(system: system, profile: profile)

        let category = determineCategory(from: userQuestion)

        // Step 3: ローカル計算を実行
        let localContext = buildLocalContext(system: system, profile: profile)

        // Step 4: ローカルで完結する占術
        if !system.requiresAIGeneration {
            return buildLocalReading(system: system, category: category, profile: profile)
        }

        // Step 5: AI鑑定を生成
        do {
            let depth: ReadingDepth = userQuestion != nil ? .standard : .snapshot

            // システムプロンプトを構築
            let systemPrompt = SystemPromptBuilder.build(system: system, depth: depth)

            // ユーザープロンプト（コンテキスト + 質問）を構築
            let promptContext = BasePromptContext.build(
                date: Date(),
                userQuestion: userQuestion,
                category: category,
                depth: depth
            )
            let userPrompt = buildUserPrompt(
                context: promptContext,
                localContext: localContext,
                profile: profile,
                system: system
            )

            // Cloud Function 呼び出し
            let aiResponse = try await cloudClient.generateReading(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                system: system
            )

            // FortuneReading を組み立て
            return buildFortuneReading(
                system: system,
                category: category,
                profile: profile,
                userQuestion: userQuestion,
                aiResponse: aiResponse
            )
        } catch let error as FortuneEngineError {
            throw error
        } catch {
            throw FortuneEngineError.aiGenerationFailed(error)
        }
    }

    // MARK: - Input Validation

    /// 必要な入力が揃っているか検証
    private func validateRequiredInputs(system: FortuneSystem, profile: UserProfile) throws {
        for input in system.requiredInputs {
            switch input {
            case .birthday:
                guard profile.birthday != nil else {
                    throw FortuneEngineError.missingBirthday
                }
            case .bloodType:
                guard profile.bloodType != nil else {
                    throw FortuneEngineError.missingBloodType
                }
            case .question:
                break // 質問は任意
            }
        }
    }

    // MARK: - Local Context Building

    /// ローカル計算エンジンの結果を文字列コンテキストとして構築
    private func buildLocalContext(system: FortuneSystem, profile: UserProfile) -> String {
        var contextParts: [String] = []
        let today = Date()

        switch system {
        case .omikuji:
            let omikuji = OmikujiCalculator.draw(
                for: today,
                birthday: profile.birthday,
                bloodType: profile.bloodType
            )
            contextParts.append("【おみくじ】\(omikuji.rank.japaneseName)")
            contextParts.append("御言葉: \(omikuji.poem)")
            contextParts.append("指針: \(omikuji.guidance)")
            contextParts.append("吉方: \(omikuji.luckyDirection)")
            contextParts.append("吉時間: \(omikuji.luckyTime)")

        case .horoscope:
            if let birthday = profile.birthday {
                let sign = ZodiacCalculator.calculate(from: birthday)
                contextParts.append("【星座情報】\(sign.japaneseName)")
            }

        case .bloodType:
            if let bloodType = profile.bloodType {
                let traits = BloodTypeCalculator.traits(for: bloodType)
                contextParts.append("【血液型情報】\(bloodType.japaneseName)")
                contextParts.append("性格: \(traits.personality)")
                contextParts.append("強み: \(traits.strengths)")
            }

        case .birthdayPersonality:
            if let birthday = profile.birthday {
                let birthdayProfile = BirthdayPersonalityCalculator.profile(from: birthday)
                contextParts.append("【誕生日性格】\(birthdayProfile.personality)")
                contextParts.append("強み: \(birthdayProfile.strength)")
                contextParts.append("ラッキーカラー: \(birthdayProfile.luckyColor)")
            }

        case .rokuyo:
            let rokuyo = RokuyoCalculator.calculate(from: today)
            contextParts.append("【六曜】\(rokuyo.japaneseName)")
            contextParts.append("指針: \(rokuyo.briefGuidance)")

        case .tarot:
            let drawnCards = TarotDrawEngine.draw(count: 3)
            contextParts.append("【タロットカード】")
            for card in drawnCards {
                contextParts.append("\(card.position.japaneseName): \(card.displayName)")
            }

        case .numerology:
            if let birthday = profile.birthday {
                let dayNumber = NumerologyCalculator.personalDayNumber(from: birthday, on: today)
                let lifePathNumber = NumerologyCalculator.lifePathNumber(from: birthday)
                contextParts.append("【数秘術】")
                contextParts.append("ライフパスナンバー: \(lifePathNumber)")
                contextParts.append("パーソナルデイナンバー: \(dayNumber)")
            }

        case .nineStarKi:
            if let birthday = profile.birthday {
                let nineStarProfile = NineStarKiCalculator.calculate(from: birthday)
                let dailyStar = NineStarKiCalculator.dailyStar(for: today)
                contextParts.append("【九星気学】")
                contextParts.append("本命星: \(nineStarProfile.honmeisei.japaneseName)")
                contextParts.append("月命星: \(nineStarProfile.getsumeisei.japaneseName)")
                contextParts.append("本日の星: \(dailyStar.japaneseName)")
            }
        }

        return contextParts.joined(separator: "\n")
    }

    // MARK: - User Prompt Building

    /// AI に送るユーザープロンプトを構築
    private func buildUserPrompt(
        context: BasePromptContext,
        localContext: String,
        profile: UserProfile,
        system: FortuneSystem
    ) -> String {
        var parts: [String] = []

        // 日付・暦のコンテキスト
        parts.append(context.buildContextBlock())

        // ローカル計算結果
        if !localContext.isEmpty {
            parts.append("")
            parts.append(localContext)
        }

        // プロフィール情報
        parts.append("")
        parts.append("【相談者情報】")
        if let nickname = profile.nickname {
            parts.append("・お名前: \(nickname)さん")
        }
        if let sign = profile.zodiacSign {
            parts.append("・星座: \(sign.japaneseName)")
        }
        if let bloodType = profile.bloodType {
            parts.append("・血液型: \(bloodType.japaneseName)")
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Rokuyo Local Reading

    /// 六曜は AI 不要のローカル鑑定
    private func buildLocalReading(
        system: FortuneSystem,
        category: ReadingCategory,
        profile: UserProfile
    ) -> FortuneReading {
        let readingText: String

        switch system {
        case .rokuyo:
            let rokuyo = RokuyoCalculator.calculate(from: Date())
            let stars = scoreString(rokuyo.auspiciousnessScore)
            let loveLine = rokuyo.isAuspicious
                ? "言葉を急がずとも、自然な笑顔が相手に安心感を届けやすい日です。"
                : "思いを押し通すより、ひと呼吸おいて気持ちを整えるほど関係が穏やかになります。"
            let workLine = rokuyo.isAuspicious
                ? "大事な確認や提案は\(rokuyo.luckyTimeOfDay)を意識すると進めやすくなりそうです。"
                : "今日は仕上げよりも段取りの見直しが吉。焦らず順序を整えるほど成果が安定します。"
            let moneyLine = rokuyo.isAuspicious
                ? "勢いのある日でも、使う理由をひとつ言葉にすると金運が整います。"
                : "衝動買いを避け、必要な出費を丁寧に見極める姿勢が安心につながります。"

            readingText = """
            【総合運】\(stars)
            今日の六曜は「\(rokuyo.japaneseName)」です。\(rokuyo.briefGuidance)

            【恋愛運】\(stars)
            \(loveLine)

            【仕事運】\(stars)
            \(workLine)

            【金運】\(stars)
            \(moneyLine)

            【ラッキーアイテム】
            和紙のメモ

            【ラッキーカラー】
            藍色

            【メッセージ】
            暦の流れはあくまで今日の目印です。\(category.japaneseName)に意識を向けながら、ご自身の感覚も大切に一日を整えてみてください。
            """

        case .omikuji:
            let omikuji = OmikujiCalculator.draw(
                for: Date(),
                birthday: profile.birthday,
                bloodType: profile.bloodType
            )
            let stars = scoreString(omikuji.rank.starScore)

            readingText = """
            【総合運】\(stars)
            \(omikuji.headline) \(omikuji.guidance)

            【恋愛運】\(stars)
            \(omikuji.loveHint)

            【仕事運】\(stars)
            \(omikuji.workHint)

            【金運】\(stars)
            \(omikuji.moneyHint)

            【ラッキーアイテム】
            \(omikuji.luckyItem)

            【ラッキーカラー】
            \(omikuji.luckyColor)

            【メッセージ】
            \(omikuji.poem) 吉方は\(omikuji.luckyDirection)、吉時間は\(omikuji.luckyTime)です。神社で一枚引いたときのように、今日の心構えとして静かに受け取ってみてください。
            """

        default:
            readingText = ""
        }

        var messages: [ReadingMessage] = []
        messages.append(.systemMessage("\(system.japaneseName)に基づく本日の指針"))
        messages.append(.assistantMessage(readingText, presentation: .readingResult))

        return FortuneReading(
            id: UUID().uuidString,
            userId: profile.id,
            system: system,
            theme: category == .general ? .daily : category,
            messages: messages,
            creditsCost: system.creditCost,
            createdAt: Date()
        )
    }

    // MARK: - Reading Assembly

    /// AI 応答から FortuneReading を組み立て
    private func buildFortuneReading(
        system: FortuneSystem,
        category: ReadingCategory,
        profile: UserProfile,
        userQuestion: String?,
        aiResponse: String
    ) -> FortuneReading {
        var messages: [ReadingMessage] = []

        // システムメッセージ
        messages.append(.systemMessage("\(system.japaneseName)に基づく鑑定"))

        // ユーザーの質問がある場合
        if let question = userQuestion, !question.isEmpty {
            messages.append(.userMessage(question))
        }

        // AI の応答
        messages.append(.assistantMessage(aiResponse, presentation: .readingResult))

        return FortuneReading(
            id: UUID().uuidString,
            userId: profile.id,
            system: system,
            theme: category,
            messages: messages,
            creditsCost: system.creditCost,
            createdAt: Date()
        )
    }

    // MARK: - Category Detection

    /// ユーザーの質問からカテゴリを推定
    private func determineCategory(from question: String?) -> ReadingCategory {
        ReadingCategory.infer(from: question)
    }

    private func scoreString(_ score: Int) -> String {
        let clamped = min(max(score, 1), 5)
        return String(repeating: "★", count: clamped) + String(repeating: "☆", count: 5 - clamped)
    }
}
