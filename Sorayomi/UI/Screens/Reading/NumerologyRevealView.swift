import SwiftUI

/// 数秘術リビールビュー
/// Displays an animated numerology reveal with sacred geometry,
/// life path archetype, personal cycle cascade, number harmony visualization,
/// and pinnacle/challenge life map.
struct NumerologyRevealView: View {
    let energy: NumerologyCalculator.DailyNumerologyEnergy
    let profile: NumerologyProfile
    let onComplete: () -> Void

    // MARK: - Animation State

    @State private var sacredGeometryPhase: CGFloat = 0
    @State private var sacredGeometryRotation: Double = 0
    @State private var lifePathRevealed = false
    @State private var lifePathScale: CGFloat = 0.3
    @State private var cycleAppeared: [Bool] = [false, false, false] // year, month, day
    @State private var harmonyProgress: CGFloat = 0
    @State private var scoreRevealed = false
    @State private var pinnacleOpacity: Double = 0
    @State private var luckyOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var particlePhase: CGFloat = 0
    @State private var numberPulse: CGFloat = 0
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }

    private var isLargeScreen: Bool { viewWidth > 600 }

    private var archetype: NumerologyProfile.NumberArchetype {
        NumerologyProfile.archetype(for: energy.lifePathNumber)
    }

    private var themeColor: Color {
        Color(hex: archetype.colorHex) ?? .purple
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    Spacer().frame(height: 30)

                    // Sacred Geometry + Life Path Number
                    lifePathSection

                    // Personal Cycle Cascade
                    cycleSection

                    // Number Harmony
                    harmonySection

                    // Overall Score
                    scoreSection

                    // Pinnacle & Challenge
                    pinnacleSection

                    // Lucky Timing
                    luckySection

                    // CTA Button
                    ctaButton

                    Spacer().frame(height: 40)
                }
                .adaptiveScreenPadding()
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            startRevealSequence()
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            // Deep cosmic gradient
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.12),
                    Color(red: 0.08, green: 0.04, blue: 0.18),
                    Color(red: 0.05, green: 0.02, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Element-themed nebula glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeColor.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .frame(width: sizes.numerologyGlow, height: sizes.numerologyGlow)
                .offset(y: -100)
                .blur(radius: 40)

            // Floating number particles
            Canvas { context, size in
                let w = Double(size.width)
                let h = Double(size.height)
                let pp = Double(particlePhase)
                for i in 0..<40 {
                    let seed = Double(i) * 137.508
                    let x = (sin(seed + pp * .pi * 2) * 0.5 + 0.5) * w
                    let y = (cos(seed * 0.7 + pp * .pi) * 0.5 + 0.5) * h
                    let alpha = 0.08 + sin(seed * 3 + pp * .pi * 4) * 0.06
                    let radius = 1.0 + sin(seed) * 0.8

                    context.opacity = alpha
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Circle().path(in: rect), with: .color(.white))
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Life Path Section

    private var lifePathSection: some View {
        VStack(spacing: Spacing.lg) {
            // Sacred Geometry Ring
            ZStack {
                sacredGeometryRing
                    .opacity(sacredGeometryPhase)

                // Central number
                VStack(spacing: 4) {
                    Text("\(energy.lifePathNumber)")
                        .font(.system(size: isLargeScreen ? 100 : 72, weight: .thin, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeColor, themeColor.opacity(0.7), .white],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: themeColor.opacity(0.6), radius: 20)
                        .scaleEffect(lifePathScale)

                    if NumerologyCalculator.isMasterNumber(energy.lifePathNumber) {
                        // 数秘術の国際的専門用語として英語表記を意図的に使用
                        Text("MASTER NUMBER")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundStyle(themeColor)
                    }
                }
            }
            .frame(height: sizes.numerologyCentralRing)

            // Archetype info
            VStack(spacing: Spacing.sm) {
                Text(archetype.title)
                    .font(.system(size: isLargeScreen ? 36 : 28, weight: .light, design: .serif))
                    .foregroundStyle(.white)

                // 数秘術の国際的専門用語として英語表記を意図的に使用
                Text("LIFE PATH NUMBER")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.5))

                // Element + Polarity + Ruling badges
                HStack(spacing: Spacing.sm) {
                    archetypeBadge(
                        icon: archetype.element.symbolName,
                        text: archetype.element.rawValue
                    )
                    archetypeBadge(
                        icon: archetype.polarity == .yang ? "sun.max.fill" : "moon.fill",
                        text: archetype.polarity.rawValue
                    )
                    archetypeBadge(
                        icon: "sparkle",
                        text: archetype.ruling
                    )
                }

                Text(archetype.keyword)
                    .font(SorayomiTypography.callout)
                    .foregroundStyle(themeColor)
                    .padding(.top, 2)

                Text(archetype.personality)
                    .japaneseText(SorayomiTypography.caption, lineSpacing: 5)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
            }
            .opacity(lifePathRevealed ? 1.0 : 0.0)
        }
    }

    private func archetypeBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(themeColor.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(themeColor.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Sacred Geometry Ring

    private var sacredGeometryRing: some View {
        ZStack {
            // Outer rotating ring
            ForEach(0..<9, id: \.self) { i in
                let angle = Double(i) * 40.0 + sacredGeometryRotation
                let rad = angle * .pi / 180
                Circle()
                    .fill(themeColor.opacity(0.2 + sin(rad * 2) * 0.1))
                    .frame(width: 8, height: 8)
                    .offset(
                        x: cos(rad) * (85.0 / 390.0 * viewWidth),
                        y: sin(rad) * (85.0 / 390.0 * viewWidth)
                    )
            }

            // Inner ring
            Circle()
                .stroke(themeColor.opacity(0.15), lineWidth: 1)
                .frame(width: sizes.numerologyInnerRing, height: sizes.numerologyInnerRing)

            // Outer ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [themeColor.opacity(0.4), themeColor.opacity(0.05), themeColor.opacity(0.4)],
                        center: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: sizes.numerologyOuterRing, height: sizes.numerologyOuterRing)
                .rotationEffect(.degrees(sacredGeometryRotation))

            // Sacred polygon (number of sides = life path base)
            sacredPolygon(sides: max(3, min(9, baseSingle(energy.lifePathNumber))), radius: 65.0 / 390.0 * viewWidth)
                .stroke(themeColor.opacity(0.2), lineWidth: 0.8)
                .rotationEffect(.degrees(-sacredGeometryRotation * 0.3))

            // Pulsing glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeColor.opacity(0.15 * numberPulse), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: sizes.numerologyCentralRing, height: sizes.numerologyCentralRing)
        }
    }

    private func sacredPolygon(sides: Int, radius: CGFloat) -> Path {
        Path { path in
            for i in 0...sides {
                let angle = (CGFloat(i) / CGFloat(sides)) * 2 * .pi - .pi / 2
                let point = CGPoint(
                    x: radius * cos(angle),
                    y: radius * sin(angle)
                )
                if i == 0 {
                    path.move(to: CGPoint(x: point.x + radius + 25, y: point.y + radius + 25))
                } else {
                    path.addLine(to: CGPoint(x: point.x + radius + 25, y: point.y + radius + 25))
                }
            }
            path.closeSubpath()
        }
    }

    // MARK: - Cycle Section

    private var cycleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("パーソナルサイクル", subtitle: "あなたの9年サイクルの現在地")

            VStack(spacing: Spacing.sm) {
                cycleCard(
                    label: "パーソナルイヤー",
                    number: energy.personalYear,
                    detail: NumerologyProfile.personalYearTheme(for: energy.personalYear).theme,
                    phase: energy.cyclePhase.rawValue,
                    appeared: cycleAppeared[0],
                    delay: 0
                )

                cycleCard(
                    label: "パーソナルマンス",
                    number: energy.personalMonth,
                    detail: NumerologyProfile.archetype(for: energy.personalMonth).keyword,
                    phase: nil,
                    appeared: cycleAppeared[1],
                    delay: 1
                )

                cycleCard(
                    label: "パーソナルデイ",
                    number: energy.personalDay,
                    detail: NumerologyProfile.archetype(for: energy.personalDay).keyword,
                    phase: nil,
                    appeared: cycleAppeared[2],
                    delay: 2
                )
            }

            // Cycle phase indicator
            if cycleAppeared[2] {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(themeColor)
                    Text("\(energy.cyclePhase.rawValue)：\(energy.cyclePhase.description)")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(themeColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func cycleCard(label: String, number: Int, detail: String, phase: String?, appeared: Bool, delay: Int) -> some View {
        HStack(spacing: Spacing.md) {
            // Number circle
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.15))
                Circle()
                    .stroke(themeColor.opacity(0.4), lineWidth: 1)
                Text("\(number)")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundStyle(themeColor)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    if NumerologyCalculator.isMasterNumber(number) {
                        Text("MASTER")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(themeColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(themeColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(detail)
                    .font(SorayomiTypography.callout)
                    .foregroundStyle(.white.opacity(0.85))

                if let phase {
                    Text(phase)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(themeColor.opacity(0.8))
                }
            }

            Spacer()

            // Connecting line
            if delay < 2 {
                Rectangle()
                    .fill(themeColor.opacity(0.2))
                    .frame(width: 1, height: 20)
                    .offset(y: 30)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(themeColor.opacity(appeared ? 0.15 : 0), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1.0 : 0.0)
        .offset(x: appeared ? 0 : 30)
    }

    // MARK: - Harmony Section

    private var harmonySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("数字のハーモニー", subtitle: "パーソナル × ユニバーサルの共鳴")

            VStack(spacing: Spacing.md) {
                // Two number circles connected by harmony line
                HStack(spacing: 0) {
                    numberCircle(energy.personalDay, label: "Personal", color: themeColor)

                    // Connecting harmony bar
                    GeometryReader { geo in
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 3)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [themeColor, harmonyColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * harmonyProgress, height: 3)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Harmony label
                            Text(energy.personalUniversalHarmony.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(harmonyColor.opacity(0.3))
                                .clipShape(Capsule())
                                .opacity(harmonyProgress)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 60)

                    numberCircle(energy.universalDay, label: "Universal", color: harmonyColor)
                }
                .padding(.horizontal, Spacing.sm)

                // Harmony description
                Text(energy.personalUniversalHarmony.description)
                    .japaneseText(.system(size: 13), lineSpacing: 4)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(harmonyProgress)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }

    private func numberCircle(_ number: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 1.5)
                Text("\(number)")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(color)
            }
            .frame(width: 56, height: 56)

            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        VStack(spacing: Spacing.sm) {
            sectionTitle("今日のエネルギー", subtitle: nil)

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(i <= energy.overallScore ? themeColor : Color.white.opacity(0.08))

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(themeColor.opacity(i <= energy.overallScore ? 0.6 : 0.15), lineWidth: 1)

                        if i <= energy.overallScore {
                            Image(systemName: "sparkle")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .frame(height: 44)
                    .opacity(scoreRevealed ? 1.0 : 0.3)
                    .scaleEffect(scoreRevealed && i <= energy.overallScore ? 1.0 : 0.8)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.1),
                        value: scoreRevealed
                    )
                }
            }

            Text(energy.advice)
                .japaneseText(SorayomiTypography.caption, lineSpacing: 5)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .opacity(scoreRevealed ? 1.0 : 0.0)
        }
    }

    // MARK: - Pinnacle Section

    private var pinnacleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("人生のステージ", subtitle: "ピナクル（転換期）とチャレンジ（課題）")

            // Current pinnacle highlight
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "mountain.2.fill")
                        .font(.caption)
                        .foregroundStyle(themeColor)
                    Text("現在の転換期：\(energy.currentPinnacle.name)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }

                HStack(spacing: Spacing.sm) {
                    Text("\(energy.currentPinnacle.number)")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(themeColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(energy.currentPinnacle.ageRange)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(energy.currentPinnacle.description)
                            .japaneseText(.system(size: 12), lineSpacing: 3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(themeColor.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(themeColor.opacity(0.15), lineWidth: 1)
                    )
            )

            // Current challenge
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("現在の課題：\(energy.currentChallenge.name)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }

                HStack(spacing: Spacing.sm) {
                    Text("\(energy.currentChallenge.number)")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(energy.currentChallenge.ageRange)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(energy.currentChallenge.description)
                            .japaneseText(.system(size: 12), lineSpacing: 3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.orange.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .opacity(pinnacleOpacity)
    }

    // MARK: - Lucky Section

    private var luckySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("ラッキーアイテム", subtitle: nil)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: Spacing.sm) {
                luckyItem(icon: "clock.fill", label: "ラッキータイム", value: energy.luckyHours.first ?? "10:00")
                luckyItem(icon: "sparkle", label: "パワーストーン", value: archetype.gemstone)
                luckyItem(icon: "number", label: "ラッキーナンバー", value: "\(archetype.luckyDays.first ?? energy.lifePathNumber)")
            }
        }
        .opacity(luckyOpacity)
    }

    private func luckyItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(themeColor)
                .frame(width: 36, height: 36)
                .background(themeColor.opacity(0.1))
                .clipShape(Circle())

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button(action: onComplete) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16, weight: .semibold))
                Text("鑑定を受け取る")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [themeColor, themeColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: themeColor.opacity(0.4), radius: 12, y: 4)
            )
        }
        .opacity(buttonOpacity)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: isLargeScreen ? 22 : 16, weight: .semibold))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: isLargeScreen ? 14 : 11))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }

    private var harmonyColor: Color {
        switch energy.personalUniversalHarmony {
        case .perfect: return Color(red: 0.3, green: 0.9, blue: 0.5)
        case .strong: return Color(red: 0.4, green: 0.8, blue: 0.6)
        case .masterBoost: return Color(red: 0.7, green: 0.5, blue: 1.0)
        case .moderate: return Color(red: 0.6, green: 0.7, blue: 0.8)
        case .tension: return Color(red: 0.9, green: 0.5, blue: 0.3)
        }
    }

    private func baseSingle(_ number: Int) -> Int {
        NumerologyCalculator.reduceToSingleStrict(number)
    }

    // MARK: - Animation Sequence

    private func startRevealSequence() {
        // Phase 1: Sacred geometry fades in + rotates
        withAnimation(.easeOut(duration: 1.2)) {
            sacredGeometryPhase = 1.0
        }
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            sacredGeometryRotation = 360
        }

        // Phase 2: Life path number scales up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                lifePathScale = 1.0
            }
        }

        // Phase 3: Archetype info
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.6)) {
                lifePathRevealed = true
            }
        }

        // Number pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                numberPulse = 1.0
            }
        }

        // Phase 4: Cycle cascade (year → month → day)
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(i) * 0.25) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    cycleAppeared[i] = true
                }
            }
        }

        // Phase 5: Harmony animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.easeInOut(duration: 1.0)) {
                harmonyProgress = 1.0
            }
        }

        // Phase 6: Score
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scoreRevealed = true
            }
        }

        // Phase 7: Pinnacle
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                pinnacleOpacity = 1.0
            }
        }

        // Phase 8: Lucky + Button
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            withAnimation(.easeOut(duration: 0.5)) {
                luckyOpacity = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.9) {
            withAnimation(.easeOut(duration: 0.5)) {
                buttonOpacity = 1.0
            }
        }

        // Particle animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                particlePhase = 1.0
            }
        }
    }
}

// MARK: - Color Extension

private extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar(identifier: .gregorian)
    let birthday = calendar.date(from: DateComponents(year: 1990, month: 7, day: 15))!
    let profile = NumerologyCalculator.profile(from: birthday)
    let energy = NumerologyCalculator.dailyEnergy(birthday: birthday)

    NumerologyRevealView(
        energy: energy,
        profile: profile,
        onComplete: {}
    )
}
