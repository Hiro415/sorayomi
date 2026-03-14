import SwiftUI

// MARK: - FortuneResultCardView

/// 構造化された鑑定結果をリッチなカード形式で表示する
/// 各運勢セクションが個別カードとして表示され、★スコア、
/// ラッキーアイテム・カラー、締めメッセージを含む。
struct FortuneResultCardView: View {
    let result: FortuneResult

    @State private var visibleSections: Set<UUID> = []
    @State private var showLucky = false
    @State private var showMessage = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            // 鑑定結果ヘッダー
            resultHeader

            // 運勢セクション
            ForEach(Array(result.sections.enumerated()), id: \.element.id) { index, section in
                fortuneSectionCard(section: section, index: index)
            }

            // ラッキーアイテム & カラー
            if result.luckyItem != nil || result.luckyColor != nil {
                luckyItemsCard
                    .opacity(showLucky ? 1 : 0)
                    .offset(y: showLucky ? 0 : 20)
            }

            // 締めメッセージ
            if let message = result.closingMessage, !message.isEmpty {
                closingMessageCard(message: message)
                    .opacity(showMessage ? 1 : 0)
                    .offset(y: showMessage ? 0 : 20)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Result Header

    private var resultHeader: some View {
        VStack(spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(goldGradient)

                Text("鑑定結果")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(goldGradient)

                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(goldGradient)
            }

            // 装飾ライン
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, goldAccent.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, Spacing.xl)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Fortune Section Card

    private func fortuneSectionCard(section: FortuneSection, index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // ヘッダー行: アイコン + カテゴリ名 + ★スコア
            HStack(spacing: Spacing.xs) {
                // カテゴリアイコン
                let colors = section.category.gradientColors
                Image(systemName: section.category.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hue: colors.start.0, saturation: colors.start.1, brightness: colors.start.2),
                                Color(hue: colors.end.0, saturation: colors.end.1, brightness: colors.end.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // カテゴリ名
                Text(section.category.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Spacer()

                if section.category.usesRating {
                    starRating(score: section.score)
                }
            }

            // 区切り線
            Rectangle()
                .fill(Color.sorayomiDivider.opacity(0.5))
                .frame(height: 0.5)

            // 本文
            Text(section.body)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.sorayomiTextPrimary.opacity(0.85))
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                .fill(Color.sorayomiSurface)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                .strokeBorder(Color.sorayomiDivider.opacity(0.3), lineWidth: 0.5)
        )
        .opacity(visibleSections.contains(section.id) ? 1 : 0)
        .offset(y: visibleSections.contains(section.id) ? 0 : 20)
    }

    // MARK: - Star Rating

    private func starRating(score: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= score ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(starColor(filled: i <= score))
            }
        }
    }

    private func starColor(filled: Bool) -> Color {
        filled
            ? Color(hue: 0.12, saturation: 0.55, brightness: 0.85)
            : Color.sorayomiTextSecondary.opacity(0.3)
    }

    // MARK: - Lucky Items Card

    private var luckyItemsCard: some View {
        HStack(spacing: Spacing.lg) {
            if let item = result.luckyItem {
                VStack(spacing: Spacing.xxs) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(goldGradient)

                    Text("ラッキーアイテム")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.sorayomiTextSecondary)

                    Text(item)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(Color.sorayomiTextPrimary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            if result.luckyItem != nil && result.luckyColor != nil {
                Rectangle()
                    .fill(Color.sorayomiDivider.opacity(0.4))
                    .frame(width: 0.5, height: 50)
            }

            if let color = result.luckyColor {
                VStack(spacing: Spacing.xxs) {
                    // カラーサークル
                    Circle()
                        .fill(colorFromName(color))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: colorFromName(color).opacity(0.4), radius: 4, x: 0, y: 2)

                    Text("ラッキーカラー")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.sorayomiTextSecondary)

                    Text(color)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(Color.sorayomiTextPrimary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                .fill(Color.sorayomiSurface)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            goldAccent.opacity(0.2),
                            goldAccent.opacity(0.1),
                            goldAccent.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Closing Message

    private func closingMessageCard(message: String) -> some View {
        VStack(spacing: Spacing.sm) {
            // 装飾ライン（上）
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, goldAccent.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text(message)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.sorayomiTextPrimary.opacity(0.8))
                .lineSpacing(8)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // 装飾ライン（下）
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, goldAccent.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Animations

    private func animateEntrance() {
        // 各セクションを順次表示
        for (index, section) in result.sections.enumerated() {
            let delay = Double(index) * 0.15 + 0.1
            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                _ = visibleSections.insert(section.id)
            }
        }

        // ラッキーアイテム
        let luckyDelay = Double(result.sections.count) * 0.15 + 0.2
        withAnimation(.easeOut(duration: 0.5).delay(luckyDelay)) {
            showLucky = true
        }

        // メッセージ
        withAnimation(.easeOut(duration: 0.5).delay(luckyDelay + 0.2)) {
            showMessage = true
        }
    }

    // MARK: - Styling

    private var goldGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(hue: 0.12, saturation: 0.5, brightness: 0.9),
                Color(hue: 0.08, saturation: 0.6, brightness: 0.8),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var goldAccent: Color {
        Color(hue: 0.12, saturation: 0.5, brightness: 0.8)
    }

    /// 日本語の色名からSwiftUI Colorに変換
    private func colorFromName(_ name: String) -> Color {
        let lowered = name.lowercased()
        // よく使われる色名のマッピング
        if lowered.contains("ピンク") || lowered.contains("pink") { return Color(hue: 0.95, saturation: 0.5, brightness: 0.9) }
        if lowered.contains("赤") || lowered.contains("red") { return Color(hue: 0.0, saturation: 0.7, brightness: 0.8) }
        if lowered.contains("オレンジ") || lowered.contains("orange") { return Color(hue: 0.08, saturation: 0.7, brightness: 0.9) }
        if lowered.contains("黄") || lowered.contains("イエロー") || lowered.contains("yellow") { return Color(hue: 0.15, saturation: 0.6, brightness: 0.9) }
        if lowered.contains("ゴールド") || lowered.contains("金") || lowered.contains("gold") { return Color(hue: 0.12, saturation: 0.7, brightness: 0.85) }
        if lowered.contains("緑") || lowered.contains("グリーン") || lowered.contains("green") { return Color(hue: 0.35, saturation: 0.6, brightness: 0.7) }
        if lowered.contains("青") || lowered.contains("ブルー") || lowered.contains("blue") { return Color(hue: 0.6, saturation: 0.6, brightness: 0.7) }
        if lowered.contains("水色") || lowered.contains("ライトブルー") { return Color(hue: 0.55, saturation: 0.4, brightness: 0.85) }
        if lowered.contains("紫") || lowered.contains("パープル") || lowered.contains("purple") { return Color(hue: 0.75, saturation: 0.5, brightness: 0.7) }
        if lowered.contains("ラベンダー") || lowered.contains("lavender") { return Color(hue: 0.73, saturation: 0.35, brightness: 0.8) }
        if lowered.contains("白") || lowered.contains("ホワイト") || lowered.contains("white") { return Color(hue: 0, saturation: 0, brightness: 0.95) }
        if lowered.contains("黒") || lowered.contains("ブラック") || lowered.contains("black") { return Color(hue: 0, saturation: 0, brightness: 0.2) }
        if lowered.contains("グレー") || lowered.contains("gray") || lowered.contains("灰") { return Color(hue: 0, saturation: 0, brightness: 0.6) }
        if lowered.contains("シルバー") || lowered.contains("銀") || lowered.contains("silver") { return Color(hue: 0, saturation: 0.05, brightness: 0.78) }
        if lowered.contains("茶") || lowered.contains("ブラウン") || lowered.contains("brown") { return Color(hue: 0.07, saturation: 0.6, brightness: 0.5) }
        if lowered.contains("ベージュ") || lowered.contains("beige") { return Color(hue: 0.1, saturation: 0.25, brightness: 0.85) }
        if lowered.contains("コーラル") || lowered.contains("coral") { return Color(hue: 0.02, saturation: 0.55, brightness: 0.9) }
        if lowered.contains("ターコイズ") || lowered.contains("turquoise") { return Color(hue: 0.48, saturation: 0.55, brightness: 0.7) }
        if lowered.contains("ネイビー") || lowered.contains("navy") || lowered.contains("紺") { return Color(hue: 0.62, saturation: 0.7, brightness: 0.4) }
        if lowered.contains("エメラルド") || lowered.contains("emerald") { return Color(hue: 0.42, saturation: 0.65, brightness: 0.65) }
        // デフォルト
        return Color(hue: 0.55, saturation: 0.4, brightness: 0.75)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        FortuneResultCardView(result: FortuneResult(
            sections: [
                FortuneSection(category: .overall, score: 4, body: "春の訪れとともに、あなたの運気も明るい方向へと動き出しています。新しい挑戦を始めるのに良い時期です。"),
                FortuneSection(category: .love, score: 3, body: "大切な人との対話が鍵になる一日です。素直な気持ちを伝えることで、関係がより深まるでしょう。"),
                FortuneSection(category: .work, score: 5, body: "集中力が高まり、効率よく物事を進められる日です。新しいプロジェクトの提案も好意的に受け止められるでしょう。"),
                FortuneSection(category: .money, score: 3, body: "衝動的な出費には注意が必要です。本当に必要なものかどうか、一呼吸おいて考えてみてください。"),
            ],
            luckyItem: "レモンティー",
            luckyColor: "ラベンダー",
            closingMessage: "今日という日が、あなたにとって心温まる一日となりますように。小さな幸せに気づく心の余裕を大切にしてみてくださいね。",
            rawText: ""
        ))
    }
    .background(Color.sorayomiBackground)
}
