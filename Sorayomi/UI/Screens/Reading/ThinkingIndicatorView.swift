import SwiftUI

// MARK: - ThinkingIndicatorView

/// Claude Code風の「考え中」インジケーター
/// 占いコンテキストに合わせた文言が1.8秒ごとに切り替わる。
struct ThinkingIndicatorView: View {
    var fortuneSystem: FortuneSystem?

    @State private var messageIndex = 0
    @State private var dotCount = 0
    @State private var isVisible = false

    /// 金色のグラデーション
    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: 0.12, saturation: 0.5, brightness: 0.9),
                Color(hue: 0.08, saturation: 0.6, brightness: 0.8),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // パルスするスパークルアイコン
            ZStack {
                // グローエフェクト
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hue: 0.12, saturation: 0.4, brightness: 0.9).opacity(isVisible ? 0.25 : 0.05),
                                Color.clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 16
                        )
                    )
                    .frame(width: 32, height: 32)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isVisible
                    )

                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(goldGradient)
                    .scaleEffect(isVisible ? 1.1 : 0.85)
                    .opacity(isVisible ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isVisible
                    )
            }

            // ローテーションメッセージ
            Text(currentMessage + animatedDots)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.sorayomiTextPrimary.opacity(0.85),
                            Color(hue: 0.10, saturation: 0.3, brightness: 0.65),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: messageIndex)

            Spacer()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                .fill(Color.sorayomiSurface.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.12, saturation: 0.4, brightness: 0.85).opacity(0.25),
                                    Color(hue: 0.08, saturation: 0.3, brightness: 0.7).opacity(0.10),
                                    Color(hue: 0.12, saturation: 0.4, brightness: 0.85).opacity(0.20),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            isVisible = true
            startMessageCycle()
            startDotAnimation()
        }
    }

    // MARK: - Current Message

    private var currentMessage: String {
        let msgs = thinkingMessages
        return msgs[messageIndex % msgs.count]
    }

    private var animatedDots: String {
        String(repeating: ".", count: dotCount + 1)
    }

    // MARK: - Messages

    private var thinkingMessages: [String] {
        guard let system = fortuneSystem else {
            return defaultMessages
        }
        switch system {
        case .omikuji:
            return [
                "御言葉を受け取っています",
                "神前の気を整えています",
                "今日の運の色を見ています",
                "吉凶の境を見極めています",
                "おみくじを読み解いています",
            ]
        case .horoscope:
            return [
                "星の配置を読んでいます",
                "天体のささやきを聞いています",
                "あなたの星座に光を当てています",
                "惑星の軌道を追っています",
                "星の物語を紡いでいます",
            ]
        case .bloodType:
            return [
                "気質のパターンを読んでいます",
                "相性の糸を辿っています",
                "内なるリズムを感じています",
                "血の記憶を紐解いています",
            ]
        case .birthdayPersonality:
            return [
                "生まれた日の運命を辿っています",
                "あなたの資質を読んでいます",
                "誕生日の物語を紡いでいます",
                "数秘の光を追いかけています",
            ]
        case .tarot:
            return [
                "カードが語りかけています",
                "スプレッドを読み解いています",
                "カードの象徴を追っています",
                "正位置と逆位置の境を見ています",
                "タロットの物語を紡いでいます",
            ]
        case .numerology:
            return [
                "数字の囁きを聞いています",
                "運命の数列を紐解いています",
                "隠れたパターンを追っています",
                "数の共鳴を感じています",
            ]
        case .nineStarKi:
            return [
                "気の流れを手繰っています",
                "吉方位を見極めています",
                "五行の相生相剋を読んでいます",
                "星の巡りを辿っています",
            ]
        case .rokuyo:
            return [
                "暦の知恵を引き出しています",
                "天の時を計っています",
                "吉凶の波を読んでいます",
                "暦の物語を聞いています",
            ]
        case .flowerFortune:
            return [
                "花びらの囁きを聞いています",
                "花言葉の奥を読み解いています",
                "花の香りを辿っています",
                "季節の花が語りかけています",
            ]
        case .stoneFortune:
            return [
                "石の輝きを読み取っています",
                "チャクラの共鳴を感じています",
                "パワーストーンの導きを受けています",
                "クリスタルの光を追っています",
            ]
        case .generalConsultation:
            return [
                "あなたの声に耳を澄ませています",
                "流れの中の転機を探しています",
                "大切な一点を見極めています",
                "導きの言葉を紡いでいます",
                "見立てを深めています",
            ]
        }
    }

    private var defaultMessages: [String] {
        [
            "見立てを深めています",
            "流れを読み解いています",
            "言葉を紡いでいます",
            "導きを探しています",
        ]
    }

    // MARK: - Animations

    private func startMessageCycle() {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageIndex += 1
                }
            }
        }
    }

    private func startDotAnimation() {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.5))
                dotCount = (dotCount + 1) % 3
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        ThinkingIndicatorView(fortuneSystem: .tarot)
        ThinkingIndicatorView(fortuneSystem: .generalConsultation)
        ThinkingIndicatorView(fortuneSystem: nil)
    }
    .padding()
    .background(Color.sorayomiBackground)
}
