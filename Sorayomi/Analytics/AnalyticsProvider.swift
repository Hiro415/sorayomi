import Foundation

// MARK: - AnalyticsProviderProtocol

/// アナリティクスプロバイダーのプロトコル
/// Firebase Analytics, Amplitude, Mixpanel 等の異なるバックエンドを
/// 統一インターフェースで扱えるようにする。
protocol AnalyticsProviderProtocol: Sendable {
    /// イベントを送信する
    /// - Parameters:
    ///   - name: イベント名
    ///   - parameters: イベントパラメータ
    func track(name: String, parameters: [String: String])

    /// ユーザープロパティを設定する
    /// - Parameters:
    ///   - name: プロパティ名
    ///   - value: プロパティ値
    func setUserProperty(name: String, value: String?)
}

// MARK: - ConsoleAnalyticsProvider

/// コンソール出力のアナリティクスプロバイダー
/// デバッグ用。全イベントを print で出力する。
final class ConsoleAnalyticsProvider: AnalyticsProviderProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = ConsoleAnalyticsProvider()

    // MARK: - Init

    init() {}

    // MARK: - Track

    func track(name: String, parameters: [String: String]) {
        let paramsString: String
        if parameters.isEmpty {
            paramsString = "(no parameters)"
        } else {
            paramsString = parameters
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
        }
        #if DEBUG
        print("[Analytics] \(name): \(paramsString)")
        #endif
    }

    // MARK: - User Property

    func setUserProperty(name: String, value: String?) {
        let displayValue = value ?? "(nil)"
        #if DEBUG
        print("[Analytics] UserProperty \(name)=\(displayValue)")
        #endif
    }
}
