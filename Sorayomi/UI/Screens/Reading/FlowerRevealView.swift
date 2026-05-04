import SwiftUI

/// 花占いのリビールアニメーション
/// 蕾から花びらが展開し、誕生花と今日の花の情報を段階的に表示する
struct FlowerRevealView: View {
    let flowerProfile: FlowerProfile
    let dailyEnergy: DailyFlowerEnergy
    let onComplete: () -> Void

    // MARK: - Animation State

    @State private var budScale: CGFloat = 0.2
    @State private var budOpacity: Double = 0
    @State private var petalsRevealed: [Bool] = Array(repeating: false, count: 6)
    @State private var petalRotations: [Double] = [0, 60, 120, 180, 240, 300]
    @State private var flowerNameOpacity: Double = 0
    @State private var dailyFlowerOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var particlePhase: CGFloat = 0
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }

    private var birthFlowerColor: Color {
        Color(hex: flowerProfile.birthMonthFlower.colorHex) ?? .pink
    }

    private var todaysFlowerColor: Color {
        Color(hex: dailyEnergy.todaysFlower.colorHex) ?? .purple
    }

    var body: some View {
        ZStack {
            // Background
            botanicalBackground

            // Floating petals
            floatingPetals

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Spacer(minLength: Spacing.xl)

                    // Central flower
                    flowerSection

                    // Birth flower info
                    birthFlowerInfo
                        .opacity(flowerNameOpacity)

                    // Today's flower
                    todaysFlowerInfo
                        .opacity(dailyFlowerOpacity)

                    // Combined message
                    combinedMessageSection
                        .opacity(messageOpacity)

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

    private var botanicalBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.05),
                    Color(red: 0.08, green: 0.12, blue: 0.08),
                    Color(red: 0.06, green: 0.10, blue: 0.10),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Soft glow behind flower
            RadialGradient(
                colors: [birthFlowerColor.opacity(0.15), .clear],
                center: .center,
                startRadius: 0,
                endRadius: sizes.flowerGlow / 2
            )
            .frame(width: sizes.flowerGlow, height: sizes.flowerGlow)
            .offset(y: -60)
        }
    }

    private var floatingPetals: some View {
        Canvas { context, size in
            let petalCount = 20
            for i in 0..<petalCount {
                let seed = Double(i) * 137.508
                let x = (sin(seed + Double(particlePhase) * 0.3) * 0.4 + 0.5) * size.width
                let y = fmod(Double(i) / Double(petalCount) + Double(particlePhase) * 0.02, 1.0) * size.height
                let alpha = 0.15 + sin(seed * 0.5 + Double(particlePhase)) * 0.1
                let petalSize = CGFloat(4 + sin(seed) * 2)

                let rect = CGRect(x: x - petalSize / 2, y: y - petalSize, width: petalSize, height: petalSize * 2)
                let path = Capsule().path(in: rect)
                context.fill(path, with: .color(birthFlowerColor.opacity(alpha)))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Central Flower

    private var flowerSection: some View {
        ZStack {
            // Bud / center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [birthFlowerColor, birthFlowerColor.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: sizes.flowerSize * 0.15
                    )
                )
                .frame(width: sizes.flowerSize * 0.25, height: sizes.flowerSize * 0.25)
                .scaleEffect(budScale)
                .opacity(budOpacity)

            // Petals
            ForEach(0..<6, id: \.self) { index in
                petalView(index: index)
            }
        }
        .frame(height: sizes.flowerSize)
    }

    private func petalView(index: Int) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        birthFlowerColor.opacity(0.9),
                        birthFlowerColor.opacity(0.5),
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: sizes.petalSize * 0.45, height: sizes.petalSize)
            .offset(y: -sizes.petalSize * 0.55)
            .rotationEffect(.degrees(petalRotations[index]))
            .scaleEffect(petalsRevealed[index] ? 1.0 : 0.1)
            .opacity(petalsRevealed[index] ? 1.0 : 0)
    }

    // MARK: - Info Sections

    private var birthFlowerInfo: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "camera.macro")
                    .font(.caption)
                    .foregroundStyle(birthFlowerColor)
                Text("あなたの誕生花")
                    .font(SorayomiTypography.eyebrow)
                    .foregroundStyle(birthFlowerColor)
            }

            Text(flowerProfile.birthMonthFlower.japaneseName)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("花言葉：\(flowerProfile.primaryHanakotoba)")
                .font(SorayomiTypography.callout)
                .foregroundStyle(Color.white.opacity(0.8))

            Text(flowerProfile.personalityTraits)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var todaysFlowerInfo: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sun.max.fill")
                    .font(.caption)
                    .foregroundStyle(todaysFlowerColor)
                Text("今日の花")
                    .font(SorayomiTypography.eyebrow)
                    .foregroundStyle(todaysFlowerColor)
            }

            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(dailyEnergy.todaysFlower.japaneseName)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(.white)
                    Text("花言葉：\(dailyEnergy.todaysHanakotoba)")
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
                            Circle()
                                .fill(i < dailyEnergy.resonanceScore ? birthFlowerColor : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))

            Text(dailyEnergy.resonanceDescription)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var combinedMessageSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(dailyEnergy.combinedMessage)
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.xs) {
                Image(systemName: "leaf.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.green.opacity(0.7))
                Text(dailyEnergy.luckyFlowerAction)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onComplete) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "camera.macro")
                    .font(.caption)
                Text("鑑定を受け取る")
                    .font(SorayomiTypography.headline)
                Image(systemName: "camera.macro")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [birthFlowerColor.opacity(0.8), todaysFlowerColor.opacity(0.8)],
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
        // Phase 0: Start particle drift
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            particlePhase = 100
        }

        // Phase 1: Bud appears (0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                budScale = 1.0
                budOpacity = 1.0
            }
        }

        // Phase 2: Petals unfold (1.0s, staggered)
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(i) * 0.15) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.5)) {
                    petalsRevealed[i] = true
                }
            }
        }

        // Phase 3: Birth flower name (2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 0.6)) {
                flowerNameOpacity = 1.0
            }
        }

        // Phase 4: Today's flower (2.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeIn(duration: 0.6)) {
                dailyFlowerOpacity = 1.0
            }
        }

        // Phase 5: Combined message (3.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            withAnimation(.easeIn(duration: 0.6)) {
                messageOpacity = 1.0
            }
        }

        // Phase 6: Button (4.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
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
