import SwiftUI

/// Full-screen onboarding flow: Welcome → Birthday → Blood Type → Notifications → Start.
struct OnboardingScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        TabView(selection: $viewModel.currentPage) {
            // Page 0: Welcome
            OnboardingPageView(
                iconName: "sparkles",
                title: "ようこそ、宙よみへ",
                description: "伝統の知恵を現代に紡ぎ直し、\nあなたの毎日にそっと寄り添います",
                buttonLabel: "はじめる",
                footer: OnboardingLegalFooter(),
                action: { viewModel.currentPage = 1 }
            )
            .tag(0)

            // Page 1: Birthday
            BirthdayInputView(
                birthday: $viewModel.birthday,
                onNext: { viewModel.currentPage = 2 }
            )
            .tag(1)

            // Page 2: Blood Type
            BloodTypePickerView(
                selectedType: $viewModel.bloodType,
                onNext: { viewModel.currentPage = 3 }
            )
            .tag(2)

            // Page 3: Notification permission (pre-ask UI before system dialog)
            NotificationPermissionPageView(
                onAllow: {
                    Task {
                        await env.notificationManager.requestAuthorization()
                        await viewModel.completeOnboarding(env: env)
                    }
                },
                onSkip: {
                    Task { await viewModel.completeOnboarding(env: env) }
                }
            )
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
        .background(Color.sorayomiBackground)
    }
}

// MARK: - Reusable Page

/// Reusable onboarding page with icon, title, description, action button, and optional legal footer.
struct OnboardingPageView<Footer: View>: View {
    let iconName: String
    let title: String
    let description: String
    let buttonLabel: String
    var footer: Footer
    var action: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sorayomiFortuneGradientStart, .sorayomiFortuneGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(SorayomiTypography.largeTitle)
                    .foregroundStyle(Color.sorayomiTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(description)
                    .font(SorayomiTypography.body)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button(action: action) {
                    Text(buttonLabel)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [.sorayomiPrimary, .sorayomiFortuneGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                }

                footer
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

extension OnboardingPageView where Footer == EmptyView {
    init(iconName: String, title: String, description: String, buttonLabel: String, action: @escaping () -> Void) {
        self.iconName = iconName
        self.title = title
        self.description = description
        self.buttonLabel = buttonLabel
        self.footer = EmptyView()
        self.action = action
    }
}

// MARK: - Notification Permission Page

/// 通知許可のオンボーディングページ。
/// iOS システムダイアログの前に目的を説明する「pre-ask UI」。
struct NotificationPermissionPageView: View {
    let onAllow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sorayomiFortuneGradientStart, .sorayomiFortuneGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.sm) {
                Text("星の声をお届けします")
                    .font(SorayomiTypography.largeTitle)
                    .foregroundStyle(Color.sorayomiTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("毎朝の運勢・ラッキーデーのお知らせ、\n連続利用のリマインダーを受け取りましょう")
                    .font(SorayomiTypography.body)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // 通知種類の説明
            VStack(spacing: Spacing.sm) {
                notificationFeatureRow(
                    icon: "sun.horizon.fill",
                    color: .sorayomiSecondary,
                    label: "朝の運勢通知",
                    description: "毎朝、今日のエネルギーをお届け"
                )
                notificationFeatureRow(
                    icon: "sparkles",
                    color: .sorayomiPrimary,
                    label: "大安のお知らせ",
                    description: "縁起の良い日を見逃しません"
                )
                notificationFeatureRow(
                    icon: "flame.fill",
                    color: .sorayomiAccent,
                    label: "ストリークリマインダー",
                    description: "連続利用をサポートします"
                )
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button(action: onAllow) {
                    Text("通知を許可する")
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [.sorayomiPrimary, .sorayomiFortuneGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                }

                Button(action: onSkip) {
                    Text("後で設定する")
                        .font(SorayomiTypography.body)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .padding(.vertical, Spacing.xs)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func notificationFeatureRow(
        icon: String,
        color: Color,
        label: String,
        description: String
    ) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(SorayomiTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(description)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Legal Footer

/// プライバシーポリシー・利用規約への同意フッター（オンボーディング用）
struct OnboardingLegalFooter: View {
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false

    var body: some View {
        VStack(spacing: 4) {
            Text("続けることで、以下に同意したものとみなされます")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: Spacing.xs) {
                Button {
                    showPrivacyPolicy = true
                } label: {
                    Text("プライバシーポリシー")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiPrimary)
                        .underline()
                }
                .buttonStyle(.plain)

                Text("・")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)

                Button {
                    showTermsOfService = true
                } label: {
                    Text("利用規約")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiPrimary)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyScreen()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { showPrivacyPolicy = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showTermsOfService) {
            NavigationStack {
                TermsOfServiceScreen()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { showTermsOfService = false }
                        }
                    }
            }
        }
    }
}

#Preview {
    OnboardingScreen()
        .environment(AppEnvironment())
}
