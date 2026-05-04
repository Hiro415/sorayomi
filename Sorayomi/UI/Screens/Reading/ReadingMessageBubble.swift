import SwiftUI

// MARK: - ReadingMessageBubble

/// 鑑定チャットの個別メッセージバブル
/// Renders a single message in the reading chat as a styled bubble.
/// User messages are aligned to the trailing edge; assistant messages
/// to the leading edge with a serif font for a premium reading feel.
/// The first assistant message is parsed and displayed as a structured fortune card.
struct ReadingMessageBubble: View {
    let message: ReadingMessage
    var isFirstReading: Bool = false
    var onShare: (() -> Void)? = nil

    @State private var appeared = false

    var body: some View {
        // Only show user-visible messages
        if message.role.isVisibleToUser {
            if message.role == .assistant && isFirstReading {
                // 初回鑑定結果 → パース → リッチカード or フォールバック
                fortuneResultView
                    .opacity(appeared ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5)) {
                            appeared = true
                        }
                    }
            } else {
                regularBubbleView
                    .opacity(appeared ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.4)) {
                            appeared = true
                        }
                    }
            }
        }
    }

    // MARK: - Fortune Result View（パース → リッチカード or フォールバック）

    @ViewBuilder
    private var fortuneResultView: some View {
        let result = FortuneResultParser.parse(message.content)
        VStack(spacing: Spacing.sm) {
            if message.presentation == .readingResult, result.isValid {
                // パース成功 → リッチカード表示
                FortuneResultCardView(result: result)
            } else {
                // パース失敗 → フォールバック（装飾付きテキスト）
                fallbackFortuneCard
            }

            // 共有ボタン（鑑定結果の末尾）
            if let onShare {
                shareButton(action: onShare)
            }
        }
    }

    private func shareButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .medium))
                Text("この鑑定をシェア")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Color.sorayomiPrimary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(Color.sorayomiPrimary.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.sorayomiPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, Spacing.xs)
    }

    // MARK: - Fallback Fortune Card（パース失敗時）

    private var fallbackFortuneCard: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(goldGradient)

                Text("鑑定結果")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(goldGradient)

                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(goldGradient)
            }
            .padding(.vertical, Spacing.xs)

            // 区切り線
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, goldAccent.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, Spacing.md)

            // 本文
            Text(message.content)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Color.sorayomiTextPrimary)
                .lineSpacing(10)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

            // 下部区切り線
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, goldAccent.opacity(0.2), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, Spacing.lg)

            // タイムスタンプ
            Text(formattedTime)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
                .padding(.top, Spacing.xxs)
                .padding(.bottom, Spacing.xs)
        }
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                .fill(Color.sorayomiSurface)
                .shadow(color: goldAccent.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [goldAccent.opacity(0.2), goldAccent.opacity(0.1), goldAccent.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Regular Bubble View

    private var regularBubbleView: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: Spacing.xxs) {
                // Role label
                Text(message.role.japaneseName)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary)

                // Message content
                Text(message.content)
                    .font(messageFont)
                    .foregroundStyle(messageForeground)
                    .lineSpacing(6)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs + 2)
                    .background(messageBackground)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Spacing.cornerRadiusMedium,
                            style: .continuous
                        )
                    )

                // Timestamp
                Text(formattedTime)
                    .font(SorayomiTypography.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.7))
            }

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - Styling

    private var goldGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(hue: 0.12, saturation: 0.5, brightness: 0.9),
                Color(hue: 0.08, saturation: 0.6, brightness: 0.8),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var goldAccent: Color {
        Color(hue: 0.12, saturation: 0.5, brightness: 0.8)
    }

    private var messageFont: Font {
        message.role == .assistant ? SorayomiTypography.fortuneBody : SorayomiTypography.body
    }

    private var messageForeground: Color {
        message.role == .user ? .white : Color.sorayomiTextPrimary
    }

    private var messageBackground: some ShapeStyle {
        if message.role == .user {
            return AnyShapeStyle(Color.sorayomiPrimary)
        } else {
            return AnyShapeStyle(Color.sorayomiSurface)
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "H:mm"
        return formatter.string(from: message.timestamp)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.sm) {
            ReadingMessageBubble(message: .mockAssistant, isFirstReading: true)
            ReadingMessageBubble(message: .mockUser)
            ReadingMessageBubble(message: .mockAssistant)
        }
        .padding(.vertical, Spacing.md)
    }
    .background(Color.sorayomiBackground)
}
