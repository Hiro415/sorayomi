import SwiftUI

// MARK: - Constellation Data

/// Real constellation star positions (normalized 0-1) and connection lines
/// based on actual IAU constellation patterns.
struct ConstellationData {
    /// Star positions as (x, y) in normalized coordinates, with brightness (0-1)
    let stars: [(x: CGFloat, y: CGFloat, brightness: CGFloat)]
    /// Connections as index pairs into the stars array
    let connections: [(Int, Int)]
}

/// 12 zodiac constellation star maps based on real astronomical data.
enum ZodiacConstellationData {

    static func constellation(for sign: ZodiacSign) -> ConstellationData {
        switch sign {
        case .aries:       return aries
        case .taurus:      return taurus
        case .gemini:      return gemini
        case .cancer:      return cancer
        case .leo:         return leo
        case .virgo:       return virgo
        case .libra:       return libra
        case .scorpio:     return scorpio
        case .sagittarius: return sagittarius
        case .capricorn:   return capricorn
        case .aquarius:    return aquarius
        case .pisces:      return pisces
        }
    }

    // おひつじ座 - Hamal, Sheratan, Mesarthim の三角
    static let aries = ConstellationData(
        stars: [
            (0.75, 0.35, 1.0),   // 0: Hamal (α Ari)
            (0.55, 0.42, 0.85),  // 1: Sheratan (β Ari)
            (0.45, 0.48, 0.65),  // 2: Mesarthim (γ Ari)
            (0.30, 0.55, 0.45),  // 3: 41 Ari
        ],
        connections: [(0, 1), (1, 2), (2, 3)]
    )

    // おうし座 - V字型のヒアデス星団 + アルデバラン
    static let taurus = ConstellationData(
        stars: [
            (0.55, 0.30, 1.0),   // 0: Aldebaran (α Tau)
            (0.45, 0.22, 0.75),  // 1: θ Tau (Hyades)
            (0.40, 0.28, 0.70),  // 2: γ Tau
            (0.50, 0.18, 0.65),  // 3: ε Tau
            (0.60, 0.15, 0.60),  // 4: δ Tau
            (0.35, 0.35, 0.55),  // 5: ζ Tau (horn tip)
            (0.72, 0.42, 0.80),  // 6: β Tau (Elnath, horn tip)
            (0.25, 0.12, 0.50),  // 7: Pleiades region
        ],
        connections: [(0, 1), (0, 2), (1, 3), (3, 4), (2, 5), (4, 6)]
    )

    // ふたご座 - 双子の二本線
    static let gemini = ConstellationData(
        stars: [
            (0.35, 0.15, 1.0),   // 0: Castor (α Gem)
            (0.40, 0.20, 0.95),  // 1: Pollux (β Gem)
            (0.32, 0.32, 0.70),  // 2: γ Gem
            (0.42, 0.35, 0.65),  // 3: δ Gem
            (0.28, 0.50, 0.60),  // 4: ε Gem
            (0.45, 0.52, 0.55),  // 5: ζ Gem
            (0.30, 0.65, 0.50),  // 6: μ Gem (foot)
            (0.50, 0.68, 0.50),  // 7: ξ Gem (foot)
        ],
        connections: [(0, 2), (2, 4), (4, 6), (1, 3), (3, 5), (5, 7), (0, 1)]
    )

    // かに座 - 逆Y字型
    static let cancer = ConstellationData(
        stars: [
            (0.50, 0.40, 0.75),  // 0: δ Cnc
            (0.55, 0.30, 0.70),  // 1: γ Cnc (Asellus Borealis)
            (0.52, 0.50, 0.65),  // 2: β Cnc (Tarf)
            (0.40, 0.55, 0.60),  // 3: ι Cnc
            (0.62, 0.25, 0.55),  // 4: α Cnc (Acubens)
            (0.48, 0.38, 0.80),  // 5: Praesepe region
        ],
        connections: [(0, 1), (0, 2), (1, 4), (2, 3), (0, 5)]
    )

