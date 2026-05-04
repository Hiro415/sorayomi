import SwiftUI

// MARK: - RokuyoBannerView

/// 六曜インタラクティブガジェット。
///
/// ■ 墨スタンプ風アニメーション: 漢字が霧から浮かび上がるように出現
/// ■ 時間帯バー: 6つの時間帯の運気をスタッガード grow-up で表示、現在時刻をパルスハイライト
/// ■ 行事判定: チップをタップすると今日その行事が吉か凶かを即座に表示
struct RokuyoBannerView: View {

    let rokuyo: Rokuyo

    // MARK: - Stamp animation

    @State private var kanjiScale: CGFloat = 0.28
    @State private var kanjiOpacity: Double = 0
    @State private var kanjiBlur: CGFloat = 14
    @State private var kanjiRotation: Double = -14

    // MARK: - Bar animation

    @State private var barsReady = false
    @State private var glowPulse = false

    // MARK: - Interaction

    @State private var selectedEvent: String? = nil

    // 行事判定で表示するイベント
    private static let featuredEvents: [String] = [
        "結婚・婚姻届", "引越し", "旅行・出発", "開業・起業", "契約・署名"
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            headerRow
            contentRow
            timeRibbon
            divider
            eventJudgement
        }
        .padding(Spacing.md)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: accentColor.opacity(0.14), radius: 14, x: 0, y: 6)
        .onAppear { startAnimations() }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 11))
                .foregroundStyle(Color.sorayomiTextSecondary)

            Text("六曜 ・ 今日の暦")
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.sorayomiTextSecondary)

            Spacer()

            // 吉凶バッジ
            HStack(spacing: 4) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 5, height: 5)
                Text(rokuyo.isAuspicious ? "吉日" : "慎みの日")
                    .font(SorayomiTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(accentColor.opacity(0.13))
            .clipShape(Capsule())
        }
    }

    // MARK: - Content Row (kanji + guidance)

    private var contentRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // 墨スタンプ漢字
            Text(rokuyo.japaneseName)
                .font(.system(size: 54, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: accentColor.opacity(0.38), radius: 7)
                .scaleEffect(kanjiScale)
                .opacity(kanjiOpacity)
                .blur(radius: kanjiBlur)
                .rotationEffect(.degrees(kanjiRotation))
                .frame(width: 74, alignment: .center)

            // 説明
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(rokuyo.reading)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)

                Text(rokuyo.briefGuidance)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // 現在時刻の運気
                if let slot = currentTimeSlot {
                    currentTimeBadge(slot)
                }
            }
        }
    }

    private func currentTimeBadge(
        _ slot: (period: String, hours: String, score: Int)
    ) -> some View {
        let icon: String = {
            if slot.score >= 4 { return "sun.max.fill" }
            if slot.score == 3 { return "cloud.sun.fill" }
            return "cloud.fill"
        }()

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("今は\(slot.period)・\(luckLabel(slot.score))")
                .font(SorayomiTypography.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(slotColor(slot.score))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(slotColor(slot.score).opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Time Ribbon

    private var timeRibbon: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("時間帯の運気")
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.sorayomiTextSecondary)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(rokuyo.hourlyLuck.enumerated()), id: \.offset) { idx, slot in
                    luckBarColumn(slot: slot, index: idx)
                }
            }
        }
    }

    private func luckBarColumn(
        slot: (period: String, hours: String, score: Int),
        index: Int
    ) -> some View {
        let isCurrent = slot.period == currentTimeSlot?.period
        let maxH: CGFloat = 44
        let barH: CGFloat = barsReady ? max(8, CGFloat(slot.score) / 5.0 * maxH) : 2
        let color = slotColor(slot.score)

        return VStack(spacing: 3) {
            // バー本体
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color.opacity(isCurrent ? 1.0 : 0.38))
                .frame(height: barH)
                .overlay(
                    Group {
                        if isCurrent {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .strokeBorder(color, lineWidth: 1.5)
                                .scaleEffect(glowPulse ? 1.07 : 1.0)
                                .opacity(glowPulse ? 0.95 : 0.45)
                        }
                    }
                )
                .animation(
                    .spring(duration: 0.55, bounce: 0.3).delay(Double(index) * 0.07),
                    value: barsReady
                )

            // 現在時刻マーカー（▲）
            Group {
                if isCurrent {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(color)
                } else {
                    Color.clear
                }
            }
            .frame(height: 7)

            // 時間帯ラベル
            Text(slot.period)
                .font(.system(size: 8, weight: isCurrent ? .bold : .regular))
                .foregroundStyle(
                    isCurrent ? Color.sorayomiTextPrimary : Color.sorayomiTextSecondary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color.sorayomiDivider.opacity(0.4))
            .frame(height: 1)
    }

    // MARK: - Event Judgement

    private var eventJudgement: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("行事の吉凶を調べる")
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.sorayomiTextSecondary)

            // 行事チップ（横スクロール）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(Self.featuredEvents, id: \.self) { event in
                        eventChip(event)
                    }
                }
                .padding(.horizontal, 1)
            }

            // 選択中の行事の判定結果
            if let event = selectedEvent, let suit = rokuyo.suitability(for: event) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: suitIcon(suit.suitability))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(suitColor(suit.suitability))
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(suitLabel(suit.suitability))
                            .font(SorayomiTypography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(suitColor(suit.suitability))

                        Text(suit.note)
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextPrimary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(suitColor(suit.suitability).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                        .strokeBorder(suitColor(suit.suitability).opacity(0.22), lineWidth: 1)
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.94, anchor: .top).combined(with: .opacity),
                        removal: .opacity.animation(.easeOut(duration: 0.15))
                    )
                )
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.25), value: selectedEvent)
    }

    private func eventChip(_ event: String) -> some View {
        let suit = rokuyo.suitability(for: event)
        let score = suit?.suitability ?? 3
        let isSelected = selectedEvent == event

        return Button {
            withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                selectedEvent = isSelected ? nil : event
            }
        } label: {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: suitIcon(score))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(suitColor(score))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(shortName(event))
                    .font(SorayomiTypography.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? suitColor(score) : Color.sorayomiTextPrimary)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? suitColor(score).opacity(0.13)
                    : Color.sorayomiDivider.opacity(0.28)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? suitColor(score).opacity(0.35) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Animations

    private func startAnimations() {
        // ① 墨スタンプ: scale × blur × rotation の spring
        withAnimation(.spring(duration: 0.72, bounce: 0.48).delay(0.05)) {
            kanjiScale = 1.0
            kanjiOpacity = 1.0
            kanjiBlur = 0
            kanjiRotation = 0
        }
        // ② バー grow-up: 状態を変えると各バーが自身の .animation で動く
        withAnimation(.linear(duration: 0).delay(0.22)) {
            barsReady = true
        }
        // ③ 現在時刻バーのパルス
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.9)) {
            glowPulse = true
        }
    }

    // MARK: - Computed helpers

    private var currentTimeSlot: (period: String, hours: String, score: Int)? {
        let hour = Calendar.current.component(.hour, from: Date())
        return rokuyo.hourlyLuck.first { entry in
            let parts = entry.hours.split(separator: "-")
            guard parts.count == 2,
                  let start = Int(parts[0].prefix(while: { $0 != ":" })),
                  let end   = Int(parts[1].prefix(while: { $0 != ":" })) else { return false }
            return hour >= start && hour < end
        }
    }

    // MARK: - Accent / color helpers

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

    private func slotColor(_ score: Int) -> Color {
        switch score {
        case 5: return Color(red: 0.97, green: 0.76, blue: 0.10)
        case 4: return Color(red: 0.90, green: 0.60, blue: 0.22)
        case 3: return Color.sorayomiPrimary
        case 2: return Color(red: 0.95, green: 0.50, blue: 0.12)
        case 1: return Color(red: 0.50, green: 0.48, blue: 0.56)
        default: return Color.sorayomiPrimary
        }
    }

    private func luckLabel(_ score: Int) -> String {
        switch score {
        case 5: return "吉"
        case 4: return "小吉"
        case 3: return "平"
        case 2: return "小凶"
        case 1: return "凶"
        default: return "平"
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

    private func suitLabel(_ score: Int) -> String {
        switch score {
        case 5: return "最適"
        case 4: return "良い"
        case 3: return "可"
        case 2: return "やや不向き"
        case 1: return "避けるべき"
        default: return "可"
        }
    }

    private func shortName(_ event: String) -> String {
        switch event {
        case "結婚・婚姻届": return "結婚"
        case "旅行・出発":   return "旅行"
        case "開業・起業":   return "開業"
        case "契約・署名":   return "契約"
        default:             return event
        }
    }

    // MARK: - Card chrome

    private var cardBackground: some View {
        ZStack {
            Color.sorayomiSurface
            LinearGradient(
                colors: [accentColor.opacity(0.07), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [accentColor.opacity(0.42), Color.sorayomiDivider.opacity(0.32)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.sorayomiBackground.ignoresSafeArea()
        ScrollView {
            VStack(spacing: Spacing.md) {
                RokuyoBannerView(rokuyo: .taian)
                RokuyoBannerView(rokuyo: .butsumetsu)
                RokuyoBannerView(rokuyo: .tomobiki)
                RokuyoBannerView(rokuyo: .shakkou)
            }
            .padding()
        }
    }
}
