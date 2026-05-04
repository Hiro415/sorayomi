import SwiftUI

// MARK: - TarotRevealView

/// タロットカードのリビールアニメーション
/// 神秘的な雰囲気のカードめくり演出。エレメンタルディグニティの可視化、
/// スプレッド概要、カード間の接続ライン、完了後に「鑑定結果を見る」ボタンを表示。
struct TarotRevealView: View {
    let drawnCards: [DrawnTarotCard]
    let onComplete: () -> Void

    @State private var revealedCount = 0
    @State private var allRevealed = false
    @State private var showButton = false
    @State private var showSpreadOverview = false
    @State private var ambientPhase: CGFloat = 0
    @State private var particles: [TarotParticle] = []
    @State private var connectionLineProgress: CGFloat = 0
    @State private var overviewOpacity: Double = 0
    @State private var viewWidth: CGFloat = 390

    // Phase tracking
    @State private var revealPhase: RevealPhase = .closeUp
    @State private var closeUpIndex = 0
    @State private var closeUpFlipped = false
    @State private var closeUpVisible = false
    @State private var closeUpLabelVisible = false
    @State private var selectedCard: DrawnTarotCard? = nil

    private enum RevealPhase {
        case closeUp
        case spread
    }

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }

    /// オーバーレイに表示するカード（nilで非表示、非nilでオーバーレイ表示）
    @State private var overlayCard: DrawnTarotCard? = nil

    /// spreadPhaseView の遅延マウント用（close-up中はマウントせず負荷を回避）
    @State private var spreadPhaseReady = false

    var body: some View {
        ZStack {
            mysticalBackground
                .drawingGroup() // GPU合成でパーティクルの描画負荷を軽減

            // Close-up フェーズ: 常にマウント（初期表示）
            closeUpPhaseView
                .opacity(revealPhase == .closeUp ? 1 : 0)
                .allowsHitTesting(revealPhase == .closeUp)

            // Spread フェーズ: revealPhase == .spread になった後にマウント
            // close-up 中は TarotCardView の onAppear アニメーションが走らないため軽量
            if spreadPhaseReady {
                spreadPhaseView
                    .opacity(revealPhase == .spread ? 1 : 0)
                    .allowsHitTesting(revealPhase == .spread)
            }

            // Detail overlay — overlayCard が非nil の時だけ表示
            // ツールバーは隠さない（overlay が Color.black.ignoresSafeArea() で全面カバーするため）
            // → safe area 変動なし → 上下ブレなし
            if let card = overlayCard {
                TarotCardDetailOverlay(drawnCard: card) {
                    dismissDetailOverlay()
                }
                .zIndex(100)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            startCloseUpSequence()
            // パーティクル / アンビエントは少し遅延して開始（初期描画を軽くする）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                generateParticles()
                startAmbientAnimation()
            }
        }
    }

    private func showCardDetail(_ card: DrawnTarotCard) {
        selectedCard = card
        overlayCard = card
    }

    private func dismissDetailOverlay() {
        // overlay 側の isPresented フェードアウト完了後に呼ばれる
        selectedCard = nil
        overlayCard = nil
    }

    // MARK: - Close-Up Phase View

    private var closeUpPhaseView: some View {
        VStack(spacing: 0) {
            Spacer()

            spreadTitleView
                .padding(.bottom, Spacing.lg)

            if closeUpIndex < drawnCards.count {
                VStack(spacing: isLargeScreen ? Spacing.lg : Spacing.md) {
                    // Position label
                    Text(drawnCards[closeUpIndex].position.japaneseName)
                        .font(isLargeScreen ? .system(size: 18, weight: .medium, design: .serif) : .system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(.white.opacity(closeUpLabelVisible ? 0.7 : 0))
                        .animation(.easeOut(duration: 0.4), value: closeUpLabelVisible)

                    // Card — .id forces fresh TarotCardView per card (resets internal flipDegrees)
                    TarotCardView(
                        drawnCard: drawnCards[closeUpIndex],
                        isRevealed: closeUpFlipped,
                        cardIndex: 0
                    )
                    .id("closeup-\(closeUpIndex)")
                    .frame(width: sizes.tarotCloseUpWidth, height: sizes.tarotCloseUpWidth * 1.5)
                    .opacity(closeUpVisible ? 1 : 0)
                    .scaleEffect(closeUpVisible ? 1 : 0.92)

                    // Card name (shows after flip)
                    if closeUpFlipped {
                        Text(drawnCards[closeUpIndex].card.japaneseName)
                            .font(.system(size: isLargeScreen ? 20 : 16, weight: .semibold, design: .serif))
                            .foregroundStyle(.white.opacity(0.8))
                            .transition(.opacity)

                        Text(drawnCards[closeUpIndex].isReversed ? "逆位置" : "正位置")
                            .font(.system(size: isLargeScreen ? 12 : 10, weight: .bold))
                            .foregroundStyle(drawnCards[closeUpIndex].isReversed
                                ? Color(hue: 0.0, saturation: 0.4, brightness: 0.9)
                                : Color(hue: 0.55, saturation: 0.3, brightness: 0.9))
                            .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.5), value: closeUpFlipped)
            }

            Spacer()

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<drawnCards.count, id: \.self) { i in
                    Circle()
                        .fill(i <= closeUpIndex ? Color.white.opacity(0.7) : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
    }

    // MARK: - Spread Phase View

    private var spreadPhaseView: some View {
        VStack(spacing: 0) {
            Spacer()

            spreadTitleView
                .padding(.bottom, Spacing.lg)

            cardSpread
                .padding(.horizontal, Spacing.md)

            // Elemental dignity connection indicator
            if allRevealed && drawnCards.count >= 2 {
                elementalDignityBar
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if revealedCount > 0 {
                revealedCardsSummary
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.lg)
            }

            // Spread tendency overview
            if showSpreadOverview {
                spreadOverview
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            if showButton {
                resultButton
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)).combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            }
        }
    }

    // MARK: - Mystical Background

    private var mysticalBackground: some View {
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

            // Suit-themed ambient glow (based on dominant suit)
            if let dominantSuit = dominantSuit {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [suitGlowColor(dominantSuit).opacity(0.08), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .scaleEffect(1.0 + ambientPhase * 0.2)
                    .opacity(allRevealed ? 0.8 : 0)
                    .animation(.easeInOut(duration: 1.5), value: allRevealed)
            }

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

    // MARK: - Spread Title

    private var spreadTitleView: some View {
        VStack(spacing: Spacing.xs) {
            Text(spreadTitle)
                .font(.system(size: isLargeScreen ? 20 : 14, weight: .medium, design: .serif))
                .tracking(isLargeScreen ? 6 : 4)
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

            Text(spreadSubtitle)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundStyle(.white.opacity(0.4))

            // Major arcana count badge
            if allRevealed {
                let majorCount = drawnCards.filter { $0.card.arcana == .major }.count
                if majorCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8))
                        Text("大アルカナ \(majorCount)枚")
                            .font(.system(size: 10, weight: .medium, design: .serif))
                    }
                    .foregroundStyle(Color(hue: 0.12, saturation: 0.4, brightness: 0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color(hue: 0.12, saturation: 0.3, brightness: 0.5).opacity(0.2))
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .animation(.easeOut(duration: 0.5), value: allRevealed)
    }

    // MARK: - Card Spread

    @ViewBuilder
    private var cardSpread: some View {
        switch drawnCards.count {
        case 1:
            singleCardLayout
        case 3:
            threeCardLayout
        default:
            fiveCardLayout
        }
    }

    /// iPadかどうかの簡易判定
    private var isLargeScreen: Bool { viewWidth > 600 }

    /// iPad時は位置ラベルのフォントを大きく
    private var positionLabelFont: Font {
        isLargeScreen
            ? .system(size: 15, weight: .medium, design: .serif)
            : .system(size: 11, weight: .medium, design: .serif)
    }

    private var singleCardLayout: some View {
        VStack(spacing: isLargeScreen ? Spacing.lg : Spacing.md) {
            Text(drawnCards[0].position.japaneseName)
                .font(positionLabelFont)
                .foregroundStyle(.white.opacity(revealedCount > 0 ? 0.6 : 0))
                .animation(.easeOut(duration: 0.3), value: revealedCount)

            TarotCardView(
                drawnCard: drawnCards[0],
                isRevealed: revealedCount > 0,
                cardIndex: 0
            )
            .frame(width: sizes.tarotSingleCard.width, height: sizes.tarotSingleCard.height)
            .onTapGesture { showCardDetail(drawnCards[0]) }
            .hoverEffect(.lift)
        }
    }

    private var threeCardLayout: some View {
        HStack(spacing: isLargeScreen ? Spacing.xl : Spacing.lg) {
            ForEach(Array(drawnCards.enumerated()), id: \.element.id) { index, card in
                VStack(spacing: isLargeScreen ? Spacing.md : Spacing.sm) {
                    Text(card.position.japaneseName)
                        .font(positionLabelFont)
                        .foregroundStyle(.white.opacity(revealedCount > index ? 0.6 : 0))
                        .animation(.easeOut(duration: 0.4), value: revealedCount)

                    TarotCardView(
                        drawnCard: card,
                        isRevealed: revealedCount > index,
                        cardIndex: index
                    )
                    .frame(width: sizes.tarotThreeCardWidth, height: sizes.tarotThreeCardWidth * 1.5)
                    .onTapGesture { showCardDetail(card) }
                    .hoverEffect(.lift)
                }
            }
        }
    }

    private var fiveCardLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isLargeScreen ? Spacing.lg : Spacing.md) {
                ForEach(Array(drawnCards.enumerated()), id: \.element.id) { index, card in
                    VStack(spacing: isLargeScreen ? Spacing.md : Spacing.sm) {
                        Text(card.position.japaneseName)
                            .font(isLargeScreen ? .system(size: 13, weight: .medium, design: .serif) : .system(size: 10, weight: .medium, design: .serif))
                            .foregroundStyle(.white.opacity(revealedCount > index ? 0.6 : 0))
                            .animation(.easeOut(duration: 0.4), value: revealedCount)

                        TarotCardView(
                            drawnCard: card,
                            isRevealed: revealedCount > index,
                            cardIndex: index
                        )
                        .frame(width: sizes.tarotFiveCardWidth, height: sizes.tarotFiveCardWidth * 1.5)
                        .onTapGesture { showCardDetail(card) }
                        .hoverEffect(.lift)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Elemental Dignity Bar

    private var elementalDignityBar: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<max(0, drawnCards.count - 1), id: \.self) { i in
                let rel = TarotElementalDignity.relationship(
                    between: drawnCards[i].card.suit,
                    and: drawnCards[i + 1].card.suit
                )
                HStack(spacing: 3) {
                    elementDot(for: drawnCards[i].card.suit)

                    Rectangle()
                        .fill(dignityColor(rel))
                        .frame(height: 2)
                        .frame(maxWidth: connectionLineProgress * 40)

                    if i == drawnCards.count - 2 {
                        elementDot(for: drawnCards[i + 1].card.suit)
                    }
                }

                if i < drawnCards.count - 2 {
                    Spacer(minLength: 2)
                }
            }
        }
        .frame(height: 20)
        .animation(.easeInOut(duration: 0.8), value: connectionLineProgress)
    }

    private func elementDot(for suit: TarotSuit?) -> some View {
        Circle()
            .fill(suit != nil ? suitGlowColor(suit!) : Color(hue: 0.12, saturation: 0.3, brightness: 0.8))
            .frame(width: 6, height: 6)
    }

    private func dignityColor(_ rel: TarotElementalDignity.Relationship) -> Color {
        switch rel {
        case .friendly: return Color(hue: 0.35, saturation: 0.5, brightness: 0.8)
        case .neutral:  return Color.white.opacity(0.3)
        case .hostile:  return Color(hue: 0.0, saturation: 0.5, brightness: 0.8)
        }
    }

    // MARK: - Revealed Cards Summary

    private var revealedCardsSummary: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(Array(drawnCards.prefix(revealedCount).enumerated()), id: \.element.id) { _, card in
                HStack(spacing: Spacing.xs) {
                    if let suit = card.card.suit {
                        Image(systemName: suitSymbolName(suit))
                            .font(.system(size: 8))
                            .foregroundStyle(suitGlowColor(suit))
                            .frame(width: 14)
                    } else {
                        Image(systemName: "sparkle")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hue: 0.12, saturation: 0.4, brightness: 0.8))
                            .frame(width: 14)
                    }

                    Text("\(card.position.japaneseName)：\(card.card.japaneseName)")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(card.isReversed ? "逆" : "正")
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .foregroundStyle(card.isReversed
                            ? Color(hue: 0.0, saturation: 0.4, brightness: 0.8)
                            : Color(hue: 0.55, saturation: 0.3, brightness: 0.8)
                        )

                    if card.card.arcana == .major {
                        Text("★")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hue: 0.12, saturation: 0.4, brightness: 0.85))
                    }

                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .animation(.easeOut(duration: 0.3), value: revealedCount)
    }

    // MARK: - Spread Overview

    private var spreadOverview: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            let majorCount = drawnCards.filter { $0.card.arcana == .major }.count
            let reversedCount = drawnCards.filter { $0.isReversed }.count

            HStack(spacing: Spacing.sm) {
                if majorCount > 0 {
                    tendencyBadge(
                        icon: "sparkles",
                        text: "大アルカナ×\(majorCount)",
                        color: Color(hue: 0.12, saturation: 0.4, brightness: 0.85)
                    )
                }

                tendencyBadge(
                    icon: reversedCount > drawnCards.count / 2 ? "arrow.uturn.down" : "arrow.up",
                    text: "正\(drawnCards.count - reversedCount)/逆\(reversedCount)",
                    color: reversedCount > drawnCards.count / 2
                        ? Color(hue: 0.0, saturation: 0.3, brightness: 0.8)
                        : Color(hue: 0.55, saturation: 0.3, brightness: 0.8)
                )

                if let dominantSuit {
                    tendencyBadge(
                        icon: suitSymbolName(dominantSuit),
                        text: dominantSuit.japaneseName,
                        color: suitGlowColor(dominantSuit)
                    )
                }
            }
        }
        .opacity(overviewOpacity)
    }

    private func tendencyBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.system(size: 10, weight: .medium, design: .serif))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Result Button

    private var resultButton: some View {
        Button {
            onComplete()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 14))
                Text("鑑定結果を見る")
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
                                    Color(hue: 0.72, saturation: 0.5, brightness: 0.4),
                                    Color(hue: 0.78, saturation: 0.4, brightness: 0.3),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.12, saturation: 0.3, brightness: 0.8).opacity(0.3),
                                    Color(hue: 0.12, saturation: 0.3, brightness: 0.8).opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color(hue: 0.72, saturation: 0.5, brightness: 0.3).opacity(0.4), radius: 12, y: 4)
        }
    }

    // MARK: - Helpers

    private var spreadTitle: String {
        switch drawnCards.count {
        case 1: return "ONE  ORACLE"
        case 3: return "THREE  CARD  SPREAD"
        default: return "TAROT  SPREAD"
        }
    }

    private var spreadSubtitle: String {
        switch drawnCards.count {
        case 1: return "一枚引き"
        case 3: return "過去 ・ 現在 ・ 未来"
        default: return "\(drawnCards.count)枚展開"
        }
    }

    private var dominantSuit: TarotSuit? {
        let suits = drawnCards.compactMap { $0.card.suit }
        guard !suits.isEmpty else { return nil }
        let counts = Dictionary(grouping: suits, by: { $0 })
        let maxCount = counts.values.map(\.count).max() ?? 0
        let dominants = counts.filter { $0.value.count == maxCount }
        // タイの場合は不安定になるため表示しない
        guard dominants.count == 1 else { return nil }
        return dominants.first?.key
    }

    private func suitGlowColor(_ suit: TarotSuit) -> Color {
        switch suit {
        case .wands:     return Color(hue: 0.05, saturation: 0.6, brightness: 0.85)
        case .cups:      return Color(hue: 0.58, saturation: 0.5, brightness: 0.85)
        case .swords:    return Color(hue: 0.55, saturation: 0.3, brightness: 0.85)
        case .pentacles: return Color(hue: 0.12, saturation: 0.5, brightness: 0.85)
        }
    }

    private func suitSymbolName(_ suit: TarotSuit) -> String {
        switch suit {
        case .wands:     return "flame.fill"
        case .cups:      return "drop.fill"
        case .swords:    return "wind"
        case .pentacles: return "circle.hexagongrid.fill"
        }
    }

    // MARK: - Close-Up Reveal Sequence

    private func startCloseUpSequence() {
        showNextCloseUpCard()
    }

    private func showNextCloseUpCard() {
        guard closeUpIndex < drawnCards.count else {
            // All cards shown, transition to spread
            transitionToSpread()
            return
        }

        // Dramatic pause before first card; shorter for subsequent cards
        let initialDelay: Double = closeUpIndex == 0 ? 1.2 : 0.3

        // 1. Card appears (with initial delay for buildup)
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                closeUpVisible = true
            }

            // 2. Label appears (staggered)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    closeUpLabelVisible = true
                }
            }

            // 3. Card flips — longer pause on first card for dramatic effect
            let flipDelay: Double = closeUpIndex == 0 ? 1.4 : 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + flipDelay) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                    closeUpFlipped = true
                }
                let style: UIImpactFeedbackGenerator.FeedbackStyle =
                    drawnCards[closeUpIndex].card.arcana == .major ? .heavy : .medium
                UIImpactFeedbackGenerator(style: style).impactOccurred()
            }

            // 4. Hold, then fade out smoothly before moving to next
            let totalHold: Double = (closeUpIndex == 0 ? 1.4 : 1.0) + 1.8
            DispatchQueue.main.asyncAfter(deadline: .now() + totalHold) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    closeUpVisible = false
                    closeUpLabelVisible = false
                }

                // Wait for fade-out to complete, then switch card
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        closeUpVisible = false
                        closeUpLabelVisible = false
                        closeUpFlipped = false
                        closeUpIndex += 1
                    }
                    // Small delay to let SwiftUI commit the invisible state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        showNextCloseUpCard()
                    }
                }
            }
        }
    }

    private func transitionToSpread() {
        // 1. spread ビューをマウント（opacity=0 の状態で描画準備）
        spreadPhaseReady = true

        // 2. 1フレーム後にクロスフェード開始（マウント完了を待つ）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.8)) {
                revealPhase = .spread
                revealedCount = drawnCards.count
                allRevealed = true
            }
        }

        // Show elemental dignity (staggered)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                connectionLineProgress = 1.0
            }
        }

        // Show spread overview
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.6)) {
                showSpreadOverview = true
                overviewOpacity = 1.0
            }
        }

        // Show button — gentle spring
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                showButton = true
            }
        }
    }

    // MARK: - Ambient Animation

    private func startAmbientAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            ambientPhase = 1.0
        }
    }

    private func generateParticles() {
        let w = viewWidth
        let h = viewWidth * 2.16 // approximate screen aspect ratio
        // パーティクル数を抑えて初期描画負荷を軽減
        particles = (0..<8).map { _ in
            TarotParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...w),
                    y: CGFloat.random(in: 0...h)
                ),
                size: CGFloat.random(in: 1...2.5),
                opacity: Double.random(in: 0.1...0.5),
                blur: CGFloat.random(in: 0...0.5)
            )
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            while !Task.isCancelled {
                // バッチ更新で再描画回数を削減
                withAnimation(.easeInOut(duration: 3.0)) {
                    for i in particles.indices {
                        particles[i].opacity = Double.random(in: 0.05...0.6)
                        particles[i].position.y -= CGFloat.random(in: 0...2)
                    }
                }
                try? await Task.sleep(for: .seconds(4))
            }
        }
    }
}

