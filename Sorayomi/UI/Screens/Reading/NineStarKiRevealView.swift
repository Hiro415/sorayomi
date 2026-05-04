import SwiftUI

/// 九星気学リビールビュー
/// Displays an animated nine-palace ki-grid (後天定位盤) showing the user's
/// honmeisei position, daily star interaction, auspicious directions,
/// and five-element energy flow with rich animations.
struct NineStarKiRevealView: View {
    let profile: NineStarKiProfile
    let energy: NineStarKiDailyEnergy
    let onComplete: () -> Void

    // MARK: - Animation State

    @State private var gridOpacity: Double = 0
    @State private var gridScale: CGFloat = 0.6
    @State private var cellAppeared: [Bool] = Array(repeating: false, count: 9)
    @State private var honmeiseiGlow: CGFloat = 0
    @State private var dailyStarGlow: CGFloat = 0
    @State private var connectionLineProgress: CGFloat = 0
    @State private var infoOpacity: Double = 0
    @State private var directionOpacity: Double = 0
    @State private var adviceOpacity: Double = 0
    @State private var particlePhase: CGFloat = 0
    @State private var viewWidth: CGFloat = 390

    private var sizes: RevealSizeProvider {
        RevealSizeProvider(availableWidth: viewWidth)
    }

    private var isLargeScreen: Bool { viewWidth > 600 }

    // Grid layout: Luo Shu magic square positions
    // [4][9][2]
    // [3][5][7]
    // [8][1][6]
    private let luoShuOrder: [Int] = [4, 9, 2, 3, 5, 7, 8, 1, 6]

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    Spacer().frame(height: 30)

                    // Header
                    headerSection

                    // Nine Palace Grid
                    kiGridSection

                    // Five Element Relationship
                    elementRelationSection

                    // Direction Guidance
                    directionSection

                    // Today's Advice
                    adviceSection

