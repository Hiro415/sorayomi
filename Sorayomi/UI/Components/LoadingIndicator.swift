import SwiftUI

/// Branded loading view with Japanese text and animated dots.
struct LoadingIndicator: View {
    var message: String = "導きを準備中"
    @State private var dotCount = 0

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.sorayomiPrimary)

            Text(message + String(repeating: ".", count: dotCount + 1))
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.sorayomiTextSecondary)
                .animation(.easeInOut(duration: 0.3), value: dotCount)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

#Preview {
    LoadingIndicator()
}
