import SwiftUI
import PhotosUI

/// Profile screen rebuilt around personal identity, readiness, and shortcuts.
struct ProfileScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = ProfileViewModel()
    @State private var isEditingNickname = false
    @State private var editedNickname = ""
    @State private var isEditingBirthday = false
    @State private var editedBirthday = Date()
    @State private var isEditingBloodType = false
    @State private var isEditingFavorites = false

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    profileHero
                    profileSnapshot
                    favoritesSection
                    creditSection
                    settingsSection
                }
                .adaptiveScreenPadding()
                .contentWidthConstraint()
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .task {
            viewModel.loadProfile(env: env)
        }
        .alert("ニックネームを変更", isPresented: $isEditingNickname) {
            TextField("ニックネーム", text: $editedNickname)
            Button("保存") {
                viewModel.updateNickname(env: env, name: editedNickname)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("新しいニックネームを入力してください")
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                viewModel.saveProfilePhoto(env: env)
            }
        }
    }

    private var profileHero: some View {
        let profileImage = viewModel.profileImage
        let completionScore = profileCompletionScore

        return HStack(alignment: .center, spacing: Spacing.sm) {
            PhotosPicker(
                selection: Binding(
                    get: { viewModel.selectedPhotoItem },
                    set: { viewModel.selectedPhotoItem = $0 }
                ),
                matching: .images,
                photoLibrary: .shared()
            ) {
                ProfileAvatarView(profileImage: profileImage, size: 60, completionScore: completionScore)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(viewModel.profile?.displayName ?? "ゲスト")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(.white)

                heroBadge(title: "星座", value: viewModel.profile?.zodiacSign?.japaneseName ?? "未設定")
            }

            Spacer(minLength: 0)

            Button {
                editedNickname = viewModel.profile?.nickname ?? ""
                isEditingNickname = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sorayomiPanel(tone: .night, padding: Spacing.md)
    }

    private var profileSnapshot: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "基本情報",
                title: "あなたの基本データ",
                subtitle: "鑑定の精度に関わる基本情報です。"
            )

            VStack(spacing: Spacing.sm) {
                Button {
                    editedBirthday = viewModel.profile?.birthday
                        ?? Calendar.current.date(byAdding: .year, value: -25, to: Date())!
                    isEditingBirthday = true
                } label: {
                    editableDetailRow(
                        label: "誕生日",
                        value: formattedBirthday,
                        icon: "birthday.cake.fill"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isEditingBloodType = true
                } label: {
                    editableDetailRow(
                        label: "血液型",
                        value: viewModel.profile?.bloodType?.japaneseName ?? "未設定",
                        icon: "drop.fill"
                    )
                }
                .buttonStyle(.plain)

                profileDetailRow(
                    label: "星座",
                    value: viewModel.profile?.zodiacSign?.japaneseName ?? "未設定",
                    icon: "sparkles"
                )
            }
        }
        .sorayomiPanel(tone: .spotlight)
        .sheet(isPresented: $isEditingBirthday) {
            birthdayEditSheet
        }
        .sheet(isPresented: $isEditingBloodType) {
            bloodTypeEditSheet
        }
    }

    // MARK: - Birthday Edit Sheet

    private var birthdayEditSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Spacer()
                DatePicker(
                    "誕生日",
                    selection: $editedBirthday,
                    in: birthdayRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ja_JP"))
                Spacer()
            }
            .navigationTitle("誕生日を変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isEditingBirthday = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.updateBirthday(env: env, date: editedBirthday)
                        isEditingBirthday = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Blood Type Edit Sheet

    private var bloodTypeEditSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Spacer()
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Spacing.sm
                ) {
                    ForEach(BloodType.allCases) { type in
                        let isSelected = viewModel.profile?.bloodType == type
                        Button {
                            viewModel.updateBloodType(env: env, type: type)
                            isEditingBloodType = false
                        } label: {
                            VStack(spacing: Spacing.xs) {
                                Text(type.rawValue)
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                Text(type.shortDescription)
                                    .font(SorayomiTypography.caption)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                                    .fill(isSelected ? Color.sorayomiPrimary.opacity(0.12) : Color.sorayomiSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                                    .strokeBorder(
                                        isSelected ? Color.sorayomiPrimary : Color.sorayomiDivider,
                                        lineWidth: isSelected ? 2 : 1
                                    )
                            )
                            .foregroundStyle(isSelected ? Color.sorayomiPrimary : Color.sorayomiTextPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                Spacer()
            }
            .navigationTitle("血液型を変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isEditingBloodType = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var birthdayRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let min = calendar.date(byAdding: .year, value: -100, to: Date())!
        let max = calendar.date(byAdding: .year, value: -13, to: Date())!
        return min...max
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                sectionHeader(
                    eyebrow: "お気に入り",
                    title: "よく使う占い",
                    subtitle: "タップするとすぐに占いを始められます。"
                )
                Spacer(minLength: Spacing.sm)
                Button {
                    isEditingFavorites = true
                } label: {
                    Text(favoriteSystems.isEmpty ? "追加" : "編集")
                        .font(SorayomiTypography.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.sorayomiPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(Color.sorayomiPrimary.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if favoriteSystems.isEmpty {
                // Empty state
                VStack(spacing: Spacing.md) {
                    Text("よく使う占いを登録しておくと、ここからすぐに呼び出せます。")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .lineSpacing(4)

                    Button {
                        isEditingFavorites = true
                    } label: {
                        Label("占いを追加する", systemImage: "plus")
                            .font(SorayomiTypography.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.sorayomiPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                                    .strokeBorder(Color.sorayomiPrimary.opacity(0.35), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Favorite system rows
                VStack(spacing: 0) {
                    ForEach(Array(favoriteSystems.enumerated()), id: \.element.id) { index, system in
                        VStack(spacing: 0) {
                            if index > 0 {
                                Divider().opacity(0.25)
                            }
                            Button {
                                launchFavoriteSystem(system)
                            } label: {
                                favoriteSystemRow(system)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sorayomiPanel(tone: .elevated)
        .sheet(isPresented: $isEditingFavorites) {
            FavoritesEditorSheet()
        }
    }

    private func favoriteSystemRow(_ system: FortuneSystem) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: system.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.sorayomiAccent)
                .frame(width: 34, height: 34)
                .background(Color.sorayomiAccent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(system.shortName)
                    .font(SorayomiTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.sorayomiTextPrimary)
                Text(system.japaneseDescription)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Credit cost badge
            if system.creditCost == 0 {
                Text("無料")
                    .font(SorayomiTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.sorayomiSuccess)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.sorayomiSuccess.opacity(0.10))
                    .clipShape(Capsule())
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 7, weight: .bold))
                    Text("\(system.creditCost)")
                        .font(SorayomiTypography.caption2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(Color.sorayomiSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.sorayomiSecondary.opacity(0.10))
                .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.4))
        }
        .padding(.vertical, Spacing.sm)
    }

    private var creditSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "クレジット",
                title: "クレジット状況",
                subtitle: "鑑定に使えるクレジットの残高です。"
            )

            HStack(alignment: .center, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("利用可能")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                        Text("\(env.creditWalletService.totalAvailable)")
                            .font(SorayomiTypography.metricNumber)
                            .foregroundStyle(Color.sorayomiPrimary)
                        Text("クレジット")
                            .font(SorayomiTypography.callout)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                    }

                    if env.creditWalletService.freeCreditsRemaining > 0 {
                        Text("無料クレジット残り \(env.creditWalletService.freeCreditsRemaining) 回")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiSuccess)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer()

                NavigationLink {
                    StoreScreen()
                        .environment(env)
                } label: {
                    Text("ストアを見る")
                        .sorayomiGoldButton()
                        .frame(width: 160)
                }
                .buttonStyle(.plain)
            }
        }
        .sorayomiPanel(tone: .spotlight)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "設定",
                title: "設定とサポート",
                subtitle: "通知やアプリ情報を確認できます。"
            )

            VStack(spacing: Spacing.sm) {
                NavigationLink {
                    SettingsScreen()
                        .environment(env)
                } label: {
                    settingsCard(
                        title: "アプリ設定",
                        detail: "通知やアプリ情報の設定",
                        icon: "gearshape.fill",
                        tint: .sorayomiPrimary
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    StoreScreen()
                        .environment(env)
                } label: {
                    settingsCard(
                        title: "クレジットストア",
                        detail: "クレジットの購入と復元",
                        icon: "sparkle",
                        tint: .sorayomiSecondary
                    )
                }
                .buttonStyle(.plain)
            }
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

    private func heroBadge(title: String, value: String) -> some View {
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

    private func editableDetailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(Color.sorayomiAccent)
                .frame(width: 28, height: 28)
                .background(Color.sorayomiAccent.opacity(0.10))
                .clipShape(Circle())

            Text(label)
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Spacer()

            Text(value)
                .font(SorayomiTypography.subheadline)
                .foregroundStyle(Color.sorayomiTextSecondary)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
        }
        .padding(.vertical, Spacing.xs)
    }

    private func profileDetailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(Color.sorayomiAccent)
                .frame(width: 28, height: 28)
                .background(Color.sorayomiAccent.opacity(0.10))
                .clipShape(Circle())

            Text(label)
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Spacer()

            Text(value)
                .font(SorayomiTypography.subheadline)
                .foregroundStyle(Color.sorayomiTextSecondary)
        }
        .padding(.vertical, Spacing.xs)
    }

    /// お気に入りの占術からリーディングを起動
    private func launchFavoriteSystem(_ system: FortuneSystem) {
        let category: ReadingCategory
        switch system {
        case .omikuji, .rokuyo, .horoscope, .bloodType, .birthdayPersonality,
             .flowerFortune, .stoneFortune:
            category = .daily
        case .tarot, .generalConsultation:
            category = .general
        case .nineStarKi:
            category = .career
        case .numerology:
            category = .personality
        }
        env.navigationRouter.pendingFortuneSystem = system
        env.navigationRouter.pendingReadingCategory = category
        env.navigationRouter.navigate(to: .reading)
    }

    private var favoriteSystems: [FortuneSystem] {
        env.userProfileService.currentProfile?.favoriteSystems ?? []
    }

    private func settingsCard(title: String, detail: String, icon: String, tint: Color) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(detail)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.6))
        }
        .sorayomiPanel(tone: .elevated, padding: Spacing.md)
    }

    /// プロフィール完成スコア (0.0 – 1.0): ニックネーム/誕生日/血液型 各1/3
    private var profileCompletionScore: Double {
        var count = 0
        if viewModel.profile?.nickname != nil { count += 1 }
        if viewModel.profile?.birthday != nil { count += 1 }
        if viewModel.profile?.bloodType != nil { count += 1 }
        return count == 0 ? 0.0 : Double(count) / 3.0
    }

    private var formattedBirthday: String {
        guard let birthday = viewModel.profile?.birthday else { return "未設定" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        return formatter.string(from: birthday)
    }
}

private struct ProfileAvatarView: View {
    let profileImage: UIImage?
    var size: CGFloat = 90
    var completionScore: Double = 0.0

    private var iconFontSize: CGFloat { size * 0.87 }
    private var cameraBadgeSize: CGFloat { max(22, size * 0.31) }
    private var ringSize: CGFloat { size + 7 }
    private let ringLineWidth: CGFloat = 3

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            if let profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: iconFontSize))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .frame(width: size, height: size)
            }

            // Camera badge
            Circle()
                .fill(Color.white)
                .frame(width: cameraBadgeSize, height: cameraBadgeSize)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: cameraBadgeSize * 0.4, weight: .bold))
                        .foregroundStyle(Color.sorayomiPrimary)
                )
        }
        // Progress ring — drawn as overlay so it doesn't affect layout
        .overlay(alignment: .center) {
            ZStack {
                // Track
                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: ringLineWidth)

                // Filled arc
                if completionScore > 0 {
                    Circle()
                        .trim(from: 0, to: completionScore)
                        .stroke(
                            ringGradient(for: completionScore),
                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
            }
            .frame(width: ringSize, height: ringSize)
        }
    }

    private func ringGradient(for score: Double) -> LinearGradient {
        if score >= 1.0 {
            // 完成: ゴールドグラデーション
            return LinearGradient(
                colors: [Color.sorayomiSecondary, Color.sorayomiGlow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if score >= 0.5 {
            // 途中: ヴァイオレット
            return LinearGradient(
                colors: [Color.sorayomiPrimary, Color.sorayomiAccent.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // 初期: アンバー（1項目のみ）
            return LinearGradient(
                colors: [Color.sorayomiWarning, Color.sorayomiWarning.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Favorites Editor Sheet

/// お気に入り占術の選択シート。
/// 独立した View struct にすることで @Observable の観測コンテキストを
/// ProfileScreen から切り離し、toggle 後の即時再描画を保証する。
private struct FavoritesEditorSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("追加したい占いをタップして選択・解除できます。")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .padding(.horizontal, Spacing.md)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: Spacing.sm
                    ) {
                        ForEach(FortuneSystem.allCases) { system in
                            FavoriteToggleCell(system: system)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .navigationTitle("お気に入りを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// 各占術の選択セル。独立した View にすることで、
/// toggleFavoriteSystem 後に自セルだけを効率よく再描画できる。
private struct FavoriteToggleCell: View {
    @Environment(AppEnvironment.self) private var env
    let system: FortuneSystem

    var body: some View {
        let isSelected = env.userProfileService.isFavorite(system)

        Button {
            env.userProfileService.toggleFavoriteSystem(system)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: system.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.sorayomiPrimary : Color.sorayomiTextSecondary)
                    .frame(width: 34, height: 34)
                    .background(
                        (isSelected ? Color.sorayomiPrimary : Color.sorayomiTextSecondary)
                            .opacity(0.10)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                Text(system.shortName)
                    .font(SorayomiTypography.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.sorayomiPrimary : Color.sorayomiTextPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        isSelected
                            ? Color.sorayomiPrimary
                            : Color.sorayomiTextSecondary.opacity(0.3)
                    )
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                    .fill(isSelected ? Color.sorayomiPrimary.opacity(0.07) : Color.sorayomiSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.sorayomiPrimary.opacity(0.4) : Color.sorayomiDivider.opacity(0.5),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProfileScreen()
            .environment(AppEnvironment())
    }
}
