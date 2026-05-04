import SwiftUI

/// 鑑定履歴の詳細表示画面
/// 保存された鑑定のチャット会話を読み返すためのビュー。
struct ReadingDetailScreen: View {
    let reading: FortuneReading

    /// 最新の鑑定結果メッセージID（スクロール先）
    private var lastReadingResultId: String? {
        visibleMessages.last(where: { $0.presentation == .readingResult })?.id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // ヘッダー情報
                    readingHeader
                        .padding(.bottom, Spacing.sm)

                    // メッセージ一覧
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(visibleMessages) { message in
                            ReadingMessageBubble(
                                message: message,
                                isFirstReading: message.presentation == .readingResult
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.vertical, Spacing.md)
                }
            }
            .onAppear {
                // 鑑定結果がある場合、最新の結果の先頭にスクロール
                if let resultId = lastReadingResultId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.35)) {
                            proxy.scrollTo(resultId, anchor: .top)
                        }
                    }
                }
            }
        }
        .background(Color.sorayomiBackground)
        .navigationTitle("鑑定詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var readingHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: reading.system.iconName)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [.sorayomiAccent, .sorayomiPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(reading.displayTitle)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    Text(formattedDate)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer()
            }

            HStack(spacing: Spacing.xs) {
                metaPill(
                    icon: reading.theme.iconName,
                    label: reading.theme.consultationLabel,
                    tint: .sorayomiAccent
                )
                metaPill(
                    icon: "ellipsis.bubble.fill",
                    label: "\(visibleMessages.count)件の会話",
                    tint: .sorayomiPrimary
                )
                if reading.creditsCost > 0 {
                    metaPill(
                        icon: "sparkle",
                        label: "\(reading.creditsCost)クレジット",
                        tint: .sorayomiSecondary
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.sorayomiSurface)
    }

    // MARK: - Helpers

    private var visibleMessages: [ReadingMessage] {
        reading.messages.filter { $0.role.isVisibleToUser }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: reading.createdAt)
    }

    private func metaPill(icon: String, label: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(SorayomiTypography.caption2)
                .fontWeight(.bold)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        ReadingDetailScreen(reading: .mock)
    }
}
