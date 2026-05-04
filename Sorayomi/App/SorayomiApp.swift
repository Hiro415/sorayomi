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
                    default:
                        break
                    }
                }
        }
    }
}
