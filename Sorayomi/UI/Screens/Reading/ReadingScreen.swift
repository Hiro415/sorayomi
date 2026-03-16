import SwiftUI

// MARK: - ReadingScreen

/// Main reading screen with a clearer consultation flow and premium presentation.
struct ReadingScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = ReadingViewModel()

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            VStack(spacing: 0) {
                if viewModel.selectedSystem == nil {
                    systemSelectionContent
                } else {
                    readingContent
                }
            }
        }
        .navigationTitle(viewModel.selectedSystem == nil ? "" : "対話鑑定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let system = viewModel.selectedSystem {
                let shareText = ReadingShareService.shareText(
                    systemName: system.japaneseName,
                    readingText: viewModel.lastReadingText
                )
                ShareSheet(items: [shareText])
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.xs) {
                    if viewModel.sessionStage == .completed {
                        Button {
                            viewModel.showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.callout)
                                .foregroundStyle(Color.sorayomiPrimary)
                        }
                    }

                    CreditBadge(
                        totalCredits: env.creditWalletService.totalAvailable,
                        freeCredits: env.creditWalletService.freeCreditsRemaining
                    )
                }
            }

            if viewModel.selectedSystem != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        resetSession()
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Text("占術を選び直す")
                                .font(SorayomiTypography.caption)
                        }
                        .foregroundStyle(Color.sorayomiPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallSheet(
                isPresented: $viewModel.showPaywall,
                creditsNeeded: viewModel.selectedSystem?.creditCost ?? 1,
                isSubscribed: env.storeKitManager.isSubscribed,
                currentBalance: env.creditWalletService.totalAvailable
            )
        }
        .onAppear {
            consumePendingSystem()
        }
        .onChange(of: env.navigationRouter.pendingFortuneSystem) { _, newValue in
            if newValue != nil {
                consumePendingSystem()
            }
        }
        .onChange(of: env.navigationRouter.shouldResetReading) { _, shouldReset in
            if shouldReset {
                env.navigationRouter.shouldResetReading = false
                resetSession()
            }
        }
    }

    private var systemSelectionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                selectionHero
                quickStartButton
                consultationFlowPanel

                FortuneSystemPickerView(
                    selectedSystem: viewModel.selectedSystem,
                    onSelect: { system in
                        Task {
                            await viewModel.startReading(system: system, env: env)
                        }
                    }
                )
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
    }

    private var selectionHero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("相談の準備")
                .font(SorayomiTypography.eyebrow)
                .foregroundStyle(Color.white.opacity(0.72))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("まずは自由に相談する")
                    .font(SorayomiTypography.title)
                    .foregroundStyle(.white)

                Text("恋愛か仕事かを先に決めなくても大丈夫です。占術を選んだあと、そのまま状況を話し始められます。")
                    .japaneseText(SorayomiTypography.callout, lineSpacing: 6)
                    .foregroundStyle(Color.white.opacity(0.86))
            }

            HStack(spacing: Spacing.xs) {
                selectionBadge("自由相談")
                selectionBadge("ヒアリング")
                selectionBadge("深掘りOK")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sorayomiPanel(tone: .night, padding: Spacing.lg)
    }

    private var quickStartButton: some View {
        Button {
            Task {
                await viewModel.startReading(system: .generalConsultation, env: env)
            }
        } label: {
            VStack(spacing: Spacing.sm) {
                if env.freeTrialManager.isFirstConsultationAvailable {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "gift.fill")
                            .font(.caption2)
                        Text("初回無料で体験できます")
                            .font(SorayomiTypography.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(Color.sorayomiGlow)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: Spacing.md) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("まずは話してみる")
                            .font(SorayomiTypography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("占術は自動で選ばれます。気軽にどうぞ。")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.82))
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(Spacing.md)
            .background(
                LinearGradient(
                    colors: [.sorayomiPrimary, .sorayomiAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
            .shadow(color: Color.sorayomiPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var consultationFlowPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "相談の始め方",
                title: "テーマは話しながら整理します",
                subtitle: "気になる出来事や相手のこと、迷っている選択を、そのまま伝えてください。"
            )
        }
        .sorayomiPanel(tone: .spotlight)
    }

    private var readingContent: some View {
        VStack(spacing: 0) {
            if let system = viewModel.selectedSystem {
                compactSessionHeader(system)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.xs)
            }

            if viewModel.showBloodTypeModePicker {
                BloodTypeModePickerView(
                    userBloodType: env.userProfileService.currentProfile?.bloodType ?? .a,
                    onSelect: { mode in
                        viewModel.selectBloodTypeMode(mode, env: env)
                    },
                    onBack: {
                        viewModel.showBloodTypeModePicker = false
                        viewModel.selectedSystem = nil
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.showBloodTypeReveal {
                BloodTypeRevealView(
                    mode: viewModel.selectedBloodTypeMode ?? .dailyFortune,
                    userBloodType: env.userProfileService.currentProfile?.bloodType ?? .a,
                    partnerBloodType: viewModel.partnerBloodType,
                    dailyFortune: viewModel.bloodTypeDailyFortune,
                    ranking: viewModel.bloodTypeRanking,
                    compatibilityData: viewModel.bloodTypeCompatibilityData,
                    loveSubScores: viewModel.bloodTypeLoveSubScores,
                    onComplete: {
                        Task {
                            await viewModel.completeBloodTypeReveal(env: env)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.showTarotReveal {
                TarotRevealView(
                    drawnCards: viewModel.drawnTarotCards,
                    onComplete: {
                        Task {
                            await viewModel.completeTarotReveal(env: env)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isGenerating && !hasVisibleMessages {
                ReadingLoadingView(fortuneSystem: viewModel.selectedSystem)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ReadingChatView(
                    messages: viewModel.messages,
                    userInput: $viewModel.userInput,
                    isGenerating: viewModel.isGenerating,
                    fortuneSystem: viewModel.selectedSystem,
                    inputPlaceholder: viewModel.inputPlaceholder,
                    onSend: {
                        Task {
                            await viewModel.sendFollowUp(env: env)
                        }
                    }
                )
            }

            // Post-reading engagement prompt
            if viewModel.sessionStage == .completed && !viewModel.isGenerating {
                postReadingPrompt
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.bottom, Spacing.xs)
            }

            if let error = viewModel.errorMessage {
                ErrorBanner(
                    message: error,
                    retryAction: {
                        viewModel.errorMessage = nil
                        if let system = viewModel.selectedSystem {
                            Task {
                                await viewModel.startReading(system: system, env: env)
                            }
                        }
                    },
                    dismissAction: {
                        viewModel.errorMessage = nil
                    }
                )
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xs)
            }
        }
    }

    // MARK: - Compact Session Header

    private func compactSessionHeader(_ system: FortuneSystem) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: system.iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    LinearGradient(
                        colors: [.sorayomiAccent, .sorayomiPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(system.japaneseName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(viewModel.sessionStage.statusLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            Spacer()

            // ミニステージインジケーター
            HStack(spacing: 3) {
                miniStageDot(filled: true)
                miniStageDot(filled: viewModel.sessionStage == .hearing || viewModel.sessionStage == .completed)
                miniStageDot(filled: viewModel.sessionStage == .completed)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.sorayomiSurface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
    }

    private func miniStageDot(filled: Bool) -> some View {
        Circle()
            .fill(filled ? Color.sorayomiAccent : Color.sorayomiDivider)
            .frame(width: 6, height: 6)
    }

    // MARK: - Session Overview (legacy, kept for reference)

    private func sessionOverview(_ system: FortuneSystem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: system.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(
                            colors: [.sorayomiAccent, .sorayomiPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(system.japaneseName)
                        .font(SorayomiTypography.title3)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text("\(viewModel.selectedCategory.consultationLabel) ・ \(viewModel.sessionStage.statusLabel)")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer()

                Text(system.highlightLabel)
                    .font(SorayomiTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.sorayomiAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.sorayomiAccent.opacity(0.10))
                    .clipShape(Capsule())
            }

            stageMeter

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(stageLead)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(stageDetail)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
            }
        }
        .sorayomiPanel(tone: .spotlight)
    }

    private func hearingGuideCard(_ system: FortuneSystem) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.caption2)
                .foregroundStyle(Color.sorayomiPrimary)
                .frame(width: 28, height: 28)
                .background(Color.sorayomiPrimary.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("ヒアリング中")
                    .font(SorayomiTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.sorayomiPrimary)

                Text("\(system.shortName)に必要な材料を集めています。テーマは話しながら整理するので、最近の出来事や理想の形を一つだけでも具体的に書いてみてください。")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.sorayomiSurface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.sorayomiDivider.opacity(0.65), lineWidth: 1)
        )
    }

    private var stageMeter: some View {
        HStack(spacing: Spacing.xs) {
            stageSegment(title: "選択", isActive: true, isCompleted: true)
            stageSegment(
                title: "ヒアリング",
                isActive: viewModel.sessionStage == .hearing,
                isCompleted: viewModel.sessionStage == .completed
            )
            stageSegment(
                title: "本鑑定",
                isActive: viewModel.sessionStage == .completed,
                isCompleted: false
            )
        }
    }

    private func stageSegment(title: String, isActive: Bool, isCompleted: Bool) -> some View {
        HStack(spacing: Spacing.xxs) {
            Circle()
                .fill(isActive || isCompleted ? Color.sorayomiAccent : Color.sorayomiDivider)
                .frame(width: 8, height: 8)

            Text(title)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(isActive || isCompleted ? Color.sorayomiTextPrimary : Color.sorayomiTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background((isActive || isCompleted) ? Color.sorayomiAccent.opacity(0.10) : Color.sorayomiPaper.opacity(0.8))
        .clipShape(Capsule())
    }

    private var stageLead: String {
        switch viewModel.sessionStage {
        case .idle:
            return "占術を選んだら、そのまま相談を始められます。"
        case .hearing:
            return "状況をうかがいながら、読みの芯を整えています。"
        case .completed:
            return "本鑑定が出ています。気になる点はそのまま追加で深掘りできます。"
        }
    }

    private var stageDetail: String {
        switch viewModel.sessionStage {
        case .idle:
            return "テーマがまだ曖昧でも大丈夫です。お話を聞きながら、相談の軸を一緒に整えていきます。"
        case .hearing:
            return "具体的な材料が増えるほど、テンプレではない見立てに近づきます。"
        case .completed:
            return "結果だけで終わらず、納得するまで会話を続けられる状態です。"
        }
    }

    private func sectionHeader(eyebrow: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(eyebrow.uppercased())
                .font(SorayomiTypography.eyebrow)
                .foregroundStyle(Color.sorayomiAccent)

            Text(title)
                .font(SorayomiTypography.title2)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Text(subtitle)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func selectionBadge(_ text: String) -> some View {
        Text(text)
            .font(SorayomiTypography.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.10))
            .clipShape(Capsule())
    }

    private var postReadingPrompt: some View {
        VStack(spacing: Spacing.xs) {
            if env.creditWalletService.totalAvailable <= 2 && !env.storeKitManager.isSubscribed {
                // Low credit upsell
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.sorayomiAccent)

                    Text("深掘りを続けるなら — プレミアムパスで毎日クレジットが届きます")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .lineSpacing(3)

                    Spacer(minLength: 0)
                }
                .padding(Spacing.sm)
                .background(Color.sorayomiAccent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))
            }

            // Try another system suggestion
            if let current = viewModel.selectedSystem {
                let suggestions = FortuneSystem.allCases.filter { $0 != current && $0.creditCost > 0 }.prefix(2)
                if !suggestions.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Text("他の占術も試す:")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary)

                        ForEach(Array(suggestions), id: \.self) { system in
                            Button {
                                resetSession()
                                Task {
                                    try? await Task.sleep(for: .milliseconds(100))
                                    await viewModel.startReading(system: system, env: env)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: system.iconName)
                                        .font(.caption2)
                                    Text(system.shortName)
                                        .font(SorayomiTypography.caption)
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(Color.sorayomiPrimary.opacity(0.1))
                                .foregroundStyle(Color.sorayomiPrimary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, Spacing.xs)
                }
            }
        }
    }

    private func resetSession() {
        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.selectedSystem = nil
            viewModel.selectedCategory = .general
            viewModel.messages = []
            viewModel.errorMessage = nil
            viewModel.sessionStage = .idle
            viewModel.userInput = ""
        }
    }

    private func consumePendingSystem() {
        guard let system = env.navigationRouter.pendingFortuneSystem else { return }
        env.navigationRouter.pendingFortuneSystem = nil
        let pendingCategory = env.navigationRouter.pendingReadingCategory
        env.navigationRouter.pendingReadingCategory = nil

        resetSession()

        Task {
            try? await Task.sleep(for: .milliseconds(100))
            viewModel.selectedCategory = pendingCategory ?? .general
            await viewModel.startReading(system: system, env: env)
        }
    }

    private var hasVisibleMessages: Bool {
        viewModel.messages.contains { $0.role.isVisibleToUser }
    }
}

#Preview {
    NavigationStack {
        ReadingScreen()
            .environment(AppEnvironment())
    }
}
