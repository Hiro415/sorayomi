# Tarot Cinematic Reveal & iPad Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign the tarot reveal into a cinematic two-phase experience (close-up individual reveals → tappable spread) and polish iPad sizing for BloodType/NineStarKi reveal views.

**Architecture:** The existing TarotRevealView is refactored to add a close-up phase before the spread layout. A new TarotCardDetailOverlay provides tap-to-zoom with card meaning data. Minor arcana meanings are composed from existing suit+number data. iPad polish is applied to BloodTypeRevealView (UIScreen removal + font scaling) and NineStarKiRevealView (font scaling).

**Tech Stack:** SwiftUI, existing RevealSizeProvider, TarotMajorMeaning/TarotMinorNumberMeaning data

---

### Task 1: Add Close-Up Card Sizes to RevealSizeProvider

**Files:**
- Modify: `Sorayomi/UI/Theme/RevealSizeProvider.swift`

**Step 1: Add close-up and detail overlay size properties**

Add after the existing tarot section (~line 60):

```swift
// MARK: - Tarot Close-Up

/// タロットクローズアップ表示のカード幅（Phase 1: 個別リビール）
var tarotCloseUpWidth: CGFloat {
    isLargeScreen
        ? min(availableWidth * 0.40, 340)
        : min(availableWidth * 0.62, 260)
}

/// タロット詳細オーバーレイのカード幅（タップ拡大時）
var tarotDetailWidth: CGFloat {
    isLargeScreen
        ? min(availableWidth * 0.38, 320)
        : min(availableWidth * 0.58, 240)
}
```

**Step 2: Build and verify**

Run: `cd "Sorayomi" && xcodebuild build -scheme Sorayomi -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.3.1' 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sorayomi/UI/Theme/RevealSizeProvider.swift
git commit -m "feat: add close-up and detail card sizes to RevealSizeProvider"
```

---

### Task 2: Create TarotCardDetailOverlay

**Files:**
- Create: `Sorayomi/UI/Screens/Reading/TarotCardDetailOverlay.swift`

**Step 1: Create the detail overlay view**

This full-screen overlay shows when a user taps a card in the spread. It displays:
- Large card artwork
- Card name (Japanese + English)
- 正位置/逆位置 indicator
- Keywords as tag badges
- Meaning text
- Major arcana: archetype + astrological correspondence
- Minor arcana: suit domain + number theme

