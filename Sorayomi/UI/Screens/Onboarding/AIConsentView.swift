import SwiftUI

/// Apple Guideline 5.1.2(i) compliant AI consent screen.
/// Names Anthropic Claude, explains data flow, requires explicit opt-in.
struct AIConsentView: View {
    @Binding var hasConsented: Bool
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "cpu.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.sorayomiPrimary)

            VStack(spacing: Spacing.sm) {
                Text("AIの利用について")
                    .font(SorayomiTypography.title2)
                    .foregroundStyle(Color.sorayomiTextPrimary)
            }

            // Consent body
            VStack(alignment: .leading, spacing: Spacing.md) {
                consentItem(
                    icon: "wand.and.stars",
                    text: "このアプリはAnthropic社のAI「Claude」を使用して、パーソナライズされた導きを生成します"
                )
                consentItem(
                    icon: "arrow.up.forward.circle",
                    text: "あなたの質問内容はAnthropic社（米国）のサーバーに送信されます"
                )
                consentItem(
                    icon: "lock.shield",
                    text: "個人を特定する情報（氏名・住所等）は送信されません"
                )
                consentItem(
                    icon: "doc.text",
                    text: "詳しくはプライバシーポリシーをご確認ください"
                )
            }
            .padding(Spacing.md)
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            .padding(.horizontal, Spacing.md)

            Spacer()

            // Consent toggle
            Toggle(isOn: $hasConsented) {
                Text("AI利用に同意します")
                    .font(SorayomiTypography.body)
                    .foregroundStyle(Color.sorayomiTextPrimary)
            }
            .tint(Color.sorayomiPrimary)
            .padding(.horizontal, Spacing.lg)

            Button(action: onComplete) {
                Text("始める")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(hasConsented ? Color.sorayomiPrimary : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            }
            .disabled(!hasConsented)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func consentItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.sorayomiPrimary)
                .frame(width: 24)
            Text(text)
                .font(SorayomiTypography.footnote)
                .foregroundStyle(Color.sorayomiTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    AIConsentView(hasConsented: .constant(false), onComplete: {})
}