    // しし座 - 鎌型 + 三角の胴体
    static let leo = ConstellationData(
        stars: [
            (0.30, 0.25, 1.0),   // 0: Regulus (α Leo)
            (0.25, 0.18, 0.80),  // 1: η Leo
            (0.35, 0.12, 0.75),  // 2: γ Leo (Algieba)
            (0.42, 0.15, 0.65),  // 3: ζ Leo
            (0.48, 0.18, 0.60),  // 4: μ Leo
            (0.65, 0.28, 0.90),  // 5: β Leo (Denebola)
            (0.55, 0.32, 0.70),  // 6: δ Leo (Zosma)
            (0.50, 0.25, 0.65),  // 7: θ Leo
        ],
        connections: [(0, 1), (1, 2), (2, 3), (3, 4), (0, 7), (7, 6), (6, 5)]
    )

    // おとめ座 - Y字型の大きな星座
    static let virgo = ConstellationData(
        stars: [
            (0.50, 0.55, 1.0),   // 0: Spica (α Vir)
            (0.45, 0.40, 0.75),  // 1: γ Vir (Porrima)
            (0.38, 0.30, 0.70),  // 2: δ Vir
            (0.52, 0.28, 0.65),  // 3: ε Vir (Vindemiatrix)
            (0.30, 0.22, 0.55),  // 4: η Vir
            (0.55, 0.42, 0.60),  // 5: ζ Vir
            (0.60, 0.35, 0.50),  // 6: β Vir
            (0.42, 0.48, 0.55),  // 7: θ Vir
        ],
        connections: [(0, 1), (1, 2), (2, 4), (1, 5), (5, 6), (5, 3), (0, 7)]
    )

    // てんびん座 - ダイヤモンド型
    static let libra = ConstellationData(
        stars: [
            (0.40, 0.35, 0.85),  // 0: α Lib (Zubenelgenubi)
            (0.60, 0.30, 0.80),  // 1: β Lib (Zubeneschamali)
            (0.50, 0.50, 0.65),  // 2: γ Lib
            (0.55, 0.55, 0.60),  // 3: σ Lib
            (0.35, 0.50, 0.55),  // 4: τ Lib
        ],
        connections: [(0, 1), (0, 2), (1, 2), (2, 3), (0, 4)]
    )

    // さそり座 - S字カーブの尻尾
    static let scorpio = ConstellationData(
        stars: [
            (0.35, 0.25, 1.0),   // 0: Antares (α Sco)
            (0.30, 0.18, 0.75),  // 1: σ Sco
            (0.25, 0.22, 0.70),  // 2: δ Sco (Dschubba)
            (0.20, 0.28, 0.65),  // 3: β Sco (Acrab)
            (0.38, 0.35, 0.70),  // 4: τ Sco
            (0.42, 0.45, 0.65),  // 5: ε Sco
            (0.48, 0.55, 0.60),  // 6: μ Sco
            (0.55, 0.62, 0.55),  // 7: ζ Sco
            (0.62, 0.68, 0.60),  // 8: η Sco
            (0.68, 0.65, 0.55),  // 9: θ Sco
            (0.72, 0.58, 0.70),  // 10: ι Sco
            (0.75, 0.52, 0.75),  // 11: κ Sco (Shaula)
            (0.73, 0.48, 0.65),  // 12: λ Sco (stinger)
        ],
        connections: [
            (3, 2), (2, 1), (1, 0), (0, 4), (4, 5),
            (5, 6), (6, 7), (7, 8), (8, 9), (9, 10),
            (10, 11), (11, 12)
        ]
    )

