import SwiftUI

/// Premium history card with clearer metadata and quick delete affordance.
struct HistoryRowView: View {
    let reading: FortuneReading
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                systemIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(reading.displayTitle)
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)
                        .lineLimit(2)

                    Text(relativeDate)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer(minLength: 0)

                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiError)
                            .padding(10)
                            .background(Color.sorayomiError.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if let summary = reading.summary {
                Text(summary)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
                    .lineLimit(3)
            }

            HStack(spacing: Spacing.xs) {
                metaPill(
                    icon: reading.theme.iconName,
                    label: reading.theme.consultationLabel,
                    tint: .sorayomiAccent
                )
                metaPill(
                    icon: "ellipsis.bubble.fill",
                    label: "\(visibleMessageCount)件の会話",
                    tint: .sorayomiPrimary
                )

                if reading.creditsCost > 0 {
                    metaPill(
                        icon: "diamond.fill",
                        label: "\(reading.creditsCost)クレジット",
                        tint: .sorayomiSecondary
                    )
                }
            }
        }
        .sorayomiPanel(tone: .elevated, padding: Spacing.md)
    }

    private var systemIcon: some View {
        Image(systemName: reading.system.iconName)
            .font(.title3)
            .foregroundStyle(.white)
            .frame(width: 46, height: 46)
            .background(
                LinearGradient(
                    colors: [.sorayomiAccent, .sorayomiPrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
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

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: reading.createdAt, relativeTo: Date())
    }

    private var visibleMessageCount: Int {
        reading.messages.filter { $0.role.isVisibleToUser }.count
    }
}

#Preview {
    VStack(spacing: 8) {
        HistoryRowView(reading: .mock)
        HistoryRowView(reading: .tarotMock)
    }
    .padding()
    .background(Color.sorayomiBackground)
}
