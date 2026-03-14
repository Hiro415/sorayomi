import SwiftUI

// MARK: - Semantic Color Palette

/// Japanese-inspired premium color palette for the Sorayomi app.
///
/// Every color is defined as a pair of light / dark mode values so
/// the app respects the system appearance setting automatically.
/// Access colors through the `Color.sorayomi*` static properties.
extension Color {

    // MARK: - Brand Colors

    /// Deep midnight indigo -- primary brand color.
    static let sorayomiPrimary = Color(
        light: .init(red: 0.11, green: 0.16, blue: 0.33),  // #1D2954
        dark:  .init(red: 0.65, green: 0.72, blue: 0.93)   // #A5B8ED
    )

    /// Warm gold -- secondary accent.
    static let sorayomiSecondary = Color(
        light: .init(red: 0.80, green: 0.66, blue: 0.37),  // #CCA85E
        dark:  .init(red: 0.90, green: 0.80, blue: 0.56)   // #E6CC8F
    )

    /// Vermilion-inspired accent used for ritual highlights.
    static let sorayomiAccent = Color(
        light: .init(red: 0.80, green: 0.34, blue: 0.24),  // #CC573D
        dark:  .init(red: 0.93, green: 0.55, blue: 0.44)   // #ED8C70
    )

    // MARK: - Backgrounds

    /// Warm paper background.
    static let sorayomiBackground = Color(
        light: .init(red: 0.97, green: 0.95, blue: 0.91),  // #F7F1E8
        dark:  .init(red: 0.06, green: 0.08, blue: 0.11)   // #10131B
    )

    /// Primary card surface.
    static let sorayomiSurface = Color(
        light: .init(red: 1.0,  green: 0.99, blue: 0.98),  // #FFFCFA
        dark:  .init(red: 0.11, green: 0.13, blue: 0.18)   // #1C202E
    )

    static let sorayomiPaper = Color(
        light: .init(red: 0.99, green: 0.97, blue: 0.95),  // #FCF7F2
        dark:  .init(red: 0.17, green: 0.18, blue: 0.24)   // #2A2E3D
    )

    static let sorayomiSurfaceElevated = Color(
        light: .init(red: 1.0, green: 0.98, blue: 0.96),   // #FFF9F4
        dark:  .init(red: 0.19, green: 0.20, blue: 0.27)   // #303446
    )

    /// Deep lacquer-like surface used for hero panels.
    static let sorayomiNight = Color(
        light: .init(red: 0.18, green: 0.20, blue: 0.33),  // #2E3354
        dark:  .init(red: 0.12, green: 0.15, blue: 0.23)   // #1F263A
    )

    /// Soft highlight wash used behind chips and supportive surfaces.
    static let sorayomiMist = Color(
        light: .init(red: 0.95, green: 0.91, blue: 0.86),  // #F2E9DB
        dark:  .init(red: 0.21, green: 0.22, blue: 0.28)   // #363947
    )

    // MARK: - Text

    /// Deep ink text.
    static let sorayomiTextPrimary = Color(
        light: .init(red: 0.15, green: 0.13, blue: 0.16),  // #261F28
        dark:  .init(red: 0.95, green: 0.93, blue: 0.90)   // #F2EDE6
    )

    /// Secondary text with a warm slate tint.
    static let sorayomiTextSecondary = Color(
        light: .init(red: 0.41, green: 0.37, blue: 0.41),  // #695E68
        dark:  .init(red: 0.72, green: 0.68, blue: 0.72)   // #B7ADB7
    )

    // MARK: - Semantic Status

    static let sorayomiSuccess = Color(
        light: .init(red: 0.29, green: 0.58, blue: 0.34),  // #4A9457
        dark:  .init(red: 0.42, green: 0.76, blue: 0.50)   // #6BC280
    )

    static let sorayomiWarning = Color(
        light: .init(red: 0.86, green: 0.60, blue: 0.22),  // #DB9938
        dark:  .init(red: 0.94, green: 0.76, blue: 0.36)   // #F0C15C
    )

    static let sorayomiError = Color(
        light: .init(red: 0.74, green: 0.24, blue: 0.24),  // #BC3D3D
        dark:  .init(red: 0.90, green: 0.40, blue: 0.40)   // #E66666
    )

    // MARK: - Fortune Gradient

    /// Start of the signature fortune-reading gradient (vermilion).
    static let sorayomiFortuneGradientStart = Color(
        light: .init(red: 0.79, green: 0.31, blue: 0.25),  // #C94F40
        dark:  .init(red: 0.88, green: 0.45, blue: 0.37)   // #E0735E
    )

    /// End of the signature fortune-reading gradient (midnight indigo).
    static let sorayomiFortuneGradientEnd = Color(
        light: .init(red: 0.14, green: 0.19, blue: 0.39),  // #243163
        dark:  .init(red: 0.34, green: 0.39, blue: 0.66)   // #5763A8
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
        light: .init(red: 0.89, green: 0.84, blue: 0.79),  // #E3D7CA
        dark:  .init(red: 0.24, green: 0.26, blue: 0.31)   // #3D424F
    )

    static let sorayomiHighlight = Color(
        light: .init(red: 0.98, green: 0.88, blue: 0.70),  // #FAE1B3
        dark:  .init(red: 0.50, green: 0.42, blue: 0.24)   // #7F6A3D
    )

    static let sorayomiGlow = Color(
        light: .init(red: 0.95, green: 0.75, blue: 0.56),  // #F2BF8F
        dark:  .init(red: 0.55, green: 0.42, blue: 0.30)   // #8C6B4D
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
