import SwiftUI

/// A lightweight routing view that checks the onboarding state and
/// displays either the main tab interface or the onboarding flow.
/// On first launch, displays an animated splash screen.
struct ContentView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // メインコンテンツ
            Group {
                if appEnvironment.isOnboardingComplete {
                    AppTabView()
                } else {
                    OnboardingScreen()
                }
            }
            .animation(.easeInOut(duration: AppConstants.standardAnimationDuration), value: appEnvironment.isOnboardingComplete)

            // スプラッシュスクリーン（最前面）
            if showSplash {
                SplashScreen {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding") {
    ContentView()
        .environment({
            let env = AppEnvironment()
            env.resetOnboarding()
            return env
        }())
}

#Preview("Main App") {
    ContentView()
        .environment({
            let env = AppEnvironment()
            env.completeOnboarding()
            return env
        }())
}
