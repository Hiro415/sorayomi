import SwiftUI

// MARK: - QuickAccessGrid

/// Fortune system grid shown on the home screen.
struct QuickAccessGrid: View {
    let systems: [FortuneSystem]
    let onSelect: (FortuneSystem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("その他の占術")
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text("定番の占いから本格鑑定まで、必要なときに選べます。")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer()
            }

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(systems) { system in
                    QuickAccessCard(system: system) {
                        onSelect(system)
                    }
                }
            }
        }
    }
}

private struct QuickAccessCard: View {
    let system: FortuneSystem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    Image(systemName: system.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(iconBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

                    Spacer()

                    Text(system.highlightLabel)
                        .font(SorayomiTypography.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badgeColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(system.shortName)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text(system.japaneseDescription)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                HStack {
                    creditBadge
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(Color.sorayomiPrimary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
            .padding(Spacing.md)
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(Color.sorayomiDivider.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: Color.sorayomiPrimary.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var iconBackground: some ShapeStyle {
        LinearGradient(
            colors: gradientColors(for: system),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var creditBadge: some View {
        if system.creditCost == 0 {
            Text("無料")
                .font(SorayomiTypography.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Color.sorayomiSuccess)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.sorayomiSuccess.opacity(0.12))
                .clipShape(Capsule())
        } else {
            HStack(spacing: 4) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 9))
                Text("\(system.creditCost)")
                    .font(SorayomiTypography.caption2)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.sorayomiSecondary)
        }
    }

    private var badgeColor: Color {
        switch system.tier {
        case .daily:    return .sorayomiAccent
        case .standard: return .sorayomiPrimary
        case .premium:  return .sorayomiSecondary
        }
    }

    private func gradientColors(for system: FortuneSystem) -> [Color] {
        switch system.tier {
        case .daily:
            return [.sorayomiAccent, .sorayomiFortuneGradientEnd]
        case .standard:
            return [.sorayomiFortuneGradientStart, .sorayomiFortuneGradientEnd]
        case .premium:
            return [.sorayomiSecondary, .sorayomiPrimary]
        }
    }
}

#Preview {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        ScrollView {
            QuickAccessGrid(
                systems: FortuneSystem.showcaseOrder,
                onSelect: { _ in }
            )
            .padding()
        }
    }
}
