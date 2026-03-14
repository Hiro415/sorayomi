import SwiftUI

// MARK: - ReadingLoadingView

/// 鑑定生成中のローディング表示
/// 段階的な「儀式」演出で占い体験を盛り上げる。
/// 3つのフェーズ（準備 → 鑑定中 → まとめ中）を切り替えながら
/// プログレスバー、パーティクル、ハプティクスで没入感を演出する。
struct ReadingLoadingView: View {
    /// 選択された占いシステム
    var fortuneSystem: FortuneSystem?

    // MARK: - State

    @State private var isAnimating = false
    @State private var currentPhase: LoadingPhase = .preparing
    @State private var messageIndex = 0
    @State private var dotCount = 0
    @State private var progress: CGFloat = 0
    @State private var particles: [LoadingParticle] = []
    @State private var showPhaseLabel = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // フェーズラベル
            phaseLabelView
                .padding(.bottom, Spacing.lg)

            // 中央のシンボル
            centralSymbol
                .padding(.bottom, Spacing.lg)

            // ローディングメッセージ
            messageView
                .padding(.bottom, Spacing.xl)

            // プログレスバー
            progressBar
                .padding(.horizontal, Spacing.xxl)
                .padding(.bottom, Spacing.sm)

            // プログレステキスト
            Text(currentPhase.progressLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))

            Spacer()

            // 免責事項
            Text("※ AIが鑑定内容を生成しております")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
                .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color.sorayomiBackground

                // パーティクル
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
        )
        .onAppear {
            isAnimating = true
            generateParticles()
            animateParticles()
            startMessageCycle()
            startDotAnimation()
            startPhaseTransitions()
            startProgressAnimation()
        }
    }

    // MARK: - Phase Label

    private var phaseLabelView: some View {
        Text(currentPhase.label)
            .font(.system(size: 12, weight: .medium, design: .serif))
            .tracking(2)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(hue: 0.12, saturation: 0.4, brightness: 0.85),
                        Color(hue: 0.08, saturation: 0.5, brightness: 0.75),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(showPhaseLabel ? 1 : 0)
            .scaleEffect(showPhaseLabel ? 1.0 : 0.9)
            .animation(.easeOut(duration: 0.5), value: showPhaseLabel)
            .animation(.easeOut(duration: 0.4), value: currentPhase)
    }

    // MARK: - Central Symbol

    private var centralSymbol: some View {
        ZStack {
            // 外側リング
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hue: 0.12, saturation: 0.5, brightness: 0.8).opacity(0.3),
                            Color(hue: 0.08, saturation: 0.6, brightness: 0.7).opacity(0.1),
                            Color(hue: 0.12, saturation: 0.5, brightness: 0.8).opacity(0.3),
                            Color(hue: 0.08, saturation: 0.4, brightness: 0.6).opacity(0.1),
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 110, height: 110)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 6).repeatForever(autoreverses: false),
                    value: isAnimating
                )

            // 中間リング（ダッシュ、逆回転）
            Circle()
                .stroke(
                    Color.sorayomiTextSecondary.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 8])
                )
                .frame(width: 92, height: 92)
                .rotationEffect(.degrees(isAnimating ? -360 : 0))
                .animation(
                    .linear(duration: 10).repeatForever(autoreverses: false),
                    value: isAnimating
                )

            // 内側グロー
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.12, saturation: 0.5, brightness: 0.8).opacity(0.12),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 42
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(isAnimating ? 1.15 : 0.85)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            // 中央アイコン
            Image(systemName: systemIcon)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.12, saturation: 0.45, brightness: 0.95),
                            Color(hue: 0.08, saturation: 0.55, brightness: 0.8),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
    }

    // MARK: - Message View

    private var messageView: some View {
        Text(currentMessages[messageIndex % currentMessages.count] + animatedDots)
            .font(.system(size: 14, weight: .regular, design: .serif))
            .foregroundStyle(Color.sorayomiTextSecondary)
            .multilineTextAlignment(.center)
            .frame(height: 24)
            .animation(.easeInOut(duration: 0.3), value: messageIndex)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.sorayomiDivider.opacity(0.3))

                // プログレス
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: 0.12, saturation: 0.5, brightness: 0.85),
                                Color(hue: 0.08, saturation: 0.6, brightness: 0.75),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)

                // シマーエフェクト
                if progress > 0.05 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40)
                        .offset(x: isAnimating
                            ? geometry.size.width * progress
                            : -40
                        )
                        .animation(
                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
            }
        }
        .frame(height: 6)
    }

    // MARK: - System Icon

    private var systemIcon: String {
        fortuneSystem?.iconName ?? "sparkles"
    }

    // MARK: - Messages per Phase

    private var currentMessages: [String] {
        switch currentPhase {
        case .preparing:
            return preparingMessages
        case .reading:
            return readingMessages
        case .summarizing:
            return summarizingMessages
        }
    }

    private var preparingMessages: [String] {
        guard let system = fortuneSystem else { return ["準備しています"] }
        switch system {
        case .omikuji:       return ["おみくじを整えています", "本日の御言葉を選んでいます"]
        case .horoscope:     return ["星の配置を確認しています", "天体の位置を計算しています"]
        case .bloodType:     return ["血液型の特性を分析しています", "気質パターンを確認しています"]
        case .birthdayPersonality: return ["誕生日の星を読み解いています", "誕生数を計算しています"]
        case .tarot:         return ["カードをシャッフルしています", "カードを展開しています"]
        case .numerology:    return ["数字の神秘を計算しています", "ライフパスナンバーを分析中"]
        case .nineStarKi:    return ["九星の巡りを確認しています", "本命星のエネルギーを読み取っています"]
        case .rokuyo:        return ["今日の六曜を確認しています", "暦の導きを読み解いています"]
        }
    }

    private var readingMessages: [String] {
        guard let system = fortuneSystem else { return ["鑑定しています"] }
        switch system {
        case .omikuji:       return ["神前のような静けさを整えています", "今日の運の流れを受け取っています"]
        case .horoscope:     return ["天体のエネルギーを感じ取っています", "星座からのメッセージを受信中"]
        case .bloodType:     return ["気質と相性を読み解いています", "内なるエネルギーの流れを感じています"]
        case .birthdayPersonality: return ["生まれた日のエネルギーを感じ取っています", "運命の糸を辿っています"]
        case .tarot:         return ["タロットカードのメッセージを読み解いています", "運命のカードが語りかけています"]
        case .numerology:    return ["数字が語るメッセージを紡いでいます", "運命の数列を読み解いています"]
        case .nineStarKi:    return ["吉方位を計算しています", "気の流れを感じ取っています"]
        case .rokuyo:        return ["吉凶の流れを感じ取っています", "天の時を計っています"]
        }
    }

    private var summarizingMessages: [String] {
        ["鑑定結果をまとめています", "あなたへのメッセージを仕上げています"]
    }

    // MARK: - Animations

    private var animatedDots: String {
        String(repeating: ".", count: dotCount + 1)
    }

    private func startMessageCycle() {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageIndex = (messageIndex + 1)
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

    private func startPhaseTransitions() {
        Task { @MainActor in
            // フェーズ1: 準備（即時表示）
            withAnimation(.easeOut(duration: 0.5)) {
                showPhaseLabel = true
            }

            // フェーズ2: 鑑定中（1.5秒後）
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeInOut(duration: 0.4)) {
                showPhaseLabel = false
            }
            try? await Task.sleep(for: .seconds(0.2))
            currentPhase = .reading
            messageIndex = 0
            withAnimation(.easeOut(duration: 0.5)) {
                showPhaseLabel = true
            }

            // フェーズ3: まとめ中（4秒後）
            try? await Task.sleep(for: .seconds(4.0))
            withAnimation(.easeInOut(duration: 0.4)) {
                showPhaseLabel = false
            }
            try? await Task.sleep(for: .seconds(0.2))
            currentPhase = .summarizing
            messageIndex = 0
            withAnimation(.easeOut(duration: 0.5)) {
                showPhaseLabel = true
            }
        }
    }

    private func startProgressAnimation() {
        Task { @MainActor in
            // フェーズ1: 0% → 30%（1.5秒）
            withAnimation(.easeOut(duration: 1.5)) {
                progress = 0.3
            }

            // フェーズ2: 30% → 70%（4秒）
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeInOut(duration: 4.0)) {
                progress = 0.7
            }

            // フェーズ3: 70% → 90%（ゆっくり）
            try? await Task.sleep(for: .seconds(4.0))
            withAnimation(.easeInOut(duration: 3.0)) {
                progress = 0.9
            }

            // 最後のスパート: 90% → 95%
            try? await Task.sleep(for: .seconds(3.0))
            withAnimation(.easeInOut(duration: 2.0)) {
                progress = 0.95
            }
        }
    }

    // MARK: - Particles

    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        particles = (0..<15).map { _ in
            LoadingParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 20...(screenWidth - 20)),
                    y: CGFloat.random(in: 80...(screenHeight - 80))
                ),
                size: CGFloat.random(in: 1.5...3.5),
                opacity: 0,
                color: [
                    Color(hue: 0.12, saturation: 0.4, brightness: 0.9),
                    Color(hue: 0.08, saturation: 0.3, brightness: 0.8),
                    Color.white,
                ].randomElement()!.opacity(0.4),
                blur: CGFloat.random(in: 0...1.0)
            )
        }
    }

    private func animateParticles() {
        Task { @MainActor in
            // フェードイン
            for i in particles.indices {
                let delay = Double.random(in: 0.5...2.0)
                withAnimation(.easeInOut(duration: 1.0).delay(delay)) {
                    particles[i].opacity = Double.random(in: 0.15...0.5)
                }
            }

            // ゆっくり上昇
            try? await Task.sleep(for: .seconds(1.5))
            for i in particles.indices {
                withAnimation(.easeInOut(duration: Double.random(in: 4.0...8.0))) {
                    particles[i].position.y -= CGFloat.random(in: 30...60)
                }
            }

            // きらめきループ
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.0))
                for i in particles.indices {
                    withAnimation(.easeInOut(duration: Double.random(in: 1.0...2.5))) {
                        particles[i].opacity = Double.random(in: 0.1...0.5)
                    }
                }
            }
        }
    }
}

// MARK: - LoadingPhase

private enum LoadingPhase {
    case preparing
    case reading
    case summarizing

    var label: String {
        switch self {
        case .preparing:   return "― 準 備 ―"
        case .reading:     return "― 鑑 定 中 ―"
        case .summarizing: return "― 仕 上 げ ―"
        }
    }

    var progressLabel: String {
        switch self {
        case .preparing:   return "鑑定の準備をしています..."
        case .reading:     return "あなたの運勢を読み解いています..."
        case .summarizing: return "鑑定結果をまとめています..."
        }
    }
}

// MARK: - LoadingParticle

private struct LoadingParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var color: Color
    var blur: CGFloat
}

// MARK: - Preview

#Preview {
    ReadingLoadingView(fortuneSystem: .tarot)
}
