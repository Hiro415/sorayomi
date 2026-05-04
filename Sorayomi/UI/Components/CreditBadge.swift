import SwiftUI

/// Small inline badge showing remaining credits.
/// Designed to sit directly inside a toolbar without extra chrome.
struct CreditBadge: View {
    let totalCredits: Int
    let freeCredits: Int

    private var isLow: Bool { totalCredits <= 2 }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 9, weight: .bold))
            Text("\(totalCredits)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundStyle(isLow ? Color.sorayomiWarning : Color.sorayomiSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isLow ? Color.sorayomiWarning : Color.sorayomiSecondary).opacity(0.13))
        )
    }
}

#Preview {
    HStack(spacing: 16) {
        CreditBadge(totalCredits: 12, freeCredits: 3)
        CreditBadge(totalCredits: 1, freeCredits: 0)
    }
    .padding()
    .background(Color.sorayomiBackground)
}
