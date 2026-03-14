import SwiftUI

/// Onboarding page for birthday input.
struct BirthdayInputView: View {
    @Binding var birthday: Date
    var onNext: () -> Void

    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let min = calendar.date(byAdding: .year, value: -100, to: Date())!
        let max = calendar.date(byAdding: .year, value: -13, to: Date())!
        return min...max
    }()

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "birthday.cake.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.sorayomiAccent)

            VStack(spacing: Spacing.sm) {
                Text("お誕生日を教えてください")
                    .font(SorayomiTypography.title2)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text("星座や数秘術の導きに使用します")
                    .font(SorayomiTypography.body)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            DatePicker(
                "誕生日",
                selection: $birthday,
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ja_JP"))

            Spacer()

            Button(action: onNext) {
                Text("次へ")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.sorayomiPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview {
    BirthdayInputView(
        birthday: .constant(Date()),
        onNext: {}
    )
}