```swift
import SwiftUI

/// タロットカードの詳細オーバーレイ
/// カードタップ時にフルスクリーンで表示し、アートワーク・キーワード・意味を見せる。
struct TarotCardDetailOverlay: View {
    let drawnCard: DrawnTarotCard
    let onDismiss: () -> Void

    @State private var viewWidth: CGFloat = 390
    @State private var appear = false

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }

    private var isLargeScreen: Bool { viewWidth > 600 }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(appear ? 0.85 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            ScrollView(showsIndicators: false) {
                VStack(spacing: isLargeScreen ? 24 : 16) {
                    // Close button
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: isLargeScreen ? 28 : 24))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Card artwork
                    TarotCardView(
                        drawnCard: drawnCard,
                        isRevealed: true,
                        cardIndex: 0
                    )
                    .frame(
                        width: sizes.tarotDetailWidth,
                        height: sizes.tarotDetailWidth * 1.5
                    )
                    .shadow(color: cardGlowColor.opacity(0.4), radius: 20)

                    // Card name
                    VStack(spacing: 4) {
                        Text(drawnCard.card.japaneseName)
                            .font(.system(size: isLargeScreen ? 28 : 22, weight: .bold, design: .serif))
                            .foregroundStyle(.white)

                        Text(drawnCard.card.englishName)
                            .font(.system(size: isLargeScreen ? 14 : 12, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.5))

                        // Position + orientation
                        HStack(spacing: 8) {
                            Text(drawnCard.position.japaneseName)
                                .font(.system(size: isLargeScreen ? 13 : 11, weight: .medium, design: .serif))
                                .foregroundStyle(.white.opacity(0.6))

                            Text(drawnCard.isReversed ? "逆位置" : "正位置")
                                .font(.system(size: isLargeScreen ? 12 : 10, weight: .bold))
                                .foregroundStyle(
                                    drawnCard.isReversed
                                        ? Color(hue: 0.0, saturation: 0.4, brightness: 0.9)
                                        : Color(hue: 0.55, saturation: 0.3, brightness: 0.9)
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    (drawnCard.isReversed
                                        ? Color(hue: 0.0, saturation: 0.3, brightness: 0.5)
                                        : Color(hue: 0.55, saturation: 0.2, brightness: 0.4)
                                    ).opacity(0.3)
                                )
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }

                    // Divider
                    Rectangle()
                        .fill(.white.opacity(0.15))
                        .frame(width: isLargeScreen ? 200 : 140, height: 0.5)

                    // Keywords
                    keywordsView

                    // Meaning
                    meaningView

                    // Extra info (archetype / suit domain)
                    extraInfoView

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: isLargeScreen ? 500 : .infinity)
                .frame(maxWidth: .infinity) // center on iPad
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.9)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appear = true
            }
        }
    }

    // MARK: - Keywords

    private var keywordsView: some View {
        let keywords = drawnCard.isReversed ? reversedKeywords : uprightKeywords
        return FlowLayout(spacing: 8) {
            ForEach(keywords, id: \.self) { keyword in
                Text(keyword)
                    .font(.system(size: isLargeScreen ? 13 : 11, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, isLargeScreen ? 40 : 24)
    }

    // MARK: - Meaning

    private var meaningView: some View {
        Text(drawnCard.isReversed ? reversedMeaning : uprightMeaning)
            .font(.system(size: isLargeScreen ? 15 : 13, weight: .regular, design: .serif))
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, isLargeScreen ? 40 : 24)
    }

    // MARK: - Extra Info

    @ViewBuilder
    private var extraInfoView: some View {
        if drawnCard.card.arcana == .major {
            let meaning = TarotMajorMeaning.meaning(for: drawnCard.card.number)
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    infoPill(icon: "sparkle", text: meaning.archetype)
                    infoPill(icon: "star.fill", text: meaning.astrologicalCorrespondence)
                }
                infoPill(icon: "number", text: "数秘 \(meaning.numerologicalValue)")
            }
        } else if let suit = drawnCard.card.suit {
            let numberMeaning = TarotMinorNumberMeaning.meaning(for: drawnCard.card.number)
            VStack(spacing: 8) {
                infoPill(icon: suitIcon(suit), text: "\(suit.japaneseName) — \(suit.domain)")
                infoPill(icon: "list.number", text: "テーマ：\(numberMeaning.theme)")
            }
        }
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: isLargeScreen ? 12 : 10, weight: .medium, design: .serif))
        }
        .foregroundStyle(.white.opacity(0.55))
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }

    // MARK: - Data Access

    private var uprightKeywords: [String] {
        if drawnCard.card.arcana == .major {
            return TarotMajorMeaning.meaning(for: drawnCard.card.number).uprightKeywords
        }
        let nm = TarotMinorNumberMeaning.meaning(for: drawnCard.card.number)
        if let suit = drawnCard.card.suit {
            return [suit.element, nm.theme, suit.domain.components(separatedBy: "・").first ?? ""]
        }
        return [nm.theme]
    }

    private var reversedKeywords: [String] {
        if drawnCard.card.arcana == .major {
            return TarotMajorMeaning.meaning(for: drawnCard.card.number).reversedKeywords
        }
        let nm = TarotMinorNumberMeaning.meaning(for: drawnCard.card.number)
        // Compose from number meaning reversed essence
        let parts = nm.reversedEssence.components(separatedBy: "。")
        return Array(parts.prefix(3).map { $0.trimmingCharacters(in: .whitespaces) })
    }

    private var uprightMeaning: String {
        if drawnCard.card.arcana == .major {
            return TarotMajorMeaning.meaning(for: drawnCard.card.number).uprightMeaning
        }
        let nm = TarotMinorNumberMeaning.meaning(for: drawnCard.card.number)
        if let suit = drawnCard.card.suit {
            return "\(suit.japaneseName)の\(nm.theme)。\(nm.uprightEssence)"
        }
        return nm.uprightEssence
    }

    private var reversedMeaning: String {
        if drawnCard.card.arcana == .major {
            return TarotMajorMeaning.meaning(for: drawnCard.card.number).reversedMeaning
        }
        let nm = TarotMinorNumberMeaning.meaning(for: drawnCard.card.number)
        if let suit = drawnCard.card.suit {
            return "\(suit.japaneseName)の\(nm.theme)が滞る時。\(nm.reversedEssence)"
        }
        return nm.reversedEssence
    }

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

    private func suitIcon(_ suit: TarotSuit) -> String {
        switch suit {
        case .wands:     return "flame.fill"
        case .cups:      return "drop.fill"
        case .swords:    return "wind"
        case .pentacles: return "circle.hexagongrid.fill"
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.25)) {
            appear = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - FlowLayout (simple horizontal wrapping)

/// A simple flow layout that wraps content horizontally.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews)
        -> (positions: [CGPoint], sizes: [CGSize], size: CGSize)
    {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
        }

        return (positions, sizes, CGSize(width: totalWidth, height: y + rowHeight))
    }
}
```

