import SwiftUI

/// Modal sheet for purchasing credit packs or subscribing.
struct PaywallSheet: View {
    @Binding var isPresented: Bool
    let creditsNeeded: Int
    let isSubscribed: Bool
    var onPurchase: ((String) -> Void)? = nil
    var onSubscribe: ((String) -> Void)? = nil
    var onRestore: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.sorayomiSecondary, .sorayomiAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("クレジットが必要です")
                            .font(SorayomiTypography.title2)
                            .foregroundStyle(Color.sorayomiTextPrimary)

                        Text("この導きには \(creditsNeeded) クレジットが必要です")
                            .font(SorayomiTypography.body)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                    }
                    .padding(.top, Spacing.lg)

                    // Subscription CTA (if not already subscribed)
                    if !isSubscribed {
                        subscriptionCTA
                    }

                    // Divider
                    if !isSubscribed {
                        HStack {
                            Rectangle()
                                .fill(Color.sorayomiTextSecondary.opacity(0.2))
                                .frame(height: 1)
                            Text("または")
                                .font(SorayomiTypography.caption)
                                .foregroundStyle(Color.sorayomiTextSecondary)
                            Rectangle()
                                .fill(Color.sorayomiTextSecondary.opacity(0.2))
                                .frame(height: 1)
                        }
                    }

                    // Pack Options
                    VStack(spacing: Spacing.sm) {
                        CreditPackOption(
                            credits: 4,
                            price: "¥160",
                            label: "おためしパック",
                            badge: nil,
                            productId: ProductIdentifiers.pack4,
                            onPurchase: onPurchase
                        )
                        CreditPackOption(
                            credits: 12,
                            price: "¥400",
                            label: "おすすめパック",
                            badge: "人気",
                            productId: ProductIdentifiers.pack12,
                            onPurchase: onPurchase
                        )
                        CreditPackOption(
                            credits: 24,
                            price: "¥800",
                            label: "お得パック",
                            badge: "お得",
                            productId: ProductIdentifiers.pack24,
                            onPurchase: onPurchase
                        )
                    }

                    // Restore
                    Button(action: { onRestore?() }) {
                        Text("購入を復元")
                            .font(SorayomiTypography.footnote)
                            .foregroundStyle(Color.sorayomiPrimary)
                    }

                    // Legal Notice
                    VStack(spacing: Spacing.xxs) {
                        Text("※クレジットは消耗型です")
                        Text("※未使用分の払い戻しはできません")
                        Text("※サブスクリプションは自動更新されます")
                    }
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
            }
            .background(Color.sorayomiBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { isPresented = false }
                }
            }
        }
    }

    // MARK: - Subscription CTA

    private var subscriptionCTA: some View {
        VStack(spacing: Spacing.sm) {
            VStack(spacing: Spacing.xxs) {
                Text("無制限パス")
                    .font(SorayomiTypography.eyebrow)
                    .foregroundStyle(Color.sorayomiAccent)

                Text("すべての鑑定が使い放題")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)
            }

            Button(action: { onSubscribe?(ProductIdentifiers.weeklyUnlimited) }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("週間パス")
                            .font(SorayomiTypography.headline)
                            .foregroundStyle(.white)
                        Text("7日間すべての鑑定が無制限")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.8))
                    }

                    Spacer()

                    Text("¥480/週")
                        .font(SorayomiTypography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding(Spacing.md)
                .background(
                    LinearGradient(
                        colors: [.sorayomiPrimary, .sorayomiAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            }
            .buttonStyle(.plain)

            Button(action: { onSubscribe?(ProductIdentifiers.monthlyUnlimited) }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("月間パス")
                            .font(SorayomiTypography.headline)
                            .foregroundStyle(Color.sorayomiTextPrimary)
                        Text("30日間すべての鑑定が無制限")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                    }

                    Spacer()

                    Text("¥1,480/月")
                        .font(SorayomiTypography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.sorayomiPrimary)
                }
                .padding(Spacing.md)
                .background(Color.sorayomiSurface)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                        .stroke(Color.sorayomiPrimary.opacity(0.3), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

/// Individual credit pack purchase option.
private struct CreditPackOption: View {
    let credits: Int
    let price: String
    let label: String
    let badge: String?
    let productId: String
    var onPurchase: ((String) -> Void)?

    var body: some View {
        Button(action: { onPurchase?(productId) }) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "diamond.fill")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiSecondary)
                        Text("\(credits) クレジット")
                            .font(SorayomiTypography.headline)
                            .foregroundStyle(Color.sorayomiTextPrimary)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.sorayomiAccent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(label)
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer()

                Text(price)
                    .font(SorayomiTypography.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.sorayomiPrimary)
            }
            .padding(Spacing.md)
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(badge != nil ? Color.sorayomiAccent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallSheet(isPresented: .constant(true), creditsNeeded: 2, isSubscribed: false)
}
