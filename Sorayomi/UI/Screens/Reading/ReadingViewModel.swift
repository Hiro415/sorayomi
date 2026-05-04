import Foundation

// MARK: - ReadingSessionStage

enum ReadingSessionStage {
    case idle
    case hearing
    case completed

    var inputPlaceholder: String {
        switch self {
        case .idle:
            return "相談したいことを入力..."
        case .hearing:
            return "状況やお気持ちを教えてください"
        case .completed:
            return "気になることを聞いてみる..."
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
    /// リビューが一度表示済みかどうか（completeBloodTypeReveal後の再入防止用）
    var bloodTypeRevealShown = false
    var bloodTypeDailyFortune: BloodTypeDailyFortune?
    var bloodTypeRanking: BloodTypeRanking?
    var bloodTypeCompatibilityData: BloodTypeCompatibilityData?
    var bloodTypeLoveSubScores: BloodTypeLoveSubScores?

    // 星座占い専用
    var showZodiacReveal = false
    var zodiacHoroscope: ZodiacCalculator.DailyHoroscope?

    // 九星気学専用
    var showNineStarKiReveal = false
    var nineStarKiProfile: NineStarKiProfile?
    var nineStarKiEnergy: NineStarKiDailyEnergy?

    // 数秘術専用
    var showNumerologyReveal = false
    var numerologyProfile: NumerologyProfile?
    var numerologyEnergy: NumerologyCalculator.DailyNumerologyEnergy?

    // おみくじ専用（チャット不要・AI不要）
    var showOmikujiReveal = false
    var omikujiResult: Omikuji?

    // 六曜専用（決定論的・AI不要）
    var showRokuyoReveal = false
    var rokuyoForReveal: Rokuyo?
    /// true = 当日すでに利用済み（プリドロー画面をスキップして結果を即表示）
    var rokuyoAlreadyUsedToday = false

    // 花占い専用
    var showFlowerReveal = false
    var flowerProfile: FlowerProfile?
    var flowerDailyEnergy: DailyFlowerEnergy?

    // ストーン占い専用
    var showStoneReveal = false
    var stoneProfile: StoneProfile?
    var stoneDailyEnergy: DailyStoneEnergy?

    // 総合相談専用
    var showTopicSuggestions = false

    // MARK: - Credit Tracking（無償/有償クレジット差別化）

    /// セッション中に有償クレジット（balance）が使用されたか
    /// - true  → 履歴保存済み or 保存対象
    /// - false → 無償クレジット/フリートライアルのみ → 未保存
    private(set) var sessionUsedPaidCredit: Bool = false

    /// 無償クレジットで完了した初回鑑定のシステム（保留中）
    /// 初めて有償深掘りが発生したタイミングで履歴に保存する
    private var pendingFreeReadingSystem: FortuneSystem? = nil

    /// CrisisDetectorがmedium/low severityを検出した場合にON。
    /// AIシステムプロンプトに相談窓口紹介の指示を付加するシグナル。
    private var sensitiveContextFlag = false

    private var hearingResponses: [String] = []
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

    // MARK: - Full State Reset

    /// セッション切り替え時にすべての占術固有の状態をリセットする。
    /// `ReadingScreen.resetSession()` から呼び出す。
    func resetAllState() {
        selectedSystem = nil
        selectedCategory = .general
        messages = []
        userInput = ""
        errorMessage = nil
        sessionStage = .idle
        isGenerating = false
        lastReadingText = ""

        // ヒアリング
        hearingResponses = []
        isUsingFreeTrial = false

        // タロット
        drawnTarotCards = []
        showTarotReveal = false

        // 血液型
        selectedBloodTypeMode = nil
        partnerBloodType = nil
        showBloodTypeModePicker = false
        showBloodTypeReveal = false
        bloodTypeRevealShown = false
        bloodTypeDailyFortune = nil
        bloodTypeRanking = nil
        bloodTypeCompatibilityData = nil
        bloodTypeLoveSubScores = nil

        // 星座
        showZodiacReveal = false
        zodiacHoroscope = nil

        // 九星気学
        showNineStarKiReveal = false
        nineStarKiProfile = nil
        nineStarKiEnergy = nil

        // 数秘術
        showNumerologyReveal = false
        numerologyProfile = nil
        numerologyEnergy = nil

        // おみくじ
        showOmikujiReveal = false
        omikujiResult = nil

        // 六曜
        showRokuyoReveal = false
        rokuyoForReveal = nil
        rokuyoAlreadyUsedToday = false

        // 花占い
        showFlowerReveal = false
        flowerProfile = nil
        flowerDailyEnergy = nil

        // ストーン占い
        showStoneReveal = false
        stoneProfile = nil
        stoneDailyEnergy = nil

        // 総合相談
        showTopicSuggestions = false
        sensitiveContextFlag = false

        // クレジット追跡
        sessionUsedPaidCredit = false
        pendingFreeReadingSystem = nil
    }

    func startReading(system: FortuneSystem, env: AppEnvironment) async {
        guard !isGenerating else { return }

        // 1日1回の無料コンテンツ：当日使用済みなら結果閲覧モードへ（引き直し不可）
        if system.creditCost == 0 && env.dailyFortuneTracker.isUsedToday(system: system) {
            if system == .omikuji {
                selectedSystem = system
                omikujiResult = env.dailyFortuneTracker.todayOmikujiResult
                showOmikujiReveal = true
            } else if system == .rokuyo {
                // 六曜は決定論的なので何度でも閲覧可。引き済みはプリドロー画面をスキップ。
                selectedSystem = system
                rokuyoForReveal = RokuyoCalculator.today()
                rokuyoAlreadyUsedToday = true
                showRokuyoReveal = true
            }
            return
        }

        // Check if free trial applies (first paid consultation ever)
        let trialAvailable = system.creditCost > 0 && env.freeTrialManager.shouldGrantFreeTrial()
        isUsingFreeTrial = trialAvailable

        if system.creditCost > 0 && !trialAvailable && !env.creditWalletService.canAfford(system.creditCost) {
            showPaywall = true
            return
        }

        selectedSystem = system

        // おみくじ：ヒアリング不要・AI不要。
        // ランク決定はOmikujiRevealView内のドラッグ操作に委ねる。
        if system == .omikuji {
            omikujiResult = nil  // 新規抽選 → storedResult は nil
            showOmikujiReveal = true
            env.analyticsService.track(.readingStarted(
                system: system.rawValue,
                category: selectedCategory.rawValue
            ))
            return
        }

        // 六曜：決定論的・AI不要。プリドロー画面 → タップで結果表示。
        // markUsed は drawRokuyo() でユーザーがタップした時点に行う。
        if system == .rokuyo {
            rokuyoForReveal = RokuyoCalculator.today()
            rokuyoAlreadyUsedToday = false
            showRokuyoReveal = true
            return
        }

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
        sensitiveContextFlag = false

        // 総合相談はトピック提案を表示
        showTopicSuggestions = (system == .generalConsultation)

        env.analyticsService.track(.readingStarted(
            system: system.rawValue,
            category: selectedCategory.rawValue
        ))

        messages.append(.assistantMessage(openingInterviewPrompt(for: system)))
    }

    func sendFollowUp(env: AppEnvironment) async {
        let text = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let system = selectedSystem else { return }

        // --- Safety Gate: 明示的crisis + inappropriate のみon-deviceでブロック ---
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

        // --- CrisisDetector: 曖昧な苦痛表現のシグナル検出（ブロックしない） ---
        let crisisResult = CrisisDetector().detect(in: text)
        if crisisResult.isCrisis && crisisResult.severity >= .low {
            sensitiveContextFlag = true
        }

        messages.append(.userMessage(text))
        userInput = ""
        errorMessage = nil

        if sessionStage == .hearing {
            // トピック提案チップスを非表示
            if showTopicSuggestions {
                showTopicSuggestions = false
            }

            if !isMeaningfulHearingResponse(text) {
                messages.append(.assistantMessage(insufficientDetailPrompt(for: system, text: text)))
                return
            }

            if hearingResponses.isEmpty || selectedCategory == .general {
                refreshSelectedCategory(with: text)
            }

            hearingResponses.append(text)

            // 総合相談は適切な回答があれば即鑑定（更問いによるストレスを避ける）
            if system == .generalConsultation {
                await generateDetailedReading(system: system, env: env)
                return
            }

            // 適応型ヒアリング: 品質ベースで判定
            let richness = assessResponseRichness(text)
            let totalCount = hearingResponses.count
            let maxExchanges = 2

            if totalCount >= maxExchanges {
                // 最大2回に到達 → 鑑定生成
                await generateDetailedReading(system: system, env: env)
                return
            }

            switch richness {
            case .rich, .moderate:
                // 十分な詳細 or 中程度 → 即座に鑑定生成
                await generateDetailedReading(system: system, env: env)
                return
            case .minimal:
                // 短い・抽象的 → フォローアップ1回のみ
                messages.append(.assistantMessage(adaptiveFollowUpPrompt(
                    for: system,
                    richness: richness
                )))
                return
            }
        }

        // 鑑定完了後の深掘りは有償クレジット専用
        // 無償クレジットは使用不可 — ストアへの動線を設ける
        if sessionStage == .completed {
            let followUpCost = 1
            if !env.storeKitManager.isSubscribed {
                guard env.creditWalletService.canAffordWithPaidOnly(followUpCost) else {
                    showPaywall = true
                    userInput = text
                    messages.removeLast()
                    return
                }
                try? await env.creditWalletService.deductPaidCredits(followUpCost)
                // 初めて有償クレジットを使用 → 保留中の初回鑑定を履歴に保存
                if !sessionUsedPaidCredit {
                    sessionUsedPaidCredit = true
                    if let pendingSystem = pendingFreeReadingSystem {
                        saveReadingToHistory(system: pendingSystem, wasFree: false, env: env)
                        pendingFreeReadingSystem = nil
                    }
                }
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
            bloodTypeRevealShown = true
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
            followUp = """
            \(userBloodType.japaneseName)と\(type.japaneseName)の恋の縁を見てまいりますね。

            今のお二人の状況を教えてください。片思い中ですか、それとも既にお付き合い中でしょうか？どんな未来を望んでいるかも、自由に聞かせてもらえると嬉しいです。
            """
        } else {
            followUp = """
            \(userBloodType.japaneseName)と\(type.japaneseName)の相性を見ていきますね。

            お二人はどのようなご関係ですか？（たとえば職場の同僚、友人、パートナーなど）気になっていることがあれば、あわせて聞かせてください。
            """
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
            \(bloodType.japaneseName)のあなたの今日を見立てていきますね。

            今日気になっていること、今日の予定、あるいは最近の心の状態を聞かせてください。お話を土台に、今日一日の流れを丁寧に読み解いていきます。
            """
        case .compatibility:
            return """
            誰かとの相性を見ていきましょう。

            まず、お相手の血液型を選んでください。
            """
        case .loveMatch:
            return """
            恋のお相手との縁を読んでいきますね。

            お相手の血液型を選んでください。
            """
        case .ranking:
            return "" // rankingはヒアリングなし
        }
    }

    /// おみくじランク確定時のコールバック（ドラッグ操作完了 → スピン終了時）。
    /// 使用済みマーク・結果保存をここで行う（dismiss時ではなくランク確定時）。
    func omikujiResultDetermined(_ result: Omikuji, env: AppEnvironment) {
        guard let system = selectedSystem, system == .omikuji else { return }
        omikujiResult = result
        env.dailyFortuneTracker.markUsed(system: system)
        env.dailyFortuneTracker.storeOmikujiResult(result)
        env.analyticsService.track(.readingCompleted(
            system: system.rawValue,
            category: selectedCategory.rawValue,
            creditsCost: 0
        ))
    }

    /// おみくじ閉じる（dismissボタン押下時）
    func completeOmikuji(env: AppEnvironment) {
        resetAllState()
    }

    /// 六曜プリドロー画面でユーザーがタップして結果を「引いた」とき。
    /// 使用済みマーク・アナリティクスはここで行う（表示時ではなくタップ時）。
    func drawRokuyo(env: AppEnvironment) {
        env.dailyFortuneTracker.markUsed(system: .rokuyo)
        env.analyticsService.track(.readingStarted(
            system: FortuneSystem.rokuyo.rawValue,
            category: selectedCategory.rawValue
        ))
    }

    /// 六曜リビュー閉じる
    func completeRokuyo() {
        resetAllState()
    }

    /// 星座リビール完了後のコールバック
    func completeZodiacReveal(env: AppEnvironment) async {
        guard let system = selectedSystem, system == .horoscope else { return }
        showZodiacReveal = false
        await generateDetailedReading(system: system, env: env)
    }

    /// 九星気学リビール完了後のコールバック
    func completeNineStarKiReveal(env: AppEnvironment) async {
        guard let system = selectedSystem, system == .nineStarKi else { return }
        showNineStarKiReveal = false
        await generateDetailedReading(system: system, env: env)
    }

    /// 総合相談：トピック提案を選択してテキスト入力欄に反映
    func selectSuggestedTopic(_ topic: String) {
        userInput = topic
        showTopicSuggestions = false
    }

    /// 数秘術リビール完了後のコールバック
    func completeNumerologyReveal(env: AppEnvironment) async {
        guard let system = selectedSystem, system == .numerology else { return }
        showNumerologyReveal = false
        await generateDetailedReading(system: system, env: env)
    }

    /// 花占いリビール完了後のコールバック
    func completeFlowerReveal(env: AppEnvironment) async {
        guard let system = selectedSystem, system == .flowerFortune else { return }
        showFlowerReveal = false
        await generateDetailedReading(system: system, env: env)
    }

    /// ストーン占いリビール完了後のコールバック
    func completeStoneReveal(env: AppEnvironment) async {
        guard let system = selectedSystem, system == .stoneFortune else { return }
        showStoneReveal = false
        await generateDetailedReading(system: system, env: env)
    }

    private func generateDetailedReading(system: FortuneSystem, env: AppEnvironment) async {
        // 数秘術の場合：先にプロファイル計算してリビール画面を表示
        if system == .numerology && numerologyEnergy == nil {
            let userProfile = env.userProfileService.currentProfile
            if let birthday = userProfile?.birthday {
                numerologyProfile = NumerologyCalculator.profile(from: birthday)
                numerologyEnergy = NumerologyCalculator.dailyEnergy(birthday: birthday)
            } else {
                // 誕生日未設定の場合：ユニバーサルサイクルベースのフォールバック
                let today = Date()
                let fallbackLP = NumerologyCalculator.universalDayNumber(for: today)
                numerologyProfile = NumerologyProfile(
                    lifePathNumber: fallbackLP,
                    birthdayNumber: fallbackLP,
                    personalYearNumber: NumerologyCalculator.universalYearNumber(for: today),
                    personalMonthNumber: NumerologyCalculator.universalMonthNumber(for: today),
                    personalDayNumber: NumerologyCalculator.universalDayNumber(for: today)
                )
                // For fallback, use a dummy birthday (Jan 1 current year) to generate energy
                let calendar = Calendar(identifier: .gregorian)
                let dummyBirthday = calendar.date(from: DateComponents(
                    year: calendar.component(.year, from: today) - 30,
                    month: 1, day: 1
                ))!
                numerologyEnergy = NumerologyCalculator.dailyEnergy(birthday: dummyBirthday, on: today)
            }
            showNumerologyReveal = true
            return
        }

        // 九星気学の場合：先にエネルギー計算してリビール画面を表示
        if system == .nineStarKi && nineStarKiEnergy == nil {
            let profile = env.userProfileService.currentProfile
            if let birthday = profile?.birthday {
                let kiProfile = NineStarKiCalculator.calculate(from: birthday)
                nineStarKiProfile = kiProfile
                nineStarKiEnergy = NineStarKiCalculator.dailyEnergy(profile: kiProfile)
            } else {
                // 誕生日未設定の場合：今年の星をベースにフォールバック
                let fallbackProfile = NineStarKiProfile(
                    honmeisei: NineStarKiCalculator.yearStar(),
                    getsumeisei: NineStarKiCalculator.monthlyStar(),
                    birthYear: Calendar(identifier: .gregorian).component(.year, from: Date())
                )
                nineStarKiProfile = fallbackProfile
                nineStarKiEnergy = NineStarKiCalculator.dailyEnergy(profile: fallbackProfile)
            }
            showNineStarKiReveal = true
            return
        }

        // 花占いの場合：プロフィール計算 → リビール画面表示
        if system == .flowerFortune && flowerDailyEnergy == nil {
            let userProfile = env.userProfileService.currentProfile
            if let birthday = userProfile?.birthday {
                flowerProfile = FlowerFortuneCalculator.profile(from: birthday)
                flowerDailyEnergy = FlowerFortuneCalculator.dailyEnergy(birthday: birthday)
            } else {
                let todaysFlower = FlowerFortuneCalculator.todaysFlower()
                flowerProfile = FlowerFortuneCalculator.fallbackProfile(flower: todaysFlower)
                flowerDailyEnergy = FlowerFortuneCalculator.fallbackDailyEnergy(flower: todaysFlower)
            }
            showFlowerReveal = true
            return
        }

        // ストーン占いの場合：プロフィール計算 → リビール画面表示
        if system == .stoneFortune && stoneDailyEnergy == nil {
            let userProfile = env.userProfileService.currentProfile
            if let birthday = userProfile?.birthday {
                stoneProfile = StoneFortuneCalculator.profile(from: birthday)
                stoneDailyEnergy = StoneFortuneCalculator.dailyEnergy(birthday: birthday)
            } else {
                let todaysStone = StoneFortuneCalculator.todaysStone()
                stoneProfile = StoneFortuneCalculator.fallbackProfile(stone: todaysStone)
                stoneDailyEnergy = StoneFortuneCalculator.fallbackDailyEnergy(stone: todaysStone)
            }
            showStoneReveal = true
            return
        }

        // 星座の場合：先にホロスコープ計算してリビール画面を表示
        if system == .horoscope && zodiacHoroscope == nil {
            let profile = env.userProfileService.currentProfile
            if let birthday = profile?.birthday {
                let sign = ZodiacCalculator.calculate(from: birthday)
                zodiacHoroscope = ZodiacCalculator.dailyHoroscope(for: sign)
            } else {
                let currentSign = ZodiacCalculator.currentSeason()
                zodiacHoroscope = ZodiacCalculator.dailyHoroscope(for: currentSign)
            }
            showZodiacReveal = true
            return
        }

        // タロットの場合：先にカードをドローしてリビール画面を表示
        if system == .tarot && drawnTarotCards.isEmpty {
            let cardCount = hearingResponses.count >= 3 ? 5 : 3
            drawnTarotCards = TarotDrawEngine.draw(count: cardCount)
            showTarotReveal = true
            // リビール完了後に completeTarotReveal → 再度この関数が呼ばれる
            return
        }

        // 血液型の場合：RevealViewを表示（まだ表示済みでない場合のみ）
        // bloodTypeRevealShown で再入防止（タロットの drawnTarotCards.isEmpty と同パターン）
        if system == .bloodType, let mode = selectedBloodTypeMode, !bloodTypeRevealShown {
            let profile = env.userProfileService.currentProfile
            let userBloodType = profile?.bloodType ?? .a

            switch mode {
            case .dailyFortune:
                if bloodTypeDailyFortune == nil {
                    bloodTypeDailyFortune = BloodTypeCompatibility.dailyFortune(for: userBloodType)
                }
                bloodTypeRevealShown = true
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
                bloodTypeRevealShown = true
                showBloodTypeReveal = true
                return
            case .ranking:
                // ランキングは selectBloodTypeMode() で既にReveal済み → そのまま進行
                break
            }
        }

        isGenerating = true

        let profile = env.userProfileService.currentProfile
        var systemPrompt = SystemPromptBuilder.build(
            system: system,
            depth: .standard,
            category: selectedCategory,
            bloodTypeMode: selectedBloodTypeMode
        )
        let userPrompt = buildDetailedReadingPrompt(system: system, profile: profile)

        // sensitiveContextFlag: 曖昧な苦痛表現が検出された場合、
        // AIに相談窓口紹介を自然に行うよう指示を付加
        if sensitiveContextFlag {
            systemPrompt += """

            【追加配慮】
            この相談者はつらい状況にある可能性があります。
            鑑定は通常通り丁寧に行ってください。
            鑑定の最後に、必要に応じて「専門の相談窓口（いのちの電話：0570-783-556）もありますので、\
            おひとりで抱え込まないでくださいね」と自然な形で一言添えてください。
            ただし、相談内容が明らかに占い相談の範囲内であれば、この一文は不要です。
            """
        }

        messages.append(.systemMessage(userPrompt))

        do {
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

            // クレジット消費はAPI成功後に行う（失敗時にクレジットが消えるのを防止）
            if system.creditCost > 0 && !isUsingFreeTrial {
                // 消費前に有償クレジットが使われるか確認（無償分で全額カバーできるか）
                let willUsePaidCredit = env.creditWalletService.freeCreditsRemaining < system.creditCost
                try await env.creditWalletService.deductCredits(system.creditCost)
                if willUsePaidCredit {
                    sessionUsedPaidCredit = true
                }
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

            // 履歴保存の判断:
            // - 無料占術（おみくじ/六曜等、creditCost==0）→ 履歴保存しない（使用済みマークのみ）
            // - 有償クレジット使用 → 即時保存
            // - 無償クレジット or フリートライアル → 保留（初回有償深掘り時に保存）
            if system.creditCost == 0 {
                // 無料コンテンツは履歴に残さない。1日1回使用済みとしてマーク。
                env.dailyFortuneTracker.markUsed(system: system)
                pendingFreeReadingSystem = nil
            } else if sessionUsedPaidCredit {
                saveReadingToHistory(system: system, wasFree: false, env: env)
                pendingFreeReadingSystem = nil
            } else {
                pendingFreeReadingSystem = system
            }

            env.analyticsService.track(.readingCompleted(
                system: system.rawValue,
                category: selectedCategory.rawValue,
                creditsCost: wasFreeTrialUsed ? 0 : system.creditCost
            ))

            // レビュー依頼チェック（鑑定完了後の適切なタイミングで表示）
            env.reviewRequestManager.recordReadingCompletion()
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

        let systemPrompt = SystemPromptBuilder.build(
            system: system,
            depth: .standard,
            category: selectedCategory,
            bloodTypeMode: selectedBloodTypeMode
        )
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
            let seasonal = SeasonalContext.from(date: Date())
            return """
            こんにちは。\(seasonal.seasonalImagery)の頃ですね。

            今日はどんなことが気になっていますか？恋愛でも仕事でも、まだはっきりしない感覚でも、そのまま聞かせてください。
            """
        }

        return """
        こんにちは。\(system.japaneseName)で見ていきますね。

        今いちばん気になっていること、最近の状況を聞かせてください。テーマが決まっていなくても大丈夫です。
        """
    }

    // MARK: - Adaptive Hearing

    /// ヒアリング回答の品質レベル
    private enum ResponseRichness {
        /// 十分な詳細あり（意図明確 or 25文字超+ディテール）
        case rich
        /// ある程度の内容あり（12文字超）
        case moderate
        /// 短い・抽象的
        case minimal
    }

    /// 回答の品質を評価する
    private func assessResponseRichness(_ text: String) -> ResponseRichness {
        let normalized = normalizeHearingText(text)
        let length = normalized.count

        // 意図が明確なら文字数に関係なく即鑑定
        if hasClearIntent(normalized) && length >= 8 {
            return .rich
        }

        let hasDetail = containsSpecificDetail(normalized)

        if length > 25 && hasDetail {
            return .rich
        } else if length > 12 {
            return .moderate
        } else {
            return .minimal
        }
    }

    /// 明確な意思決定言語が含まれているか
    private func hasClearIntent(_ text: String) -> Bool {
        let intentIndicators = [
            "迷って", "迷い", "迷う", "すべきか", "どうすれば", "どうしたら",
            "やめるべき", "続けるべき", "別れるか", "付き合うか",
            "不安", "悩んで", "悩み", "心配", "つらい", "苦しい", "焦って", "モヤモヤ",
            "転職", "結婚", "離婚", "引っ越し", "告白", "復縁", "妊娠",
            "でしょうか", "ですか", "かな", "だろう", "いいのか",
        ]
        return intentIndicators.contains { text.contains($0) }
    }

    /// 具体的なディテール（人物、時間、場所、感情、イベント）が含まれているか
    private func containsSpecificDetail(_ text: String) -> Bool {
        let detailIndicators = [
            "歳", "年", "月", "週", "日",
            "彼", "彼女", "上司", "同僚", "友人", "親", "夫", "妻", "母", "父",
            "会社", "職場", "学校", "家",
            "迷って", "悩んで", "不安", "心配", "気になる",
            "転職", "結婚", "離婚", "引っ越し", "妊娠", "出産",
            "したい", "したくない", "すべきか", "どうすれば",
            "関係", "距離", "気持ち", "将来",
        ]
        return detailIndicators.contains { text.contains($0) }
    }

    /// 品質に応じた適応型フォローアッププロンプト
    private func adaptiveFollowUpPrompt(
        for system: FortuneSystem,
        richness: ResponseRichness
    ) -> String {
        // 血液型モード専用の更問い
        if system == .bloodType, let mode = selectedBloodTypeMode {
            return bloodTypeFollowUpPrompt(mode: mode, richness: richness)
        }

        // 総合相談専用（sendFollowUp内の早期returnにより理論上は呼ばれないが安全弁として）
        if system == .generalConsultation {
            switch richness {
            case .minimal:
                return """
                もう少しだけ聞かせてください。

                今いちばん頭に残っている場面や、どうなったらいいという感覚があれば教えてもらえますか？
                """
            case .moderate:
                return """
                聞かせてくれてありがとうございます。

                もう一点だけ、今特に迷っていることや、気になっている時期があれば教えてください。
                """
            case .rich:
                return "ありがとうございます。それでは鑑定に入りますね。"
            }
        }

        let categoryAck: String
        if selectedCategory != .general {
            categoryAck = "\(selectedCategory.consultationLabel)のことですね。"
        } else {
            categoryAck = ""
        }

        switch richness {
        case .minimal:
            return """
            もう少しだけ聞かせてください。\(categoryAck)

            いちばん引っかかっている場面や、どうなったらいいという感覚があれば教えてもらえますか？
            """
        case .moderate:
            return """
            \(categoryAck)聞かせてくれてありがとうございます。

            もう一点だけ、今特に迷っていることや、気になっている時期があれば教えてください。
            """
        case .rich:
            return "ありがとうございます。それでは鑑定に入りますね。"
        }
    }

    /// 血液型モード別の更問い
    private func bloodTypeFollowUpPrompt(mode: BloodTypeMode, richness: ResponseRichness) -> String {
        switch mode {
        case .dailyFortune:
            switch richness {
            case .minimal:
                return "もう少しだけ聞かせてください。今日で特に気になっている場面や、今の気持ちを一言でも教えてもらえますか？"
            case .moderate:
                return "ありがとうございます。今日の中で、とくに占いで見てほしい場面や悩みはありますか？"
            case .rich:
                return "ありがとうございます。それでは見立てていきますね。"
            }
        case .compatibility:
            switch richness {
            case .minimal:
                return "もう少し聞かせてください。お二人の間でいちばん気になっていることを、一つだけ教えてもらえますか？"
            case .moderate:
                return "ありがとうございます。その関係で、今どんなことが気になっていますか？もう少しだけ聞かせてください。"
            case .rich:
                return "ありがとうございます。それでは相性を見ていきますね。"
            }
        case .loveMatch:
            switch richness {
            case .minimal:
                return "もう少しだけ聞かせてください。今のお二人の距離感や、どうなりたいかを一言でも教えてもらえますか？"
            case .moderate:
                return "ありがとうございます。今の恋愛でいちばん気になっていること——たとえば「気持ちを伝えるべきか」「このまま続くか」など——を教えてもらえますか？"
            case .rich:
                return "ありがとうございます。それでは恋の相性を読んでいきますね。"
            }
        case .ranking:
            return "ありがとうございます。それでは鑑定に入りますね。"
        }
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
            depth: .standard,
            userQuestion: hearingResponses.joined(separator: "\n"),
            preDrawnTarotCards: preDrawnCards,
            bloodTypeMode: selectedBloodTypeMode,
            partnerBloodType: partnerBloodType
        )

        // ランキングモードはヒアリング無しのため、専用の鑑定方針を使用
        let isRankingMode = selectedBloodTypeMode == .ranking

        if isRankingMode {
            return """
            \(basePrompt)

            【鑑定方針】
            ・ランキング結果を踏まえ、ユーザーの血液型が今日をどう過ごすべきかを中心に鑑定してください。
            ・「今日のあなたの運勢は〜」のように、ランキング結果の解説から自然に始めてください。
            ・順位が低い場合も前向きな助言を添え、1位の型の良い影響を受ける方法にも触れてください。
            ・エンタメ感を保ちつつも、占い師としての深みある助言を提供してください。
            ・今日一日の過ごし方（午前・午後・夜）のアドバイスを含めてください。
            """
        }

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

    private func insufficientDetailPrompt(for system: FortuneSystem, text: String = "") -> String {
        // 総合相談：テキストからカテゴリを推定して文脈に合ったヒントを返す
        if system == .generalConsultation {
            let inferredCategory = ReadingCategory.infer(from: text)
            let hint: String
            switch inferredCategory {
            case .love, .relationships:
                hint = "「気になる相手がいる」「連絡頻度に迷っている」「これからどうなるか不安」など、恋愛のどんな場面を見てほしいか教えてもらえますか？"
            case .career:
                hint = "「転職を迷っている」「人間関係が重い」「このまま続けていいか不安」など、仕事のどの場面かを教えてもらえますか？"
            case .wealth:
                hint = "「出費が増えて不安」「収入を上げたい」「貯金の流れが気になる」など、お金の悩みの芯を教えてもらえますか？"
            default:
                hint = "何について気になっていますか？少しだけ状況を聞かせてもらえますか？"
            }
            return """
            もう少しだけ教えてください。

            \(hint)
            """
        }

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
        case .personality:
            categoryHint = "たとえば「自分の強みを知りたい」「向いている方向が分からない」「最近の自分のリズムを整えたい」など、自分について気になることを一つだけでも教えてください。"
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
