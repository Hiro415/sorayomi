import SwiftUI

// MARK: - RokuyoRevealView

/// 六曜の全画面リビュー画面。
/// 導きページから六曜を選択した際に表示される。
///
/// ■ waiting  — 未引き: 暦スタンプアニメーション + 引く誘導UI
/// ■ drawing  — 抽選中: 3フェーズ演出（期待感 → 印影クラッシュ → 定着）
///   Phase 1 (0.0→2.3s): 外/内スピナーリング + 暦プレースホルダー + テキスト
///   Phase 2 (2.3s):      漢字スタンプ + 衝撃波
///   Phase 3 (3.0s):      読み名フェードイン + グロー脈動
///   Phase 4 (4.5s):      結果画面へ遷移
/// ■ revealed — 引き済み: 結果（ガジェット・全行事・詳細意味）を表示
struct RokuyoRevealView: View {

    // MARK: - Draw State

    private enum DrawState: Equatable {
        case waiting
        case drawing
        case revealed
    }

    // MARK: - Properties

    let rokuyo: Rokuyo
    let onComplete: () -> Void
    let wasAlreadyUsedToday: Bool
    let onDraw: () -> Void

    // Shared
    @State private var appeared = false
    @State private var drawState: DrawState
    @State private var revealAppeared = false

    // プリドローアニメーション
    @State private var preRingRotation: Double = 0
    @State private var preGlowPulse: CGFloat = 1.0

    // ドロー演出 — フェーズ1: 期待感（anticipation, 0.0 → 2.3s）
    @State private var anticipationGlowOpacity: Double = 0
    @State private var anticipationPulse: CGFloat = 1.0
    @State private var anticipationOuterRingRotation: Double = 0   // 時計回り（遅）
    @State private var anticipationOuterRingOpacity: Double = 0
    @State private var anticipationInnerRingRotation: Double = 0   // 反時計回り（速）
    @State private var anticipationInnerRingOpacity: Double = 0
    @State private var anticipationTextOpacity: Double = 0
    @State private var anticipationPlaceholderOpacity: Double = 0  // 「暦」文字
    @State private var anticipationPlaceholderPulse: CGFloat = 1.0

    // ドロー演出 — フェーズ2: 印影クラッシュ（2.3s）
    @State private var impactRingScale: CGFloat = 0.5
    @State private var impactRingOpacity: Double = 0
    @State private var stampKanjiScale: CGFloat = 1.8
    @State private var stampKanjiOpacity: Double = 0
    @State private var stampKanjiBlur: CGFloat = 16
    @State private var stampKanjiRotation: Double = -10
    @State private var stampRingScale: CGFloat = 1.6
    @State private var stampRingOpacity: Double = 0
    @State private var stampGlowOpacity: Double = 0

    // ドロー演出 — フェーズ3: 定着（3.0s）
    @State private var readingNameOpacity: Double = 0
    @State private var stampGlowPulse: CGFloat = 1.0

    private let goldColor = Color(red: 1.0, green: 0.86, blue: 0.46)

