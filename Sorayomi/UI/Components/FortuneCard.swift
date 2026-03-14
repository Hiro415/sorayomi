import SwiftUI

/// Reusable card for displaying fortune system options and daily insights.
struct FortuneCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    var gradientColors: [Color] = [.sorayomiFortuneGradientStart, .sorayomiFortuneGradientEnd]
    var creditCost: Int? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)
                    Text(subtitle)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                if let cost = creditCost {
                    if cost == 0 {
                        Text("無料")
                            .font(SorayomiTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.sorayomiSuccess)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, Spacing.xxs)
                            .background(Color.sorayomiSuccess.opacity(0.1))
                            .clipShape(Capsule())
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "diamond.fill")
                                .font(.caption2)
                            Text("\(cost)")
                                .font(SorayomiTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color.sorayomiSecondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
            }
            .padding(Spacing.md)
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        FortuneCard(
            title: "タロットの導き",
            subtitle: "カードが映し出す、今のあなたへの導き",
            iconName: "rectangle.portrait.on.rectangle.portrait.fill",
            creditCost: 1
        )
        FortuneCard(
            title: "六曜の導き",
            subtitle: "日本の暦が教える、今日の吉凶と過ごし方",
            iconName: "calendar",
            creditCost: 0
        )
    }
    .padding()
    .background(Color.sorayomiBackground)
}
