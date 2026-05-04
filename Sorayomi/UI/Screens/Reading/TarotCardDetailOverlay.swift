import SwiftUI

// MARK: - TarotCardDetailOverlay

/// タロットカードの詳細オーバーレイ。
/// スプレッド内のカードをタップすると表示される全画面モーダル。
/// カードアートワーク、名称、正逆位置、キーワード、意味、
/// 大アルカナの元型・占星術対応、小アルカナのスート領域・数字テーマを表示。
struct TarotCardDetailOverlay: View {
    let drawnCard: DrawnTarotCard
    let onDismiss: () -> Void

    @State private var isPresented = false
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }

    private var isLargeScreen: Bool { viewWidth > 600 }

    var body: some View {
        // 全体をタップ可能にする — ScrollViewの空白部分もdismiss対象
        ZStack {
            // Fully opaque dark backdrop
            Color.black
                .ignoresSafeArea()

            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: isLargeScreen ? Spacing.lg : Spacing.md) {
                    Spacer(minLength: Spacing.sm)

                    // Card artwork
                    cardArtworkSection

                    // Card name
                    cardNameSection

                    // Orientation badge
                    orientationBadge

                    // Keywords
                    keywordsSection

                    // Meaning
                    meaningSection

                    // Divider
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(height: 1)
                        .padding(.horizontal, Spacing.xl)

                    // Arcana-specific extras
                    if drawnCard.card.arcana == .major {
                        majorArcanaExtras
                    } else {
                        minorArcanaExtras
                    }

                    Spacer(minLength: Spacing.xxl)
                }
                .frame(maxWidth: isLargeScreen ? 500 : .infinity)
                .frame(maxWidth: .infinity) // center on iPad
            }
        }
        // カード以外のどこをタップしてもdismiss
        // （ScrollView内のテキスト・バッジ部分を含む全域）
        .contentShape(Rectangle())
        .onTapGesture {
            dismissOverlay()
        }
        .opacity(isPresented ? 1 : 0)
        .scaleEffect(isPresented ? 1 : 0.97)
        // Scoped animation — only reacts to isPresented, does NOT leak to parent views
        .animation(.easeInOut(duration: 0.3), value: isPresented)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            isPresented = true
        }
    }

    // MARK: - Card Artwork

    private var cardArtworkSection: some View {
        ZStack {
            // Glow behind card
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardGlowColor.opacity(0.2))
                .blur(radius: 30)
                .frame(
                    width: sizes.tarotDetailWidth * 1.2,
                    height: sizes.tarotDetailWidth * 1.5 * 1.2
                )

            TarotCardView(
                drawnCard: drawnCard,
                isRevealed: true,
                cardIndex: 0
            )
            .frame(
                width: sizes.tarotDetailWidth,
                height: sizes.tarotDetailWidth * 1.5
            )
        }
    }

    // MARK: - Card Name

    private var cardNameSection: some View {
        VStack(spacing: Spacing.xxs) {
            Text(drawnCard.card.japaneseName)
                .font(.system(
                    size: isLargeScreen ? 28 : 22,
                    weight: .bold,
                    design: .serif
                ))
                .foregroundStyle(.white)

            Text(drawnCard.card.englishName)
                .font(.system(
                    size: isLargeScreen ? 15 : 12,
                    weight: .medium,
                    design: .serif
                ))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Orientation Badge

    private var orientationBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: drawnCard.isReversed ? "arrow.uturn.down" : "arrow.up")
                .font(.system(size: isLargeScreen ? 12 : 10, weight: .bold))
            Text(drawnCard.isReversed ? "逆位置" : "正位置")
                .font(.system(
                    size: isLargeScreen ? 14 : 12,
                    weight: .semibold,
                    design: .serif
                ))
        }
        .foregroundStyle(
            drawnCard.isReversed
                ? Color(hue: 0.0, saturation: 0.45, brightness: 0.9)
                : Color(hue: 0.12, saturation: 0.35, brightness: 0.9)
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            (drawnCard.isReversed
                ? Color(hue: 0.0, saturation: 0.4, brightness: 0.5)
                : Color(hue: 0.12, saturation: 0.3, brightness: 0.5)
            ).opacity(0.25)
        )
        .clipShape(Capsule())
    }

    // MARK: - Keywords

    private var keywordsSection: some View {
        VStack(spacing: Spacing.xs) {
            sectionLabel("キーワード")

            FlowLayout(spacing: 8) {
                ForEach(keywords, id: \.self) { keyword in
                    keywordBadge(keyword)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    private func keywordBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(
                size: isLargeScreen ? 13 : 11,
                weight: .medium,
                design: .serif
            ))
            .foregroundStyle(cardGlowColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(cardGlowColor.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Meaning

    private var meaningSection: some View {
        VStack(spacing: Spacing.xs) {
            sectionLabel("意味")

            Text(meaningText)
                .font(.system(
                    size: isLargeScreen ? 15 : 13,
                    weight: .regular,
                    design: .serif
                ))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Major Arcana Extras

    private var majorArcanaExtras: some View {
        let meaning = TarotMajorMeaning.meaning(for: drawnCard.card.number)

        return VStack(spacing: Spacing.sm) {
            detailRow(label: "元型", value: meaning.archetype, icon: "sparkles")
            detailRow(
                label: "占星術対応",
                value: meaning.astrologicalCorrespondence,
                icon: "star.fill"
            )
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Minor Arcana Extras

    private var minorArcanaExtras: some View {
        let suit = drawnCard.card.suit
        let numberMeaning = TarotMinorNumberMeaning.meaning(for: drawnCard.card.number)

        return VStack(spacing: Spacing.sm) {
            if let suit {
                detailRow(
                    label: "スートの領域",
                    value: "\(suit.japaneseName) — \(suit.domain)",
                    icon: suitSymbolName(suit)
                )
            }
            detailRow(
                label: "数字のテーマ",
                value: numberMeaning.theme,
                icon: "number"
            )
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Shared Detail Row

    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: isLargeScreen ? 14 : 11))
                .foregroundStyle(cardGlowColor.opacity(0.8))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(
                        size: isLargeScreen ? 11 : 9,
                        weight: .medium
                    ))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(1)

                Text(value)
                    .font(.system(
                        size: isLargeScreen ? 15 : 13,
                        weight: .medium,
                        design: .serif
                    ))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(
                size: isLargeScreen ? 11 : 9,
                weight: .bold
            ))
            .tracking(3)
            .foregroundStyle(.white.opacity(0.35))
            .textCase(.uppercase)
    }

    // MARK: - Helpers

    private var keywords: [String] {
        if drawnCard.card.arcana == .major {
            let meaning = TarotMajorMeaning.meaning(for: drawnCard.card.number)
            return drawnCard.isReversed ? meaning.reversedKeywords : meaning.uprightKeywords
        } else {
            return minorArcanaKeywords
        }
    }

    /// Minor arcana keywords: number theme + essence phrases (suit info shown in extras below)
    private var minorArcanaKeywords: [String] {
        let numberMeaning = TarotMinorNumberMeaning.meaning(for: drawnCard.card.number)
        let essence = drawnCard.isReversed
            ? numberMeaning.reversedEssence
            : numberMeaning.uprightEssence

        // Split essence by 。 into stable keyword phrases
        let essenceParts = essence.components(separatedBy: "。")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var result: [String] = [numberMeaning.theme]
        result.append(contentsOf: essenceParts.prefix(3))
        return result
    }

    private var meaningText: String {
        if drawnCard.card.arcana == .major {
            let meaning = TarotMajorMeaning.meaning(for: drawnCard.card.number)
            return drawnCard.isReversed ? meaning.reversedMeaning : meaning.uprightMeaning
        } else {
            return minorArcanaMeaning
        }
    }

    /// Minor arcana meaning: "スートのテーマ。エッセンス" pattern
    private var minorArcanaMeaning: String {
        guard let suit = drawnCard.card.suit else { return "" }

        let numberMeaning = TarotMinorNumberMeaning.meaning(for: drawnCard.card.number)
        let essence = drawnCard.isReversed
            ? numberMeaning.reversedEssence
            : numberMeaning.uprightEssence

        return "\(suit.japaneseName)の\(numberMeaning.theme)。\(essence)"
    }

    private var cardGlowColor: Color {
        if drawnCard.card.arcana == .major {
            return Color(hue: 0.12, saturation: 0.5, brightness: 0.85) // gold
        }
        guard let suit = drawnCard.card.suit else { return .white }
        switch suit {
        case .wands:     return Color(hue: 0.05, saturation: 0.6, brightness: 0.85)  // fire red
        case .cups:      return Color(hue: 0.58, saturation: 0.5, brightness: 0.85)  // blue
        case .swords:    return Color(hue: 0.55, saturation: 0.3, brightness: 0.85)  // silver
        case .pentacles: return Color(hue: 0.12, saturation: 0.5, brightness: 0.85)  // gold
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

    // MARK: - Dismiss

    private func dismissOverlay() {
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Major Arcana - Upright") {
    TarotCardDetailOverlay(
        drawnCard: DrawnTarotCard(
            card: TarotCard.majorArcana[0],
            isReversed: false,
            position: .single
        ),
        onDismiss: {}
    )
}

#Preview("Major Arcana - Reversed") {
    TarotCardDetailOverlay(
        drawnCard: DrawnTarotCard(
            card: TarotCard.majorArcana[1],
            isReversed: true,
            position: .present
        ),
        onDismiss: {}
    )
}

#Preview("Minor Arcana") {
    TarotCardDetailOverlay(
        drawnCard: DrawnTarotCard(
            card: TarotCard.minorArcana[0],
            isReversed: false,
            position: .future
        ),
        onDismiss: {}
    )
}
