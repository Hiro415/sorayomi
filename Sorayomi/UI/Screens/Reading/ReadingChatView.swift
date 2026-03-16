import SwiftUI

// MARK: - ReadingChatView

/// 鑑定チャットビュー
/// Displays the conversation between the user and the AI fortune reader,
/// with a text input bar at the bottom for follow-up questions.
struct ReadingChatView: View {
    let messages: [ReadingMessage]
    @Binding var userInput: String
    let isGenerating: Bool
    var fortuneSystem: FortuneSystem?
    let inputPlaceholder: String
    let onSend: () -> Void
    var showPartnerBloodTypePicker: Bool = false
    var onSelectPartnerBloodType: ((BloodType) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Messages scroll area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        // Safety disclaimer
                        safetyDisclaimer

                        // Messages
                        ForEach(visibleMessages) { message in
                            ReadingMessageBubble(
                                message: message,
                                isFirstReading: message.presentation == .readingResult
                            )
                            .id(message.id)
                        }

                        // Typing indicator
                        if isGenerating {
                            typingIndicator
                                .id("typing-indicator")
                        }
                    }
                    .padding(.vertical, Spacing.md)
                }
                .onAppear {
                    // タロットリビールからの遷移時に最新メッセージへスクロール
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isGenerating) { _, newValue in
                    if newValue {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }

            Divider()
                .foregroundStyle(Color.sorayomiDivider)

            // Input bar
            if showPartnerBloodTypePicker {
                partnerBloodTypePicker
            } else {
                inputBar
            }
        }
    }

    // MARK: - Visible Messages

    /// Filters out system messages that shouldn't be shown to the user.
    private var visibleMessages: [ReadingMessage] {
        messages.filter { $0.role.isVisibleToUser }
    }

    // MARK: - Safety Disclaimer

    private var safetyDisclaimer: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)

            Text("本サービスはエンターテインメント目的です。重要な決断の際は専門家にご相談ください。")
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.sorayomiTextSecondary)
                .lineSpacing(2)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sorayomiSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous))
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Typing Indicator (Claude Code style)

    private var typingIndicator: some View {
        ThinkingIndicatorView(fortuneSystem: fortuneSystem)
            .padding(.horizontal, Spacing.md)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: Spacing.xs) {
            TextField(inputPlaceholder, text: $userInput, axis: .vertical)
                .font(SorayomiTypography.body)
                .lineLimit(1...4)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.sorayomiSurface)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                        .strokeBorder(Color.sorayomiDivider, lineWidth: 1)
                )

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(sendButtonColor)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color.sorayomiBackground)
    }

    // MARK: - Partner Blood Type Picker

    private var partnerBloodTypePicker: some View {
        VStack(spacing: Spacing.xs) {
            Text("血液型を選択")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)

            HStack(spacing: Spacing.sm) {
                ForEach(BloodType.allCases) { type in
                    Button {
                        onSelectPartnerBloodType?(type)
                    } label: {
                        Text(type.japaneseName)
                            .font(SorayomiTypography.headline)
                            .foregroundStyle(Color.sorayomiTextPrimary)
                            .frame(width: 64, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                                    .fill(Color.sorayomiSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                                    .strokeBorder(Color.sorayomiPrimary.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.sorayomiBackground)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    private var sendButtonColor: Color {
        canSend ? .sorayomiPrimary : .sorayomiTextSecondary.opacity(0.3)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if isGenerating {
                proxy.scrollTo("typing-indicator", anchor: .bottom)
            } else if let lastMessage = visibleMessages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReadingChatView(
        messages: [.mockUser, .mockAssistant],
        userInput: .constant(""),
        isGenerating: false,
        fortuneSystem: .tarot,
        inputPlaceholder: "追加の質問を入力...",
        onSend: {}
    )
    .background(Color.sorayomiBackground)
}
