import SwiftUI

/// Dismissible error banner that displays localized Japanese error messages.
struct ErrorBanner: View {
    let message: String
    var retryAction: (() -> Void)? = nil
    var dismissAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.sorayomiError)

            Text(message)
                .font(SorayomiTypography.footnote)
                .foregroundStyle(Color.sorayomiTextPrimary)
                .lineLimit(3)

            Spacer()

            if let retryAction {
                Button("再試行") {
                    retryAction()
                }
                .font(SorayomiTypography.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color.sorayomiPrimary)
            }

            if let dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.sorayomiError.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    VStack(spacing: 16) {
        ErrorBanner(
            message: "ネットワーク接続を確認してください",
            retryAction: {},
            dismissAction: {}
        )
        ErrorBanner(message: "予期しないエラーが発生しました")
    }
    .padding()
}
