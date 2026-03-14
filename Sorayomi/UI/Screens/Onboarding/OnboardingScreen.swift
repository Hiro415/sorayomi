import SwiftUI

/// Full-screen onboarding flow: Welcome → Birthday → Blood Type → AI Consent.
struct OnboardingScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        TabView(selection: $viewModel.currentPage) {
            // Page 1: Welcome
            OnboardingPageView(
                iconName: "sparkles",
                title: "ようこそ、宙よみへ",
                description: "日本の伝統的な知恵とAIの力を組み合わせて、\nあなたの日々に寄り添う導きをお届けします",
                buttonLabel: "はじめる",
                action: { viewModel.currentPage = 1 }
            )
            .tag(0)

            // Page 2: Birthday
            BirthdayInputView(
                birthday: $viewModel.birthday,
                onNext: { viewModel.currentPage = 2 }
            )
            .tag(1)

            // Page 3: Blood Type
            BloodTypePickerView(
                selectedType: $viewModel.bloodType,
                onNext: { viewModel.currentPage = 3 }
            )
            .tag(2)

            // Page 4: AI Consent
            AIConsentView(
                hasConsented: $viewModel.hasConsentedToAI,
                onComplete: {
                    Task {
                        await viewModel.completeOnboarding(env: env)
                    }
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

/// Reusable onboarding page with icon, title, description, and action button.
struct OnboardingPageView: View {
    let iconName: String
    let title: String
    let description: String
    let buttonLabel: String
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
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview {
    OnboardingScreen()
        .environment(AppEnvironment())
}
