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
                isSubscribed: env.storeKitManager.isSubscribed
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
                sessionOverview(system)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.sm)

                if viewModel.sessionStage == .hearing {
                    hearingGuideCard(system)
                        .padding(.horizontal, Spacing.screenPadding)
                        .padding(.top, Spacing.sm)
                }
            }

            if viewModel.isGenerating && !hasVisibleMessages {
                ReadingLoadingView(fortuneSystem: viewModel.selectedSystem)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ReadingChatView(
                    messages: viewModel.messages,
                    userInput: $viewModel.userInput,
                    isGenerating: viewModel.isGenerating,
                    inputPlaceholder: viewModel.inputPlaceholder,
                    onSend: {
                        Task {
                            await viewModel.sendFollowUp(env: env)
                        }
                    }
                )
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
