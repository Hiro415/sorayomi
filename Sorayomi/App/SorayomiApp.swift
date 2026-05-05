import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct SorayomiApp: App {

    init() {
        // App Check は FirebaseApp.configure() より前に設定する必要がある
        AppCheck.setAppCheckProviderFactory(SorayomiAppCheckProviderFactory())
        FirebaseApp.configure()
    }

    @State private var appEnvironment = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appEnvironment)
                .task {
                    await appEnvironment.grantPremiumCreditsIfNeeded()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        // フォアグラウンド復帰: ウォレット再読み込み
                        appEnvironment.creditWalletService.loadWallet()
                        // サブスクリプション状態を再確認（期限切れ・支払い失敗を検出）
                        Task {
                            await appEnvironment.storeKitManager.checkSubscriptionStatus()
                            appEnvironment.adRewardManager.isSubscribed = appEnvironment.storeKitManager.isSubscribed
                        }
                    default:
                        break
                    }
                }
        }
    }
}