    init(
        rokuyo: Rokuyo,
        onComplete: @escaping () -> Void,
        wasAlreadyUsedToday: Bool = false,
        onDraw: @escaping () -> Void = {}
    ) {
        self.rokuyo = rokuyo
        self.onComplete = onComplete
        self.wasAlreadyUsedToday = wasAlreadyUsedToday
        self.onDraw = onDraw
        self._drawState = State(initialValue: wasAlreadyUsedToday ? .revealed : .waiting)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            if drawState == .waiting {
                preDrawContent
                    .transition(.opacity)
            } else if drawState == .drawing {
                drawingContent
                    .transition(.opacity)
            } else {
                revealContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
            }
            if drawState == .revealed {
                revealAppeared = true
            }
        }
        .onChange(of: drawState) { _, newState in
            if newState == .revealed {
                revealAppeared = true
            }
        }
    }

    // MARK: - Pre-draw state

    private var preDrawContent: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(goldColor.opacity(0.14))
                    .frame(width: 180, height: 180)
                    .blur(radius: 28)
                    .scaleEffect(preGlowPulse)

                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                goldColor.opacity(0.9),
                                goldColor.opacity(0.15),
                                goldColor.opacity(0.9),
                                goldColor.opacity(0.15),
                                goldColor.opacity(0.9),
                            ],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(preRingRotation))

                Circle()
                    .fill(Color(red: 0.10, green: 0.05, blue: 0.22))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle().strokeBorder(goldColor.opacity(0.25), lineWidth: 0.8)
                    )

                Text("暦")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [goldColor.opacity(0.95), goldColor.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: goldColor.opacity(0.45), radius: 8)
            }
            .frame(width: 160, height: 160)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.85)

            Spacer().frame(height: Spacing.xxl)

            VStack(spacing: Spacing.sm) {
                Text("今日の六曜")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)

                Text("今日の暦を確かめる")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.sorayomiTextPrimary)
                    .multilineTextAlignment(.center)

                Text("今日の吉凶と行事の向き不向きが\n一目でわかります。")
                    .font(SorayomiTypography.body)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer()

            Button {
                onDraw()
                withAnimation(.easeIn(duration: 0.2)) {
                    drawState = .drawing
                }
            } label: {
                Text("今日の六曜を見る")
                    .font(SorayomiTypography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(goldColor)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
                    .shadow(color: goldColor.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .padding(.bottom, Spacing.xxl)
        }
        .adaptiveScreenPadding()
        .contentWidthConstraint()
        .onAppear(perform: startPreDrawAnimations)
    }

    private func startPreDrawAnimations() {
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            preRingRotation = 360
        }
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            preGlowPulse = 1.25
        }
    }

    // MARK: - Drawing state

    private var drawingContent: some View {
        ZStack {
            // フェーズ1グロー（脈動）
            Circle()
                .fill(accentColor.opacity(0.20))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .scaleEffect(anticipationPulse)
                .opacity(anticipationGlowOpacity)

            // フェーズ2グロー（残光）
            Circle()
                .fill(accentColor.opacity(0.28))
                .frame(width: 300, height: 300)
                .blur(radius: 65)
                .scaleEffect(stampGlowPulse)
                .opacity(stampGlowOpacity)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // 衝撃波リング（スタンプ時に外へ広がる）
                    Circle()
                        .strokeBorder(accentColor.opacity(0.55), lineWidth: 1.5)
                        .frame(width: 210, height: 210)
                        .scaleEffect(impactRingScale)
                        .opacity(impactRingOpacity)

                    // 外スピナーリング（時計回り・遅）
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    accentColor.opacity(0.85),
                                    accentColor.opacity(0.08),
                                    accentColor.opacity(0.85),
                                ],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 155, height: 155)
                        .rotationEffect(.degrees(anticipationOuterRingRotation))
                        .opacity(anticipationOuterRingOpacity)

                    // 内スピナーリング（反時計回り・速）
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    accentColor.opacity(0.50),
                                    accentColor.opacity(0.04),
                                    accentColor.opacity(0.50),
                                ],
                                center: .center
                            ),
                            lineWidth: 1.0
                        )
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(-anticipationInnerRingRotation))
                        .opacity(anticipationInnerRingOpacity)

                    // スタンプ外リング
                    Circle()
                        .strokeBorder(accentColor.opacity(0.55), lineWidth: 2)
                        .frame(width: 195, height: 195)
                        .scaleEffect(stampRingScale)
                        .opacity(stampRingOpacity)

                    // スタンプ内円（墨ベース）
                    Circle()
                        .fill(Color(red: 0.08, green: 0.04, blue: 0.20))
                        .frame(width: 158, height: 158)
                        .scaleEffect(stampRingScale)
                        .opacity(stampRingOpacity)

                    // 期待感フェーズ: 「暦」プレースホルダー
                    // スタンプ判明前は六曜の名前を隠す役割
                    Text("暦")
                        .font(.system(size: 58, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor.opacity(0.72), accentColor.opacity(0.42)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: accentColor.opacity(0.38), radius: 10)
                        .scaleEffect(anticipationPlaceholderPulse)
                        .opacity(anticipationPlaceholderOpacity)

                    // 六曜漢字（印影クラッシュで登場）
                    Text(rokuyo.japaneseName)
                        .font(.system(size: 70, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.72)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: accentColor.opacity(0.55), radius: 14)
                        .scaleEffect(stampKanjiScale)
                        .opacity(stampKanjiOpacity)
                        .blur(radius: stampKanjiBlur)
                        .rotationEffect(.degrees(stampKanjiRotation))
                }
                .frame(width: 220, height: 220)

                Spacer().frame(height: Spacing.xl)

                // テキストエリア: 期待感 ↔ 定着で切り替わる
                ZStack {
                    Text("今日の暦を読んでいます…")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                        .opacity(anticipationTextOpacity)

                    VStack(spacing: 4) {
                        Text(rokuyo.japaneseName)
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundStyle(accentColor)
                        Text(rokuyo.reading)
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                    }
                    .opacity(readingNameOpacity)
                }
                .frame(height: 52)

                Spacer()
            }
        }
        .onAppear(perform: startDrawingSequence)
    }

    /// タメ演出シーケンス（合計 約4.5s）
    private func startDrawingSequence() {

        // ─── フェーズ1: 期待感（0.0 → 2.3s）────────────────────────────────
        // グロー・外リング・テキスト・暦プレースホルダーを順番にフェードイン
        withAnimation(.easeOut(duration: 0.45)) {
            anticipationGlowOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.40).delay(0.18)) {
            anticipationOuterRingOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.22)) {
            anticipationPlaceholderOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.50).delay(0.30)) {
            anticipationTextOpacity = 1.0
        }

        // 外リング: 時計回り・ゆっくり（8s/周）
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            anticipationOuterRingRotation = 360
        }
        // グロー: 緩やかな呼吸（1.1s周期）
        withAnimation(.easeInOut(duration: 1.10).repeatForever(autoreverses: true)) {
            anticipationPulse = 1.28
        }
        // 「暦」: ごくわずかに脈動（1.5s周期）
        withAnimation(.easeInOut(duration: 1.50).repeatForever(autoreverses: true)) {
            anticipationPlaceholderPulse = 1.06
        }

        // 内リング: 0.6s後に反時計回りで出現（4s/周）
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeOut(duration: 0.45)) {
                anticipationInnerRingOpacity = 1.0
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                anticipationInnerRingRotation = 360
            }
        }

        // ─── フェーズ2: 印影クラッシュ（2.3s）──────────────────────────────
        Task {
            try? await Task.sleep(for: .milliseconds(2300))

            // 期待感要素を一斉にフェードアウト
            withAnimation(.easeIn(duration: 0.20)) {
                anticipationOuterRingOpacity   = 0
                anticipationInnerRingOpacity   = 0
                anticipationTextOpacity        = 0
                anticipationGlowOpacity        = 0
                anticipationPlaceholderOpacity = 0
            }

            // 漢字スタンプ + リング: 上から叩きつける spring
            withAnimation(.spring(duration: 0.65, bounce: 0.55)) {
                stampRingScale     = 1.0
                stampRingOpacity   = 1.0
                stampKanjiScale    = 1.0
                stampKanjiOpacity  = 1.0
                stampKanjiBlur     = 0
                stampKanjiRotation = 0
                stampGlowOpacity   = 1.0
            }

            // 衝撃波リング: 一瞬光って外へ広がりながら消える
            withAnimation(.easeIn(duration: 0.12)) {
                impactRingOpacity = 0.75
            }
            withAnimation(.easeOut(duration: 0.70)) {
                impactRingScale = 2.0
            }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeOut(duration: 0.55)) {
                impactRingOpacity = 0
            }
        }

        // ─── フェーズ3: 定着（3.0s）─────────────────────────────────────────
        Task {
            try? await Task.sleep(for: .milliseconds(3000))

            withAnimation(.easeOut(duration: 0.55)) {
                readingNameOpacity = 1.0
            }
            // 残光をゆっくり脈動させて余韻を演出
            withAnimation(.easeInOut(duration: 1.60).repeatForever(autoreverses: true)) {
                stampGlowPulse = 1.18
            }
        }

        // ─── フェーズ4: 結果へ遷移（4.5s）──────────────────────────────────
        Task {
            try? await Task.sleep(for: .milliseconds(4500))
            withAnimation(.easeOut(duration: 0.45)) {
                drawState = .revealed
            }
        }
    }

    // MARK: - Reveal content

    private var revealContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {

                titleBlock
                    .slideIn(revealAppeared, delay: 0.05)

                RokuyoBannerView(rokuyo: rokuyo)
                    .slideIn(revealAppeared, delay: 0.14)

                allEventsCard
                    .slideIn(revealAppeared, delay: 0.22)

                meaningCard
                    .slideIn(revealAppeared, delay: 0.30)

                completeButton
                    .slideIn(revealAppeared, delay: 0.36)
            }
            .adaptiveScreenPadding()
            .contentWidthConstraint()
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
    }

    // MARK: - Title block

    private var titleBlock: some View {
        VStack(spacing: Spacing.xs) {
            Text("今日の六曜")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)

            Text(rokuyo.japaneseName)
                .font(.system(size: 46, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.68)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: accentColor.opacity(0.30), radius: 8)

            Text(rokuyo.reading)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - All events card

    private var allEventsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("行事の吉凶")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)
                Spacer()
                Text("本日基準")
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Spacing.xs
            ) {
                ForEach(rokuyo.eventSuitabilities) { suit in
                    eventRow(suit)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.sorayomiSurface)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.sorayomiDivider.opacity(0.5), lineWidth: 1)
        )
    }

    private func eventRow(_ suit: Rokuyo.EventSuitability) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: suitIcon(suit.suitability))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(suitColor(suit.suitability))
                .frame(width: 18)

            Text(suit.event)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.sorayomiTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Meaning card

    private var meaningCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("六曜の意味")
                .font(SorayomiTypography.headline)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Text(rokuyo.detailedMeaning)
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.sorayomiTextPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.xs) {
                Image(systemName: "circle.grid.cross.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                Text("陰陽五行：\(rokuyo.elementCorrespondence)")
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.sorayomiSurface)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [accentColor.opacity(0.30), Color.sorayomiDivider.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Complete button

    private var completeButton: some View {
        Button(action: onComplete) {
            Text("確認しました")
                .font(SorayomiTypography.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
                .shadow(color: accentColor.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var accentColor: Color {
        switch rokuyo {
        case .taian:      return Color(red: 0.97, green: 0.76, blue: 0.10)
        case .tomobiki:   return Color(red: 0.90, green: 0.60, blue: 0.22)
        case .senshou:    return Color(red: 0.18, green: 0.76, blue: 0.52)
        case .senbu:      return Color.sorayomiPrimary
        case .shakkou:    return Color(red: 0.95, green: 0.45, blue: 0.12)
        case .butsumetsu: return Color(red: 0.52, green: 0.50, blue: 0.60)
        }
    }

    private func suitColor(_ score: Int) -> Color {
        switch score {
        case 5: return Color(red: 0.97, green: 0.76, blue: 0.10)
        case 4: return Color(red: 0.18, green: 0.76, blue: 0.52)
        case 3: return Color.sorayomiPrimary
        case 2: return Color(red: 0.95, green: 0.50, blue: 0.12)
        case 1: return Color(red: 0.88, green: 0.22, blue: 0.22)
        default: return Color.sorayomiPrimary
        }
    }

    private func suitIcon(_ score: Int) -> String {
        switch score {
        case 5: return "checkmark.seal.fill"
        case 4: return "checkmark.circle.fill"
        case 3: return "minus.circle.fill"
        case 2: return "exclamationmark.circle.fill"
        case 1: return "xmark.circle.fill"
        default: return "minus.circle.fill"
        }
    }
}

// MARK: - Slide-in helper modifier

private extension View {
    func slideIn(_ appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
}

// MARK: - Preview

#Preview("未引き") {
    RokuyoRevealView(rokuyo: .taian, onComplete: {})
        .environment(AppEnvironment())
}

#Preview("引き済み") {
    RokuyoRevealView(rokuyo: .taian, onComplete: {}, wasAlreadyUsedToday: true)
        .environment(AppEnvironment())
}

#Preview("仏滅・引き済み") {
    RokuyoRevealView(rokuyo: .butsumetsu, onComplete: {}, wasAlreadyUsedToday: true)
        .environment(AppEnvironment())
}
