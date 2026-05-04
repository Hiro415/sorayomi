import SwiftUI

// MARK: - SplashScreen

/// アプリ起動時のスプラッシュ画面
/// 占いアプリに相応しい幻想的なアニメーション付きスプラッシュ。
/// 約4.5秒間表示してからメインコンテンツへ遷移する。
struct SplashScreen: View {
    var onFinished: () -> Void

    // MARK: - Animation State

    @State private var isAnimating = false
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showTagline = false
    @State private var backgroundGlow: Double = 0
    @State private var fadeOut = false

    // MARK: - Particle State

    @State private var particles: [SplashParticle] = []
    @State private var viewSize: CGSize = CGSize(width: 390, height: 844)

    var body: some View {
        ZStack {
            // 背景（深い紺色 → 暗い紫のグラデーション）
            LinearGradient(
                colors: [
                    Color(hue: 0.70, saturation: 0.85, brightness: 0.12),
                    Color(hue: 0.75, saturation: 0.70, brightness: 0.08),
                    Color(hue: 0.80, saturation: 0.60, brightness: 0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 背景の放射状グロー
            RadialGradient(
                colors: [
                    Color(hue: 0.72, saturation: 0.6, brightness: 0.4).opacity(backgroundGlow * 0.25),
                    Color(hue: 0.12, saturation: 0.5, brightness: 0.6).opacity(backgroundGlow * 0.1),
                    Color.clear,
                ],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()

            // パーティクル
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .blur(radius: particle.blur)
            }

            // メインコンテンツ
            VStack(spacing: 0) {
                Spacer()
                Spacer()

                // 中央のシンボル
                ZStack {
                    // 外側のリング 1（ゆっくり時計回り）
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .white.opacity(0.08),
                                    Color(hue: 0.12, saturation: 0.6, brightness: 0.9).opacity(0.35),
                                    .white.opacity(0.04),
                                    Color(hue: 0.08, saturation: 0.7, brightness: 0.85).opacity(0.25),
                                    .white.opacity(0.08),
                                ],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 10).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                        .opacity(showIcon ? 1 : 0)

                    // 外側のリング 2（反時計回り、ダッシュ）
                    Circle()
                        .stroke(
                            Color(hue: 0.12, saturation: 0.5, brightness: 0.8).opacity(0.2),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 10])
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(isAnimating ? -360 : 0))
                        .animation(
                            .linear(duration: 14).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                        .opacity(showIcon ? 1 : 0)

                    // 内側のリング（小さいダッシュ、時計回り）
                    Circle()
                        .stroke(
                            Color(hue: 0.08, saturation: 0.4, brightness: 0.7).opacity(0.15),
                            style: StrokeStyle(lineWidth: 0.8, dash: [2, 6])
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(isAnimating ? 180 : 0))
                        .animation(
                            .linear(duration: 20).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                        .opacity(showIcon ? 1 : 0)

                    // 内側のグロー
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.12, saturation: 0.7, brightness: 0.9).opacity(0.15),
                                    Color(hue: 0.08, saturation: 0.6, brightness: 0.7).opacity(0.06),
                                    Color.clear,
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 55
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                        .opacity(showIcon ? 1 : 0)

                    // 中央アイコン
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.12, saturation: 0.45, brightness: 1.0),
                                    Color(hue: 0.08, saturation: 0.55, brightness: 0.85),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(showIcon ? 1 : 0)
                        .scaleEffect(showIcon ? 1.0 : 0.6)
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }

                Spacer()
                    .frame(height: 48)

                // アプリ名（日本語） — offset ではなく scale で入場
                Text("宙よみ")
                    .font(.system(size: 42, weight: .thin, design: .serif))
                    .fixedSize()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hue: 0.12, saturation: 0.35, brightness: 1.0),
                                Color(hue: 0.10, saturation: 0.50, brightness: 0.92),
                                Color(hue: 0.08, saturation: 0.55, brightness: 0.82),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showTitle ? 1.0 : 0.0)
                    .scaleEffect(showTitle ? 1.0 : 0.85)

