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
            // Dynamic Type の上限を xxxLarge に設定。
            // 現行レイアウトは固定サイズ前提で設計されているため、
            // accessibility スケール（+1〜+5）まで追従するとレイアウトが崩壊する。
            // この1行でアプリ全体の文字サイズを .xSmall〜.xxxLarge の範囲に制限し、
            // 超大文字設定ユーザーへの最低限の配慮と現行デザインの保護を両立する。
            .dynamicTypeSize(.xSmall ... .xxxLarge)
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
