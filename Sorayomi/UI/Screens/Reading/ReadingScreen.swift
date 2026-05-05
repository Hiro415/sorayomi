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
        .navigationTitle(viewModel.selectedSystem.map {
            $0.requiresAIGeneration ? "対話鑑定" : $0.japaneseName
        } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let system = viewModel.selectedSystem {
                let shareText = ReadingShareService.shareText(
                    systemName: system.japaneseName,
                    readingText: viewModel.lastReadingText
                )
                // テキストのみ共有（コピー時に画像が混入しない）
                ShareSheet(items: [shareText])
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.xs) {
                    NavigationLink(value: NavigationDestination.creditStore) {
                        CreditBadge(
                            totalCredits: env.creditWalletService.totalAvailable,
                            freeCredits: env.creditWalletService.freeCreditsRemaining
                        )
                    }
                    .buttonStyle(.plain)
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
                currentBalance: env.creditWalletService.totalAvailable,
                hasUsedStarterPack: env.storeKitManager.hasUsedStarterPack,
                onPurchase: { productId in
                    Task {
                        if let product = env.storeKitManager.product(for: productId) {
                            let storeVM = StoreViewModel()
                            await storeVM.purchase(product: product, env: env)
                            env.creditWalletService.loadWallet()
                        }
                    }
                },
                onSubscribe: { productId in
                    Task {
                        if let product = env.storeKitManager.subscription(for: productId) {
                            let storeVM = StoreViewModel()
                            await storeVM.purchaseSubscription(product: product, env: env)
                        }
                    }
                },
                onRestore: {
                    Task {
                        await env.storeKitManager.restorePurchases()
                        env.creditWalletService.loadWallet()
                    }
                },
                onWatchAd: {
                    env.adRewardManager.startWatchingAd()
                    env.creditWalletService.loadWallet()
                },
                isAdRewardAvailable: env.featureFlags.isAdRewardEnabled && env.creditWalletService.isAdRewardAvailableToday && !env.storeKitManager.isSubscribed
            )
        }
        .onAppear {
            env.dailyFortuneTracker.refreshIfNeeded()
            // おみくじ結果を開いたまま別タブへ移動した場合、
            // 意図的な再開でなければ（pending systemなし）選択画面にリセット
            if env.navigationRouter.pendingFortuneSystem == nil && viewModel.showOmikujiReveal {
                viewModel.resetAllState()
            }
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
                quickStartButton

                FortuneSystemPickerView(
                    selectedSystem: viewModel.selectedSystem,
                    onSelect: { system in
                        Task {
                            await viewModel.startReading(system: system, env: env)
                        }
                    },
                    usedTodayIDs: env.dailyFortuneTracker.usedSystemIDs
                )
            }
            .adaptiveScreenPadding()
            .contentWidthConstraint()
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
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
                } else {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "sparkle")
                            .font(.caption2)
                        Text("1 クレジット消費")
                            .font(SorayomiTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.sorayomiSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.white.opacity(0.12))
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

    private var readingContent: some View {
        VStack(spacing: 0) {
            // おみくじ・六曜はヘッダー非表示（全画面儀式UI）
            if let system = viewModel.selectedSystem,
               !viewModel.showOmikujiReveal,
               !viewModel.showRokuyoReveal {
                compactSessionHeader(system)
                    .adaptiveScreenPadding()
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.xs)
            }

            if viewModel.showOmikujiReveal {
                OmikujiRevealView(
                    profile: env.userProfileService.currentProfile,
                    // nil = 新規ドラッグ抽選、non-nil = 当日保存済み結果の閲覧
                    storedResult: viewModel.omikujiResult,
                    onResultDetermined: { result in
                        viewModel.omikujiResultDetermined(result, env: env)
                    },
                    onDismiss: { viewModel.completeOmikuji(env: env) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.showBloodTypeModePicker {
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
            } else if viewModel.showNumerologyReveal,
                      let numEnergy = viewModel.numerologyEnergy,
                      let numProfile = viewModel.numerologyProfile {
                NumerologyRevealView(
                    energy: numEnergy,
                    profile: numProfile,
                    onComplete: {
                        Task {
                            await viewModel.completeNumerologyReveal(env: env)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.showNineStarKiReveal,
                      let kiProfile = viewModel.nineStarKiProfile,
                      let kiEnergy = viewModel.nineStarKiEnergy {
                NineStarKiRevealView(
                    profile: kiProfile,
                    energy: kiEnergy,
                    onComplete: {
                        Task {
                            await viewModel.completeNineStarKiReveal(env: env)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.showFlowerReveal,
                      let flowerProfile = viewModel.flowerProfile,
                      let flowerEnergy = viewModel.flowerDailyEnergy {
                FlowerRevealView(
                    flowerProfile: flowerProfile,
                    dailyEnergy: flowerEnergy,
                    onComplete: {
                        Task {
                            await viewModel.completeFlowerReveal(env: env)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.showStoneReveal,
                      let stoneProfile = viewModel.stoneProfile,
                      let stoneEnergy = viewModel.stoneDailyEnergy {
                StoneRevealView(
                    stoneProfile: stoneProfile,
                    dailyEnergy: stoneEnergy,
                    onComplete: {
                        Task {
                            await viewModel.completeStoneReveal(env: env)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.showZodiacReveal, let horoscope = viewModel.zodiacHoroscope {
                ZodiacRevealView(
                    sign: horoscope.sign,
                    horoscope: horoscope,
                    onComplete: {
                        Task {
                            await viewModel.completeZodiacReveal(env: env)
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
            } else if viewModel.showRokuyoReveal, let rokuyo = viewModel.rokuyoForReveal {
                RokuyoRevealView(
                    rokuyo: rokuyo,
                    onComplete: { viewModel.completeRokuyo() },
                    wasAlreadyUsedToday: viewModel.rokuyoAlreadyUsedToday,
                    onDraw: { viewModel.drawRokuyo(env: env) }
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
                    },
                    showPartnerBloodTypePicker: viewModel.selectedBloodTypeMode?.requiresPartner == true && viewModel.partnerBloodType == nil,
                    onSelectPartnerBloodType: { type in
                        viewModel.setPartnerBloodType(type, env: env)
                    },
                    showTopicSuggestions: viewModel.showTopicSuggestions,
                    onSelectTopic: { topic in
                        viewModel.selectSuggestedTopic(topic)
                    },
                    onShare: viewModel.sessionStage == .completed ? {
                        viewModel.showShareSheet = true
                    } : nil
                )
            }

            // Post-reading engagement prompt
            if viewModel.sessionStage == .completed && !viewModel.isGenerating {
                postReadingPrompt
                    .adaptiveScreenPadding()
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
                .adaptiveScreenPadding()
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
                HStack(spacing: Spacing.xs) {
                    Text(system.japaneseName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    // 消費クレジット表示
                    creditCostLabel(for: system)
                }

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

    // MARK: - Unsaved Notice

    private var unsavedReadingNotice: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "bookmark.slash.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.sorayomiTextSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("鑑定結果は未保存")
                    .font(SorayomiTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.sorayomiTextPrimary)
                Text("有償クレジットで継続すると保存されます")
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            Spacer(minLength: 0)

            NavigationLink(value: NavigationDestination.creditStore) {
                HStack(spacing: 3) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("ストアへ")
                        .font(SorayomiTypography.caption2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(Color.sorayomiSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Color.sorayomiSecondary.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.sorayomiSurface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous)
                .strokeBorder(Color.sorayomiDivider.opacity(0.55), lineWidth: 1)
        )
    }

    private var postReadingPrompt: some View {
        VStack(spacing: Spacing.xs) {
            // 無償クレジット鑑定の未保存通知
            if !viewModel.sessionUsedPaidCredit && !env.storeKitManager.isSubscribed {
                unsavedReadingNotice
            }

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

    /// セッションヘッダー内の消費クレジット表示ラベル
    @ViewBuilder
    private func creditCostLabel(for system: FortuneSystem) -> some View {
        let cost = system.creditCost
        HStack(spacing: 3) {
            Image(systemName: cost == 0 ? "gift.fill" : "sparkle")
                .font(.system(size: 8, weight: .bold))
            Text(cost == 0 ? "無料" : "消費: \(cost)クレジット")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(cost == 0 ? Color.sorayomiSuccess : Color.sorayomiAccent)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            (cost == 0 ? Color.sorayomiSuccess : Color.sorayomiAccent).opacity(0.10)
        )
        .clipShape(Capsule())
    }

    private func resetSession() {
        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.resetAllState()
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