**Step 2: Build and verify**

Run: `xcodebuild build` (after regenerating xcodeproj)
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/TarotCardDetailOverlay.swift
git commit -m "feat: add TarotCardDetailOverlay with card meanings and FlowLayout"
```

---

### Task 3: Rewrite TarotRevealView with Cinematic Two-Phase Reveal

**Files:**
- Modify: `Sorayomi/UI/Screens/Reading/TarotRevealView.swift`

**Step 1: Add phase state and close-up logic**

Add new state properties to TarotRevealView:

```swift
// Phase tracking
@State private var revealPhase: RevealPhase = .closeUp
@State private var closeUpIndex = 0
@State private var closeUpCardFlipped = false
@State private var closeUpCardVisible = false
@State private var showCloseUpLabel = false

// Tap-to-detail
@State private var selectedCard: DrawnTarotCard? = nil

private enum RevealPhase {
    case closeUp      // Phase 1: individual card close-ups
    case transitioning // Animating from close-up to spread
    case spread        // Phase 2: all cards in spread layout
}
```

**Step 2: Rewrite body to use phase-based rendering**

Replace the body with conditional rendering:
- `revealPhase == .closeUp` → show `closeUpView` (single card at center)
- `revealPhase == .spread` → show existing spread layout + tap gesture on each card
- Overlay `TarotCardDetailOverlay` when `selectedCard != nil`

**Step 3: Implement closeUpView**

A centered single card that flips, shows label, then transitions to next card or to spread phase.

**Step 4: Add tap gesture to spread cards**

Wrap each `TarotCardView` in the spread layouts with `.onTapGesture { selectedCard = card }`.

**Step 5: Rewrite startRevealSequence()**

New timing:
- Phase 1 (close-up): each card gets ~2.5s (0.5s appear + 0.7s flip + 1.3s hold)
- After all close-ups: transition to spread phase
- Phase 2: elemental dignity bar + overview + button appear

**Step 6: Build and verify**

Run: `xcodebuild build`
Expected: BUILD SUCCEEDED

**Step 7: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/TarotRevealView.swift
git commit -m "feat: cinematic two-phase tarot reveal with close-up and tap-to-detail"
```

---

### Task 4: iPad Polish — BloodTypeRevealView

**Files:**
- Modify: `Sorayomi/UI/Screens/Reading/BloodTypeRevealView.swift`

**Step 1: Add viewWidth + sizes + isLargeScreen to each sub-content view**

