import SwiftUI

/// Small badge showing remaining credits with a coin icon.
struct CreditBadge: View {
    let totalCredits: Int
    let freeCredits: Int

    private var isLow: Bool { totalCredits <= 2 }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "diamond.fill")
                .font(.caption2)
            Text("残り \(totalCredits)")
                .font(SorayomiTypography.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(isLow ? Color.sorayomiWarning.opacity(0.15) : Color.sorayomiSecondary.opacity(0.15))
        .foregroundStyle(isLow ? Color.sorayomiWarning : Color.sorayomiSecondary)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        CreditBadge(totalCredits: 5, freeCredits: 2)
        CreditBadge(totalCredits: 1, freeCredits: 0)
    }
}
