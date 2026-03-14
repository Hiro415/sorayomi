import SwiftUI

// MARK: - FortuneSystemPickerView

/// Grouped fortune system picker for the reading tab.
struct FortuneSystemPickerView: View {
    let selectedSystem: FortuneSystem?
    let onSelect: (FortuneSystem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            pickerSection(
                title: "毎日の導き",
                subtitle: "無料でさっと見られる、日本の暮らしに馴染む占術",
                systems: FortuneSystem.showcaseOrder.filter { $0.tier == .daily }
            )

            pickerSection(
                title: "じっくり鑑定",
                subtitle: "恋愛や仕事の悩みを深く読み解きたい日に",
                systems: FortuneSystem.showcaseOrder.filter { $0.tier != .daily }
            )
        }
    }

    private func pickerSection(
        title: String,
        subtitle: String,
        systems: [FortuneSystem]
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(subtitle)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(systems) { system in
                    FortuneSystemCard(
                        system: system,
                        isSelected: selectedSystem == system,
                        onSelect: { onSelect(system) }
                    )
                }
            }
        }
    }
}

private struct FortuneSystemCard: View {
    let system: FortuneSystem
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    Image(systemName: system.iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : Color.sorayomiPrimary)
                        .frame(width: 40, height: 40)
                        .background(iconBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

                    Spacer()

                    Text(system.highlightLabel)
                        .font(SorayomiTypography.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.88) : badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            isSelected
                                ? Color.white.opacity(0.14)
                                : badgeColor.opacity(0.10)
                        )
                        .clipShape(Capsule())
                }

                Text(system.shortName)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(isSelected ? .white : Color.sorayomiTextPrimary)

                Text(system.japaneseDescription)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : Color.sorayomiTextSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack(spacing: Spacing.xs) {
                    creditBadge
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.right")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.92) : Color.sorayomiPrimary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 196, alignment: .topLeading)
            .padding(Spacing.md)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.20) : Color.sorayomiDivider.opacity(0.6),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .shadow(
            color: isSelected ? Color.sorayomiFortuneGradientEnd.opacity(0.22) : Color.sorayomiPrimary.opacity(0.04),
            radius: isSelected ? 16 : 8,
            x: 0,
            y: isSelected ? 8 : 4
        )
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.sorayomiFortuneGradientStart, .sorayomiFortuneGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(Color.sorayomiSurface)
    }

    private var iconBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.white.opacity(0.16))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: system.tier == .premium
                    ? [.sorayomiSecondary.opacity(0.95), .sorayomiPrimary]
                    : [.sorayomiAccent, .sorayomiFortuneGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    @ViewBuilder
    private var creditBadge: some View {
        if system.creditCost == 0 {
            Text("無料")
                .font(SorayomiTypography.caption2)
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? Color.white : Color.sorayomiSuccess)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isSelected ? Color.white.opacity(0.14) : Color.sorayomiSuccess.opacity(0.12)
                )
                .clipShape(Capsule())
        } else {
            HStack(spacing: 4) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 8))
                Text("\(system.creditCost)")
                    .font(SorayomiTypography.caption2)
                    .fontWeight(.bold)
            }
            .foregroundStyle(isSelected ? Color.white : Color.sorayomiSecondary)
        }
    }

    private var badgeColor: Color {
        switch system.tier {
        case .daily:    return .sorayomiAccent
        case .standard: return .sorayomiPrimary
        case .premium:  return .sorayomiSecondary
        }
    }
}

#Preview {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        ScrollView {
            FortuneSystemPickerView(
                selectedSystem: .omikuji,
                onSelect: { _ in }
            )
            .padding(Spacing.md)
        }
    }
}