                Spacer()
                    .frame(height: 8)

                // アプリ名（英字）
                Text("S O R A Y O M I")
                    .font(.system(size: 12, weight: .light, design: .default))
                    .tracking(4)
                    .fixedSize()
                    .foregroundStyle(Color.white.opacity(showSubtitle ? 0.35 : 0))
                    .scaleEffect(showSubtitle ? 1.0 : 0.9)

                Spacer()
                    .frame(height: 36)

                // タグライン
                Text("— 空の流れを、心の導きに —")
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .fixedSize()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color(hue: 0.12, saturation: 0.3, brightness: 0.8).opacity(0.4),
                                Color.white.opacity(0.3),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showTagline ? 1.0 : 0.0)
                    .scaleEffect(showTagline ? 1.0 : 0.9)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .opacity(fadeOut ? 0 : 1)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            viewSize = newSize
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // パーティクル生成
        generateParticles()

        // 即座にリング回転開始
        isAnimating = true

        // 0.3秒後: アイコンフェードイン
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            showIcon = true
        }

        // 0.5秒後: 背景グロー
        withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
            backgroundGlow = 1.0
        }

        // 1.0秒後: タイトルフェードイン
        withAnimation(.easeOut(duration: 1.0).delay(1.0)) {
            showTitle = true
        }

        // 1.5秒後: サブタイトルフェードイン
        withAnimation(.easeOut(duration: 0.8).delay(1.5)) {
            showSubtitle = true
        }

        // 2.2秒後: タグラインフェードイン
        withAnimation(.easeOut(duration: 0.8).delay(2.2)) {
            showTagline = true
        }

        // パーティクルアニメーション
        animateParticles()

        // 4.0秒後: フェードアウト開始 → 4.5秒で終了
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4.0))
            withAnimation(.easeInOut(duration: 0.6)) {
                fadeOut = true
            }
            try? await Task.sleep(for: .seconds(0.6))
            onFinished()
        }
    }

    // MARK: - Particles

    private func generateParticles() {
        let screenWidth = viewSize.width
        let screenHeight = viewSize.height

        particles = (0..<25).map { _ in
            SplashParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 20...max(screenWidth - 20, 40)),
                    y: CGFloat.random(in: 40...max(screenHeight - 40, 80))
                ),
                size: CGFloat.random(in: 1.5...3.5),
                opacity: 0,
                color: [
                    Color(hue: 0.12, saturation: 0.4, brightness: 0.9),
                    Color(hue: 0.72, saturation: 0.3, brightness: 0.8),
                    Color(hue: 0.58, saturation: 0.2, brightness: 0.9),
                    Color.white,
                ].randomElement()!.opacity(0.5),
                blur: CGFloat.random(in: 0...1.0)
            )
        }
    }

    private func animateParticles() {
        Task { @MainActor in
            // フェードイン（ばらばらのタイミング）
            for i in particles.indices {
                let delay = Double.random(in: 0.3...2.0)
                withAnimation(.easeInOut(duration: 1.2).delay(delay)) {
                    particles[i].opacity = Double.random(in: 0.2...0.7)
                }
            }

            // ゆっくり上昇
            try? await Task.sleep(for: .seconds(1.0))
            for i in particles.indices {
                withAnimation(.easeInOut(duration: Double.random(in: 3.0...5.0))) {
                    particles[i].position.y -= CGFloat.random(in: 30...80)
                }
            }

            // きらめき（不規則にフェードイン/アウト）
            try? await Task.sleep(for: .seconds(1.5))
            for i in particles.indices {
                withAnimation(.easeInOut(duration: Double.random(in: 0.8...2.0))) {
                    particles[i].opacity = Double.random(in: 0.1...0.5)
                }
            }
        }
    }
}

// MARK: - SplashParticle

struct SplashParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var color: Color
    var blur: CGFloat
}

// MARK: - Preview

#Preview {
    SplashScreen(onFinished: {})
}
