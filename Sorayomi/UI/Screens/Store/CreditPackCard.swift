import SwiftUI
import StoreKit

// MARK: - CreditPackCard

/// クレジットパック購入カード
/// Displays a single purchasable credit pack with icon, credit count,
/// label, optional badge, and App Store price.
struct CreditPackCard: View {
    let product: Product
    let credits: Int
    let label: String
    let badge: String?
    let isPurchasing: Bool
    let onPurchase: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 56

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onPurchase()
        } label: {
            HStack(spacing: Spacing.md) {
                // Credit icon and count
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.sorayomiSecondary.opacity(0.22), .sorayomiAccent.opacity(0.16)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: iconSize, height: iconSize)

                    Image(systemName: "sparkle")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.sorayomiSecondary, .sorayomiGlow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Pack info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text("\(credits)クレジット")
                            .font(SorayomiTypography.headline)
                            .foregroundStyle(Color.sorayomiTextPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.sorayomiAccent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(label)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)

                    // Unit price
                    if credits > 0, let price = unitPrice {
                        Text("1回あたり 約\(price)")
                            .font(SorayomiTypography.caption2)
                            .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.7))
                    }
                }

                Spacer()

                // Price / purchase button
                VStack(spacing: Spacing.xxs) {
                    if isPurchasing {
                        ProgressView()
                            .tint(Color.sorayomiPrimary)
                    } else {
                        Text(product.displayPrice)
                            .font(SorayomiTypography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.sorayomiPrimary)

                        Text("購入")
                            .font(SorayomiTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.sorayomiAccent)
                    }
                }
            }
            .sorayomiPanel(tone: badge != nil ? .spotlight : .elevated, padding: Spacing.md)
        }
        .buttonStyle(SorayomiPressableButtonStyle())
        .hoverEffect(.lift)
        .disabled(isPurchasing)
    }

    // MARK: - Helpers

    /// 1クレジットあたりの概算単価
    private var unitPrice: String? {
        guard credits > 0 else { return nil }
        let perCredit = product.price / Decimal(credits)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: perCredit as NSDecimalNumber)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.sm) {
        // Note: Real previews require StoreKit Configuration
        Text("CreditPackCard requires StoreKit products to render")
            .font(SorayomiTypography.caption)
            .foregroundStyle(Color.sorayomiTextSecondary)
    }
    .padding(Spacing.md)
    .background(Color.sorayomiBackground)
}
