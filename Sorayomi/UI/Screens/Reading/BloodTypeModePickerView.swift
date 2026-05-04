import SwiftUI

// MARK: - BloodTypeModePickerView

/// A 2×2 grid of fortune mode cards for blood type divination.
struct BloodTypeModePickerView: View {
    let userBloodType: BloodType
    let onSelect: (BloodTypeMode) -> Void
    let onBack: () -> Void

    @State private var appearedCards: Set<BloodTypeMode> = []

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                modeGrid
                backButton
            }
            .adaptiveScreenPadding()
            .contentWidthConstraint()
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.bottomSafeArea)
        }
        .background(backgroundGradient)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.sorayomiAccent)

                Text("血液型占い")
                    .font(SorayomiTypography.title2)
                    .foregroundStyle(Color.sorayomiTextPrimary)
            }

            Text("\(userBloodType.japaneseName)のあなた")
                .font(SorayomiTypography.headline)
                .foregroundStyle(Color.sorayomiSecondary)
        }
    }

    // MARK: - Mode Grid

    private var modeGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(BloodTypeMode.allCases) { mode in
                modeCard(for: mode)
            }
        }
    }

    private func modeCard(for mode: BloodTypeMode) -> some View {
        let index = BloodTypeMode.allCases.firstIndex(of: mode) ?? 0
        return BloodTypeModeCard(
            mode: mode,
            isVisible: appearedCards.contains(mode),
            onSelect: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onSelect(mode)
            }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.1)) {
                _ = appearedCards.insert(mode)
            }
        }
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("占術を選び直す")
                    .font(SorayomiTypography.callout)
            }
            .foregroundStyle(Color.sorayomiTextSecondary)
        }
        .buttonStyle(.plain)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color.sorayomiBackground.ignoresSafeArea()
            RadialGradient(
                colors: [
                    Color.sorayomiFortuneGradientEnd.opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - BloodTypeModeCard

private struct BloodTypeModeCard: View {
    let mode: BloodTypeMode
    let isVisible: Bool
    let onSelect: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(iconGradient)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.CornerRadius.medium, style: .continuous))

                Text(mode.japaneseName)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(mode.description)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(Color.sorayomiPrimary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
            .padding(Spacing.md)
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.CornerRadius.large, style: .continuous)
                    .strokeBorder(Color.sorayomiDivider.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .shadow(
            color: Color.sorayomiPrimary.opacity(0.04),
            radius: Spacing.shadowRadius,
            x: 0,
            y: Spacing.shadowY
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 16)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = false
                    }
                }
        )
    }

    private var iconGradient: some ShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [.sorayomiAccent, .sorayomiFortuneGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Preview

#Preview {
    BloodTypeModePickerView(
        userBloodType: .a,
        onSelect: { _ in },
        onBack: { }
    )
}
