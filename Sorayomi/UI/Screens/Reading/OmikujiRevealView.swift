import SwiftUI

// MARK: - OmikujiRevealView

/// おみくじ専用のインタラクティブUI。
///
/// ■ 通常フロー（storedResult == nil）
///   いずれかの方向にドラッグすると漢字・色がサイクル。
///   指を離した時点でランクが確定 → 多段階スピン演出 → 結果リビール。
///   ランク確定時に `onResultDetermined(result)` を呼ぶ（即時使用済みマーク）。
///
/// ■ 結果閲覧フロー（storedResult != nil）
///   当日保存済みの結果を直接表示。ドラッグ儀式をスキップ。
struct OmikujiRevealView: View {

    // MARK: - Inputs

    let profile: UserProfile?
    /// 当日保存済みの結果。non-nil のとき儀式をスキップして結果を直接表示する。
    let storedResult: Omikuji?
    /// ランクが確定した瞬間に呼ぶ（使用済みマーク + 結果保存）
    let onResultDetermined: (Omikuji) -> Void
    let onDismiss: () -> Void

    // MARK: - Phase State Machine

    private enum Phase: Equatable {
        case viewingStored             // storedResult を直接表示
        case idle                      // 初期待機
        case dragging                  // ドラッグ中
        case spinning                  // 多段階スピン中
        case locked                    // ランク確定・スタンプ演出
        case revealed                  // 結果スクロール表示
    }

    @State private var phase: Phase = .idle

    // MARK: - Rank Pool (加重、シャッフル済み)

    /// 浅草寺分布: 大吉×2, 吉×4, 中吉×2, 小吉×2, 末吉×2, 凶×2
    private static let basePool: [Omikuji.Rank] = [
        .daikichi, .daikichi,
        .kichi, .kichi, .kichi, .kichi,
        .chukichi, .chukichi,
        .shokichi, .shokichi,
        .suekichi, .suekichi,
        .kyo, .kyo
    ]

    /// ドラッグ中に表示する神秘的な漢字（吉凶のヒントを一切含まない）
    private static let mysticKanjiPool: [String] = [
        "神", "霊", "宙", "縁", "運", "天", "地", "水", "火", "風",
        "光", "月", "星", "花", "道", "空", "心", "命", "福", "寿",
        "夢", "力", "気", "和", "妙", "幽", "玄", "霞", "雲", "嵐",
        "波", "岩", "翠", "輝", "響", "静", "清", "禅", "祈", "縁"
    ]

    @State private var selectedRank: Omikuji.Rank = .kichi
    @State private var finalResult: Omikuji?
    /// ドラッグ中の神秘漢字サイクルインデックス
    @State private var kanjiCycleIndex: Int = 0

    // MARK: - Drag State

    @State private var dragDistance: CGFloat = 0
    @State private var dragVector: CGSize = .zero
    /// スリングショット: ドラッグ方向に印が引っ張られるオフセット（減衰済み）
    @State private var slingOffset: CGSize = .zero

    // MARK: - Idle Animations

    @State private var ringRotation: Double = 0
    @State private var middlePulse: Double = 0.5
    @State private var glowPulse: CGFloat = 1.0

    // MARK: - Drag / Spin Cycle Animations

    @State private var displayKanji: String = "御"
    @State private var displayColor: Color = Color(red: 1.0, green: 0.86, blue: 0.46)
    @State private var sealBlur: CGFloat = 0
    @State private var sealRotation: Double = 0

    // MARK: - Lock / Stamp Animations

    @State private var stampScale: CGFloat = 0.3
    @State private var stampOpacity: Double = 0
    @State private var rankBurstScale: CGFloat = 1.0
    @State private var lockRingOpacity: Double = 0
    @State private var lockRingScale: CGFloat = 0.6

    // MARK: - Reveal Animations

