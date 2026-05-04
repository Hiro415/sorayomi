import SwiftUI

// MARK: - TarotCardArtwork

/// タロットカードのアートワーク表示
/// Asset Catalogに画像がある場合はそれを使用し、なければフォールバックのグラデーションを表示。
struct TarotCardArtwork: View {
    let card: TarotCard
    let isReversed: Bool

    var body: some View {
        GeometryReader { geo in
            if let uiImage = UIImage(named: card.assetImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .rotationEffect(isReversed ? .degrees(180) : .zero)
            } else {
                fallbackArtwork(size: geo.size)
                    .rotationEffect(isReversed ? .degrees(180) : .zero)
            }
        }
    }

    @ViewBuilder
    private func fallbackArtwork(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: fallbackGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 4) {
                if card.arcana == .major {
                    Text(romanNumeral)
                        .font(.system(size: min(size.width, size.height) * 0.15, weight: .bold, design: .serif))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Image(systemName: fallbackSymbol)
                    .font(.system(size: min(size.width, size.height) * 0.2, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var fallbackGradientColors: [Color] {
        if card.arcana == .major {
            return [
                Color(hue: 0.72, saturation: 0.45, brightness: 0.30),
                Color(hue: 0.78, saturation: 0.35, brightness: 0.15),
            ]
        }
        guard let suit = card.suit else { return [.gray, .black] }
        switch suit {
        case .wands:
            return [
                Color(hue: 0.02, saturation: 0.50, brightness: 0.30),
                Color(hue: 0.05, saturation: 0.40, brightness: 0.15),
            ]
        case .cups:
            return [
                Color(hue: 0.58, saturation: 0.45, brightness: 0.30),
                Color(hue: 0.62, saturation: 0.35, brightness: 0.15),
            ]
        case .swords:
            return [
                Color(hue: 0.55, saturation: 0.25, brightness: 0.32),
                Color(hue: 0.58, saturation: 0.18, brightness: 0.16),
            ]
        case .pentacles:
            return [
                Color(hue: 0.10, saturation: 0.45, brightness: 0.30),
                Color(hue: 0.12, saturation: 0.35, brightness: 0.15),
            ]
        }
    }

    private var fallbackSymbol: String {
        if card.arcana == .major { return "sparkle" }
        guard let suit = card.suit else { return "sparkle" }
        switch suit {
        case .wands:     return "flame.fill"
        case .cups:      return "drop.fill"
        case .swords:    return "wind"
        case .pentacles: return "circle.hexagongrid.fill"
        }
    }

    private var romanNumeral: String {
        let numerals = ["0", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX",
                        "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII",
                        "XIX", "XX", "XXI"]
        return card.number < numerals.count ? numerals[card.number] : "\(card.number)"
    }
}
