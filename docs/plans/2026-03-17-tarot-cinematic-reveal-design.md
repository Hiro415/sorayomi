# Tarot Cinematic Reveal & iPad Polish Design

**Date:** 2026-03-17
**Status:** Approved

## Overview

Redesign the tarot card reveal experience with a two-phase cinematic animation (close-up individual reveals → spread layout with tap-to-detail), plus iPad sizing polish across all remaining reveal views.

## Part 1: Tarot Cinematic Reveal

### Phase 1 — Close-Up Individual Card Reveal

Each card is revealed one-by-one at center screen in a large close-up view before being arranged into the spread layout.

**Flow:**
1. Screen shows mystical background + spread title
2. First card appears at center, face-down, at close-up size (~60-70% screen width)
3. Card flips with existing 3D rotation animation
4. Card name + position label + 正位置/逆位置 shown below
5. Hold for ~2 seconds
6. Card shrinks and slides to its final spread position
7. Next card appears at center → repeat
8. After all cards revealed, transition to Phase 2

**Sizing:**
- iPhone: card width = `min(viewWidth * 0.65, 260)`
- iPad: card width = `min(viewWidth * 0.45, 360)`
- Aspect ratio: 1:1.5 (standard tarot)

### Phase 2 — Spread Layout + Tap-to-Detail

After all cards are revealed individually, they settle into the familiar spread layout (1/3/5 card arrangements). Each card is now tappable.

**Tap-to-Detail Overlay (TarotCardDetailOverlay):**
- Full-screen dimmed overlay with centered card modal
- Card artwork displayed large (similar to close-up size)
- Below artwork:
  - Card name (Japanese) + English name
  - 正位置/逆位置 indicator
  - Keywords as horizontal tag badges (3-4 keywords)
  - 1-2 line meaning text
  - For Major Arcana: archetype + astrological correspondence
  - For Minor Arcana: suit domain + number theme + suit-specific essence
- Dismiss: tap outside, X button, or drag-down gesture
- iPad: modal maxWidth 500pt, centered

### New Data: Minor Arcana Suit-Specific Meanings

Currently `TarotMinorNumberMeaning` only has number-based meanings shared across suits. We need suit×number specific one-line descriptions for the detail overlay.

**Approach:** Add a new `TarotMinorSuitMeaning` struct with `suitEssence(suit:number:isReversed:)` that combines:
- Suit domain (e.g., "情熱・行動・創造性" for Wands)
- Number theme (e.g., "始まり" for Ace)
- A composed one-line meaning: "{suit.domain}の{numberMeaning.theme}。{essence}"

This avoids needing 56×2=112 individual strings. Instead, compose from existing data:
- Suit provides the domain context
- Number provides the theme and essence
- Combined: "ワンドのエース — 情熱の始まり。新しい可能性の種。純粋なエネルギーの発現"

## Part 2: iPad Polish for Remaining Reveal Views

### BloodTypeRevealView (Major Fix)
- Add `@State private var viewWidth` + `onGeometryChange`
- Add `sizes: RevealSizeProvider` computed property
- Add `isLargeScreen` computed property
- Replace 3× `UIScreen.main.bounds` in particle generators with `viewWidth`
- Scale all hardcoded font sizes with isLargeScreen ternaries
- Scale spacing for iPad

### NineStarKiRevealView (Minor Fix)
- Add `isLargeScreen` computed property
- Scale hardcoded font sizes (36pt emoji, 26pt title, 14pt grid label, etc.)

## New Files

1. `TarotCardDetailOverlay.swift` — Full-screen detail overlay for tapped cards
2. `TarotMinorSuitMeaning.swift` — Suit×number composed meanings

## Modified Files

1. `TarotRevealView.swift` — Major rewrite: 2-phase reveal + tap interaction
2. `BloodTypeRevealView.swift` — iPad sizing polish
3. `NineStarKiRevealView.swift` — Font scaling polish
4. `RevealSizeProvider.swift` — Add close-up card size properties

## Animation Timing (3-card spread example)

```
0.0s  — Background + title appear
1.0s  — Card 1 appears center (face-down)
1.3s  — Card 1 flips (0.7s animation)
3.3s  — Card 1 shrinks to spread position
3.8s  — Card 2 appears center
4.1s  — Card 2 flips
6.1s  — Card 2 shrinks
6.6s  — Card 3 appears center
6.9s  — Card 3 flips
8.9s  — Card 3 shrinks
9.4s  — Elemental dignity bar + overview appear
10.2s — "鑑定結果を見る" button appears
```

Total: ~10s for 3-card, ~6s for 1-card, ~16s for 5-card.
