import SwiftUI

/// Convenience container that bundles the full Sorayomi design system.
///
/// Primarily useful when you need to pass the whole theme as a single
/// reference, or when building previews with a consistent appearance.
/// Most day-to-day usage should go through the individual namespaces
/// (`Color.sorayomi*`, `SorayomiTypography.*`, `SorayomiSpacing.*`).
enum SorayomiTheme {
    typealias Colors = Color // Access via Color.sorayomi*
    typealias Typography = SorayomiTypography
    typealias Spacing = SorayomiSpacing
}

// MARK: - Common View Modifiers

enum SorayomiPanelTone {
    case standard
    case elevated
    case spotlight
    case night
}

/// Versatile panel modifier used to build the app's new premium card language.
struct SorayomiPanelModifier: ViewModifier {
    let tone: SorayomiPanelTone
    var padding: CGFloat = SorayomiSpacing.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(background)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: SorayomiSpacing.CornerRadius.large,
                    style: .continuous
                )
            )
            .overlay(border)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }

    private var background: some ShapeStyle {
        switch tone {
        case .standard:
            return AnyShapeStyle(Color.sorayomiSurface.opacity(0.96))
        case .elevated:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.sorayomiSurfaceElevated,
                        Color.sorayomiSurface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .spotlight:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.sorayomiPaper.opacity(0.95),
                        Color.sorayomiSurfaceElevated.opacity(0.98),
                        Color.sorayomiMist.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .night:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.sorayomiNight,
                        Color.sorayomiPrimary,
                        Color.sorayomiNight.opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var border: some View {
        RoundedRectangle(
            cornerRadius: SorayomiSpacing.CornerRadius.large,
            style: .continuous
        )
        .strokeBorder(borderGradient, lineWidth: 1)
    }

    private var borderGradient: LinearGradient {
        switch tone {
        case .night:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.20),
                    Color.sorayomiSecondary.opacity(0.25),
                    Color.white.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.45),
                    Color.sorayomiDivider.opacity(0.65),
                    Color.sorayomiDivider.opacity(0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var shadowColor: Color {
        switch tone {
        case .night:
            return Color.sorayomiPrimary.opacity(0.28)
        case .spotlight:
            return Color.sorayomiAccent.opacity(0.08)
        case .elevated:
            return Color.sorayomiPrimary.opacity(0.10)
        case .standard:
            return Color.sorayomiPrimary.opacity(0.06)
        }
    }

    private var shadowRadius: CGFloat {
        switch tone {
        case .night:
            return 18
        case .spotlight:
            return 16
        case .elevated:
            return 12
        case .standard:
            return 8
        }
    }

    private var shadowY: CGFloat {
        switch tone {
        case .night, .spotlight:
            return 10
        case .elevated:
            return 6
        case .standard:
            return 4
        }
    }
}

/// Card modifier: rounded corners, shadow, padding, surface background.
struct SorayomiCardModifier: ViewModifier {
    var padding: CGFloat = SorayomiSpacing.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.medium, style: .continuous))
            .shadow(
                color: Color.sorayomiTextPrimary.opacity(0.08),
                radius: SorayomiSpacing.shadowRadius,
                x: 0,
                y: SorayomiSpacing.shadowY
            )
    }
}

/// Primary button modifier: filled background, full width, rounded.
struct SorayomiPrimaryButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .font(SorayomiTypography.headline)
            .foregroundStyle(.white)
            .padding(.vertical, SorayomiSpacing.sm + 3)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? [Color.sorayomiPrimary, Color.sorayomiNight]
                        : [Color.sorayomiPrimary.opacity(0.45)]
                        ,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.medium, style: .continuous))
            .shadow(color: Color.sorayomiPrimary.opacity(isEnabled ? 0.16 : 0.05), radius: 10, x: 0, y: 6)
            .contentShape(Rectangle())
    }
}

/// Secondary (outlined) button modifier.
struct SorayomiSecondaryButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .font(SorayomiTypography.headline)
            .foregroundStyle(isEnabled ? Color.sorayomiPrimary : Color.sorayomiPrimary.opacity(0.4))
            .padding(.vertical, SorayomiSpacing.sm + 3)
            .frame(maxWidth: .infinity)
            .background(Color.sorayomiSurface.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.medium, style: .continuous)
                    .strokeBorder(
                        isEnabled ? Color.sorayomiPrimary : Color.sorayomiPrimary.opacity(0.4),
                        lineWidth: 1.5
                    )
            )
            .contentShape(Rectangle())
    }
}

/// Gold accent button modifier for premium / purchase actions.
struct SorayomiGoldButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .font(SorayomiTypography.headline)
            .foregroundStyle(Color.sorayomiTextPrimary)
            .padding(.vertical, SorayomiSpacing.sm + 3)
            .frame(maxWidth: .infinity)
            .background(
                isEnabled
                    ? LinearGradient(
                        colors: [Color.sorayomiSecondary, Color.sorayomiGlow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color.sorayomiSecondary.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.medium, style: .continuous))
            .shadow(color: Color.sorayomiSecondary.opacity(isEnabled ? 0.18 : 0.05), radius: 12, x: 0, y: 6)
            .contentShape(Rectangle())
    }
}

// MARK: - Pressable Button Style

/// Lightweight press-response style: subtle scale-down on tap, no other decoration.
/// Use this on purchase cards and any button that currently uses `.plain` but
/// needs tactile feedback.
struct SorayomiPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies the standard Sorayomi card appearance (surface background,
    /// rounded corners, drop shadow).
    func sorayomiCard(padding: CGFloat = SorayomiSpacing.cardPadding) -> some View {
        modifier(SorayomiCardModifier(padding: padding))
    }

    /// Applies the new premium panel treatment.
    func sorayomiPanel(
        tone: SorayomiPanelTone = .standard,
        padding: CGFloat = SorayomiSpacing.cardPadding
    ) -> some View {
        modifier(SorayomiPanelModifier(tone: tone, padding: padding))
    }

    /// Applies the primary filled-button style.
    func sorayomiButton() -> some View {
        modifier(SorayomiPrimaryButtonModifier())
    }

    /// Applies the secondary outlined-button style.
    func sorayomiSecondaryButton() -> some View {
        modifier(SorayomiSecondaryButtonModifier())
    }

    /// Applies the gold premium-button style.
    func sorayomiGoldButton() -> some View {
        modifier(SorayomiGoldButtonModifier())
    }
}

// MARK: - Previews

#Preview("Card Modifier") {
    VStack(spacing: SorayomiSpacing.lg) {
        Text("Card content")
            .frame(maxWidth: .infinity, minHeight: 100)
            .sorayomiCard()

        Button("Primary Button") {}
            .sorayomiButton()

        Button("Secondary Button") {}
            .sorayomiSecondaryButton()

        Button("Gold Button") {}
            .sorayomiGoldButton()
    }
    .padding(SorayomiSpacing.screenPadding)
    .background(Color.sorayomiBackground)
}
