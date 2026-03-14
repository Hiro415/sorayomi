import SwiftUI

/// Persistent footer banner showing safety/entertainment disclaimer.
struct SafetyDisclaimerBanner: View {
    var text: String = "※この導きは個人の内省と娯楽のためのものです"

    var body: some View {
        Text(text)
            .font(SorayomiTypography.caption)
            .foregroundStyle(Color.sorayomiTextSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity)
            .background(Color.sorayomiBackground.opacity(0.95))
    }
}

#Preview {
    SafetyDisclaimerBanner()
}
