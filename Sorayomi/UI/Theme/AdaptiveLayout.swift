import SwiftUI

// MARK: - LayoutSizeCategory

/// デバイスの画面幅カテゴリ
/// compact = iPhone全般, regular = iPad・iPhone Plus横向き等
enum LayoutSizeCategory {
    case compact
    case regular

    /// 推奨グリッド列数
    var defaultColumnCount: Int {
        switch self {
        case .compact: return 2
        case .regular:  return 3
        }
    }

    /// UIスケールファクター（アイコン・装飾要素向け）
    var scaleFactor: CGFloat {
        switch self {
        case .compact: return 1.0
        case .regular:  return 1.15
        }
    }
}

// MARK: - LayoutMetrics

/// 画面サイズに応じたレイアウト設定値を一元管理する。
/// `@Environment(\.layoutMetrics)` で任意のViewから参照可能。
struct LayoutMetrics: Sendable {

    let sizeCategory: LayoutSizeCategory

    /// グリッドのデフォルト列数（compact=2, regular=3）
    var columnCount: Int { sizeCategory.defaultColumnCount }

    /// UI要素のスケールファクター
    var scaleFactor: CGFloat { sizeCategory.scaleFactor }

    /// コンテンツの最大幅（iPad detail pane内で中央寄せ用）
    var maxContentWidth: CGFloat {
        switch sizeCategory {
        case .compact: return .infinity
        case .regular:  return 700
        }
    }

    /// 画面端の水平パディング
    var screenPadding: CGFloat {
        switch sizeCategory {
        case .compact: return SorayomiSpacing.screenPadding    // 20pt
        case .regular:  return 40
        }
    }

    /// カード内パディング
    var cardPadding: CGFloat {
        switch sizeCategory {
        case .compact: return SorayomiSpacing.cardPadding      // 16pt
        case .regular:  return 20
        }
    }

    /// セクション間スペーシング
    var sectionSpacing: CGFloat {
        switch sizeCategory {
        case .compact: return SorayomiSpacing.lg               // 24pt
        case .regular:  return 32
        }
    }

    /// チャットバブルの最大幅
    var maxBubbleWidth: CGFloat {
        switch sizeCategory {
        case .compact: return .infinity
        case .regular:  return 600
        }
    }

    // MARK: - Defaults

    static let compact = LayoutMetrics(sizeCategory: .compact)
    static let regular = LayoutMetrics(sizeCategory: .regular)
}

// MARK: - EnvironmentKey

private struct LayoutMetricsKey: EnvironmentKey {
    static let defaultValue = LayoutMetrics.compact
}

extension EnvironmentValues {
    /// 現在のデバイスサイズに応じたレイアウト設定値
    var layoutMetrics: LayoutMetrics {
        get { self[LayoutMetricsKey.self] }
        set { self[LayoutMetricsKey.self] = newValue }
    }
}

// MARK: - LayoutMetrics Provider

/// アプリのルートに配置して `horizontalSizeClass` を `LayoutMetrics` に変換する。
/// 子ビューは `@Environment(\.layoutMetrics)` で参照。
struct LayoutMetricsProvider<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        let metrics = sizeClass == .regular
            ? LayoutMetrics.regular
            : LayoutMetrics.compact
        content()
            .environment(\.layoutMetrics, metrics)
    }
}
