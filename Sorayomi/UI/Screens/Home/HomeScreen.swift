import SwiftUI

/// Main home screen with a stronger ritual-like flow and clearer next actions.
struct HomeScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    welcomeHero
                    primaryActions
                    todaySection
                    shortcutDeck
                    QuickAccessGrid(
                        systems: FortuneSystem.showcaseOrder,
                        onSelect: { system in
                            startReading(system: system, category: .general)
                        }
                    )
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CreditBadge(
                    totalCredits: env.creditWalletService.totalAvailable,
                    freeCredits: env.creditWalletService.freeCreditsRemaining
                )
            }
        }
        .task {
            await viewModel.loadDailyFortune(env: env)
        }
    }

    private var welcomeHero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(formattedDate)
                .font(SorayomiTypography.eyebrow)
                .foregroundStyle(Color.white.opacity(0.72))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(heroTitle)
                    .font(SorayomiTypography.title)
                    .foregroundStyle(.white)

                Text(heroNarrative)
                    .japaneseText(SorayomiTypography.callout, lineSpacing: 6)
                    .foregroundStyle(Color.white.opacity(0.86))
            }

            HStack(spacing: Spacing.xs) {
                heroPill(title: "季節", value: viewModel.seasonalContext.season)
                heroPill(title: "節気", value: viewModel.seasonalContext.solarTerm)
                heroPill(title: "本日", value: viewModel.todayOmikuji.rank.japaneseName)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sorayomiPanel(tone: .night, padding: Spacing.lg)
    }

    private var primaryActions: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle(
                eyebrow: "すぐ始める",
                title: "今の気分に合う入口",
                subtitle: "さっと流れを見るか、相談からじっくり入るかをここで選べます。"
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.sm) {
                    primaryActionCard(
                        title: "今日の運を見る",
                        subtitle: "おみくじから、今の空気を手早く確かめる",
                        symbol: "sparkles.rectangle.stack.fill",
                        tint: .sorayomiAccent
                    ) {
                        startReading(system: .omikuji, category: .daily)
                    }

                    primaryActionCard(
                        title: "相談を始める",
                        subtitle: "恋愛や仕事など、気になるテーマから入る",
                        symbol: "bubble.left.and.bubble.right.fill",
                        tint: .sorayomiPrimary
                    ) {
                        env.navigationRouter.navigate(to: .reading)
                    }
                }

                VStack(spacing: Spacing.sm) {
                    primaryActionCard(
                        title: "今日の運を見る",
                        subtitle: "おみくじから、今の空気を手早く確かめる",
                        symbol: "sparkles.rectangle.stack.fill",
                        tint: .sorayomiAccent
                    ) {
                        startReading(system: .omikuji, category: .daily)
                    }

                    primaryActionCard(
                        title: "相談を始める",
                        subtitle: "恋愛や仕事など、気になるテーマから入る",
                        symbol: "bubble.left.and.bubble.right.fill",
                        tint: .sorayomiPrimary
                    ) {
                        env.navigationRouter.navigate(to: .reading)
                    }
                }
            }
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle(
                eyebrow: "今日の流れ",
                title: "まずは今日の空気を確認",
                subtitle: "おみくじ、運の整えどころ、六曜をまとめて見られます。"
            )

            OmikujiSpotlightCard(omikuji: viewModel.todayOmikuji) {
                startReading(system: .omikuji, category: .daily)
            }

            dailyRhythmCard
            RokuyoBannerView(rokuyo: viewModel.todayRokuyo)
        }
    }

    private var dailyRhythmCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if let dailyFortune = viewModel.dailyFortune {
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("整えどころ")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary)

                        Text("\(dailyFortune.overallScore)/5")
                            .font(SorayomiTypography.metricNumber)
                            .foregroundStyle(Color.sorayomiPrimary)

                        Text(scoreNarrative(for: dailyFortune.overallScore))
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        rhythmBadge(
                            icon: "sparkles",
                            title: "気分の鍵",
                            value: dailyFortune.horoscopeSnippet
                        )
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
            } else {
                ProgressView()
                    .tint(Color.sorayomiPrimary)
                    .frame(maxWidth: .infinity, minHeight: 96)
            }
        }
        .sorayomiPanel(tone: .spotlight)
    }

    private var shortcutDeck: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle(
                eyebrow: "人気テーマ",
                title: "迷ったときの入口",
                subtitle: "よくある相談から入ると、占術選びで迷いにくくなります。"
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.sm),
                    GridItem(.flexible(), spacing: Spacing.sm)
                ],
                spacing: Spacing.sm
            ) {
                ForEach(themeShortcuts) { shortcut in
                    ThemeShortcutCard(shortcut: shortcut) {
                        startReading(system: shortcut.system, category: shortcut.category)
                    }
                }
            }
        }
    }

    private var themeShortcuts: [ThemeShortcut] {
        [
            ThemeShortcut(
                title: "恋愛・相性",
                subtitle: "人気のタロットで気持ちの流れと距離感を丁寧に確認",
                symbol: "heart.fill",
                system: .tarot,
                category: .love
            ),
            ThemeShortcut(
                title: "仕事・転機",
                subtitle: "九星気学で今の巡りと、動き出すべき時期を読む",
                symbol: "briefcase.fill",
                system: .nineStarKi,
                category: .career
            ),
            ThemeShortcut(
                title: "金運・開運",
                subtitle: "おみくじで今日のお金の使い方と整え方を受け取る",
                symbol: "yensign.circle.fill",
                system: .omikuji,
                category: .wealth
            ),
            ThemeShortcut(
                title: "今日の流れ",
                subtitle: "星座の流れから、いまの空気とペース配分を知る",
                symbol: "sun.max.fill",
                system: .horoscope,
                category: .daily
            )
        ]
    }

    private var heroNarrative: String {
        if let fortune = viewModel.dailyFortune {
            return "今日は\(scoreNarrative(for: fortune.overallScore))。流れを見るか、気になるテーマから始めましょう。"
        }
        return "\(viewModel.seasonalContext.solarTerm)に合う導きを用意しています。"
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

    private func primaryActionCard(
        title: String,
        subtitle: String,
        symbol: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(tint)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text(subtitle)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .lineSpacing(4)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(Color.sorayomiPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
            .sorayomiPanel(tone: .elevated, padding: Spacing.md)
        }
        .buttonStyle(.plain)
    }

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.white.opacity(0.68))

            Text(value)
                .font(SorayomiTypography.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.white.opacity(0.10))
        .clipShape(Capsule())
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
        env.navigationRouter.pendingFortuneSystem = system
        env.navigationRouter.pendingReadingCategory = category
        env.navigationRouter.navigate(to: .reading)
    }
}

private struct ThemeShortcut: Identifiable {
    var id: String { title }
    let title: String
    let subtitle: String
    let symbol: String
    let system: FortuneSystem
    let category: ReadingCategory
}

private struct ThemeShortcutCard: View {
    let shortcut: ThemeShortcut
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    Image(systemName: shortcut.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [.sorayomiAccent, .sorayomiPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(Color.sorayomiPrimary)
                }

                Text(shortcut.title)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(shortcut.subtitle)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack(spacing: Spacing.xs) {
                    Text(shortcut.system.shortName)
                        .font(SorayomiTypography.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.sorayomiAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.sorayomiAccent.opacity(0.10))
                        .clipShape(Capsule())

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .sorayomiPanel(tone: .elevated, padding: Spacing.md)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeScreen()
        .environment(AppEnvironment())
}
