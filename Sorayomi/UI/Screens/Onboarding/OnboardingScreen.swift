import SwiftUI

/// Full-screen onboarding flow: Welcome → Birthday → Blood Type → Start.
struct OnboardingScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        TabView(selection: $viewModel.currentPage) {
            // Page 1: Welcome
            OnboardingPageView(
                iconName: "sparkles",
                title: "ようこそ、宙よみへ",
                description: "伝統の知恵を現代に紡ぎ直し、\nあなたの毎日にそっと寄り添います",
                buttonLabel: "はじめる",
                footer: OnboardingLegalFooter(),
                action: { viewModel.currentPage = 1 }
            )
            .tag(0)

            // Page 2: Birthday
            BirthdayInputView(
                birthday: $viewModel.birthday,
                onNext: { viewModel.currentPage = 2 }
            )
            .tag(1)

            // Page 3: Blood Type → Complete
            BloodTypePickerView(
                selectedType: $viewModel.bloodType,
                onNext: {
                    Task {
                        await viewModel.completeOnboarding(env: env)
                    }
                }
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
        .background(Color.sorayomiBackground)
    }
}

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
