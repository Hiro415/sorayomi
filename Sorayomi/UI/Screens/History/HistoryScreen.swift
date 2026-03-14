import SwiftUI

/// History screen redesigned as a reflective archive instead of a plain list.
struct HistoryScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            Group {
                if viewModel.isLoading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            archiveHero

                            if viewModel.readings.isEmpty {
                                emptyStateView
                            } else {
                                archiveStats
                                readingsTimeline
                            }
                        }
                        .padding(.horizontal, Spacing.screenPadding)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.xxl)
                    }
                    .refreshable {
                        await viewModel.loadReadings(env: env)
                    }
                }
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
            await viewModel.loadReadings(env: env)
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Color.sorayomiPrimary)
            Text("記録を整えています...")
                .font(SorayomiTypography.callout)
                .foregroundStyle(Color.sorayomiTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var archiveHero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("鑑定を振り返る")
                    .font(SorayomiTypography.title2)
                    .foregroundStyle(.white)

                Text(heroSubtitle)
                    .font(SorayomiTypography.callout)
                    .foregroundStyle(Color.white.opacity(0.86))
                    .lineSpacing(5)
            }

            HStack(spacing: Spacing.xs) {
                archiveBadge(title: "累計", value: "\(viewModel.readings.count)件")
                archiveBadge(title: "今月", value: "\(monthlyReadingCount)件")
                archiveBadge(title: "最多", value: mostUsedSystemName)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sorayomiPanel(tone: .night, padding: Spacing.lg)
    }

    private var archiveStats: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "傾向",
                title: "最近の傾向",
                subtitle: "よく見るテーマや、最後に鑑定したタイミングがすぐ分かるようにしています。"
            )

            HStack(spacing: Spacing.sm) {
                archiveMetric(
                    title: "最後の鑑定",
                    value: latestReadingLabel,
                    icon: "clock.fill",
                    tint: .sorayomiAccent
                )
                archiveMetric(
                    title: "多いテーマ",
                    value: mostUsedThemeName,
                    icon: "sparkles",
                    tint: .sorayomiPrimary
                )
            }
        }
    }

    private var readingsTimeline: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "履歴",
                title: "鑑定アーカイブ",
                subtitle: "過去の読みは削除するまでここに残り、後から見返せます。"
            )

            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.readings) { reading in
                    HistoryRowView(reading: reading) {
                        Task {
                            await viewModel.deleteReading(id: reading.id, env: env)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(
                eyebrow: "はじめての鑑定",
                title: "まだ記録がありません",
                subtitle: "最初の鑑定を受けると、ここに対話の履歴が少しずつ積み上がっていきます。"
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("おすすめの始め方")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                EmptyArchiveStep(
                    icon: "heart.fill",
                    title: "恋愛や相性を見る",
                    detail: "相手との距離感や迷いがあるときに向いています。"
                )
                EmptyArchiveStep(
                    icon: "briefcase.fill",
                    title: "仕事の転機を聞く",
                    detail: "動くべき時期や優先順位を整理したいときに便利です。"
                )
                EmptyArchiveStep(
                    icon: "sparkles",
                    title: "今日の流れを整える",
                    detail: "大きな悩みがなくても、気分を整える入り口として使えます。"
                )

                Button {
                    env.navigationRouter.navigate(to: .reading)
                } label: {
                    Text("鑑定を始める")
                        .sorayomiButton()
                }
                .buttonStyle(.plain)
            }
        }
        .sorayomiPanel(tone: .spotlight)
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

    private func archiveBadge(title: String, value: String) -> some View {
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

    private func archiveMetric(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.10))
                .clipShape(Circle())

            Text(title)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)

            Text(value)
                .font(SorayomiTypography.headline)
                .foregroundStyle(Color.sorayomiTextPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .sorayomiPanel(tone: .elevated, padding: Spacing.md)
    }

    private var heroSubtitle: String {
        if viewModel.readings.isEmpty {
            return "鑑定を始めると、ここに対話の記録が残ります。"
        }

        return "最近は\(mostUsedThemeName)をよく見ています。気になったときにすぐ見返せます。"
    }

    private var latestReadingLabel: String {
        guard let latest = viewModel.readings.first?.createdAt else {
            return "まだありません"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: latest, relativeTo: Date())
    }

    private var monthlyReadingCount: Int {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        return viewModel.readings.filter {
            calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month)
        }.count
    }

    private var mostUsedSystemName: String {
        let grouped = Dictionary(grouping: viewModel.readings, by: \.system)
        return grouped.max { $0.value.count < $1.value.count }?.key.shortName ?? "未使用"
    }

    private var mostUsedThemeName: String {
        let grouped = Dictionary(grouping: viewModel.readings, by: \.theme)
        return grouped.max { $0.value.count < $1.value.count }?.key.japaneseName ?? "まだありません"
    }
}

private struct EmptyArchiveStep: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.sorayomiAccent)
                .frame(width: 30, height: 30)
                .background(Color.sorayomiAccent.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(detail)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        HistoryScreen()
            .environment(AppEnvironment())
    }
}
