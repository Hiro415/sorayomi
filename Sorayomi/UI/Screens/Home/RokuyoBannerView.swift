import SwiftUI

// MARK: - RokuyoBannerView

/// Compact Japanese-calendar banner.
struct RokuyoBannerView: View {
    let rokuyo: Rokuyo

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(rokuyo.isAuspicious ? Color.sorayomiSecondary : Color.sorayomiTextSecondary)
                .frame(width: 44, height: 44)
                .background(
                    (rokuyo.isAuspicious ? Color.sorayomiSecondary : Color.sorayomiTextSecondary)
                        .opacity(0.10)
                )
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text("六曜")
                        .font(SorayomiTypography.caption2)
                        .foregroundStyle(Color.sorayomiTextSecondary)

                    Text(rokuyo.japaneseName)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)
                }

                Text(rokuyo.briefGuidance)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(rokuyo.isAuspicious ? "整えどき" : "慎重どき")
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                Text(rokuyo.luckyTimeOfDay)
                    .font(SorayomiTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(rokuyo.isAuspicious ? Color.sorayomiSecondary : Color.sorayomiTextPrimary)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(Spacing.md)
        .background(Color.sorayomiSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                .strokeBorder(
                    rokuyo.isAuspicious
                        ? Color.sorayomiSecondary.opacity(0.25)
                        : Color.sorayomiDivider.opacity(0.6),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.sorayomiPrimary.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            RokuyoBannerView(rokuyo: .taian)
            RokuyoBannerView(rokuyo: .butsumetsu)
        }
        .padding()
    }
}
