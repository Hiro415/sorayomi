import SwiftUI

// MARK: - BloodTypeRevealView

/// 血液型占いの4モード別リビールアニメーション
/// モードに応じて異なる演出でフォーチュン結果を表示する。
struct BloodTypeRevealView: View {
    let mode: BloodTypeMode
    let userBloodType: BloodType
    let partnerBloodType: BloodType?
    let dailyFortune: BloodTypeDailyFortune?
    let ranking: BloodTypeRanking?
    let compatibilityData: BloodTypeCompatibilityData?
    let loveSubScores: BloodTypeLoveSubScores?
    let onComplete: () -> Void

    var body: some View {
        switch mode {
        case .dailyFortune:
            DailyFortuneRevealContent(
                bloodType: userBloodType,
                fortune: dailyFortune,
                onComplete: onComplete
            )
        case .compatibility:
            CompatibilityRevealContent(
                userType: userBloodType,
                partnerType: partnerBloodType ?? .a,
                data: compatibilityData,
                onComplete: onComplete
            )
        case .loveMatch:
            LoveMatchRevealContent(
                userType: userBloodType,
                partnerType: partnerBloodType ?? .a,
                subScores: loveSubScores,
                onComplete: onComplete
            )
        case .ranking:
            RankingRevealContent(
                userBloodType: userBloodType,
                ranking: ranking,
                onComplete: onComplete
            )
        }
    }
}

// MARK: - Shared Particle

private struct BloodTypeParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
}

// MARK: - Shared Score Stars

private struct ScoreStarsView: View {
    let score: Int
    let maxScore: Int
    let litCount: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<maxScore, id: \.self) { i in
                Image(systemName: i < litCount ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        i < litCount
                            ? Color(hue: 0.12, saturation: 0.5, brightness: 0.9)
                            : .white.opacity(0.2)
                    )
            }
        }
    }
}

// MARK: - Shared Result Button

private struct RevealResultButton: View {
    let label: String
    let glowPhase: CGFloat
    let onComplete: () -> Void

    var body: some View {
        Button {
            onComplete()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.10, saturation: 0.5, brightness: 0.5),
                                    Color(hue: 0.08, saturation: 0.4, brightness: 0.35),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.12, saturation: 0.3, brightness: 0.9).opacity(0.3 + glowPhase * 0.2),
                                    Color(hue: 0.12, saturation: 0.3, brightness: 0.8).opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color(hue: 0.10, saturation: 0.5, brightness: 0.4).opacity(0.4 + glowPhase * 0.2), radius: 12, y: 4)
        }
    }
}

// MARK: - Mode 1: Daily Fortune (今日の運勢)

private struct DailyFortuneRevealContent: View {
    let bloodType: BloodType
    let fortune: BloodTypeDailyFortune?
    let onComplete: () -> Void

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var revealedBars = 0
    @State private var showLucky = false
    @State private var showButton = false
    @State private var ambientPhase: CGFloat = 0
    @State private var particles: [BloodTypeParticle] = []
    @State private var iconFlip: Double = 0
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider { RevealSizeProvider(availableWidth: viewWidth) }
    private var isLargeScreen: Bool { viewWidth > 600 }

    private let barLabels = ["総合", "恋愛", "仕事", "金運"]

