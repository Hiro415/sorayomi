import SwiftUI
import PhotosUI

/// Profile screen rebuilt around personal identity, readiness, and shortcuts.
struct ProfileScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = ProfileViewModel()
    @State private var isEditingNickname = false
    @State private var editedNickname = ""

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    profileHero
                    profileSnapshot
                    interestSection
                    creditSection
                    settingsSection
                }
                .padding(.horizontal, Spacing.screenPadding)
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

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                PhotosPicker(
                    selection: Binding(
                        get: { viewModel.selectedPhotoItem },
                        set: { viewModel.selectedPhotoItem = $0 }
                    ),
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    ProfileAvatarView(profileImage: profileImage)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("プロフィール")
                        .font(SorayomiTypography.eyebrow)
                        .foregroundStyle(Color.white.opacity(0.70))

                    Text(viewModel.profile?.displayName ?? "ゲスト")
                        .font(SorayomiTypography.title)
                        .foregroundStyle(.white)

                    Text(heroNarrative)
                        .font(SorayomiTypography.callout)
                        .foregroundStyle(Color.white.opacity(0.86))
                        .lineSpacing(5)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: Spacing.xs) {
                heroBadge(title: "完成度", value: profileCompletionLabel)
                heroBadge(title: "星座", value: viewModel.profile?.zodiacSign?.japaneseName ?? "未設定")
                heroBadge(title: "AI鑑定", value: aiConsentLabel)
            }

            Button {
                editedNickname = viewModel.profile?.nickname ?? ""
                isEditingNickname = true
            } label: {
                Text("名前を整える")
                    .font(SorayomiTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sorayomiPanel(tone: .night, padding: Spacing.lg)
    }

    private var profileSnapshot: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "基本情報",
                title: "あなたの基本データ",
                subtitle: "占いの土台になる情報を、すぐ確認できるようにまとめています。"
            )

            VStack(spacing: Spacing.sm) {
                profileDetailRow(
                    label: "誕生日",
                    value: formattedBirthday,
                    icon: "birthday.cake.fill"
                )
                profileDetailRow(
                    label: "血液型",
                    value: viewModel.profile?.bloodType?.japaneseName ?? "未設定",
                    icon: "drop.fill"
                )
                profileDetailRow(
                    label: "星座",
                    value: viewModel.profile?.zodiacSign?.japaneseName ?? "未設定",
                    icon: "sparkles"
                )
            }
        }
        .sorayomiPanel(tone: .spotlight)
    }

    private var interestSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "関心テーマ",
                title: "気になりやすいテーマ",
                subtitle: "よく見たいテーマがあると、次に選ぶ導線が自然になります。"
            )

            if themeInterests.isEmpty {
                Text("まだテーマ登録がありません。恋愛、仕事、今日の流れなど、気になるものが増えたら今後の提案にも反映しやすくなります。")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 110), spacing: Spacing.xs)],
                    alignment: .leading,
                    spacing: Spacing.xs
                ) {
                    ForEach(themeInterests, id: \.id) { interest in
                        interestChip(interest)
                    }
                }
            }
        }
        .sorayomiPanel(tone: .elevated)
    }

    private var creditSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "クレジット",
                title: "クレジット状況",
                subtitle: "本格鑑定に入る前に、残高と無料分がひと目で分かります。"
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
                subtitle: "必要な設定やストアへの導線を、迷わず辿れるようにしています。"
            )

            VStack(spacing: Spacing.sm) {
                NavigationLink {
                    SettingsScreen()
                        .environment(env)
                } label: {
                    settingsCard(
                        title: "アプリ設定",
                        detail: "通知やアプリ情報、細かな設定を確認する",
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
                        detail: "パックの比較と購入、復元を行う",
                        icon: "diamond.fill",
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

    private func interestChip(_ interest: ThemeInterest) -> some View {
        HStack(spacing: 6) {
            Image(systemName: interest.iconName)
                .font(.system(size: 10, weight: .semibold))
            Text(interest.japaneseName)
                .font(SorayomiTypography.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(Color.sorayomiAccent)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sorayomiAccent.opacity(0.10))
        .clipShape(Capsule())
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

    private var profileCompletionLabel: String {
        viewModel.profile?.isProfileComplete == true ? "整っています" : "あと少し"
    }

    private var aiConsentLabel: String {
        viewModel.profile?.hasConsentedToAI == true ? "設定済み" : "未設定"
    }

    private var heroNarrative: String {
        if viewModel.profile?.isProfileComplete == true {
            return "プロフィールは整っています。必要なときに見直せます。"
        }
        return "誕生日などを入れると、鑑定の提案がより合いやすくなります。"
    }

    private var themeInterests: [ThemeInterest] {
        viewModel.profile?.themeInterests ?? []
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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.sorayomiSecondary, .sorayomiAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 78))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .frame(width: 90, height: 90)
            }

            Circle()
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.sorayomiPrimary)
                )
        }
    }
}

#Preview {
    NavigationStack {
        ProfileScreen()
            .environment(AppEnvironment())
    }
}
