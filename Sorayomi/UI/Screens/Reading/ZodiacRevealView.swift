import SwiftUI

/// 星座占いリビールビュー
/// Celestial-themed reveal animation showing the user's zodiac sign,
/// daily horoscope scores, planetary influence, and element harmony
/// with a starfield background and constellation motif.
struct ZodiacRevealView: View {
    let sign: ZodiacSign
    let horoscope: ZodiacCalculator.DailyHoroscope
    let onComplete: () -> Void

    // MARK: - Animation State

    @State private var phase: RevealPhase = .starfield
    @State private var starOpacity: Double = 0
    @State private var constellationScale: CGFloat = 0.3
    @State private var constellationOpacity: Double = 0
    @State private var constellationAnimateIn: Bool = false
    @State private var signNameOpacity: Double = 0
    @State private var planetaryOpacity: Double = 0
    @State private var scoreBarProgress: [CGFloat] = [0, 0, 0, 0, 0]
    @State private var detailsOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var starPositions: [(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = []
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }

    private var isLargeScreen: Bool { viewWidth > 600 }

    private enum RevealPhase {
        case starfield, constellation, scores, complete
    }

    var body: some View {
        ZStack {
            // Celestial background
            celestialBackground

            // Star particles
            starParticles

            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    Spacer().frame(height: 40)

                    // Constellation symbol
                    constellationSection

                    // Sign name & element
                    signInfoSection

                    // Planetary influence
                    planetarySection

                    // Score bars
                    scoreSection

                    // Lucky details
                    luckyDetailsSection

                    // Continue button
                    continueButton

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            generateStarPositions()
            startRevealSequence()
        }
    }

    // MARK: - Celestial Background

    private var celestialBackground: some View {
        ZStack {
            // Deep space gradient using sign's element colors
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.08, green: 0.06, blue: 0.2),
                    sign.themeGradient[0].opacity(0.3),
                    Color(red: 0.03, green: 0.03, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Nebula glow
            RadialGradient(
                colors: [
                    sign.accentColor.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()
            .opacity(constellationOpacity)
        }
    }

    // MARK: - Star Particles

    private var starParticles: some View {
        GeometryReader { geo in
            ForEach(0..<starPositions.count, id: \.self) { i in
                let star = starPositions[i]
                Circle()
                    .fill(Color.white)
                    .frame(width: star.size, height: star.size)
                    .position(
                        x: star.x * geo.size.width,
                        y: star.y * geo.size.height
                    )
                    .opacity(starOpacity)
                    .animation(
                        .easeInOut(duration: 1.5 + star.delay)
                            .repeatForever(autoreverses: true)
                            .delay(star.delay),
                        value: starOpacity
                    )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Constellation Section

    private var constellationSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: sign.themeGradient + [sign.accentColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: sizes.constellationGlowSize, height: sizes.constellationGlowSize)
                    .opacity(constellationOpacity * 0.4)

                // Constellation nebula glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                sign.accentColor.opacity(0.12),
                                sign.themeGradient[0].opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 120
                        )
                    )
                    .frame(width: sizes.constellationGlowSize, height: sizes.constellationGlowSize)

                // Real constellation star map
                ZodiacConstellationView(
                    sign: sign,
                    accentColor: sign.accentColor,
                    animateIn: constellationAnimateIn
                )
                .frame(width: sizes.constellationSize, height: sizes.constellationSize)

                // Zodiac emoji overlay (small, bottom right)
                Text(sign.emoji)
                    .font(.system(size: isLargeScreen ? 36 : 24))
                    .shadow(color: sign.accentColor.opacity(0.6), radius: 8)
                    .offset(x: sizes.constellationSize * 0.36, y: sizes.constellationSize * 0.36)
                    .opacity(constellationOpacity * 0.7)
            }
            .scaleEffect(constellationScale)
            .opacity(constellationOpacity)

            // Element badge
            HStack(spacing: 6) {
                Image(systemName: elementIcon(sign.element))
                    .font(.caption)
                Text(sign.element.japaneseName)
                    .font(SorayomiTypography.caption)
                Text("・")
                Text(sign.modality.japaneseName)
                    .font(SorayomiTypography.caption)
            }
            .foregroundStyle(sign.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(sign.accentColor.opacity(0.15))
                    .overlay(Capsule().strokeBorder(sign.accentColor.opacity(0.3), lineWidth: 0.5))
            )
            .opacity(constellationOpacity)
        }
    }

    // MARK: - Sign Info

    private var signInfoSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(sign.japaneseName)
                .font(.system(size: isLargeScreen ? 38 : 28, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, sign.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(sign.dateRange)
                .font(SorayomiTypography.caption)
                .foregroundStyle(.white.opacity(0.6))

            Text("支配星：\(sign.rulingPlanet.japaneseName)")
                .font(SorayomiTypography.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
        .opacity(signNameOpacity)
    }

    // MARK: - Planetary Section

    private var planetarySection: some View {
        VStack(spacing: Spacing.sm) {
            // Planetary influence card
            HStack(spacing: Spacing.sm) {
                Image(systemName: sign.rulingPlanet.symbolName)
                    .font(.title3)
                    .foregroundStyle(sign.accentColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(sign.accentColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("今日の惑星の影響")
                        .font(SorayomiTypography.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(horoscope.planetaryInfluence)
                        .font(SorayomiTypography.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(sign.accentColor.opacity(0.2), lineWidth: 0.5)
                    )
            )

            // Element harmony card
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(sign.accentColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(sign.accentColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("エレメントの調和")
                        .font(SorayomiTypography.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(horoscope.elementHarmony)
                        .font(SorayomiTypography.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(sign.accentColor.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .opacity(planetaryOpacity)
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        VStack(spacing: Spacing.md) {
            Text("今日の星の導き")
                .font(.system(size: isLargeScreen ? 22 : 16, weight: .semibold, design: .serif))
                .foregroundStyle(.white.opacity(0.9))

            let scores: [(String, String, Int, Int)] = [
                ("総合運", "star.fill", horoscope.overallScore, 0),
                ("恋愛運", "heart.fill", horoscope.loveScore, 1),
                ("仕事運", "briefcase.fill", horoscope.workScore, 2),
                ("金運", "yensign.circle.fill", horoscope.moneyScore, 3),
                ("健康運", "leaf.fill", horoscope.healthScore, 4),
            ]

            ForEach(scores, id: \.0) { label, icon, score, idx in
                scoreBar(label: label, icon: icon, score: score, progress: scoreBarProgress[idx])
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [sign.accentColor.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .opacity(detailsOpacity)
    }

    private func scoreBar(label: String, icon: String, score: Int, progress: CGFloat) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(sign.accentColor)
                .frame(width: 20)

            Text(label)
                .font(SorayomiTypography.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 48, alignment: .leading)

            // Star rating bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: sign.themeGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (CGFloat(score) / 5.0) * progress)

                    // Shimmer overlay
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60)
                        .offset(x: shimmerOffset)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(height: 8)

            // Star icons
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: i < score ? "star.fill" : "star")
                        .font(.system(size: 10))
                        .foregroundStyle(i < score ? sign.accentColor : .white.opacity(0.2))
                }
            }
        }
        .frame(height: 24)
    }

    // MARK: - Lucky Details

    private var luckyDetailsSection: some View {
        VStack(spacing: Spacing.md) {
            // Advice
            Text(horoscope.advice)
                .font(SorayomiTypography.footnote)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.sm)

            // Lucky items grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                luckyItem(icon: "paintpalette.fill", label: "ラッキーカラー", value: horoscope.luckyColor)
                luckyItem(icon: "number", label: "ラッキーナンバー", value: "\(horoscope.luckyNumber)")
                luckyItem(icon: "safari.fill", label: "吉方位", value: horoscope.luckyDirection)
            }

            // Power stone
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkle")
                    .font(.caption2)
                    .foregroundStyle(sign.accentColor)
                Text("パワーストーン：\(sign.powerStone)")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .opacity(detailsOpacity)
    }

    private func luckyItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(sign.accentColor)
            Text(label)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(SorayomiTypography.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onComplete) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkle")
                Text("鑑定を受け取る")
                    .font(SorayomiTypography.body)
                    .fontWeight(.semibold)
                Image(systemName: "sparkle")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: sign.themeGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: sign.accentColor.opacity(0.4), radius: 12, y: 4)
            )
        }
        .opacity(detailsOpacity)
    }

    // MARK: - Helpers

    private func elementIcon(_ element: ZodiacElement) -> String {
        switch element {
        case .fire:  return "flame.fill"
        case .earth: return "mountain.2.fill"
        case .air:   return "wind"
        case .water: return "drop.fill"
        }
    }

    private func generateStarPositions() {
        starPositions = (0..<60).map { _ in
            (
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 1...3),
                delay: Double.random(in: 0...2)
            )
        }
    }

    // MARK: - Animation Sequence

    private func startRevealSequence() {
        // Phase 1: Stars fade in
        withAnimation(.easeIn(duration: 1.0)) {
            starOpacity = 0.8
        }

        // Phase 2: Constellation appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                constellationScale = 1.0
                constellationOpacity = 1.0
            }
            // Trigger constellation star-line animation slightly after container appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                constellationAnimateIn = true
            }
        }

        // Phase 3: Sign name
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                signNameOpacity = 1.0
            }
        }

        // Phase 4: Planetary info
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.6)) {
                planetaryOpacity = 1.0
            }
        }

        // Phase 5: Scores animate in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                detailsOpacity = 1.0
            }
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        scoreBarProgress[i] = 1.0
                    }
                }
            }
        }

        // Phase 6: Shimmer effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZodiacRevealView(
        sign: .leo,
        horoscope: ZodiacCalculator.dailyHoroscope(for: .leo),
        onComplete: {}
    )
}