    var body: some View {
        ZStack {
            dailyBackground

            VStack(spacing: 0) {
                Spacer()

                // Blood type icon with 3D flip
                if showIcon {
                    bloodTypeIcon
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, Spacing.md)
                }

                // Title
                if showTitle {
                    Text("\(bloodType.japaneseName)のあなたの今日")
                        .font(.system(size: isLargeScreen ? 26 : 20, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.12, saturation: 0.3, brightness: 0.9),
                                    Color(hue: 0.08, saturation: 0.4, brightness: 0.75),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .transition(.opacity)
                        .padding(.bottom, Spacing.lg)
                }

                // Score bars
                if let fortune = fortune {
                    VStack(spacing: Spacing.sm) {
                        let scores = [fortune.overall, fortune.love, fortune.work, fortune.money]
                        ForEach(0..<4, id: \.self) { i in
                            if i < revealedBars {
                                scoreBarRow(label: barLabels[i], score: scores[i])
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .leading)),
                                        removal: .opacity
                                    ))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.lg)
                }

                // Lucky color + direction
                if showLucky, let fortune = fortune {
                    HStack(spacing: Spacing.lg) {
                        luckyItem(icon: "paintpalette.fill", label: "ラッキーカラー", value: fortune.luckyColor)
                        luckyItem(icon: "compass.drawing", label: "ラッキー方位", value: fortune.luckyDirection)
                    }
                    .transition(.opacity)
                    .padding(.bottom, Spacing.lg)
                }

                Spacer()

                // Button
                if showButton {
                    RevealResultButton(label: "鑑定結果を見る", glowPhase: ambientPhase, onComplete: onComplete)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)).combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            generateParticles()
            startAmbientAnimation()
            startDailySequence()
        }
    }

    private var bloodTypeIcon: some View {
        Text(bloodType.rawValue)
            .font(.system(size: isLargeScreen ? 64 : 48, weight: .bold, design: .serif))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(hue: 0.12, saturation: 0.4, brightness: 0.9),
                        Color(hue: 0.08, saturation: 0.5, brightness: 0.7),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .rotation3DEffect(.degrees(iconFlip), axis: (x: 0, y: 1, z: 0))
    }

    private func scoreBarRow(label: String, score: Int) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(label)
                .font(.system(size: isLargeScreen ? 17 : 14, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 40, alignment: .trailing)

            ScoreStarsView(score: score, maxScore: 5, litCount: score)

            Spacer()
        }
    }

    private func luckyItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: isLargeScreen ? 20 : 16))
                .foregroundStyle(Color(hue: 0.12, saturation: 0.4, brightness: 0.8))
            Text(label)
                .font(.system(size: isLargeScreen ? 12 : 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.system(size: isLargeScreen ? 17 : 14, weight: .semibold, design: .serif))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var dailyBackground: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    Color(hue: 0.75, saturation: 0.4, brightness: 0.15),
                    Color(hue: 0.78, saturation: 0.3, brightness: 0.08),
                    .black,
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )

            ForEach(particles) { particle in
                Circle()
                    .fill(.white)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .blur(radius: particle.blur)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.75, saturation: 0.5, brightness: 0.5).opacity(0.06),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .scaleEffect(1.0 + ambientPhase * 0.15)
                .opacity(0.5 + ambientPhase * 0.3)
        }
        .ignoresSafeArea()
    }

    private func startDailySequence() {
        // 0.3s: icon with Y-axis flip
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                showIcon = true
            }
            withAnimation(.easeInOut(duration: 0.6)) {
                iconFlip = 360
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // 0.8s: title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                showTitle = true
            }
        }

        // 1.2-2.4s: score bars (0.4s stagger)
        for i in 0..<4 {
            let delay = 1.2 + Double(i) * 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                    revealedBars = i + 1
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }

        // 3.0s: lucky items
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showLucky = true
            }
        }

        // 3.5s: button
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }

    private func startAmbientAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            ambientPhase = 1.0
        }
    }

    private func generateParticles() {
        let w = viewWidth
        let h = viewWidth * 2.16
        particles = (0..<18).map { _ in
            BloodTypeParticle(
                position: CGPoint(x: .random(in: 0...w), y: .random(in: 0...h)),
                size: .random(in: 1...3.5),
                opacity: .random(in: 0.1...0.6),
                blur: .random(in: 0...0.5)
            )
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            while !Task.isCancelled {
                for i in particles.indices {
                    withAnimation(.easeInOut(duration: .random(in: 1.5...3.0))) {
                        particles[i].opacity = .random(in: 0.05...0.6)
                        particles[i].position.y -= .random(in: 0...3)
                    }
                }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
}

// MARK: - Mode 2: Compatibility (相性診断)

private struct CompatibilityRevealContent: View {
    let userType: BloodType
    let partnerType: BloodType
    let data: BloodTypeCompatibilityData?
    let onComplete: () -> Void

    @State private var showUser = false
    @State private var showPartner = false
    @State private var mergeToCenter = false
    @State private var showMeter = false
    @State private var meterProgress: CGFloat = 0
    @State private var litStars = 0
    @State private var showDescription = false
    @State private var showButton = false
    @State private var ambientPhase: CGFloat = 0
    @State private var sparkleParticles: [BloodTypeParticle] = []
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }
    private var isLargeScreen: Bool { viewWidth > 600 }

    var body: some View {
        ZStack {
            compatibilityBackground

            VStack(spacing: 0) {
                Spacer()

                // Two blood types
                HStack(spacing: mergeToCenter ? Spacing.lg : viewWidth * 0.25) {
                    if showUser {
                        bloodTypeBadge(type: userType)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    if showPartner {
                        bloodTypeBadge(type: partnerType)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.bottom, Spacing.xl)

                // Sparkle particles between types
                if mergeToCenter {
                    HStack(spacing: 2) {
                        ForEach(sparkleParticles) { p in
                            Circle()
                                .fill(Color(hue: 0.12, saturation: 0.4, brightness: 0.9))
                                .frame(width: p.size, height: p.size)
                                .opacity(p.opacity)
                        }
                    }
                    .transition(.opacity)
                    .padding(.bottom, Spacing.sm)
                }

                // Circular compatibility meter
                if showMeter, let data = data {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.1), lineWidth: 8)
                            .frame(width: sizes.bloodTypeCircle, height: sizes.bloodTypeCircle)

                        Circle()
                            .trim(from: 0, to: meterProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.sorayomiFortuneGradientStart, .sorayomiFortuneGradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: sizes.bloodTypeCircle, height: sizes.bloodTypeCircle)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            ScoreStarsView(score: data.score, maxScore: 5, litCount: litStars)

                            Text("\(data.score)")
                                .font(.system(size: isLargeScreen ? 44 : 32, weight: .bold, design: .serif))
                                .foregroundStyle(.white)

                            Text("/ 5")
                                .font(.system(size: isLargeScreen ? 14 : 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, Spacing.lg)
                }

                // Description
                if showDescription, let data = data {
                    Text(data.description)
                        .font(.system(size: isLargeScreen ? 17 : 14, weight: .regular, design: .serif))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .transition(.opacity)
                        .padding(.bottom, Spacing.lg)
                }

                Spacer()

                // Button
                if showButton {
                    RevealResultButton(label: "鑑定結果を見る", glowPhase: ambientPhase, onComplete: onComplete)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)).combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            startAmbientAnimation()
            startCompatibilitySequence()
        }
    }

    private func bloodTypeBadge(type: BloodType) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(type.rawValue)
                .font(.system(size: isLargeScreen ? 48 : 36, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.12, saturation: 0.4, brightness: 0.9),
                            Color(hue: 0.08, saturation: 0.5, brightness: 0.7),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(type.japaneseName)
                .font(.system(size: isLargeScreen ? 14 : 12, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var compatibilityBackground: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    Color(hue: 0.72, saturation: 0.4, brightness: 0.15),
                    Color(hue: 0.75, saturation: 0.3, brightness: 0.08),
                    .black,
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.12, saturation: 0.5, brightness: 0.6).opacity(0.06),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .scaleEffect(1.0 + ambientPhase * 0.15)
                .opacity(0.5 + ambientPhase * 0.3)
        }
        .ignoresSafeArea()
    }

    private func startCompatibilitySequence() {
        // 0.3s: user type slides in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                showUser = true
            }
        }

        // 0.6s: partner type slides in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                showPartner = true
            }
        }

        // 1.0s: merge toward center + sparkles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            generateSparkles()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                mergeToCenter = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // 1.5s: meter appears and fills
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showMeter = true
            }
            let targetProgress = CGFloat(data?.score ?? 3) / 5.0
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                meterProgress = targetProgress
            }
        }

        // 2.2s: stars light up
        let starCount = data?.score ?? 3
        for i in 0..<starCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2 + Double(i) * 0.15) {
                withAnimation(.easeOut(duration: 0.2)) {
                    litStars = i + 1
                }
            }
        }

        // 2.8s: description
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                showDescription = true
            }
        }

        // 3.3s: button
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }

    private func generateSparkles() {
        sparkleParticles = (0..<8).map { _ in
            BloodTypeParticle(
                position: .zero,
                size: .random(in: 2...5),
                opacity: .random(in: 0.3...0.8),
                blur: .random(in: 0...0.5)
            )
        }
        Task { @MainActor in
            while !Task.isCancelled {
                for i in sparkleParticles.indices {
                    withAnimation(.easeInOut(duration: .random(in: 0.8...1.5))) {
                        sparkleParticles[i].opacity = .random(in: 0.1...0.8)
                    }
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func startAmbientAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            ambientPhase = 1.0
        }
    }
}

// MARK: - Mode 3: Love Match (恋愛相性)

private struct LoveMatchRevealContent: View {
    let userType: BloodType
    let partnerType: BloodType
    let subScores: BloodTypeLoveSubScores?
    let onComplete: () -> Void

    @State private var showTypes = false
    @State private var showTitle = false
    @State private var revealedScores = 0
    @State private var showButton = false
    @State private var ambientPhase: CGFloat = 0
    @State private var heartScale: CGFloat = 1.0
    @State private var particles: [BloodTypeParticle] = []
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider { RevealSizeProvider(availableWidth: viewWidth) }
    private var isLargeScreen: Bool { viewWidth > 600 }

    private let scoreLabels = ["コミュニケーション", "価値観", "情熱度", "長期安定度"]

    var body: some View {
        ZStack {
            loveBackground

            VStack(spacing: 0) {
                Spacer()

                // Types merging with heart pulse
                if showTypes {
                    HStack(spacing: Spacing.md) {
                        Text(userType.japaneseName)
                            .font(.system(size: isLargeScreen ? 32 : 24, weight: .bold, design: .serif))
                            .foregroundStyle(.white)

                        Image(systemName: "heart.fill")
                            .font(.system(size: isLargeScreen ? 36 : 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hue: 0.95, saturation: 0.6, brightness: 0.9),
                                        Color(hue: 0.85, saturation: 0.5, brightness: 0.7),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(heartScale)

                        Text(partnerType.japaneseName)
                            .font(.system(size: isLargeScreen ? 32 : 24, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, Spacing.md)
                }

                // Title
                if showTitle {
                    Text("\(userType.japaneseName) \u{00D7} \(partnerType.japaneseName)の恋の相性")
                        .font(.system(size: isLargeScreen ? 20 : 16, weight: .semibold, design: .serif))
                        .foregroundStyle(.white.opacity(0.7))
                        .transition(.opacity)
                        .padding(.bottom, Spacing.xl)
                }

                // Sub-scores
                if let subScores = subScores {
                    VStack(spacing: Spacing.md) {
                        let scores = [subScores.communication, subScores.values, subScores.passion, subScores.stability]
                        ForEach(0..<4, id: \.self) { i in
                            if i < revealedScores {
                                loveScoreRow(label: scoreLabels[i], score: scores[i])
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    ))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                Spacer()

                // Button
                if showButton {
                    RevealResultButton(label: "鑑定結果を見る", glowPhase: ambientPhase, onComplete: onComplete)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)).combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            generateHeartParticles()
            startAmbientAnimation()
            startLoveSequence()
        }
    }

    private func loveScoreRow(label: String, score: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(.system(size: isLargeScreen ? 14 : 12, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: Spacing.sm) {
                // Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hue: 0.95, saturation: 0.5, brightness: 0.8),
                                        Color(hue: 0.80, saturation: 0.4, brightness: 0.6),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(score) / 5.0, height: 8)
                    }
                }
                .frame(height: 8)

                ScoreStarsView(score: score, maxScore: 5, litCount: score)
            }
        }
    }

    private var loveBackground: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    Color(hue: 0.92, saturation: 0.35, brightness: 0.18),
                    Color(hue: 0.80, saturation: 0.30, brightness: 0.10),
                    .black,
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )

            // Heart-shaped particles
            ForEach(particles) { particle in
                Image(systemName: "heart.fill")
                    .font(.system(size: particle.size))
                    .foregroundStyle(Color(hue: 0.95, saturation: 0.4, brightness: 0.8))
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .blur(radius: particle.blur)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.92, saturation: 0.5, brightness: 0.5).opacity(0.06),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .scaleEffect(1.0 + ambientPhase * 0.15)
                .opacity(0.5 + ambientPhase * 0.3)
        }
        .ignoresSafeArea()
    }

    private func startLoveSequence() {
        // 0.5s: types merge with heart pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                showTypes = true
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            // Heart pulse animation
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                heartScale = 1.15
            }
        }

        // 1.0s: title
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showTitle = true
            }
        }

        // 1.4-2.6s: sub-scores (0.3s stagger)
        for i in 0..<4 {
            let delay = 1.4 + Double(i) * 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                    revealedScores = i + 1
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }

        // 3.2s: button
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }

    private func startAmbientAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            ambientPhase = 1.0
        }
    }

    private func generateHeartParticles() {
        let w = viewWidth
        let h = viewWidth * 2.16
        particles = (0..<15).map { _ in
            BloodTypeParticle(
                position: CGPoint(x: .random(in: 0...w), y: .random(in: 0...h)),
                size: .random(in: 4...10),
                opacity: .random(in: 0.05...0.2),
                blur: .random(in: 0.5...1.5)
            )
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            while !Task.isCancelled {
                for i in particles.indices {
                    withAnimation(.easeInOut(duration: .random(in: 2.0...4.0))) {
                        particles[i].opacity = .random(in: 0.03...0.2)
                        particles[i].position.y -= .random(in: 1...5)
                    }
                }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
}

// MARK: - Mode 4: Ranking (ランキング)

private struct RankingRevealContent: View {
    let userBloodType: BloodType
    let ranking: BloodTypeRanking?
    let onComplete: () -> Void

    @State private var showTitle = false
    @State private var revealedRanks = 0
    @State private var highlightUser = false
    @State private var showButton = false
    @State private var ambientPhase: CGFloat = 0
    @State private var firstPlaceScale: CGFloat = 0.8
    @State private var burstParticles: [BloodTypeParticle] = []
    @State private var showBurst = false
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider { RevealSizeProvider(availableWidth: viewWidth) }
    private var isLargeScreen: Bool { viewWidth > 600 }

    var body: some View {
        ZStack {
            rankingBackground

            ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: Spacing.xl)

                // Title + trophy
                if showTitle {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: isLargeScreen ? 44 : 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hue: 0.12, saturation: 0.5, brightness: 0.9),
                                        Color(hue: 0.08, saturation: 0.4, brightness: 0.6),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("今日の血液型ランキング")
                            .font(.system(size: isLargeScreen ? 22 : 18, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hue: 0.12, saturation: 0.3, brightness: 0.9),
                                        Color(hue: 0.08, saturation: 0.4, brightness: 0.75),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .padding(.bottom, Spacing.xl)
                }

                // Ranking entries: 表示は1位→4位（上→下）、リビールは4位→1位の順
                if let ranking = ranking {
                    let sortedEntries = ranking.entries.sorted { $0.rank < $1.rank } // 1位が上
                    let totalEntries = sortedEntries.count
                    VStack(spacing: Spacing.sm) {
                        ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                            // リビール順: 4位(index=3)→1位(index=0) = 下から上に表示
                            let revealIndex = totalEntries - 1 - index
                            if revealIndex < revealedRanks {
                                rankRow(entry: entry, isFirst: entry.rank == 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(
                                                Color(hue: 0.12, saturation: 0.5, brightness: 0.9).opacity(
                                                    highlightUser && entry.bloodType == userBloodType ? 0.6 : 0
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .scaleEffect(entry.rank == 1 ? firstPlaceScale : 1.0)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                                        removal: .opacity
                                    ))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // Particle burst for 1st place
                if showBurst {
                    ZStack {
                        ForEach(burstParticles) { p in
                            Circle()
                                .fill(Color(hue: 0.12, saturation: 0.5, brightness: 0.9))
                                .frame(width: p.size, height: p.size)
                                .position(p.position)
                                .opacity(p.opacity)
                        }
                    }
                    .frame(height: 60)
                    .transition(.opacity)
                }

                Spacer(minLength: Spacing.lg)

                // Button
                if showButton {
                    RevealResultButton(label: "あなたの詳細を見る", glowPhase: ambientPhase, onComplete: onComplete)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)).combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }
            }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            startAmbientAnimation()
            startRankingSequence()
        }
    }

    private func rankRow(entry: BloodTypeRanking.Entry, isFirst: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor(for: entry.rank))
                    .frame(width: 32, height: 32)

                Text("\(entry.rank)")
                    .font(.system(size: isLargeScreen ? 20 : 16, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            }
            .shadow(color: rankGlowColor(for: entry.rank), radius: isFirst ? 8 : 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Spacing.sm) {
                    Text(entry.bloodType.japaneseName)
                        .font(.system(size: isLargeScreen ? 22 : 18, weight: .bold, design: .serif))
                        .foregroundStyle(.white)

                    Spacer()

                    ScoreStarsView(score: entry.score, maxScore: 5, litCount: entry.score)
                }

                Text(entry.oneLiner)
                    .font(.system(size: isLargeScreen ? 13 : 11, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(isFirst ? 0.08 : 0.04))
        )
    }

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(hue: 0.12, saturation: 0.6, brightness: 0.7)  // gold
        case 2: return Color(hue: 0.0, saturation: 0.0, brightness: 0.55)  // silver
        case 3: return Color(hue: 0.07, saturation: 0.5, brightness: 0.45) // bronze
        default: return .white.opacity(0.2)
        }
    }

    private func rankGlowColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(hue: 0.12, saturation: 0.5, brightness: 0.8).opacity(0.5)
        case 2: return Color(hue: 0.0, saturation: 0.0, brightness: 0.6).opacity(0.3)
        case 3: return Color(hue: 0.07, saturation: 0.4, brightness: 0.5).opacity(0.3)
        default: return .clear
        }
    }

    private var rankingBackground: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    Color(hue: 0.10, saturation: 0.3, brightness: 0.12),
                    Color(hue: 0.72, saturation: 0.2, brightness: 0.06),
                    .black,
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.12, saturation: 0.5, brightness: 0.6).opacity(0.04),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .scaleEffect(1.0 + ambientPhase * 0.15)
                .opacity(0.5 + ambientPhase * 0.3)
        }
        .ignoresSafeArea()
    }

    private func startRankingSequence() {
        // 0.0s: title + trophy
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
            showTitle = true
        }

        // 0.8s: 4th place (subtle)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                revealedRanks = 1
            }
        }

        // 1.5s: 3rd place (bronze glow + medium haptic)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                revealedRanks = 2
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // 2.2s: 2nd place (silver glow + medium haptic)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                revealedRanks = 3
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // 3.0s: 1st place (gold glow + heavy haptic + particle burst + scale bounce)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                revealedRanks = 4
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                firstPlaceScale = 1.05
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            generateBurstParticles()

            // Settle scale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    firstPlaceScale = 1.0
                }
            }
        }

        // 3.8s: highlight user's rank
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                highlightUser = true
            }
        }

        // 4.3s: button
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }

    private func generateBurstParticles() {
        let centerX = viewWidth / 2
        burstParticles = (0..<20).map { _ in
            BloodTypeParticle(
                position: CGPoint(
                    x: centerX + .random(in: -80...80),
                    y: .random(in: 10...50)
                ),
                size: .random(in: 2...5),
                opacity: .random(in: 0.4...0.9),
                blur: .random(in: 0...0.5)
            )
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showBurst = true
        }
        // Fade out burst
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 1.0)) {
                for i in burstParticles.indices {
                    burstParticles[i].opacity = 0
                }
            }
        }
    }

    private func startAmbientAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            ambientPhase = 1.0
        }
    }
}