                    // Continue button
                    continueButton

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            viewWidth = newWidth
        }
        .onAppear { startRevealSequence() }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.14),
                    elementBackgroundColor.opacity(0.15),
                    Color(red: 0.05, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating particles
            GeometryReader { geo in
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(elementAccentColor.opacity(0.3))
                        .frame(width: CGFloat.random(in: 2...4))
                        .position(
                            x: geo.size.width * CGFloat(((i * 37 + 13) % 100)) / 100.0,
                            y: geo.size.height * (CGFloat(((i * 53 + 7) % 100)) / 100.0 + particlePhase * 0.02)
                        )
                        .opacity(Double(cellAppeared.filter { $0 }.count) / 9.0)
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            // Star symbol
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [elementAccentColor.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: sizes.nineStarSymbol, height: sizes.nineStarSymbol)

                Text(elementEmoji)
                    .font(.system(size: isLargeScreen ? 48 : 36))
                    .shadow(color: elementAccentColor, radius: 10)
            }
            .opacity(gridOpacity)

            Text(profile.honmeisei.japaneseName)
                .font(.system(size: isLargeScreen ? 34 : 26, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, elementAccentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(gridOpacity)

            Text("\(profile.honmeisei.element)の星 ・ 定位：\(profile.honmeisei.direction)")
                .font(SorayomiTypography.caption)
                .foregroundStyle(.white.opacity(0.6))
                .opacity(gridOpacity)

            // Inner stars summary
            HStack(spacing: Spacing.xs) {
                starBadge(label: "本命星", name: profile.honmeisei.shortName)
                Text("×")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.caption)
                starBadge(label: "月命星", name: profile.getsumeisei.shortName)
            }
            .opacity(gridOpacity)
        }
    }

    private func starBadge(label: String, name: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(.white.opacity(0.4))
            Text(name)
                .font(SorayomiTypography.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(elementAccentColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(elementAccentColor.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Nine Palace Grid (九宮格)

    private var kiGridSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("九宮格（後天定位盤）")
                .font(.system(size: isLargeScreen ? 17 : 14, weight: .semibold, design: .serif))
                .foregroundStyle(.white.opacity(0.7))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(0..<9, id: \.self) { gridIndex in
                    let starNumber = luoShuOrder[gridIndex]
                    let star = NineStarKiStar(rawValue: starNumber) ?? .goouDosei
                    let isHonmeisei = starIsHonmeiseiPosition(star)
                    let isDailyStar = star == energy.dailyStar

                    gridCell(
                        star: star,
                        isHonmeisei: isHonmeisei,
                        isDailyStar: isDailyStar,
                        appeared: gridIndex < cellAppeared.count && cellAppeared[gridIndex]
                    )
                }
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(elementAccentColor.opacity(0.15), lineWidth: 0.5)
                    )
            )
            .scaleEffect(gridScale)
            .opacity(gridOpacity)

            // Legend
            HStack(spacing: Spacing.md) {
                legendItem(color: elementAccentColor, label: "あなた（本命星）")
                legendItem(color: Color(red: 0.9, green: 0.7, blue: 0.2), label: "今日の日命星")
            }
            .opacity(gridOpacity)
        }
    }

    private func gridCell(star: NineStarKiStar, isHonmeisei: Bool, isDailyStar: Bool, appeared: Bool) -> some View {
        let cellColor: Color = isHonmeisei ? elementAccentColor : (isDailyStar ? Color(red: 0.9, green: 0.7, blue: 0.2) : .white)
        let bgOpacity: Double = isHonmeisei ? 0.2 : (isDailyStar ? 0.15 : 0.04)
        let glowAmount: CGFloat = isHonmeisei ? honmeiseiGlow : (isDailyStar ? dailyStarGlow : 0)

        return VStack(spacing: 2) {
            Text(star.shortName)
                .font(.system(size: isLargeScreen ? 19 : 15, weight: isHonmeisei || isDailyStar ? .bold : .medium, design: .serif))
                .foregroundStyle(cellColor.opacity(appeared ? 1 : 0))

            Text(star.element)
                .font(.system(size: isLargeScreen ? 13 : 10))
                .foregroundStyle(cellColor.opacity(appeared ? 0.6 : 0))

            Text(directionLabel(for: star.rawValue))
                .font(.system(size: isLargeScreen ? 12 : 9))
                .foregroundStyle(.white.opacity(appeared ? 0.35 : 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: sizes.nineStarGridCellHeight)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(cellColor.opacity(bgOpacity))
                .shadow(color: cellColor.opacity(glowAmount * 0.5), radius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    cellColor.opacity(isHonmeisei || isDailyStar ? 0.4 : 0.08),
                    lineWidth: isHonmeisei ? 1.5 : 0.5
                )
        )
        .scaleEffect(appeared ? 1.0 : 0.5)
        .opacity(appeared ? 1 : 0)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Element Relation

    private var elementRelationSection: some View {
        VStack(spacing: Spacing.sm) {
            // Relation card
            HStack(spacing: Spacing.md) {
                VStack(spacing: 4) {
                    Text(profile.honmeisei.shortName)
                        .font(.system(size: isLargeScreen ? 20 : 16, weight: .bold, design: .serif))
                        .foregroundStyle(elementAccentColor)
                    Text(profile.honmeisei.element)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(width: viewWidth * 0.14, height: viewWidth * 0.14)
                .background(Circle().fill(elementAccentColor.opacity(0.15)))

                VStack(spacing: 2) {
                    Text(energy.honmeiseiRelation.rawValue)
                        .font(.system(size: isLargeScreen ? 17 : 14, weight: .semibold, design: .serif))
                        .foregroundStyle(relationColor)

                    // Animated connection line
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                        }
                        .trim(from: 0, to: connectionLineProgress)
                        .stroke(
                            LinearGradient(
                                colors: [elementAccentColor, Color(red: 0.9, green: 0.7, blue: 0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2, dash: [4, 3])
                        )
                    }
                    .frame(height: 12)

                    Text(energy.honmeiseiRelation.description)
                        .font(SorayomiTypography.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 4) {
                    Text(energy.dailyStar.shortName)
                        .font(.system(size: isLargeScreen ? 20 : 16, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2))
                    Text(energy.dailyStar.element)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(width: viewWidth * 0.14, height: viewWidth * 0.14)
                .background(Circle().fill(Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.15)))
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(elementAccentColor.opacity(0.15), lineWidth: 0.5)
                    )
            )

            // Score stars
            HStack(spacing: 4) {
                Text("今日の運勢：")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(.white.opacity(0.6))
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: i < energy.overallScore ? "star.fill" : "star")
                        .font(.system(size: isLargeScreen ? 17 : 14))
                        .foregroundStyle(i < energy.overallScore ? elementAccentColor : .white.opacity(0.2))
                }
            }
        }
        .opacity(infoOpacity)
    }

    // MARK: - Directions

    private var directionSection: some View {
        HStack(spacing: Spacing.sm) {
            // Auspicious
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green.opacity(0.8))
                        .font(.caption)
                    Text("吉方位")
                        .font(SorayomiTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green.opacity(0.8))
                }
                ForEach(energy.auspiciousDirections, id: \.self) { dir in
                    Text(dir)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.green.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.green.opacity(0.15), lineWidth: 0.5)
                    )
            )

            // Inauspicious
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red.opacity(0.6))
                        .font(.caption)
                    Text("凶方位")
                        .font(SorayomiTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red.opacity(0.6))
                }
                ForEach(energy.inauspiciousDirections, id: \.self) { dir in
                    Text(dir)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.red.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.red.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .opacity(directionOpacity)
    }

    // MARK: - Advice

    private var adviceSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(energy.advice)
                .font(SorayomiTypography.footnote)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.sm)

            // Palace position info
            let pos = NineStarKiCalculator.gridPosition(of: profile.honmeisei, centralStar: energy.yearlyStar)
            let palace = NineStarKiCalculator.directionForPosition(pos)
            let influence = NineStarKiCalculator.palaceInfluence(position: pos)

            VStack(spacing: 4) {
                Text("年盤：\(profile.honmeisei.shortName)は「\(palace)」に在泊")
                    .font(SorayomiTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(elementAccentColor)
                Text(influence)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
        .opacity(adviceOpacity)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onComplete) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkle")
                Text("鑑定を受け取る")
                    .font(SorayomiTypography.body)
                    .fontWeight(.semibold)
                Image(systemName: "sparkle")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [elementAccentColor, elementAccentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: elementAccentColor.opacity(0.4), radius: 12, y: 4)
            )
        }
        .opacity(adviceOpacity)
    }

    // MARK: - Helpers

    private func starIsHonmeiseiPosition(_ star: NineStarKiStar) -> Bool {
        return star == profile.honmeisei
    }

    private func directionLabel(for starNumber: Int) -> String {
        guard let star = NineStarKiStar(rawValue: starNumber) else { return "" }
        return star.direction
    }

    private var elementAccentColor: Color {
        switch profile.honmeisei.element {
        case "水": return Color(red: 0.3, green: 0.5, blue: 0.9)
        case "木": return Color(red: 0.3, green: 0.7, blue: 0.4)
        case "火": return Color(red: 0.9, green: 0.35, blue: 0.3)
        case "土": return Color(red: 0.75, green: 0.6, blue: 0.3)
        case "金": return Color(red: 0.8, green: 0.75, blue: 0.6)
        default:   return Color(red: 0.6, green: 0.5, blue: 0.8)
        }
    }

    private var elementBackgroundColor: Color {
        switch profile.honmeisei.element {
        case "水": return Color(red: 0.1, green: 0.15, blue: 0.3)
        case "木": return Color(red: 0.08, green: 0.2, blue: 0.1)
        case "火": return Color(red: 0.25, green: 0.08, blue: 0.08)
        case "土": return Color(red: 0.2, green: 0.15, blue: 0.08)
        case "金": return Color(red: 0.2, green: 0.18, blue: 0.12)
        default:   return Color(red: 0.12, green: 0.1, blue: 0.18)
        }
    }

    private var elementEmoji: String {
        switch profile.honmeisei.element {
        case "水": return "💧"
        case "木": return "🌿"
        case "火": return "🔥"
        case "土": return "🪨"
        case "金": return "✨"
        default:   return "⭐"
        }
    }

    private var relationColor: Color {
        switch energy.honmeiseiRelation {
        case .generated:   return .green
        case .generating:  return Color(red: 0.4, green: 0.8, blue: 0.6)
        case .same:        return elementAccentColor
        case .controlling: return Color(red: 0.9, green: 0.7, blue: 0.2)
        case .controlled:  return Color(red: 0.9, green: 0.4, blue: 0.3)
        }
    }

    // MARK: - Animation Sequence

    private func startRevealSequence() {
        // Phase 1: Grid container appears
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            gridOpacity = 1.0
            gridScale = 1.0
        }

        // Phase 2: Grid cells appear one by one (Luo Shu spiral order)
        let spiralOrder = [4, 0, 1, 2, 5, 8, 7, 6, 3] // center-out spiral
        for (step, cellIdx) in spiralOrder.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(step) * 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    if cellIdx < cellAppeared.count {
                        cellAppeared[cellIdx] = true
                    }
                }
            }
        }

        // Phase 3: Honmeisei and daily star glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                honmeiseiGlow = 1.0
                dailyStarGlow = 0.8
            }
        }

        // Phase 4: Element relation info
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                infoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2)) {
                connectionLineProgress = 1.0
            }
        }

        // Phase 5: Directions
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.easeOut(duration: 0.6)) {
                directionOpacity = 1.0
            }
        }

        // Phase 6: Advice and button
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            withAnimation(.easeOut(duration: 0.6)) {
                adviceOpacity = 1.0
            }
        }

        // Particle animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                particlePhase = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let profile = NineStarKiProfile(
        honmeisei: .kyushiKasei,
        getsumeisei: .shirokuMokusei,
        birthYear: 1990
    )
    let energy = NineStarKiCalculator.dailyEnergy(profile: profile)

    NineStarKiRevealView(
        profile: profile,
        energy: energy,
        onComplete: {}
    )
}
