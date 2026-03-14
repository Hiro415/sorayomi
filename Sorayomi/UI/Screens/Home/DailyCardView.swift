import SwiftUI

// MARK: - DailyCardView

/// Today's overall snapshot card combining quick fortune signals.
struct DailyCardView: View {
    let fortune: DailyFortune?

    var body: some View {
        Group {
            if let fortune {
                fortuneContent(fortune)
            } else {
                placeholderContent
            }
        }
    }

    @ViewBuilder
    private func fortuneContent(_ fortune: DailyFortune) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("今日の総合運")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)

                    Text(fortune.fortuneLevel)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text(formattedDate(fortune.date))
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(fortune.starRating)
                        .font(SorayomiTypography.title3)
                        .foregroundStyle(Color.sorayomiSecondary)

                    HStack(spacing: Spacing.xxs) {
                        badge(text: fortune.zodiacSign.japaneseName)
                        badge(text: fortune.rokuyo.japaneseName)
                    }
                }
            }

            Rectangle()
                .fill(Color.sorayomiDivider.opacity(0.8))
                .frame(height: 1)

            Text(fortune.horoscopeSnippet)
                .japaneseText(SorayomiTypography.body, lineSpacing: 6)
                .foregroundStyle(Color.sorayomiTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !fortune.bloodTypeSnippet.isEmpty {
                Text(fortune.bloodTypeSnippet)
                    .font(SorayomiTypography.callout)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
            }

            HStack(spacing: Spacing.sm) {
                luckyInfoItem(
                    icon: "paintpalette.fill",
                    label: "ラッキーカラー",
                    value: fortune.luckyColor
                )

                luckyInfoItem(
                    icon: "gift.fill",
                    label: "ラッキーアイテム",
                    value: fortune.luckyItem
                )
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.large, style: .continuous)
                .fill(Color.sorayomiSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.large, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.sorayomiSecondary.opacity(0.45),
                            Color.sorayomiDivider,
                            Color.sorayomiAccent.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .background(
            LinearGradient(
                colors: [
                    Color.sorayomiSecondary.opacity(0.10),
                    Color.clear,
                    Color.sorayomiAccent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.large, style: .continuous))
        .shadow(color: Color.sorayomiPrimary.opacity(0.10), radius: 16, x: 0, y: 8)
    }

    private func luckyInfoItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.sorayomiAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                Text(value)
                    .font(SorayomiTypography.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.sorayomiTextPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.sorayomiPaper)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
    }

    private var placeholderContent: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.sorayomiAccent)

            Text("今日の運勢を読み込み中")
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.sorayomiTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.large, style: .continuous)
                .fill(Color.sorayomiSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SorayomiSpacing.CornerRadius.large, style: .continuous)
                .strokeBorder(Color.sorayomiDivider, lineWidth: 1)
        )
    }

    private func badge(text: String) -> some View {
        Text(text)
            .font(SorayomiTypography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.sorayomiPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.sorayomiPaper)
            .clipShape(Capsule())
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（EEEE）"
        return formatter.string(from: date)
    }
}

#Preview("With Fortune") {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        ScrollView {
            DailyCardView(fortune: .mock)
                .padding()
        }
    }
}

#Preview("Loading") {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        ScrollView {
            DailyCardView(fortune: nil)
                .padding()
        }
    }
}