    // いて座 - ティーポット型
    static let sagittarius = ConstellationData(
        stars: [
            (0.40, 0.45, 0.85),  // 0: ε Sgr (Kaus Australis)
            (0.35, 0.35, 0.80),  // 1: δ Sgr (Kaus Media)
            (0.30, 0.28, 0.70),  // 2: λ Sgr (Kaus Borealis)
            (0.45, 0.35, 0.75),  // 3: γ Sgr (Alnasl)
            (0.55, 0.40, 0.70),  // 4: ζ Sgr
            (0.50, 0.50, 0.65),  // 5: φ Sgr
            (0.55, 0.55, 0.60),  // 6: σ Sgr (Nunki)
            (0.48, 0.28, 0.55),  // 7: τ Sgr
            (0.60, 0.30, 0.60),  // 8: spout
        ],
        connections: [
            (0, 1), (1, 2), (2, 7), (7, 3), (3, 0),
            (0, 5), (5, 6), (6, 4), (4, 3), (4, 8)
        ]
    )

    // やぎ座 - 三角形
    static let capricorn = ConstellationData(
        stars: [
            (0.30, 0.35, 0.80),  // 0: δ Cap (Deneb Algedi)
            (0.25, 0.40, 0.75),  // 1: γ Cap (Nashira)
            (0.40, 0.50, 0.65),  // 2: ω Cap
            (0.55, 0.55, 0.60),  // 3: ζ Cap
            (0.65, 0.50, 0.70),  // 4: β Cap (Dabih)
            (0.70, 0.42, 0.75),  // 5: α Cap (Algedi)
            (0.60, 0.40, 0.55),  // 6: ν Cap
            (0.50, 0.42, 0.50),  // 7: θ Cap
        ],
        connections: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 2)]
    )

    // みずがめ座 - 水瓶のY字型
    static let aquarius = ConstellationData(
        stars: [
            (0.42, 0.25, 0.80),  // 0: β Aqr (Sadalsuud)
            (0.48, 0.30, 0.85),  // 1: α Aqr (Sadalmelik)
            (0.52, 0.38, 0.65),  // 2: γ Aqr
            (0.55, 0.45, 0.60),  // 3: ζ Aqr
            (0.50, 0.52, 0.55),  // 4: η Aqr
            (0.58, 0.55, 0.50),  // 5: λ Aqr
            (0.45, 0.60, 0.45),  // 6: δ Aqr (Skat)
            (0.62, 0.62, 0.50),  // 7: water stream
            (0.55, 0.68, 0.45),  // 8: water stream end
        ],
        connections: [(0, 1), (1, 2), (2, 3), (3, 4), (3, 5), (4, 6), (5, 7), (7, 8)]
    )

    // うお座 - V字型の二匹の魚
    static let pisces = ConstellationData(
        stars: [
            (0.50, 0.45, 0.70),  // 0: α Psc (Alrescha - knot)
            (0.42, 0.38, 0.60),  // 1: ι Psc
            (0.35, 0.30, 0.55),  // 2: θ Psc
            (0.28, 0.22, 0.60),  // 3: γ Psc
            (0.22, 0.18, 0.65),  // 4: κ Psc (western fish)
            (0.55, 0.38, 0.55),  // 5: ε Psc
            (0.62, 0.32, 0.60),  // 6: δ Psc
            (0.68, 0.28, 0.55),  // 7: ω Psc
            (0.72, 0.22, 0.65),  // 8: η Psc (eastern fish)
        ],
        connections: [(0, 1), (1, 2), (2, 3), (3, 4), (0, 5), (5, 6), (6, 7), (7, 8)]
    )
}

// MARK: - ZodiacConstellationView

/// Renders a zodiac constellation with animated star appearance and line drawing.
struct ZodiacConstellationView: View {
    let sign: ZodiacSign
    let accentColor: Color
    var animateIn: Bool = false

    @State private var starOpacities: [Double] = []
    @State private var lineProgress: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.5

    private let data: ConstellationData

