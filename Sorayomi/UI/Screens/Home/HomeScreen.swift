import SwiftUI

/// Main home screen with a stronger ritual-like flow and clearer next actions.
struct HomeScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = HomeViewModel()
    /// 本日鑑定済みのおみくじ結果をシートで表示
    @State private var showingStoredOmikuji = false
    /// おみくじを未引きで直接起動（導きページを経由しない）
    @State private var showingOmikujiDraw = false
    /// 六曜を未引きで直接起動（導きページを経由しない）
    @State private var showingRokuyoDraw = false

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Low credit upsell banner
                    if env.creditWalletService.totalAvailable <= 2 && !env.storeKitManager.isSubscribed {
                        lowCreditBanner
                    }

                    // Subscriber daily credit info
                    if env.storeKitManager.isSubscribed {
                        subscriberBadge
                    }

                    streakCard
                    todaySection
                    primaryActions
                }
                .adaptiveScreenPadding()
                .contentWidthConstraint()
                .padding(.bottom, Spacing.xxl)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                todayGuidancePill
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: NavigationDestination.creditStore) {
                    CreditBadge(
                        totalCredits: env.creditWalletService.totalAvailable,
                        freeCredits: env.creditWalletService.freeCreditsRemaining
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .task {
            env.dailyFortuneTracker.refreshIfNeeded()
            await viewModel.loadDailyFortune(env: env)
            env.streakManager.recordActivity()
        }
        .sheet(isPresented: $showingStoredOmikuji) {
            if let result = env.dailyFortuneTracker.todayOmikujiResult {
                OmikujiRevealView(
                    profile: env.userProfileService.currentProfile,
                    storedResult: result,
                    onResultDetermined: { _ in },
                    onDismiss: { showingStoredOmikuji = false }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        // おみくじ: 未引きのとき導きページを経由せず直接起動
        .fullScreenCover(isPresented: $showingOmikujiDraw) {
            OmikujiRevealView(
                profile: env.userProfileService.currentProfile,
                storedResult: nil,
                onResultDetermined: { result in
                    env.dailyFortuneTracker.storeOmikujiResult(result)
                    env.dailyFortuneTracker.markUsed(system: .omikuji)
                    env.analyticsService.track(.readingStarted(
                        system: FortuneSystem.omikuji.rawValue,
                        category: ReadingCategory.daily.rawValue
                    ))
                },
                onDismiss: { showingOmikujiDraw = false }
            )
        }
        // 六曜: 未引きのとき導きページを経由せず直接起動
        .fullScreenCover(isPresented: $showingRokuyoDraw) {
            RokuyoRevealView(
                rokuyo: viewModel.todayRokuyo,
                onComplete: { showingRokuyoDraw = false },
                wasAlreadyUsedToday: false,
                onDraw: {
                    env.dailyFortuneTracker.markUsed(system: .rokuyo)
                    env.analyticsService.track(.readingStarted(
                        system: FortuneSystem.rokuyo.rawValue,
                        category: ReadingCategory.daily.rawValue
                    ))
                }
            )
        }
    }

    private var lowCreditBanner: some View {
        NavigationLink(value: NavigationDestination.creditStore) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.diamond.fill")
                    .font(.title3)
                    .foregroundStyle(Color.sorayomiWarning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("クレジット残りわずか")
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    if env.creditWalletService.totalAvailable == 0 {
                        Text("クレジットを追加して鑑定を続けましょう")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                    } else {
                        Text("残り\(env.creditWalletService.totalAvailable)クレジット — プレミアムパスなら毎日届きます")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.sorayomiPrimary)
            }
            .padding(Spacing.md)
            .background(Color.sorayomiWarning.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(Color.sorayomiWarning.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var subscriberBadge: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "crown.fill")
                .font(.title3)
                .foregroundStyle(Color.sorayomiAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text(env.storeKitManager.activeSubscriptionDisplayName ?? "プレミアムパス")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text("毎月\(env.storeKitManager.monthlyCreditsAllowance)クレジットが届きます")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(Color.sorayomiSuccess)
        }
        .sorayomiPanel(tone: .elevated, padding: Spacing.md)
    }

    private var streakCard: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(
                    env.streakManager.currentStreak > 0
                        ? Color.orange
                        : Color.sorayomiTextSecondary.opacity(0.5)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(env.streakManager.streakDisplayText)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                if let next = env.streakManager.nextMilestoneInfo {
                    Text("あと\(next.days - env.streakManager.currentStreak)日で+\(next.credits)クレジット")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }
            }

            Spacer()

            if env.streakManager.currentStreak > 0 {
                Text("\(env.streakManager.currentStreak)")
                    .font(SorayomiTypography.metricNumber)
                    .foregroundStyle(Color.orange)
            }
        }
        .sorayomiPanel(tone: .elevated, padding: Spacing.md)
        .alert(
            "ストリーク報酬",
            isPresented: Binding(
                get: { env.streakManager.pendingMilestoneCredits != nil },
                set: { if !$0 { env.streakManager.clearPendingMilestone() } }
            )
        ) {
            Button("受け取る") {
            if let credits = env.streakManager.pendingMilestoneCredits {
                env.creditWalletService.grantStreakReward(credits)
            }
            env.streakManager.clearPendingMilestone()
        }
        } message: {
            if let credits = env.streakManager.pendingMilestoneCredits {
                Text("\(env.streakManager.currentStreak)日連続達成！\(credits)クレジットを獲得しました 🎉")
            }
        }
    }

    private var primaryActions: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle(
                eyebrow: "はじめる",
                title: "気になることから選ぶ",
                subtitle: "テーマを選ぶと、相性のいい占術でそのまま始められます。"
            )

            // 悩みベースの入口
            concernBasedEntry

            // 自由相談バナー（初回のみ）
            if env.freeTrialManager.isFirstConsultationAvailable {
                freeTrialConsultBanner
            }

            // 導きページへの誘導
            allSystemsLink
        }
    }

    /// 導きページ（全占術選択）へのナビゲーションリンク
    /// 既存のセッション状態をリセットしてから遷移する
    private var allSystemsLink: some View {
        Button {
            // おみくじ結果などの残存状態をクリアしてからReadingタブへ
            env.navigationRouter.shouldResetReading = true
            env.navigationRouter.navigate(to: .reading)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.sorayomiPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.sorayomiPrimary.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("占術を選んで相談する")
                        .font(SorayomiTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text("タロット・星座・数秘術など好みの占術を指定して相談")
                        .font(SorayomiTypography.caption2)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.sorayomiPrimary)
            }
            .padding(Spacing.md)
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(Color.sorayomiDivider.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }

    // MARK: - Concern-Based Entry

    private var concernBasedEntry: some View {
        AdaptiveGrid(compactColumns: 2, regularColumns: 3, spacing: Spacing.sm) {
            ForEach(concernEntries) { entry in
                ConcernEntryCard(entry: entry) {
                    env.analyticsService.track(.concernEntryTapped(concern: entry.analyticsKey))
                    startReading(system: entry.system, category: entry.category)
                }
            }
        }
    }

    private var concernEntries: [ConcernEntry] {
        [
            ConcernEntry(
                title: "恋愛・人間関係",
                subtitle: "気持ちの距離感、相性、次の一歩",
                symbol: "heart.fill",
                tint: .pink,
                system: .tarot,
                category: .love,
                analyticsKey: "love_relationships"
            ),
            ConcernEntry(
                title: "仕事・将来",
                subtitle: "転機の見極め、方向性、適職",
                symbol: "briefcase.fill",
                tint: .sorayomiPrimary,
                system: .nineStarKi,
                category: .career,
                analyticsKey: "career_future"
            ),
            ConcernEntry(
                title: "お金・暮らし",
                subtitle: "金運、引越し、生活の流れ",
                symbol: "yensign.circle.fill",
                tint: .sorayomiAccent,
                system: .numerology,
                category: .wealth,
                analyticsKey: "money_life"
            ),
            ConcernEntry(
                title: "自分を知る",
                subtitle: "性格、才能、今のリズム",
                symbol: "person.fill.questionmark",
                tint: .sorayomiSecondary,
                system: .birthdayPersonality,
                category: .personality,
                analyticsKey: "self_discovery"
            )
        ]
    }

    private var freeTrialConsultBanner: some View {
        Button {
            startReading(system: .generalConsultation, category: .general)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "gift.fill")
                    .font(.caption)
                    .foregroundStyle(Color.sorayomiAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("初回無料：なんでも自由に相談")
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text("恋愛・仕事・人間関係…テーマを決めずに話せます")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.sorayomiPrimary)
            }
            .padding(Spacing.md)
            .background(Color.sorayomiAccent.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(Color.sorayomiAccent.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle(
                eyebrow: "今日の流れ",
                title: "今日の空気をひと目で",
                subtitle: "おみくじ・運勢・六曜をまとめて確認できます。"
            )

            OmikujiSpotlightCard(
                omikuji: env.dailyFortuneTracker.todayOmikujiResult ?? viewModel.todayOmikuji,
                isDrawnToday: env.dailyFortuneTracker.todayOmikujiResult != nil,
                action: { startReading(system: .omikuji, category: .daily) },
                onViewResult: { showingStoredOmikuji = true }
            )

            dailyRhythmCard

            // 六曜：未引きはティーザーカード、引き済みはフルガジェット
            if env.dailyFortuneTracker.usedSystemIDs.contains(FortuneSystem.rokuyo.rawValue) {
                RokuyoBannerView(rokuyo: viewModel.todayRokuyo)
            } else {
                RokuyoTeaserCard {
                    startReading(system: .rokuyo, category: .daily)
                }
            }
        }
    }

    private var dailyRhythmCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if let dailyFortune = viewModel.dailyFortune {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        // 整えどころ：スコアをドット表示に
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("整えどころ")
                                .font(SorayomiTypography.caption)
                                .foregroundStyle(Color.sorayomiTextSecondary)

                            HStack(spacing: 5) {
                                ForEach(1...5, id: \.self) { i in
                                    Circle()
                                        .fill(i <= dailyFortune.overallScore
                                              ? Color.sorayomiPrimary
                                              : Color.sorayomiPrimary.opacity(0.15))
                                        .frame(width: 9, height: 9)
                                }
                            }

                            Text(scoreNarrative(for: dailyFortune.overallScore))
                                .font(SorayomiTypography.caption)
                                .foregroundStyle(Color.sorayomiTextSecondary)
                                .lineSpacing(3)
                        }

                        Spacer(minLength: 0)

                        // 今日のラッキーアイテム（おみくじ由来）
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            rhythmBadge(
                                icon: "paintpalette.fill",
                                title: "ラッキーカラー",
                                value: dailyFortune.luckyColor
                            )
                            rhythmBadge(
                                icon: "bag.fill",
                                title: "ラッキーアイテム",
                                value: dailyFortune.luckyItem
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()
                        .opacity(0.25)

                    // 今日のスコアに合わせたアクション誘導
                    rhythmActionRow(for: dailyFortune.overallScore)
                }
            } else {
                ProgressView()
                    .tint(Color.sorayomiPrimary)
                    .frame(maxWidth: .infinity, minHeight: 96)
            }
        }
        .sorayomiPanel(tone: .spotlight)
    }

    @ViewBuilder
    private func rhythmActionRow(for score: Int) -> some View {
        let (label, icon, system, category) = rhythmActionDetails(for: score)
        Button {
            startReading(system: system, category: category)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.sorayomiPrimary)
                    .frame(width: 28, height: 28)
                    .background(Color.sorayomiPrimary.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("今日のおすすめ")
                        .font(SorayomiTypography.caption2)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                    Text(label)
                        .font(SorayomiTypography.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.sorayomiTextPrimary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.sorayomiPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    private func rhythmActionDetails(
        for score: Int
    ) -> (label: String, icon: String, system: FortuneSystem, category: ReadingCategory) {
        switch score {
        case 5:
            return ("大きな決断をするなら今日 — タロットで確かめる",
                    "moon.stars.fill", .tarot, .general)
        case 4:
            return ("追い風に乗って気になることを相談する",
                    "sun.max.fill", .tarot, .general)
        case 3:
            return ("九星気学で今日の気の流れを確認する",
                    "compass.drawing", .nineStarKi, .career)
        default:
            return ("数秘術でじっくり自分のリズムを知る",
                    "leaf.fill", .numerology, .personality)
        }
    }

    private var heroNarrative: String {
        if let fortune = viewModel.dailyFortune {
            return "今日は\(scoreNarrative(for: fortune.overallScore))。気になるテーマから始めてみましょう。"
        }
        return "\(viewModel.seasonalContext.solarTerm)の時期にぴったりの導きを用意しました。"
    }

    private var heroTitle: String {
        if let nickname = env.userProfileService.currentProfile?.nickname, !nickname.isEmpty {
            return "\(nickname)さんの今日の導き"
        }
        return "今日の導き"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（EEEE）"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: Date())
    }

    /// ナビバー用の短い日付表示（例: 5月3日（土））
    private var formattedDateShort: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: Date())
    }

    /// ナビバー左（.topBarLeading）に表示する横長ピル。
    /// CreditBadge と同じ vertical padding・フォントサイズでY軸の高さを揃える。
    private var todayGuidancePill: some View {
        HStack(spacing: 4) {
            Text(formattedDateShort)
                .foregroundColor(Color.sorayomiTextPrimary)

            Text("·")
                .foregroundColor(Color.sorayomiTextSecondary.opacity(0.4))

            Text(viewModel.seasonalContext.solarTerm)
                .foregroundColor(Color.sorayomiTextSecondary)

            if let rank = env.dailyFortuneTracker.todayOmikujiResult?.rank.japaneseName {
                Text("·")
                    .foregroundColor(Color.sorayomiTextSecondary.opacity(0.4))
                Text(rank)
                    .foregroundColor(Color.sorayomiAccent)
                    .fontWeight(.semibold)
            }
        }
        .font(.system(size: 12, weight: .medium))
        .fixedSize()
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.sorayomiPrimary.opacity(0.07)))
        .overlay(Capsule().strokeBorder(Color.sorayomiPrimary.opacity(0.16), lineWidth: 0.5))
    }

    private func sectionTitle(eyebrow: String, title: String, subtitle: String) -> some View {
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

    private func rhythmBadge(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.sorayomiAccent)
                .frame(width: 26, height: 26)
                .background(Color.sorayomiAccent.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)

                Text(value)
                    .font(SorayomiTypography.subheadline)
                    .foregroundStyle(Color.sorayomiTextPrimary)
                    .lineSpacing(4)
            }
        }
    }

    private func scoreNarrative(for score: Int) -> String {
        switch score {
        case 5:
            return "気持ちよく背中を押されやすい日です"
        case 4:
            return "静かに追い風が吹きやすい日です"
        case 3:
            return "整え方しだいで印象が大きく変わる日です"
        default:
            return "無理に急がず、足元を整えるほど良い日です"
        }
    }

    private func startReading(system: FortuneSystem, category: ReadingCategory) {
        // 1日1回制限の無料コンテンツは再使用不可（usedSystemIDs を直接参照）
        guard !env.dailyFortuneTracker.usedSystemIDs.contains(system.rawValue) else { return }

        switch system {
        case .omikuji:
            // 導きページを経由せずホームから直接全画面表示
            showingOmikujiDraw = true
        case .rokuyo:
            // 導きページを経由せずホームから直接全画面表示
            showingRokuyoDraw = true
        default:
            env.navigationRouter.pendingFortuneSystem = system
            env.navigationRouter.pendingReadingCategory = category
            env.navigationRouter.navigate(to: .reading)
        }
    }
}

