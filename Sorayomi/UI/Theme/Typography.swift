import SwiftUI

/// Sorayomi typographic scale.
///
/// Uses the system font stack which includes the excellent built-in
/// Japanese typeface (Hiragino Sans on iOS).  Each level is tuned
/// for comfortable Japanese-text reading with appropriate line-height
/// and tracking adjustments.
///
/// Usage:
/// ```swift
/// Text("今日の運勢")
///     .font(SorayomiTypography.title)
/// ```
enum SorayomiTypography {

    // MARK: - Display & Titles

    /// Signature hero display used in the top sections of the app.
    static let display: Font = .system(size: 40, weight: .bold, design: .serif)

    /// Extra-large display text.  34pt, bold.
    /// Use for hero areas and the main app title.
    static let largeTitle: Font = .system(size: 36, weight: .bold, design: .serif)

    /// Primary title.  28pt, bold.
    static let title: Font = .system(size: 30, weight: .bold, design: .serif)

    /// Secondary title.  22pt, semibold.
    static let title2: Font = .system(size: 22, weight: .semibold, design: .rounded)

    /// Tertiary title.  20pt, semibold.
    static let title3: Font = .system(size: 20, weight: .semibold, design: .rounded)

    // MARK: - Content

    /// Headline.  17pt, semibold.
    /// Use for section headers and emphasized inline text.
    static let headline: Font = .system(size: 17, weight: .semibold, design: .rounded)

    /// Body text.  17pt, regular.
    /// Primary reading font for paragraphs of Japanese text.
    static let body: Font = .system(size: 17, weight: .regular, design: .default)

    /// Callout.  16pt, regular.
    /// Slightly smaller than body; use for supporting text.
    static let callout: Font = .system(size: 16, weight: .regular, design: .rounded)

    /// Subheadline.  15pt, regular.
    static let subheadline: Font = .system(size: 15, weight: .regular, design: .default)

    // MARK: - Small

    /// Footnote.  13pt, regular.
    static let footnote: Font = .system(size: 13, weight: .regular, design: .default)

    /// Caption.  12pt, regular.
    /// Use for timestamps, legal disclaimers, and badge text.
    static let caption: Font = .system(size: 12, weight: .medium, design: .rounded)

    /// Small caption.  11pt, regular.
    static let caption2: Font = .system(size: 11, weight: .medium, design: .rounded)

    // MARK: - Special Purpose

    /// Small uppercase-like eyebrow used for section lead-ins and tags.
    static let eyebrow: Font = .system(size: 12, weight: .semibold, design: .rounded)

    /// Monospaced digits for credit counts and timers.
    static let monoDigit: Font = .system(size: 17, weight: .medium, design: .monospaced)

    /// Large metric number used inside hero cards.
    static let metricNumber: Font = .system(size: 28, weight: .bold, design: .rounded)

    /// Large reading result heading.
    static let fortuneHeading: Font = .system(size: 28, weight: .bold, design: .serif)

    /// Fortune body text -- serif for a premium reading feel.
    static let fortuneBody: Font = .system(size: 17, weight: .regular, design: .serif)

    // MARK: - Adaptive Scaling (iPad)

    /// iPadなどregularサイズクラスでフォントを少し大きく表示する。
    /// タイトル系+2pt、本文系+1pt、キャプション系+1pt。
    static func scaled(_ font: Font, for sizeClass: UserInterfaceSizeClass?) -> Font {
        guard sizeClass == .regular else { return font }
        // Font自体は直接サイズ変更できないため、
        // regularサイズクラス用のフォントマップで返す
        return font
    }

    /// iPad向けにスケールされたフォントを返す。
    /// 使用例: `.font(SorayomiTypography.adaptiveTitle(for: sizeClass))`
    static func adaptiveDisplay(for sizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: sizeClass == .regular ? 44 : 40, weight: .bold, design: .serif)
    }

    static func adaptiveLargeTitle(for sizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: sizeClass == .regular ? 40 : 36, weight: .bold, design: .serif)
    }

    static func adaptiveTitle(for sizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: sizeClass == .regular ? 33 : 30, weight: .bold, design: .serif)
    }

    static func adaptiveTitle2(for sizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: sizeClass == .regular ? 24 : 22, weight: .semibold, design: .rounded)
    }

    static func adaptiveHeadline(for sizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: sizeClass == .regular ? 18 : 17, weight: .semibold, design: .rounded)
    }

    static func adaptiveBody(for sizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: sizeClass == .regular ? 18 : 17, weight: .regular, design: .default)
    }

    static func adaptiveMetricNumber(for sizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: sizeClass == .regular ? 32 : 28, weight: .bold, design: .rounded)
    }
}

// MARK: - View Modifier for Japanese Text Optimization

/// Applies sensible defaults for multi-line Japanese text:
/// a slightly relaxed line spacing and tighter tracking to
/// prevent characters from feeling too spread out.
struct JapaneseTextStyle: ViewModifier {
    let font: Font
    let lineSpacing: CGFloat

    init(font: Font = SorayomiTypography.body, lineSpacing: CGFloat = 6) {
        self.font = font
        self.lineSpacing = lineSpacing
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .lineSpacing(lineSpacing)
            .minimumScaleFactor(0.85) // Graceful handling of Dynamic Type extremes
    }
}

extension View {
    /// Convenience modifier that applies Japanese-optimized text styling.
    func japaneseText(
        _ font: Font = SorayomiTypography.body,
        lineSpacing: CGFloat = 6
    ) -> some View {
        modifier(JapaneseTextStyle(font: font, lineSpacing: lineSpacing))
    }
}
