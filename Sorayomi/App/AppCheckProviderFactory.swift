import Foundation
import FirebaseCore
import FirebaseAppCheck

// MARK: - AppCheckTokenProvider Protocol

/// App Check トークンを取得するプロトコル
/// テスト時に差し替え可能な抽象化レイヤー
protocol AppCheckTokenProvider: Sendable {
    func currentToken() async -> String?
}

// MARK: - FirebaseAppCheckTokenProvider

/// Firebase App Check を使って実トークンを取得する
struct FirebaseAppCheckTokenProvider: AppCheckTokenProvider {
    func currentToken() async -> String? {
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: false)
            return token.token
        } catch {
            #if DEBUG
            print("[AppCheck] Token fetch error: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
}

// MARK: - SorayomiAppCheckProviderFactory

/// Firebase App Check のプロバイダーファクトリ
///
/// - DEBUG ビルド（シミュレータ・開発実機）: AppCheckDebugProvider
///   → 起動時にコンソールへデバッグトークンを出力する。
///     Firebase Console > App Check > アプリ > デバッグトークンに登録すること。
///
/// - RELEASE ビルド（App Store 配布）: AppAttestProvider
///   → Apple の App Attest を使用してデバイスの正当性を証明する。
final class SorayomiAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app)
        #endif
    }
}
