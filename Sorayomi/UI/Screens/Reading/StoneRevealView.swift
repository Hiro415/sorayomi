import SwiftUI

/// ストーン占いのリビールアニメーション
/// 光線が降り注ぎ、宝石が出現し、誕生石と今日のパワーストーンの情報を段階的に表示する
struct StoneRevealView: View {
    let stoneProfile: StoneProfile
    let dailyEnergy: DailyStoneEnergy
    let onComplete: () -> Void

    // MARK: - Animation State

    @State private var lightBeamProgress: CGFloat = 0
    @State private var stoneScale: CGFloat = 0.1
    @State private var stoneOpacity: Double = 0
    @State private var stoneRotation: Double = -30
    @State private var raysRevealed: [Bool] = Array(repeating: false, count: 8)
    @State private var propertiesOpacity: Double = 0
    @State private var dailyStoneOpacity: Double = 0
    @State private var chakraOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var shimmerPhase: CGFloat = 0
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }

    private var birthstoneColor: Color {
        Color(hex: stoneProfile.birthstone.colorHex) ?? .purple
    }

    private var todaysStoneColor: Color {
        Color(hex: dailyEnergy.todaysStone.colorHex) ?? .cyan
    }

    var body: some View {
        ZStack {
            // Background
            cosmicBackground

            // Shimmer particles
            shimmerParticles

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Spacer(minLength: Spacing.xl)

                    // Light beam + stone
                    stoneSection

                    // Birthstone info
                    birthstoneInfo
                        .opacity(propertiesOpacity)

                    // Today's stone
                    todaysStoneInfo
                        .opacity(dailyStoneOpacity)

                    // Chakra & element interaction
                    resonanceSection
                        .opacity(chakraOpacity)

                    // Continue button
                    continueButton
                        .opacity(buttonOpacity)

                    Spacer(minLength: Spacing.xxl)
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
            startRevealSequence()
        }
    }

    // MARK: - Background

    private var cosmicBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.03, blue: 0.08),
                    Color(red: 0.06, green: 0.04, blue: 0.12),
                    Color(red: 0.03, green: 0.03, blue: 0.06),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Soft glow behind stone
            RadialGradient(
                colors: [birthstoneColor.opacity(0.2), .clear],
                center: .center,
                startRadius: 0,
                endRadius: sizes.stoneGlow / 2
            )
            .frame(width: sizes.stoneGlow, height: sizes.stoneGlow)
            .offset(y: -60)
        }
    }

    private var shimmerParticles: some View {
        Canvas { context, size in
            let particleCount = 25
            for i in 0..<particleCount {
                let seed = Double(i) * 97.31
                let x = (sin(seed + Double(shimmerPhase) * 0.2) * 0.4 + 0.5) * size.width
                let y = fmod(Double(i) / Double(particleCount) + Double(shimmerPhase) * 0.015, 1.0) * size.height
                let alpha = 0.1 + sin(seed * 0.7 + Double(shimmerPhase) * 1.5) * 0.15
                let sparkSize = CGFloat(2 + sin(seed) * 1.5)

                let rect = CGRect(x: x - sparkSize / 2, y: y - sparkSize / 2, width: sparkSize, height: sparkSize)
                let path = Circle().path(in: rect)

                let color = i % 3 == 0 ? birthstoneColor : (i % 3 == 1 ? Color.white : todaysStoneColor)
                context.fill(path, with: .color(color.opacity(alpha)))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Central Stone

    private var stoneSection: some View {
        ZStack {
            // Light beam from above
            lightBeam

            // Prismatic refraction rays
            ForEach(0..<8, id: \.self) { index in
                refractionRay(index: index)
            }

            // Main gemstone
            gemstoneView
        }
        .frame(height: sizes.stoneSize * 1.4)
    }

    private var lightBeam: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        birthstoneColor.opacity(0.15),
                        .clear,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: sizes.stoneLightBeam * lightBeamProgress)
            .offset(y: -sizes.stoneLightBeam * lightBeamProgress / 4)
    }

    private var gemstoneView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [birthstoneColor.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: sizes.stoneSize * 0.6
                    )
                )
                .frame(width: sizes.stoneSize * 1.2, height: sizes.stoneSize * 1.2)

            // Diamond shape (rotated square)
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            birthstoneColor,
                            birthstoneColor.opacity(0.7),
                            Color.white.opacity(0.4),
                            birthstoneColor.opacity(0.8),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: sizes.stoneSize * 0.45, height: sizes.stoneSize * 0.45)
                .rotationEffect(.degrees(45))
                .overlay(
                    // Inner facet highlight
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    .clear,
                                    .clear,
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: sizes.stoneSize * 0.45, height: sizes.stoneSize * 0.45)
                        .rotationEffect(.degrees(45))
                )
        }
        .scaleEffect(stoneScale)
        .opacity(stoneOpacity)
        .rotationEffect(.degrees(stoneRotation))
    }

    private func refractionRay(index: Int) -> some View {
        let angle = Double(index) * 45.0
        let rayLength = sizes.stoneSize * 0.7
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]
        let color = colors[index % colors.count]

        return Capsule()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.6), color.opacity(0.1), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: rayLength, height: 2)
            .offset(x: rayLength / 2)
            .rotationEffect(.degrees(angle))
            .scaleEffect(raysRevealed[index] ? 1.0 : 0.0)
            .opacity(raysRevealed[index] ? 1.0 : 0)
    }

    // MARK: - Info Sections

    private var birthstoneInfo: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "diamond.fill")
                    .font(.caption)
                    .foregroundStyle(birthstoneColor)
                Text("あなたの誕生石")
                    .font(SorayomiTypography.eyebrow)
                    .foregroundStyle(birthstoneColor)
            }

            Text(stoneProfile.birthstone.japaneseName)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text(stoneProfile.birthstone.properties.joined(separator: " ・ "))
                .font(SorayomiTypography.callout)
                .foregroundStyle(Color.white.opacity(0.8))

            HStack(spacing: Spacing.md) {
                stoneTag(icon: "flame.fill", text: stoneProfile.birthstone.element.rawValue)
                stoneTag(icon: "circle.hexagongrid.fill", text: stoneProfile.birthstone.chakra.rawValue)
            }

            Text(stoneProfile.personalityFromStone)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stoneTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(SorayomiTypography.caption2)
        }
        .foregroundStyle(Color.white.opacity(0.5))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private var todaysStoneInfo: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(todaysStoneColor)
                Text("今日のパワーストーン")
                    .font(SorayomiTypography.eyebrow)
                    .foregroundStyle(todaysStoneColor)
            }

            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(dailyEnergy.todaysStone.japaneseName)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(.white)
                    Text(dailyEnergy.todaysStone.properties.joined(separator: " ・ "))
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                Spacer()

                // Resonance score
                VStack(spacing: 2) {
                    Text("共鳴")
                        .font(SorayomiTypography.caption2)
                        .foregroundStyle(Color.white.opacity(0.5))
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < dailyEnergy.resonanceScore ? "diamond.fill" : "diamond")
                                .font(.system(size: 8))
                                .foregroundStyle(i < dailyEnergy.resonanceScore ? birthstoneColor : Color.white.opacity(0.2))
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        }
    }

    private var resonanceSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(dailyEnergy.resonanceDescription)
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.md) {
                resonanceDetail(
                    icon: "flame.fill",
                    label: "元素の相互作用",
                    text: dailyEnergy.elementInteraction
                )
                resonanceDetail(
                    icon: "circle.hexagongrid.fill",
                    label: "チャクラの整列",
                    text: dailyEnergy.chakraAlignment
                )
            }

            HStack(spacing: Spacing.xs) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.caption2)
                    .foregroundStyle(todaysStoneColor.opacity(0.7))
                Text(dailyEnergy.recommendedAction)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    }

    private func resonanceDetail(icon: String, label: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(birthstoneColor.opacity(0.7))
            Text(label)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.white.opacity(0.5))
            Text(text)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onComplete) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "diamond.fill")
                    .font(.caption)
                Text("鑑定を受け取る")
                    .font(SorayomiTypography.headline)
                Image(systemName: "diamond.fill")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [birthstoneColor.opacity(0.8), todaysStoneColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Animation Sequence

    private func startRevealSequence() {
        // Phase 0: Start shimmer drift
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            shimmerPhase = 100
        }

        // Phase 1: Light beam descends (0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                lightBeamProgress = 1.0
            }
        }

        // Phase 2: Stone appears (1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.5)) {
                stoneScale = 1.0
                stoneOpacity = 1.0
                stoneRotation = 0
            }
        }

        // Phase 3: Prismatic rays (1.8s, staggered)
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8 + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    raysRevealed[i] = true
                }
            }
        }

        // Phase 4: Birthstone properties (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeIn(duration: 0.6)) {
                propertiesOpacity = 1.0
            }
        }

        // Phase 5: Today's stone (3.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            withAnimation(.easeIn(duration: 0.6)) {
                dailyStoneOpacity = 1.0
            }
        }

        // Phase 6: Chakra/element resonance (4.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation(.easeIn(duration: 0.6)) {
                chakraOpacity = 1.0
            }
        }

        // Phase 7: Button (4.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.8) {
            withAnimation(.easeIn(duration: 0.5)) {
                buttonOpacity = 1.0
            }
        }
    }
}

// MARK: - Color Hex Extension

private extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else { return nil }

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