    @State private var rankScale: CGFloat = 0.25
    @State private var rankOpacity: Double = 0
    @State private var contentOffset: CGFloat = 50
    @State private var contentOpacity: Double = 0

    // MARK: - Hint Arrow

    @State private var arrowOpacity: Double = 0
    @State private var arrowOffset: CGFloat = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundView.ignoresSafeArea()

            switch phase {
            case .viewingStored:
                if let result = storedResult {
                    resultView(for: result)
                        .transition(.opacity)
                }

            case .idle, .dragging:
                ritualView
                    .transition(.opacity)

            case .spinning, .locked:
                spinningView
                    .transition(.opacity)

            case .revealed:
                if let result = finalResult {
                    resultView(for: result)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear(perform: setupOnAppear)
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.03, blue: 0.16),
                    Color(red: 0.12, green: 0.06, blue: 0.26),
                    Color(red: 0.06, green: 0.03, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Gold shimmer particles
            TimelineView(.animation) { tl in
                Canvas { ctx, size in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    for i in 0..<35 {
                        let fi = Double(i)
                        let px = (sin(fi * 2.17 + t * 0.35) * 0.42 + 0.5) * size.width
                        let py = (cos(fi * 1.63 + t * 0.28) * 0.42 + 0.5) * size.height
                        let alpha = (sin(fi * 1.09 + t * 0.62) + 1) / 2 * 0.22
                        let r: CGFloat = 1.0 + CGFloat(i % 4) * 0.5
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                            with: .color(Color(red: 1.0, green: 0.88, blue: 0.5).opacity(alpha))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Ritual View (idle + dragging)

    private var ritualView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Eyebrow
            VStack(spacing: Spacing.xs) {
                Text("御 神 籤")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(goldColor.opacity(0.65))
                    .tracking(8)

                Text(phase == .dragging ? "手を離すとおみくじが始まります" : "スワイプして御神籤を引く")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .animation(.easeInOut, value: phase)
            }
            .padding(.bottom, 40)

            // Shrine seal with slingshot offset applied
            ZStack {
                // Stretch glow: 引っ張り方向に光が伸びる
                if phase == .dragging {
                    Ellipse()
                        .fill(goldColor.opacity(0.09))
                        .frame(width: 200 + abs(slingOffset.width) * 0.6,
                               height: 200 + abs(slingOffset.height) * 0.6)
                        .blur(radius: 22)
                        .offset(x: slingOffset.width * 0.5, y: slingOffset.height * 0.5)
                }

                shrineSeal
                    .offset(x: slingOffset.width, y: slingOffset.height)

                // Drag hint arrows (idle only)
                if phase == .idle {
                    dragHintArrows
                }
            }
            .frame(width: 300, height: 300)
            .gesture(dragGesture)

            Spacer().frame(height: 36)

            Text(phase == .dragging ? "どこまでも引いて、放してください" : "毎日1回まで無料")
                .font(SorayomiTypography.caption2)
                .foregroundStyle(.white.opacity(phase == .dragging ? 0.45 : 0.25))
                .animation(.easeInOut(duration: 0.2), value: phase)

            Spacer()

            Color.clear.frame(height: Spacing.xl)
        }
        .animation(.easeInOut(duration: 0.2), value: phase)
    }

    // MARK: - Shrine Seal

    private var shrineSeal: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(displayColor.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 32)
                .scaleEffect(glowPulse)

            // Outer ring – rotating angular gradient
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            goldColor.opacity(0.9),
                            goldColor.opacity(0.15),
                            goldColor.opacity(0.9),
                            goldColor.opacity(0.15),
                            goldColor.opacity(0.9)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(ringRotation + sealRotation))

            // Diamond markers
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "diamond.fill")
                    .font(.system(size: 4.5, weight: .bold))
                    .foregroundStyle(goldColor.opacity(0.85))
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double(i) * 90 + ringRotation))
            }

            // Middle ring – pulsing
            Circle()
                .strokeBorder(
                    displayColor.opacity(middlePulse * 0.7),
                    lineWidth: 1
                )
                .frame(width: 190, height: 190)

            // Inner circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.20, green: 0.11, blue: 0.38),
                            Color(red: 0.09, green: 0.05, blue: 0.20)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 156, height: 156)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )

            // Center kanji – cycles during drag/spin
            Text(displayKanji)
                .font(.system(size: 58, weight: .medium, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [displayColor.opacity(0.95), displayColor.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: displayColor.opacity(0.55), radius: 14)
                .blur(radius: sealBlur)
                .id(displayKanji)
        }
    }

    // MARK: - Drag Hint Arrows

    private var dragHintArrows: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                let angle = Double(i) * 90.0
                Image(systemName: "chevron.compact.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(goldColor.opacity(arrowOpacity))
                    .rotationEffect(.degrees(angle))
                    .offset(
                        x: sin(angle * .pi / 180) * (140 + arrowOffset),
                        y: -cos(angle * .pi / 180) * (140 + arrowOffset)
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.6)) {
                arrowOpacity = 0.65
                arrowOffset = 8
            }
        }
    }

    // MARK: - Spinning View (between drag-end and reveal)
    //
    // レイアウト骨格を ritualView と完全に一致させることで、
    // opacity クロスフェード中に御神籤の文字・印の位置が飛ばないようにする。

    private var spinningView: some View {
        VStack(spacing: 0) {
            Spacer()

            // ── ritualView と同一の eyebrow 構造
            VStack(spacing: Spacing.xs) {
                Text("御 神 籤")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(goldColor.opacity(0.65))
                    .tracking(8)

                Text(phase == .locked ? "ランクが定まりました" : "天の声を聞いています...")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .animation(.easeInOut, value: phase)
            }
            .padding(.bottom, 40)

            // ── 印：ritualView と同じ 300×300 フレーム
            ZStack {
                shrineSeal

                // バースト演出リング（locked フェーズのみ）
                if phase == .locked {
                    Circle()
                        .strokeBorder(displayColor.opacity(lockRingOpacity), lineWidth: 3)
                        .frame(width: 220, height: 220)
                        .scaleEffect(lockRingScale)

                    Circle()
                        .strokeBorder(displayColor.opacity(lockRingOpacity * 0.5), lineWidth: 1.5)
                        .frame(width: 260, height: 260)
                        .scaleEffect(lockRingScale)
                }
            }
            .frame(width: 300, height: 300)
            .scaleEffect(rankBurstScale)

            // ── ritualView と同一の下部スペーサー群
            Spacer().frame(height: 36)

            Text(phase == .locked ? "ランクが定まりました" : "天の声を聞いています...")
                .font(SorayomiTypography.caption2)
                .foregroundStyle(.white.opacity(0))   // 不可視（スペース確保のみ）

            Spacer()

            Color.clear.frame(height: Spacing.xl)
        }
    }

    // MARK: - Result View

    private func resultView(for omikuji: Omikuji) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                // ── Rank Header
                rankHeader(for: omikuji)
                    .scaleEffect(phase == .viewingStored ? 1.0 : rankScale)
                    .opacity(phase == .viewingStored ? 1.0 : rankOpacity)

                // ── Rest of content
                VStack(spacing: Spacing.lg) {
                    wakaSection(for: omikuji)
                    luckyAttributesSection(for: omikuji)
                    guidanceSection(for: omikuji)
                    categoriesSection(for: omikuji)

                    // Dismiss
                    Button(action: onDismiss) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle")
                                .font(.body)
                            Text("今日はこれで")
                                .font(SorayomiTypography.headline)
                        }
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge))
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, Spacing.xxl)
                }
                .offset(y: phase == .viewingStored ? 0 : contentOffset)
                .opacity(phase == .viewingStored ? 1.0 : contentOpacity)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.xl)
        }
    }

    // MARK: - Rank Header

    private func rankHeader(for omikuji: Omikuji) -> some View {
        let color = rankColor(for: omikuji.rank)
        return VStack(spacing: Spacing.sm) {
            Text(omikuji.rank.japaneseName)
                .font(.system(size: 86, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.95), color, color.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: color.opacity(0.65), radius: 24)

            Text(omikuji.rank.nuance)
                .font(SorayomiTypography.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= omikuji.rank.starScore ? color : Color.white.opacity(0.15))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                        .stroke(color.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - 御言葉 Section

    private func wakaSection(for omikuji: Omikuji) -> some View {
        sectionCard(icon: "scroll.fill", title: "御 言 葉") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(omikuji.wakaPoem)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(goldColor.opacity(0.9))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(omikuji.wakaInterpretation)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(4)

                Divider()
                    .background(Color.white.opacity(0.08))

                Text(omikuji.poem)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineSpacing(5)
            }
        }
    }

    // MARK: - Lucky Attributes Section

    private func luckyAttributesSection(for omikuji: Omikuji) -> some View {
        sectionCard(icon: "sparkles", title: "今日の開運") {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Spacing.xs),
                          GridItem(.flexible(), spacing: Spacing.xs)],
                spacing: Spacing.xs
            ) {
                luckyPill(symbol: "location.north.line.fill", label: "吉方",   value: omikuji.luckyDirection)
                luckyPill(symbol: "clock.fill",               label: "吉時間", value: omikuji.luckyTime)
                luckyPill(symbol: "paintpalette.fill",        label: "開運色", value: omikuji.luckyColor)
                luckyPill(symbol: "gift.fill",                label: "開運物", value: omikuji.luckyItem)
            }
        }
    }

    private func luckyPill(symbol: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: symbol)
                .font(.caption2)
                .foregroundStyle(goldColor.opacity(0.75))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                Text(value)
                    .font(SorayomiTypography.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    }

    // MARK: - Guidance Section

    private func guidanceSection(for omikuji: Omikuji) -> some View {
        sectionCard(icon: "circle.hexagonpath.fill", title: "本日の指針") {
            Text(omikuji.guidance)
                .font(SorayomiTypography.subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Traditional Categories Section

    private func categoriesSection(for omikuji: Omikuji) -> some View {
        let cats = omikuji.traditionalCategories
        let items: [Omikuji.CategoryFortune] = [
            cats.wish, cats.love, cats.awaitedPerson, cats.marriage,
            cats.travel, cats.study, cats.lostItem, cats.dispute,
            cats.moving, cats.illness
        ]

        return sectionCard(icon: "list.bullet.rectangle.fill", title: "十 二 縁 起") {
            VStack(spacing: Spacing.xs) {
                ForEach(items, id: \.categoryName) { cat in
                    categoryRow(cat: cat)
                }
            }
        }
    }

    private func categoryRow(cat: Omikuji.CategoryFortune) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(alignment: .center, spacing: 2) {
                Text(cat.categoryName)
                    .font(SorayomiTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(goldColor.opacity(0.8))
                Text(cat.reading)
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(width: 42)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)

            Text(cat.fortune)
                .font(SorayomiTypography.caption)
                .foregroundStyle(.white.opacity(0.82))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(goldColor.opacity(0.75))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(goldColor.opacity(0.7))
                    .tracking(4)
            }

            Divider()
                .background(goldColor.opacity(0.15))

            content()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Drag Gesture (スリングショット式)

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard phase == .idle || phase == .dragging else { return }
                phase = .dragging

                let dist = hypot(value.translation.width, value.translation.height)
                dragDistance = dist
                dragVector = value.translation

                // 神秘漢字をサイクル（吉凶のヒントなし）
                let newIdx = Int(dist / 28) % Self.mysticKanjiPool.count
                if newIdx != kanjiCycleIndex {
                    kanjiCycleIndex = newIdx
                    withAnimation(.easeInOut(duration: 0.1)) {
                        displayKanji = Self.mysticKanjiPool[kanjiCycleIndex]
                        // 色は金色ベースで微妙に変化（ランクカラーは使わない）
                        let hueShift = Double(kanjiCycleIndex) / Double(Self.mysticKanjiPool.count)
                        displayColor = Color(
                            hue: 0.10 + hueShift * 0.08,  // 金〜橙の範囲でのみ揺れる
                            saturation: 0.75,
                            brightness: 0.92
                        )
                    }
                    let light = UIImpactFeedbackGenerator(style: .light)
                    light.impactOccurred(intensity: 0.35)
                }

                // スリングショット: ドラッグ方向に印が引っ張られる（減衰 + 最大38pt）
                let maxOffset: CGFloat = 38
                let rawX = value.translation.width * 0.20
                let rawY = value.translation.height * 0.20
                withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.65)) {
                    slingOffset = CGSize(
                        width:  max(-maxOffset, min(maxOffset, rawX)),
                        height: max(-maxOffset, min(maxOffset, rawY))
                    )
                }
            }
            .onEnded { _ in
                guard phase == .dragging else { return }

                // 印をバネで中心に戻す
                withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
                    slingOffset = .zero
                }

                // ランクはドラッグ位置に関係なく、ここでランダム抽選
                selectedRank = Self.basePool.randomElement() ?? .kichi
                beginSpinSequence()
            }
    }

    // MARK: - Setup

    private func setupOnAppear() {
        // 保存済み結果を閲覧するモード
        if storedResult != nil {
            phase = .viewingStored
            return
        }

        displayKanji = "御"
        displayColor = goldColor

        startIdleAnimations()
    }

    private func startIdleAnimations() {
        withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            middlePulse = 1.0
        }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            glowPulse = 1.18
        }
    }

    // MARK: - Multi-Phase Spin Sequence

    private func beginSpinSequence() {
        phase = .spinning

        Task { @MainActor in
            // ── Phase A: 22 steps × 72ms — fast spin blur (神秘漢字のみ)
            let lightHaptic = UIImpactFeedbackGenerator(style: .light)
            lightHaptic.prepare()

            for step in 0..<22 {
                let kanji = Self.mysticKanjiPool[step % Self.mysticKanjiPool.count]
                withAnimation(.easeInOut(duration: 0.06)) {
                    displayKanji = kanji
                    displayColor = goldColor  // スピン中は常に金色
                    sealBlur = 10 + CGFloat(step % 3) * 2
                    sealRotation += 16
                }
                lightHaptic.impactOccurred(intensity: 0.3)
                try? await Task.sleep(nanoseconds: 72_000_000) // 72ms
            }

            // ── Phase B: Deceleration — 8 steps at increasing intervals (神秘漢字のみ)
            let phaseB: [UInt64] = [110, 145, 185, 230, 280, 340, 400, 420]
            let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
            mediumHaptic.prepare()

            for (i, delay) in phaseB.enumerated() {
                let kanji = Self.mysticKanjiPool[(22 + i) % Self.mysticKanjiPool.count]
                let blurAmount = max(0, 10 - CGFloat(i) * 1.5)
                withAnimation(.easeOut(duration: Double(delay) / 1000.0)) {
                    displayKanji = kanji
                    displayColor = goldColor
                    sealBlur = blurAmount
                    sealRotation += 10 - Double(i)
                }
                mediumHaptic.impactOccurred(intensity: 0.5 + Double(i) * 0.05)
                try? await Task.sleep(nanoseconds: delay * 1_000_000)
            }

            // ── Phase C: 減速収束 — 神秘漢字を使い続け、最後の一歩だけランク漢字（まだ伏せる）
            let convergenceDelays: [UInt64] = [480, 620, 820]
            for (i, delay) in convergenceDelays.enumerated() {
                // 最終ステップのみ「御」に戻す（ランク漢字は lock まで伏せる）
                let kanji = (i < convergenceDelays.count - 1)
                    ? Self.mysticKanjiPool[(30 + i) % Self.mysticKanjiPool.count]
                    : "御"
                withAnimation(.easeOut(duration: Double(delay) / 1000.0)) {
                    displayKanji = kanji
                    displayColor = goldColor
                    sealBlur = max(0, 3 - CGFloat(i) * 1.5)
                    sealRotation += 5 - Double(i) * 2
                }
                mediumHaptic.impactOccurred(intensity: 0.7 + Double(i) * 0.1)
                try? await Task.sleep(nanoseconds: delay * 1_000_000)
            }

            // ── Lock: ここでランク漢字が初めて登場 → ドラマチックな開示
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                displayKanji = selectedRank.kanji
                displayColor = rankColor(for: selectedRank)
                sealBlur = 0
            }

            let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
            heavyHaptic.impactOccurred()
            try? await Task.sleep(nanoseconds: 60_000_000) // 60ms
            let notificationHaptic = UINotificationFeedbackGenerator()
            notificationHaptic.notificationOccurred(.success)

            phase = .locked

            // Burst ring animation
            withAnimation(.easeOut(duration: 0.55)) {
                lockRingOpacity = 0.85
                lockRingScale = 1.25
                rankBurstScale = 1.08
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.55)) {
                lockRingOpacity = 0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.45)) {
                rankBurstScale = 1.0
            }

            // ── Generate result and notify (mark used happens here, not on dismiss)
            let result = OmikujiCalculator.draw(
                forcedRank: selectedRank,
                birthday: profile?.birthday,
                bloodType: profile?.bloodType
            )
            finalResult = result
            onResultDetermined(result)

            // 1.1s pause for drama
            try? await Task.sleep(nanoseconds: 1_100_000_000)

            // ── Transition to revealed
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                phase = .revealed
                rankScale = 1.0
                rankOpacity = 1.0
            }

            try? await Task.sleep(nanoseconds: 280_000_000)

            withAnimation(.spring(response: 0.65, dampingFraction: 0.80)) {
                contentOffset = 0
                contentOpacity = 1.0
            }
        }
    }

    // MARK: - Color Helpers

    private var goldColor: Color {
        Color(red: 1.0, green: 0.86, blue: 0.46)
    }

    private func rankColor(for rank: Omikuji.Rank) -> Color {
        switch rank {
        case .daikichi: return Color(red: 1.0,  green: 0.82, blue: 0.15)   // Gold
        case .kichi:    return Color(red: 0.22, green: 0.86, blue: 0.52)   // Green
        case .chukichi: return Color(red: 0.28, green: 0.68, blue: 1.0)    // Blue
        case .shokichi: return Color(red: 0.75, green: 0.52, blue: 1.0)    // Lavender
        case .suekichi: return Color(red: 1.0,  green: 0.65, blue: 0.22)   // Amber
        case .kyo:      return Color(red: 0.92, green: 0.36, blue: 0.36)   // Red
        }
    }
}

// MARK: - Omikuji.Rank kanji helper

private extension Omikuji.Rank {
    /// 印として表示する漢字（ドラッグ中にサイクルさせる）
    var kanji: String {
        switch self {
        case .daikichi: return "大"
        case .kichi:    return "吉"
        case .chukichi: return "中"
        case .shokichi: return "小"
        case .suekichi: return "末"
        case .kyo:      return "凶"
        }
    }
}

// MARK: - Preview

#Preview("通常フロー") {
    OmikujiRevealView(
        profile: nil,
        storedResult: nil,
        onResultDetermined: { _ in },
        onDismiss: {}
    )
}

#Preview("結果閲覧") {
    OmikujiRevealView(
        profile: nil,
        storedResult: .preview,
        onResultDetermined: { _ in },
        onDismiss: {}
    )
}