private struct TarotParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
}

// MARK: - TarotCardView

/// 1枚のタロットカードビュー（裏面/表面の3Dフリップアニメーション付き）
struct TarotCardView: View {
    let drawnCard: DrawnTarotCard
    let isRevealed: Bool
    let cardIndex: Int

    @State private var flipDegrees: Double = 0
    @State private var cardScale: CGFloat = 0.85
    @State private var glowOpacity: Double = 0
    @State private var elementPulse: CGFloat = 0

    var body: some View {
        ZStack {
            if isRevealed {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(cardGlowColor.opacity(glowOpacity))
                    .blur(radius: 15)
                    .scaleEffect(1.15 + elementPulse * 0.05)
            }

            ZStack {
                if flipDegrees < 90 {
                    cardBack
                } else {
                    cardFront
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
            }
            .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0))
        }
        .scaleEffect(cardScale)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(Double(cardIndex) * 0.15)) {
                cardScale = 1.0
            }
            // If already revealed on appear (e.g. spread phase), show front immediately
            if isRevealed && flipDegrees == 0 {
                flipDegrees = 180
                glowOpacity = 0.1
                if drawnCard.card.arcana == .major {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.5)) {
                        elementPulse = 1.0
                    }
                }
            }
        }
        .onChange(of: isRevealed) { _, revealed in
            if revealed {
                withAnimation(.easeInOut(duration: 0.7)) {
                    flipDegrees = 180
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                    glowOpacity = 0.3
                }
                withAnimation(.easeInOut(duration: 1.5).delay(1.5)) {
                    glowOpacity = 0.1
                }
                if drawnCard.card.arcana == .major {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.0)) {
                        elementPulse = 1.0
                    }
                }
            }
        }
    }

    // MARK: - Card Back

    private var cardBack: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                if let backImage = UIImage(named: "tarot_back") {
                    Image(uiImage: backImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.72, saturation: 0.55, brightness: 0.22),
                                    Color(hue: 0.75, saturation: 0.45, brightness: 0.12),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.12, saturation: 0.4, brightness: 0.7).opacity(0.4),
                                    Color(hue: 0.12, saturation: 0.3, brightness: 0.5).opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .padding(3)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            Color(hue: 0.12, saturation: 0.3, brightness: 0.6).opacity(0.15),
                            lineWidth: 0.5
                        )
                        .padding(8)

                    VStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: min(w, h) * 0.18, weight: .ultraLight))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hue: 0.12, saturation: 0.3, brightness: 0.8).opacity(0.35),
                                        Color(hue: 0.08, saturation: 0.4, brightness: 0.6).opacity(0.2),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Rectangle()
                            .fill(Color(hue: 0.12, saturation: 0.3, brightness: 0.7).opacity(0.15))
                            .frame(width: w * 0.4, height: 0.5)
                    }

                    ForEach(0..<4, id: \.self) { corner in
                        Circle()
                            .fill(Color(hue: 0.12, saturation: 0.3, brightness: 0.7).opacity(0.2))
                            .frame(width: 3, height: 3)
                            .position(
                                x: corner % 2 == 0 ? 14 : w - 14,
                                y: corner < 2 ? 14 : h - 14
                            )
                    }
                }
            }
            .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
        }
    }

    // MARK: - Card Front

    private var cardFront: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: cardGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.05), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: max(w, h)
                        )
                    )

                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(hue: 0.12, saturation: 0.3, brightness: 0.9).opacity(0.35),
                                Color(hue: 0.12, saturation: 0.4, brightness: 0.6).opacity(0.15),
                                Color(hue: 0.12, saturation: 0.3, brightness: 0.9).opacity(0.25),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .padding(2)

                VStack(spacing: 0) {
                    HStack {
                        Text(cardNumberDisplay)
                            .font(.system(size: min(w, h) * 0.08, weight: .bold, design: .serif))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        if drawnCard.card.arcana == .major {
                            Text("MAJOR")
                                .font(.system(size: 6, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.3))
                        } else if let suit = drawnCard.card.suit {
                            Image(systemName: suitSymbol(suit))
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)

                    TarotCardArtwork(
                        card: drawnCard.card,
                        isReversed: drawnCard.isReversed
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)

                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(.white.opacity(0.15))
                            .frame(width: w * 0.5, height: 0.5)
                            .padding(.bottom, 2)

                        Text(drawnCard.card.japaneseName)
                            .font(.system(size: min(w, h) * 0.085, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Text(drawnCard.isReversed ? "R E V E R S E D" : "U P R I G H T")
                            .font(.system(size: 6, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(drawnCard.isReversed
                                ? Color(hue: 0.0, saturation: 0.4, brightness: 0.9).opacity(0.7)
                                : Color(hue: 0.12, saturation: 0.3, brightness: 0.9).opacity(0.5)
                            )
                    }
                    .padding(.horizontal, 5)
                    .padding(.bottom, 6)
                }
            }
            .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
        }
    }

    // MARK: - Card Styling

    private var cardGlowColor: Color {
        if drawnCard.card.arcana == .major {
            return Color(hue: 0.12, saturation: 0.5, brightness: 0.8)
        }
        guard let suit = drawnCard.card.suit else { return .white }
        switch suit {
        case .wands:     return Color(hue: 0.05, saturation: 0.6, brightness: 0.8)
        case .cups:      return Color(hue: 0.58, saturation: 0.5, brightness: 0.8)
        case .swords:    return Color(hue: 0.55, saturation: 0.3, brightness: 0.8)
        case .pentacles: return Color(hue: 0.12, saturation: 0.5, brightness: 0.8)
        }
    }

    private var cardGradientColors: [Color] {
        if drawnCard.card.arcana == .major {
            return [
                Color(hue: 0.72, saturation: 0.45, brightness: 0.30),
                Color(hue: 0.78, saturation: 0.35, brightness: 0.15),
                Color(hue: 0.72, saturation: 0.40, brightness: 0.20),
            ]
        }
        guard let suit = drawnCard.card.suit else {
            return [Color.sorayomiSurface, Color.sorayomiBackground]
        }
        switch suit {
        case .wands:
            return [
                Color(hue: 0.02, saturation: 0.50, brightness: 0.30),
                Color(hue: 0.05, saturation: 0.40, brightness: 0.15),
                Color(hue: 0.02, saturation: 0.45, brightness: 0.20),
            ]
        case .cups:
            return [
                Color(hue: 0.58, saturation: 0.45, brightness: 0.30),
                Color(hue: 0.62, saturation: 0.35, brightness: 0.15),
                Color(hue: 0.58, saturation: 0.40, brightness: 0.20),
            ]
        case .swords:
            return [
                Color(hue: 0.55, saturation: 0.25, brightness: 0.32),
                Color(hue: 0.58, saturation: 0.18, brightness: 0.16),
                Color(hue: 0.55, saturation: 0.22, brightness: 0.22),
            ]
        case .pentacles:
            return [
                Color(hue: 0.10, saturation: 0.45, brightness: 0.30),
                Color(hue: 0.12, saturation: 0.35, brightness: 0.15),
                Color(hue: 0.10, saturation: 0.40, brightness: 0.20),
            ]
        }
    }

    private var cardNumberDisplay: String {
        if drawnCard.card.arcana == .major {
            let romanNumerals = ["0", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX",
                                 "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII",
                                 "XIX", "XX", "XXI"]
            let n = drawnCard.card.number
            return n < romanNumerals.count ? romanNumerals[n] : "\(n)"
        }
        guard let suit = drawnCard.card.suit else { return "" }
        return suit.element
    }

    private func suitSymbol(_ suit: TarotSuit) -> String {
        switch suit {
        case .wands:     return "flame.fill"
        case .cups:      return "drop.fill"
        case .swords:    return "wind"
        case .pentacles: return "circle.hexagongrid.fill"
        }
    }
}

// MARK: - Preview

#Preview("3 Cards") {
    TarotRevealView(
        drawnCards: TarotDrawEngine.draw(count: 3),
        onComplete: {}
    )
}

#Preview("1 Card") {
    TarotRevealView(
        drawnCards: TarotDrawEngine.draw(count: 1),
        onComplete: {}
    )
}

#Preview("5 Cards") {
    TarotRevealView(
        drawnCards: TarotDrawEngine.draw(count: 5),
        onComplete: {}
    )
}
