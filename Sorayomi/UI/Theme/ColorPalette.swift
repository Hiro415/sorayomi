import SwiftUI

// MARK: - Semantic Color Palette

/// Japanese-inspired mystical color palette for the Sorayomi app.
///
/// Built around a deep-indigo / violet cosmos theme that evokes a starlit
/// night sky — mysterious and premium, but never harsh or inaccessible.
/// All colors are defined as light / dark adaptive pairs so the app
/// respects the system appearance setting automatically.
/// Access colors through the `Color.sorayomi*` static properties.
extension Color {

    // MARK: - Brand Colors

    /// Deep royal violet -- primary brand color.
    static let sorayomiPrimary = Color(
        light: .init(red: 0.239, green: 0.169, blue: 0.549),  // #3D2B8C
        dark:  .init(red: 0.616, green: 0.561, blue: 0.984)   // #9D8FFB
    )

    /// Warm gold -- secondary accent.
    static let sorayomiSecondary = Color(
        light: .init(red: 0.722, green: 0.573, blue: 0.227),  // #B8923A
        dark:  .init(red: 0.910, green: 0.800, blue: 0.416)   // #E8CC6A
    )

    /// Amethyst -- accent used for ritual highlights.
    static let sorayomiAccent = Color(
        light: .init(red: 0.471, green: 0.200, blue: 0.627),  // #7833A0
        dark:  .init(red: 0.831, green: 0.471, blue: 0.941)   // #D478F0
    )

    // MARK: - Backgrounds

    /// Soft lavender-paper background.
    static let sorayomiBackground = Color(
        light: .init(red: 0.933, green: 0.918, blue: 0.965),  // #EEEAf6
        dark:  .init(red: 0.059, green: 0.047, blue: 0.125)   // #0F0C20
    )

    /// Primary card surface.
    static let sorayomiSurface = Color(
        light: .init(red: 0.973, green: 0.961, blue: 1.000),  // #F8F5FF
        dark:  .init(red: 0.094, green: 0.078, blue: 0.235)   // #18143C
    )

    static let sorayomiPaper = Color(
        light: .init(red: 0.957, green: 0.941, blue: 1.000),  // #F4F0FF
        dark:  .init(red: 0.114, green: 0.098, blue: 0.282)   // #1D1948
    )

    static let sorayomiSurfaceElevated = Color(
        light: .init(red: 0.980, green: 0.973, blue: 1.000),  // #FAF8FF
        dark:  .init(red: 0.133, green: 0.125, blue: 0.306)   // #22204E
    )

    /// Deep cosmic surface used for hero panels.
    static let sorayomiNight = Color(
        light: .init(red: 0.165, green: 0.118, blue: 0.408),  // #2A1E68
        dark:  .init(red: 0.047, green: 0.039, blue: 0.094)   // #0C0A18
    )

    /// Soft highlight wash used behind chips and supportive surfaces.
    static let sorayomiMist = Color(
        light: .init(red: 0.894, green: 0.871, blue: 0.961),  // #E4DEF5
        dark:  .init(red: 0.157, green: 0.141, blue: 0.361)   // #28245C
    )

    // MARK: - Text

    /// Deep ink text.
    static let sorayomiTextPrimary = Color(
        light: .init(red: 0.110, green: 0.078, blue: 0.188),  // #1C1430
        dark:  .init(red: 0.949, green: 0.933, blue: 0.973)   // #F2EEF8
    )

    /// Secondary text with a soft lavender-slate tint.
    static let sorayomiTextSecondary = Color(
        light: .init(red: 0.369, green: 0.314, blue: 0.502),  // #5E5080
        dark:  .init(red: 0.659, green: 0.620, blue: 0.784)   // #A89EC8
    )

    // MARK: - Semantic Status

    static let sorayomiSuccess = Color(
        light: .init(red: 0.165, green: 0.533, blue: 0.282),  // #2A8848
        dark:  .init(red: 0.290, green: 0.804, blue: 0.478)   // #4ACD7A
    )

    static let sorayomiWarning = Color(
        light: .init(red: 0.800, green: 0.533, blue: 0.125),  // #CC8820
        dark:  .init(red: 0.941, green: 0.753, blue: 0.251)   // #F0C040
    )

    static let sorayomiError = Color(
        light: .init(red: 0.737, green: 0.188, blue: 0.188),  // #BC3030
        dark:  .init(red: 0.910, green: 0.373, blue: 0.373)   // #E85F5F
    )

    // MARK: - Fortune Gradient

    /// Start of the signature fortune-reading gradient (vivid violet).
    static let sorayomiFortuneGradientStart = Color(
        light: .init(red: 0.420, green: 0.247, blue: 0.784),  // #6B3FC8
        dark:  .init(red: 0.608, green: 0.361, blue: 0.961)   // #9B5CF5
    )

    /// End of the signature fortune-reading gradient (cobalt blue).
    static let sorayomiFortuneGradientEnd = Color(
        light: .init(red: 0.176, green: 0.361, blue: 0.722),  // #2D5CB8
        dark:  .init(red: 0.298, green: 0.486, blue: 0.961)   // #4C7CF5
    )

    /// Convenience linear gradient used for fortune card backgrounds.
    static var sorayomiFortuneGradient: LinearGradient {
        LinearGradient(
            colors: [.sorayomiFortuneGradientStart, .sorayomiFortuneGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Divider / Border

    static let sorayomiDivider = Color(
        light: .init(red: 0.816, green: 0.784, blue: 0.910),  // #D0C8E8
        dark:  .init(red: 0.145, green: 0.125, blue: 0.282)   // #252048
    )

    static let sorayomiHighlight = Color(
        light: .init(red: 0.867, green: 0.816, blue: 1.000),  // #DDD0FF
        dark:  .init(red: 0.290, green: 0.247, blue: 0.627)   // #4A3FA0
    )

    static let sorayomiGlow = Color(
        light: .init(red: 0.565, green: 0.439, blue: 0.847),  // #9070D8
        dark:  .init(red: 0.769, green: 0.690, blue: 1.000)   // #C4B0FF
    )
}

// MARK: - Dark-Mode Adaptive Color Initializer

private extension Color {
    /// Creates a color that automatically switches between light and dark variants.
    init(light: Color.Resolved, dark: Color.Resolved) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(
                    red: CGFloat(dark.red),
                    green: CGFloat(dark.green),
                    blue: CGFloat(dark.blue),
                    alpha: CGFloat(dark.opacity)
                )
            default:
                return UIColor(
                    red: CGFloat(light.red),
                    green: CGFloat(light.green),
                    blue: CGFloat(light.blue),
                    alpha: CGFloat(light.opacity)
                )
            }
        })
    }
}
