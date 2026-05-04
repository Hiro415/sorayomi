import SwiftUI

/// Hero card for the daily omikuji ritual on the home screen.
///
/// ■ `isDrawnToday == false` — 未引き状態: 神秘的な印章アニメーション + ドロー誘導UI
/// ■ `isDrawnToday == true`  — 引き済み状態: 当日の結果（ランク・御言葉・開運情報）を表示
struct OmikujiSpotlightCard: View {
    let omikuji: Omikuji
    /// 当日すでにおみくじを引いたかどうか
    var isDrawnToday: Bool = false
    /// 未引き状態でタップしたとき（ドロー起動）
    let action: () -> Void
    /// 引き済み状態でタップしたとき（保存済み結果を表示）
    var onViewResult: (() -> Void)? = nil

    var body: some View {
        Button {
            if isDrawnToday {
                onViewResult?()
            } else {
                action()
            }
        } label: {
            if isDrawnToday {
                drawnContent
            } else {
                preDrawContent
            }
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }

    // MARK: - Drawn State (結果表示)

    private var drawnContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
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
                omikujiPill(title: "吉方",   value: omikuji.luckyDirection, symbol: "location.north.line.fill")
                omikujiPill(title: "吉時間", value: omikuji.luckyTime,      symbol: "clock.fill")
                omikujiPill(title: "開運色", value: omikuji.luckyColor,     symbol: "paintpalette.fill")
                omikujiPill(title: "開運物", value: omikuji.luckyItem,      symbol: "sparkles.square.filled.on.square")
            }

            // 詳しく見るリンク
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
        .cardFrame()
    }

    // MARK: - Pre-Draw State (未引き誘導)

    private var preDrawContent: some View {
        PreDrawContentView(action: action)
    }

    // MARK: - Pill

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
                    .lineLimit(2)
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

// MARK: - Pre-Draw Animated Content (別Viewで@Stateを持つ)

/// カード内の未引きアニメーション。
/// Button 配下で独立した View にすることで @State が正しく機能する。
private struct PreDrawContentView: View {
    let action: () -> Void

    @State private var ringRotation: Double = 0
    @State private var glowPulse: CGFloat = 1.0
    @State private var middlePulse: Double = 0.5
    @State private var arrowOffset: CGFloat = 0
    @State private var arrowOpacity: Double = 0.4

    private let goldColor = Color(red: 1.0, green: 0.86, blue: 0.46)

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // 印章アニメーション（左）
            ZStack {
                // Glow
                Circle()
                    .fill(goldColor.opacity(0.10))
                    .frame(width: 104, height: 104)
                    .blur(radius: 14)
                    .scaleEffect(glowPulse)

                // Outer ring
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                goldColor.opacity(0.9),
                                goldColor.opacity(0.15),
                                goldColor.opacity(0.9),
                                goldColor.opacity(0.15),
                                goldColor.opacity(0.9)
                            ],
                            center: .center
                        ),
                        lineWidth: 1.2
                    )
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(ringRotation))

                // Inner circle
                Circle()
                    .fill(Color(red: 0.12, green: 0.06, blue: 0.26))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                goldColor.opacity(middlePulse * 0.5),
                                lineWidth: 0.8
                            )
                    )

                // 御 kanji
                Text("御")
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [goldColor.opacity(0.95), goldColor.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: goldColor.opacity(0.4), radius: 6)
            }
            .frame(width: 96, height: 96)

            // テキスト + CTA（右）
            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("本日のおみくじ")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(.white.opacity(0.65))

                    Text("本日のおみくじ")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                }

                Text("今日の吉凶を確かめましょう")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(.white.opacity(0.80))
                    .lineSpacing(4)

                // 引く CTA ボタン
                HStack(spacing: 4) {
                    Text("おみくじを引く")
                        .font(SorayomiTypography.footnote)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .offset(x: arrowOffset)
                        .opacity(0.5 + arrowOpacity * 0.5)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())
            }

            Spacer(minLength: 0)
        }
        .cardFrame()
        .onAppear(perform: startAnimations)
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            glowPulse = 1.22
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            middlePulse = 1.0
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.4)) {
            arrowOffset = 3
            arrowOpacity = 1.0
        }
    }
}

// MARK: - Shared card container modifier

private extension View {
    func cardFrame() -> some View {
        self
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
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
}

// MARK: - Previews

#Preview("引き済み") {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        OmikujiSpotlightCard(omikuji: .preview, isDrawnToday: true, action: {})
            .padding()
    }
}

#Preview("未引き") {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        OmikujiSpotlightCard(omikuji: .preview, isDrawnToday: false, action: {})
            .padding()
    }
}