Each of the 4 content structs (DailyFortuneRevealContent, CompatibilityRevealContent, LoveMatchRevealContent, RankingRevealContent) needs:
```swift
@State private var viewWidth: CGFloat = 390
private var sizes: RevealSizeProvider { RevealSizeProvider(availableWidth: viewWidth) }
private var isLargeScreen: Bool { viewWidth > 600 }
```
Plus `.onGeometryChange` on the root ZStack.

Note: CompatibilityRevealContent already has viewWidth/sizes from previous work. The other 3 need it added.

**Step 2: Replace UIScreen.main.bounds (3 locations)**

- Line 369-370: `generateParticles()` → use `viewWidth` and `viewWidth * 2.16`
- Line 891-892: `generateHeartParticles()` → use `viewWidth` and `viewWidth * 2.16`
- Line 1184: `generateBurstParticles()` → use `viewWidth`

**Step 3: Scale font sizes with isLargeScreen**

Apply ternary scaling to all hardcoded font sizes. Key targets:
- `48pt` → `isLargeScreen ? 64 : 48` (blood type letter)
- `36pt` → `isLargeScreen ? 48 : 36` (main heading)
- `32pt` → `isLargeScreen ? 44 : 32` (score display)
- `24pt` → `isLargeScreen ? 32 : 24` (card titles)
- `20pt` → `isLargeScreen ? 26 : 20` (section title)
- `16pt` → `isLargeScreen ? 20 : 16` (body text)
- `14pt` → `isLargeScreen ? 17 : 14` (detail text)
- `12pt` → `isLargeScreen ? 14 : 12` (small text)
- `10pt` → `isLargeScreen ? 12 : 10` (caption)

**Step 4: Build and verify**

Run: `xcodebuild build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/BloodTypeRevealView.swift
git commit -m "fix: iPad polish for BloodTypeRevealView — UIScreen removal + font scaling"
```

---

### Task 5: iPad Polish — NineStarKiRevealView

**Files:**
- Modify: `Sorayomi/UI/Screens/Reading/NineStarKiRevealView.swift`

**Step 1: Add isLargeScreen computed property**

```swift
private var isLargeScreen: Bool { viewWidth > 600 }
```

(viewWidth and sizes already exist from previous work)

**Step 2: Scale font sizes**

Apply ternary scaling to all 10 hardcoded font sizes:
- Line 125: `36` → `isLargeScreen ? 48 : 36` (emoji)
- Line 131: `26` → `isLargeScreen ? 34 : 26` (title)
- Line 185: `14` → `isLargeScreen ? 18 : 14` (section label)
- Line 231: `15` → `isLargeScreen ? 19 : 15` (grid cell text)
- Line 235: `10` → `isLargeScreen ? 13 : 10` (small label)
- Line 239: `9` → `isLargeScreen ? 12 : 9` (tiny label)
- Line 277: `16` → `isLargeScreen ? 20 : 16` (element title)
- Line 288: `14` → `isLargeScreen ? 17 : 14` (element detail)
- Line 318: `16` → `isLargeScreen ? 20 : 16` (direction title)
- Line 344: `14` → `isLargeScreen ? 17 : 14` (direction detail)

**Step 3: Build and verify**

Run: `xcodebuild build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Sorayomi/UI/Screens/Reading/NineStarKiRevealView.swift
git commit -m "fix: iPad font scaling for NineStarKiRevealView"
```

---

### Task 6: Regenerate Xcode Project & Final Build

**Files:**
- Modify: `Sorayomi.xcodeproj` (auto-generated)

**Step 1: Regenerate xcodeproj**

Run: `cd "Sorayomi" && python3 generate_xcodeproj.py`

**Step 2: Full build**

Run: `xcodebuild build -scheme Sorayomi -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.3.1'`
Expected: BUILD SUCCEEDED

**Step 3: iPad build verification**

Run: `xcodebuild build -scheme Sorayomi -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.3.1'`
Expected: BUILD SUCCEEDED

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: regenerate xcodeproj with new tarot cinematic reveal files"
```