// MARK: - Concern Entry Models

private struct ConcernEntry: Identifiable {
    var id: String { analyticsKey }
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let system: FortuneSystem
    let category: ReadingCategory
    let analyticsKey: String
}

private struct ConcernEntryCard: View {
    let entry: ConcernEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(entry.tint)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

                Text(entry.title)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(entry.subtitle)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: Spacing.xs)

                HStack {
                    Spacer()
                    CreditCostTag(system: entry.system)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .sorayomiPanel(tone: .elevated, padding: Spacing.md)
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }
}

// MARK: - Credit Cost Tag

/// カード下部に表示するクレジット消費バッジ
private struct CreditCostTag: View {
    let system: FortuneSystem

    var body: some View {
        Group {
            if system.creditCost == 0 {
                Text("無料")
                    .foregroundStyle(Color.sorayomiSuccess)
                    .background(Color.sorayomiSuccess.opacity(0.10))
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 7, weight: .bold))
                    Text("\(system.creditCost)")
                }
                .foregroundStyle(Color.sorayomiSecondary)
                .background(Color.sorayomiSecondary.opacity(0.10))
            }
        }
        .font(SorayomiTypography.caption2)
        .fontWeight(.bold)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .clipShape(Capsule())
    }
}

// MARK: - Rokuyo Teaser Card

