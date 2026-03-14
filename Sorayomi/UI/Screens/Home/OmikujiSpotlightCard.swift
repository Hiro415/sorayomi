import SwiftUI

/// Hero card for the daily omikuji ritual on the home screen.
struct OmikujiSpotlightCard: View {
    let omikuji: Omikuji
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("本日のおみくじ")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(.white.opacity(0.72))

                        Text(omikuji.rank.japaneseName)
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundStyle(.white)

                        Text(omikuji.rank.nuance)
                            .font(SorayomiTypography.footnote)
                            .foregroundStyle(.white.opacity(0.86))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: Spacing.xxs) {
                        Text("今日の御言葉")
                            .font(SorayomiTypography.caption2)
                            .foregroundStyle(.white.opacity(0.6))

                        Image(systemName: "scroll.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }

                Text(omikuji.poem)
                    .japaneseText(SorayomiTypography.callout, lineSpacing: 5)
                    .foregroundStyle(.white.opacity(0.96))

                Text(omikuji.guidance)
                    .font(SorayomiTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.86))
                    .lineSpacing(5)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.xs),
                        GridItem(.flexible(), spacing: Spacing.xs)
                    ],
                    spacing: Spacing.xs
                ) {
                    omikujiPill(
                        title: "吉方",
                        value: omikuji.luckyDirection,
                        symbol: "location.north.line.fill"
                    )
                    omikujiPill(
                        title: "吉時間",
                        value: omikuji.luckyTime,
                        symbol: "clock.fill"
                    )
                    omikujiPill(
                        title: "開運色",
                        value: omikuji.luckyColor,
                        symbol: "paintpalette.fill"
                    )
                    omikujiPill(
                        title: "開運物",
                        value: omikuji.luckyItem,
                        symbol: "sparkles.square.filled.on.square"
                    )
                }

                HStack(spacing: Spacing.xs) {
                    Text("詳しく読む")
                        .font(SorayomiTypography.footnote)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.white.opacity(0.14))
                .clipShape(Capsule())
            }
            .padding(Spacing.lg)
            .background(
                LinearGradient(
                    colors: [
                        Color.sorayomiFortuneGradientStart,
                        Color.sorayomiFortuneGradientEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
            )
            .shadow(
                color: Color.sorayomiFortuneGradientStart.opacity(0.3),
                radius: 18,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(.plain)
    }

    private func omikujiPill(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(.white.opacity(0.6))

                Text(value)
                    .font(SorayomiTypography.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
    }
}

#Preview {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        OmikujiSpotlightCard(omikuji: .preview, action: {})
            .padding()
    }
}