// MARK: - Preview

#Preview("Daily Fortune") {
    BloodTypeRevealView(
        mode: .dailyFortune,
        userBloodType: .a,
        partnerBloodType: nil,
        dailyFortune: BloodTypeCompatibility.dailyFortune(for: .a),
        ranking: nil,
        compatibilityData: nil,
        loveSubScores: nil,
        onComplete: {}
    )
}

#Preview("Compatibility") {
    BloodTypeRevealView(
        mode: .compatibility,
        userBloodType: .a,
        partnerBloodType: .b,
        dailyFortune: nil,
        ranking: nil,
        compatibilityData: BloodTypeCompatibility.compatibility(between: .a, and: .b),
        loveSubScores: nil,
        onComplete: {}
    )
}

#Preview("Love Match") {
    BloodTypeRevealView(
        mode: .loveMatch,
        userBloodType: .o,
        partnerBloodType: .b,
        dailyFortune: nil,
        ranking: nil,
        compatibilityData: nil,
        loveSubScores: BloodTypeCompatibility.loveSubScores(between: .o, and: .b),
        onComplete: {}
    )
}

#Preview("Ranking") {
    BloodTypeRevealView(
        mode: .ranking,
        userBloodType: .a,
        partnerBloodType: nil,
        dailyFortune: nil,
        ranking: BloodTypeCompatibility.dailyRanking(),
        compatibilityData: nil,
        loveSubScores: nil,
        onComplete: {}
    )
}