/// 六曜未引き時にホーム画面に表示するティーザーカード。
/// OmikujiSpotlightCard の未引き状態と同じ視覚言語で統一。
private struct RokuyoTeaserCard: View {
    let action: () -> Void

    @State private var ringRotation: Double = 0
    @State private var glowPulse: CGFloat = 1.0
    @State private var arrowOffset: CGFloat = 0

    private let goldColor = Color(red: 1.0, green: 0.86, blue: 0.46)

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {

                // 暦スタンプアニメーション（左）
                ZStack {
                    Circle()
                        .fill(goldColor.opacity(0.10))
                        .frame(width: 104, height: 104)
                        .blur(radius: 14)
                        .scaleEffect(glowPulse)

                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    goldColor.opacity(0.9),
                                    goldColor.opacity(0.15),
                                    goldColor.opacity(0.9),
                                    goldColor.opacity(0.15),
                                    goldColor.opacity(0.9)
                                ],
                                center: .center
                            ),
                            lineWidth: 1.2
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(ringRotation))

                    Circle()
                        .fill(Color(red: 0.12, green: 0.06, blue: 0.26))
                        .frame(width: 64, height: 64)

                    Text("暦")
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [goldColor.opacity(0.95), goldColor.opacity(0.65)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: goldColor.opacity(0.4), radius: 6)
                }
                .frame(width: 96, height: 96)

                // テキスト + CTA（右）
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("今日の六曜")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(.white.opacity(0.65))

                        Text("今日の暦を確かめる")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                    }

                    Text("吉凶・時間帯の運気・行事の向き不向き")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(.white.opacity(0.80))
                        .lineSpacing(3)

                    HStack(spacing: 4) {
                        Text("六曜を見る")
                            .font(SorayomiTypography.footnote)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .offset(x: arrowOffset)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.06, blue: 0.24),
                        Color(red: 0.16, green: 0.10, blue: 0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(goldColor.opacity(0.20), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
            .shadow(
                color: Color(red: 0.10, green: 0.06, blue: 0.24).opacity(0.45),
                radius: 18, x: 0, y: 8
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .onAppear(perform: startAnimations)
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            glowPulse = 1.22
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.4)) {
            arrowOffset = 3
        }
    }
}

#Preview {
    HomeScreen()
        .environment(AppEnvironment())
}
