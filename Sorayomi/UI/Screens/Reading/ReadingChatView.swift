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
    var showTopicSuggestions: Bool = false
    var onSelectTopic: ((String) -> Void)? = nil
    var onShare: (() -> Void)? = nil

    @FocusState private var isInputFocused: Bool

    /// 鑑定結果が含まれているかどうか
    private var hasReadingResult: Bool {
        messages.contains { $0.presentation == .readingResult }
    }

    /// 鑑定結果メッセージのID（スクロールアンカー用）
    private var firstReadingResultId: String? {
        visibleMessages.first(where: { $0.presentation == .readingResult })?.id
    }

    /// 最新のAIメッセージID（キーボード表示時のスクロールアンカー用）
    private var lastAssistantMessageId: String? {
        visibleMessages.last(where: { $0.role == .assistant })?.id
    }

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
                                isFirstReading: message.presentation == .readingResult,
                                onShare: message.presentation == .readingResult ? onShare : nil
                            )
                            .id(message.id)
                        }

                        // トピック提案チップス
                        if showTopicSuggestions {
                            topicSuggestionChips
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        // Typing indicator
                        if isGenerating {
                            typingIndicator
                                .id("typing-indicator")
                        }
                    }
                    .contentWidthConstraint(maxWidth: 640)
                    .padding(.vertical, Spacing.md)
                }
                .onAppear {
                    // 鑑定結果がある場合は結果トップにスクロール
                    // （LoadingView → ChatView遷移時、リビール完了後の遷移時）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let resultId = firstReadingResultId {
                            scrollToTop(of: resultId, proxy: proxy)
                        } else {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }
                .onChange(of: messages.count) { oldCount, newCount in
                    guard newCount > oldCount else { return }
                    // 新しいメッセージが鑑定結果の場合、結果のトップにスクロール
                    if let lastMessage = visibleMessages.last,
                       lastMessage.presentation == .readingResult {
                        // 少し遅延を入れてレンダリング完了を待つ
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            scrollToTop(of: lastMessage.id, proxy: proxy)
                        }
                    } else {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: isGenerating) { _, newValue in
                    if newValue {
                        // AI生成開始時にキーボードを閉じる
                        isInputFocused = false
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: isInputFocused) { _, focused in
                    if focused {
                        // キーボード表示時に最新のAIメッセージの先頭が見えるようにスクロール
                        if let lastAssistantId = lastAssistantMessageId {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(lastAssistantId, anchor: .top)
                                }
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
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

    // MARK: - Topic Suggestion Chips

    private var topicSuggestionChips: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.sorayomiAccent)
                Text("こんなテーマで話せます")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            // 2段構成のトピックチップス
            FlowLayout(spacing: Spacing.xs) {
                ForEach(suggestedTopics, id: \.self) { topic in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            onSelectTopic?(topic)
                        }
                    } label: {
                        Text(topic)
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextPrimary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.sorayomiSurface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.sorayomiDivider, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    private var suggestedTopics: [String] {
        [
            "気になる人がいる",
            "転職するか迷っている",
            "人間関係がうまくいかない",
            "将来が漠然と不安",
            "最近ツイてない",
            "大きな決断を控えている",
        ]
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
                .focused($isInputFocused)
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

    /// 鑑定結果など長いメッセージの先頭が画面上部に来るようにスクロール
    private func scrollToTop(of messageId: String, proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.35)) {
            proxy.scrollTo(messageId, anchor: .top)
        }
    }
}

// MARK: - FlowLayout

/// 自動折り返しレイアウト（トピックチップス用）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews
        )
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        let proposedWidth = proposal.width ?? 0
        let maxWidth: CGFloat = proposedWidth.isFinite && proposedWidth > 0 ? proposedWidth : 320
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                // 改行
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = max(totalHeight, y + rowHeight)
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
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
