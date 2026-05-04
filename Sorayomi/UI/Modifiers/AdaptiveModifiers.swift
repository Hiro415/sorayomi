import SwiftUI

// MARK: - Adaptive Screen Padding

/// 画面端の水平パディングをデバイスサイズに応じて自動調整する。
/// compact（iPhone）= 20pt、regular（iPad）= 40pt
struct AdaptiveScreenPadding: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, sizeClass == .regular ? 40 : SorayomiSpacing.screenPadding)
    }
}

// MARK: - Content Width Constraint

/// iPad landscape 等の広い画面でコンテンツの最大幅を制限し中央寄せする。
/// compact では制限なし（.infinity）。
struct ContentWidthConstraint: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    var maxWidth: CGFloat = 700

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity) // 中央寄せ
        } else {
            content
        }
    }
}

// MARK: - View Extensions

extension View {
    /// デバイスサイズに応じた画面端パディングを適用する。
    /// `.padding(.horizontal, Spacing.screenPadding)` の代替。
    func adaptiveScreenPadding() -> some View {
        modifier(AdaptiveScreenPadding())
    }

    /// iPadで広がりすぎないようコンテンツ幅を制限する。
    /// ScrollView 内の VStack に適用推奨。
    func contentWidthConstraint(maxWidth: CGFloat = 700) -> some View {
        modifier(ContentWidthConstraint(maxWidth: maxWidth))
    }
}
