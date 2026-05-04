import SwiftUI

/// Global typealias so views can use `Spacing.md` without the namespace prefix.
typealias Spacing = SorayomiSpacing

/// Consistent spacing tokens for layout throughout the app.
///
/// Using these tokens instead of magic numbers ensures visual
/// consistency and makes future design-system tweaks trivial.
///
/// Usage:
/// ```swift
/// VStack(spacing: Spacing.md) { ... }
/// .padding(Spacing.screenPadding)
/// ```
enum SorayomiSpacing {

    // MARK: - Base Scale

    /// 4pt -- hairline gaps, icon padding.
    static let xxs: CGFloat = 4

    /// 8pt -- tight element spacing.
    static let xs: CGFloat = 8

    /// 12pt -- compact vertical rhythm.
    static let sm: CGFloat = 12

    /// 16pt -- standard inter-element spacing.
    static let md: CGFloat = 16

    /// 24pt -- section gaps.
    static let lg: CGFloat = 24

    /// 32pt -- large section dividers.
    static let xl: CGFloat = 32

    /// 48pt -- hero / breathing room.
    static let xxl: CGFloat = 48

    // MARK: - Corner Radii

    enum CornerRadius {
        /// 8pt -- small elements (badges, chips).
        static let small: CGFloat = 8

        /// 14pt -- cards, buttons.
        static let medium: CGFloat = 14

        /// 22pt -- sheets, large cards.
        static let large: CGFloat = 22

        /// Full capsule.  Use with `.clipShape(.capsule)` instead when possible.
        static let full: CGFloat = 9999
    }

    // MARK: - Legacy Convenience (flat alias for CornerRadius)

    /// Flat alias for `CornerRadius.small` (used by older view files).
    static let cornerRadiusSmall: CGFloat = CornerRadius.small

    /// Flat alias for `CornerRadius.medium`.
    static let cornerRadiusMedium: CGFloat = CornerRadius.medium

    /// Flat alias for `CornerRadius.large`.
    static let cornerRadiusLarge: CGFloat = CornerRadius.large

    // MARK: - Contextual Padding

    /// Standard internal padding for card-style containers.
    static let cardPadding: CGFloat = 16

    /// Horizontal padding applied to full-width screen content (iPhone).
    static let screenPadding: CGFloat = 20

    /// Wider screen padding for iPad / regular size class.
    static let screenPaddingRegular: CGFloat = 40

    /// Bottom padding to keep content above the safe area / tab bar.
    static let bottomSafeArea: CGFloat = 34

    // MARK: - Shadow

    /// Default card shadow radius.
    static let shadowRadius: CGFloat = 8

    /// Default shadow vertical offset.
    static let shadowY: CGFloat = 4
}
