import SwiftUI

/// History screen redesigned as a reflective archive instead of a plain list.
struct HistoryScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = HistoryViewModel()
    @State private var readingToDelete: FortuneReading?
    @State private var isSelectMode = false
    @State private var selectedIds: Set<String> = []
    @State private var showBulkDeleteConfirmation = false

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

                                // プレミアム限定の全履歴アクセス
                                if !env.storeKitManager.isSubscribed
                                    && env.featureFlags.isHistoryPremiumOnly
                                    && viewModel.readings.count > 3 {
                                    premiumHistoryUpsell
                                }
                            }
                        }
                        .adaptiveScreenPadding()
                        .contentWidthConstraint()
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
            await viewModel.loadReadings(env: env)
        }
        // 単体削除の確認ダイアログ
        .alert("この鑑定を削除しますか？", isPresented: Binding(
            get: { readingToDelete != nil },
            set: { if !$0 { readingToDelete = nil } }
        )) {
            Button("削除", role: .destructive) {
                if let reading = readingToDelete {
                    Task {
                        await viewModel.deleteReading(id: reading.id, env: env)
                    }
                    readingToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                readingToDelete = nil
            }
        } message: {
            if let reading = readingToDelete {
                Text("\(reading.displayTitle)の鑑定記録が完全に削除されます。")
            }
        }
        // 一括削除の確認ダイアログ
        .alert("\(selectedIds.count)件の鑑定を削除しますか？", isPresented: $showBulkDeleteConfirmation) {
            Button("すべて削除", role: .destructive) {
                Task {
                    for id in selectedIds {
                        await viewModel.deleteReading(id: id, env: env)
                    }
                    selectedIds.removeAll()
                    isSelectMode = false
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("選択した\(selectedIds.count)件の鑑定記録が完全に削除されます。この操作は元に戻せません。")
        }
    }

    private var premiumHistoryUpsell: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(Color.sorayomiAccent)

            Text("すべての履歴を振り返る")
                .font(SorayomiTypography.headline)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Text("月間プレミアムなら、過去の鑑定をすべて閲覧できます")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)
                .multilineTextAlignment(.center)

            NavigationLink(value: NavigationDestination.creditStore) {
                Text("プレミアムを見る")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        LinearGradient(
                            colors: [.sorayomiPrimary, .sorayomiAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .sorayomiPanel(tone: .spotlight)
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
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("鑑定を振り返る")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(.white)

                Text(heroSubtitle)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            HStack(spacing: Spacing.xs) {
                archiveBadge(title: "累計", value: "\(viewModel.readings.count)件")
                archiveBadge(title: "今月", value: "\(monthlyReadingCount)件")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sorayomiPanel(tone: .night, padding: Spacing.md)
    }

    private var archiveStats: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "傾向",
                title: "最近の傾向",
                subtitle: "よく相談するテーマや最近の鑑定がひと目でわかります。"
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
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("履歴".uppercased())
                        .font(SorayomiTypography.eyebrow)
                        .foregroundStyle(Color.sorayomiAccent)

                    Text("鑑定アーカイブ")
                        .font(SorayomiTypography.title2)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text("過去の鑑定はいつでも見返せます。")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !viewModel.readings.isEmpty {
                    Button {
                        withAnimation {
                            isSelectMode.toggle()
                            if !isSelectMode {
                                selectedIds.removeAll()
                            }
                        }
                    } label: {
                        Text(isSelectMode ? "完了" : "選択")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiPrimary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.sorayomiPrimary.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }

            // 選択モード時の一括削除ボタン
            if isSelectMode && !selectedIds.isEmpty {
                Button {
                    showBulkDeleteConfirmation = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("\(selectedIds.count)件を削除")
                            .font(SorayomiTypography.headline)
                    }
                    .foregroundStyle(Color.sorayomiError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.sorayomiError.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                            .stroke(Color.sorayomiError.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.readings) { reading in
                    if isSelectMode {
                        // 選択モード: チェックボックス付き
                        Button {
                            toggleSelection(reading.id)
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: selectedIds.contains(reading.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedIds.contains(reading.id) ? Color.sorayomiPrimary : Color.sorayomiTextSecondary.opacity(0.4))

                                HistoryRowView(reading: reading)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        // 通常モード: タップで詳細表示
                        NavigationLink(value: ReadingDetailDestination(reading: reading)) {
                            HistoryRowView(reading: reading) {
                                readingToDelete = reading
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(
                eyebrow: "はじめての鑑定",
                title: "まだ記録がありません",
                subtitle: "鑑定を受けると、ここに記録が残ります。"
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("おすすめの始め方")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                EmptyArchiveStep(
                    icon: "heart.fill",
                    title: "恋愛や相性を見る",
                    detail: "気になる相手との距離感に迷ったときに。"
                )
                EmptyArchiveStep(
                    icon: "briefcase.fill",
                    title: "仕事の転機を聞く",
                    detail: "動くべき時期や方向性を整理したいときに。"
                )
                EmptyArchiveStep(
                    icon: "sparkles",
                    title: "今日の流れを整える",
                    detail: "特に悩みがなくても、気分を整えたいときに。"
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
            return "鑑定を始めると、ここに記録が残ります。"
        }

        return "最近は\(mostUsedThemeName)をよく見ています。"
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
