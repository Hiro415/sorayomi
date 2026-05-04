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
    @State private var viewSize: CGSize = CGSize(width: 390, height: 844)
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
            Text("※ 鑑定結果はエンターテインメント目的です")
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
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            viewSize = newSize
        }
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
            .font(.system(size: 15, weight: .medium, design: .serif))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(hue: 0.12, saturation: 0.35, brightness: 0.92),
                        Color(hue: 0.08, saturation: 0.45, brightness: 0.78),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
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
        guard let system = fortuneSystem else {
            return ["場を整えています", "気の流れを感じています"]
        }
        switch system {
        case .omikuji:
            return [
                "おみくじ筒を静かに振っています",
                "神前の空気を整えています",
                "今日の運を受け取る準備をしています",
            ]
        case .horoscope:
            return [
                "星の配置を読み込んでいます",
                "天球儀を回しています",
                "星座の記憶を辿っています",
            ]
        case .bloodType:
            return [
                "気質パターンを照合しています",
                "血液型の傾向を整理しています",
                "体質のリズムを感じています",
            ]
        case .birthdayPersonality:
            return [
                "誕生日の星を探しています",
                "生まれた日のエネルギーを感じています",
                "誕生数を計算しています",
            ]
        case .tarot:
            return [
                "カードをシャッフルしています",
                "タロットデッキを清めています",
                "カードとの対話を始めています",
            ]
        case .numerology:
            return [
                "数字の振動を読み取っています",
                "ライフパスナンバーを算出しています",
                "数字の神秘に耳を澄ませています",
            ]
        case .nineStarKi:
            return [
                "九星の巡りを確認しています",
                "本命星の位置を計算しています",
                "方位盤を回しています",
            ]
        case .rokuyo:
            return [
                "暦を繰っています",
                "今日の六曜を読み解いています",
                "吉凶のリズムを確認しています",
            ]
        case .flowerFortune:
            return [
                "花の声に耳を澄ませています",
                "誕生花の花言葉を読み解いています",
                "今日の花を選んでいます",
            ]
        case .stoneFortune:
            return [
                "パワーストーンの波動を感じています",
                "誕生石との共鳴を読み取っています",
                "今日の守護石を探しています",
            ]
        case .generalConsultation:
            return [
                "あなたの声に耳を澄ませています",
                "お話の糸を整理しています",
                "最も合う見方を探しています",
            ]
        }
    }

    private var readingMessages: [String] {
        guard let system = fortuneSystem else {
            return ["見立てを深めています", "流れを読み解いています"]
        }
        switch system {
        case .omikuji:
            return [
                "御言葉が降りてくるのを待っています",
                "今日の運の色を見ています",
                "吉凶の境を丁寧に見極めています",
                "神前の静けさの中で読み取っています",
            ]
        case .horoscope:
            return [
                "天体のささやきを聞いています",
                "星の配列が語る物語を読んでいます",
                "あなたの星座に光を当てています",
                "惑星の軌道から流れを追っています",
            ]
        case .bloodType:
            return [
                "気質の奥を読み解いています",
                "相性のパターンを紡いでいます",
                "あなたの内なるリズムを感じています",
                "血の記憶を辿っています",
            ]
        case .birthdayPersonality:
            return [
                "生まれた日の運命を辿っています",
                "あなたに宿る資質を読んでいます",
                "誕生日が教える物語を紡いでいます",
                "数秘の光を追いかけています",
            ]
        case .tarot:
            return [
                "カードが語りかけています",
                "スプレッドの物語を読み解いています",
                "正位置と逆位置の境を見ています",
                "カードの象徴が浮かび上がっています",
            ]
        case .numerology:
            return [
                "数字が囁くメッセージを聞いています",
                "運命の数列を紐解いています",
                "隠された数のパターンを追っています",
                "数の共鳴を感じ取っています",
            ]
        case .nineStarKi:
            return [
                "気の流れを手繰っています",
                "吉方位を丁寧に見極めています",
                "五行の相生相剋を読んでいます",
                "星の巡りが示す景色を見ています",
            ]
        case .rokuyo:
            return [
                "暦の知恵を引き出しています",
                "天の時を慎重に計っています",
                "吉凶の波を読んでいます",
                "暦が語る今日の物語を聞いています",
            ]
        case .flowerFortune:
            return [
                "花びらの囁きを聞いています",
                "花言葉の奥を読み解いています",
                "花の香りに導かれています",
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
                "あなたの悩みの奥を見つめています",
                "流れの中にある転機を探しています",
                "最も大切な一点を見極めています",
                "導きの言葉を紡いでいます",
            ]
        }
    }

    private var summarizingMessages: [String] {
        [
            "鑑定の全体像をまとめています",
            "あなたへの言葉を仕上げています",
            "最後の一筆を入れています",
            "導きの手紙を封じています",
        ]
    }

    // MARK: - Animations

    private var animatedDots: String {
        String(repeating: ".", count: dotCount + 1)
    }

    private func startMessageCycle() {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.8))
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
        let screenWidth = viewSize.width
        let screenHeight = viewSize.height

        particles = (0..<15).map { _ in
            LoadingParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 20...max(screenWidth - 20, 40)),
                    y: CGFloat.random(in: 80...max(screenHeight - 80, 160))
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
