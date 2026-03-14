import SwiftUI

/// Onboarding page for blood type selection.
struct BloodTypePickerView: View {
    @Binding var selectedType: BloodType?
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "drop.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.sorayomiError.opacity(0.7))

            VStack(spacing: Spacing.sm) {
                Text("血液型を教えてください")
                    .font(SorayomiTypography.title2)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text("血液型の導きに使用します（任意）")
                    .font(SorayomiTypography.body)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }

            // Blood type grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(BloodType.allCases) { type in
                    Button(action: { selectedType = type }) {
                        VStack(spacing: Spacing.xs) {
                            Text(type.rawValue)
                                .font(.system(size: 28, weight: .bold))
                            Text(type.shortDescription)
                                .font(SorayomiTypography.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            selectedType == type
                                ? Color.sorayomiPrimary.opacity(0.1)
                                : Color.sorayomiSurface
                        )
                        .foregroundStyle(
                            selectedType == type
                                ? Color.sorayomiPrimary
                                : Color.sorayomiTextPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                                .stroke(
                                    selectedType == type ? Color.sorayomiPrimary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button(action: onNext) {
                    Text(selectedType != nil ? "次へ" : "スキップ")
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.sorayomiPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview {
    BloodTypePickerView(selectedType: .constant(.a), onNext: {})
}