    init(sign: ZodiacSign, accentColor: Color, animateIn: Bool = false) {
        self.sign = sign
        self.accentColor = accentColor
        self.animateIn = animateIn
        self.data = ZodiacConstellationData.constellation(for: sign)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // Connection lines (drawn with trim animation)
                constellationLines(in: size)

                // Stars
                ForEach(0..<data.stars.count, id: \.self) { i in
                    let star = data.stars[i]
                    starView(star: star, index: i)
                        .position(
                            x: star.x * size.width,
                            y: star.y * size.height
                        )
                }
            }
        }
        .onAppear {
            starOpacities = Array(repeating: 0, count: data.stars.count)
            if animateIn {
                startAnimation()
            } else {
                // Show immediately
                starOpacities = data.stars.map { Double($0.brightness) }
                lineProgress = 1.0
            }
        }
        .onChange(of: animateIn) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
    }

    // MARK: - Star View

    @ViewBuilder
    private func starView(star: (x: CGFloat, y: CGFloat, brightness: CGFloat), index: Int) -> some View {
        let opacity = index < starOpacities.count ? starOpacities[index] : 0
        let baseSize: CGFloat = star.brightness > 0.8 ? 8 : (star.brightness > 0.6 ? 6 : 4)

        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.6),
                            accentColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: baseSize * 2.5
                    )
                )
                .frame(width: baseSize * 5, height: baseSize * 5)
                .opacity(opacity * Double(glowPulse))

            // Core star
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, accentColor.opacity(0.8)],
                        center: .center,
                        startRadius: 0,
                        endRadius: baseSize * 0.6
                    )
                )
                .frame(width: baseSize, height: baseSize)
                .shadow(color: .white.opacity(0.8), radius: 3)
                .opacity(opacity)
        }
    }

    // MARK: - Constellation Lines

    @ViewBuilder
    private func constellationLines(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            for connection in data.connections {
                guard connection.0 < data.stars.count,
                      connection.1 < data.stars.count else { continue }

                let from = data.stars[connection.0]
                let to = data.stars[connection.1]

                var path = Path()
                path.move(to: CGPoint(x: from.x * size.width, y: from.y * size.height))
                path.addLine(to: CGPoint(x: to.x * size.width, y: to.y * size.height))

                context.stroke(
                    path.trimmedPath(from: 0, to: lineProgress),
                    with: .linearGradient(
                        Gradient(colors: [
                            accentColor.opacity(0.6),
                            accentColor.opacity(0.3)
                        ]),
                        startPoint: CGPoint(x: from.x * size.width, y: from.y * size.height),
                        endPoint: CGPoint(x: to.x * size.width, y: to.y * size.height)
                    ),
                    lineWidth: 1.2
                )
            }
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        // Stars appear one by one
        for i in 0..<data.stars.count {
            let delay = Double(i) * 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.4)) {
                    if i < starOpacities.count {
                        starOpacities[i] = Double(data.stars[i].brightness)
                    }
                }
            }
        }

        // Lines draw after stars start appearing
        let lineDelay = Double(data.stars.count) * 0.06
        DispatchQueue.main.asyncAfter(deadline: .now() + lineDelay) {
            withAnimation(.easeInOut(duration: 1.5)) {
                lineProgress = 1.0
            }
        }

        // Glow pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("Leo Constellation") {
    ZStack {
        Color(red: 0.05, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        ZodiacConstellationView(
            sign: .leo,
            accentColor: Color(red: 1.0, green: 0.45, blue: 0.2),
            animateIn: true
        )
        .frame(width: 280, height: 280)
    }
}

#Preview("Scorpio Constellation") {
    ZStack {
        Color(red: 0.05, green: 0.05, blue: 0.15)
            .ignoresSafeArea()

        ZodiacConstellationView(
            sign: .scorpio,
            accentColor: Color(red: 0.3, green: 0.45, blue: 0.85),
            animateIn: true
        )
        .frame(width: 280, height: 280)
    }
}
