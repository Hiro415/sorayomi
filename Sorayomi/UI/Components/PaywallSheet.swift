import SwiftUI

/// Modal sheet for purchasing credit packs or subscribing.
/// Starter pack is shown first for new users; subscription for returning users.
struct PaywallSheet: View {
    @Binding var isPresented: Bool
    let creditsNeeded: Int
    let isSubscribed: Bool
    let currentBalance: Int
    let hasUsedStarterPack: Bool
    var onPurchase: ((String) -> Void)? = nil
    var onSubscribe: ((String) -> Void)? = nil
    var onRestore: (() -> Void)? = nil
    var onWatchAd: (() -> Void)? = nil
    var isAdRewardAvailable: Bool = false
    /// 購入処理中フラグ（true の間はすべての購入ボタンを無効化して連打を防止）
    var isPurchasing: Bool = false
    /// StoreKit から取得したライブ価格（productId → displayPrice）
    /// 空の場合はビュー内のフォールバック価格を使用する
    var prices: [String: String] = [:]

    /// 指定プロダクトの表示価格を返す。StoreKit 価格が取得できない場合はフォールバックを使用。
    private func price(for productId: String, fallback: String) -> String {
        prices[productId] ?? fallback
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    urgencyHeader
                    // 購入処理中スピナー
                    if isPurchasing {
                        ProgressView("処理中…")
                            .progressViewStyle(.circular)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                            .padding(.vertical, Spacing.sm)
                    }

                    // スターターパック（未購入時のみ、最優先表示）
                    if !hasUsedStarterPack {
                        starterPackCTA
                    }

                    // サブスクリプション CTA（非サブスク時）
                    if !isSubscribed {
                        premiumPassCTA
                    }

                    // 広告リワード（有効時）
                    if isAdRewardAvailable && !isSubscribed {
                        adRewardOption
                    }

                    // 区切り
                    if !isSubscribed {
                        HStack {
                            Rectangle()
                                .fill(Color.sorayomiTextSecondary.opacity(0.2))
                                .frame(height: 1)
                            Text("都度購入する")
                                .font(SorayomiTypography.caption)
                                .foregroundStyle(Color.sorayomiTextSecondary)
                            Rectangle()
                                .fill(Color.sorayomiTextSecondary.opacity(0.2))
                                .frame(height: 1)
                        }
                    }

                    // パックオプション
                    VStack(spacing: Spacing.sm) {
                        CreditPackOption(
                            credits: 12,
                            price: price(for: ProductIdentifiers.pack12, fallback: "¥480"),
                            unitPrice: ProductIdentifiers.unitPrice(for: ProductIdentifiers.pack12),
                            label: "おすすめパック",
                            badge: "人気",
                            productId: ProductIdentifiers.pack12,
                            onPurchase: onPurchase
                        )
                        CreditPackOption(
                            credits: 30,
                            price: price(for: ProductIdentifiers.pack30, fallback: "¥980"),
                            unitPrice: ProductIdentifiers.unitPrice(for: ProductIdentifiers.pack30),
                            label: "じっくり相談パック",
                            badge: nil,
                            productId: ProductIdentifiers.pack30,
                            onPurchase: onPurchase
                        )
                        CreditPackOption(
                            credits: 60,
                            price: price(for: ProductIdentifiers.pack60, fallback: "¥1,600"),
                            unitPrice: ProductIdentifiers.unitPrice(for: ProductIdentifiers.pack60),
                            label: "たっぷり鑑定パック",
                            badge: "最安",
                            productId: ProductIdentifiers.pack60,
                            onPurchase: onPurchase
                        )
                    }

                    // 復元
                    Button(action: { onRestore?() }) {
                        Text("購入を復元")
                            .font(SorayomiTypography.footnote)
                            .foregroundStyle(Color.sorayomiPrimary)
                    }

                    // 法的表示
                    VStack(spacing: Spacing.xxs) {
                        Text("※ クレジットは消耗型のアプリ内課金です")
                        Text("※ プレミアムパスは自動更新サブスクリプションです")
                        Text("※ 月次クレジットの繰越上限は30クレジットです")
                    }
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
            }
            .disabled(isPurchasing)
            .background(Color.sorayomiBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { isPresented = false }
                }
            }
        }
    }

    // MARK: - Urgency Header

    private var urgencyHeader: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "sparkle")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sorayomiSecondary, .sorayomiAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("クレジットが足りません")
                .font(SorayomiTypography.title2)
                .foregroundStyle(Color.sorayomiTextPrimary)

            HStack(spacing: Spacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.caption2)
                    Text("必要: \(creditsNeeded)")
                }
                .foregroundStyle(Color.sorayomiWarning)

                Text("→")
                    .foregroundStyle(Color.sorayomiTextSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.caption2)
                    Text("残高: \(currentBalance)")
                }
                .foregroundStyle(currentBalance > 0 ? Color.sorayomiTextSecondary : Color.sorayomiError)
            }
            .font(SorayomiTypography.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(Color.sorayomiSurface)
            .clipShape(Capsule())
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Starter Pack CTA

    private var starterPackCTA: some View {
        Button(action: { onPurchase?(ProductIdentifiers.starterPack) }) {
            VStack(spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "gift.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                            Text("はじめてパック")
                                .font(SorayomiTypography.headline)
                                .foregroundStyle(.white)
                            Text("1回限り")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.25))
                                .clipShape(Capsule())
                        }
                        Text("5クレジットで好きな占術をお試し")
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.85))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price(for: ProductIdentifiers.starterPack, fallback: "¥160"))
                            .font(SorayomiTypography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text(ProductIdentifiers.unitPrice(for: ProductIdentifiers.starterPack))
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("いちばんお得な初回限定価格")
                        .font(SorayomiTypography.caption2)
                }
                .foregroundStyle(Color.white.opacity(0.9))
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(Spacing.md)
            .background(
                LinearGradient(
                    colors: [.sorayomiAccent, .sorayomiSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Premium Pass CTA

    private var premiumPassCTA: some View {
        VStack(spacing: Spacing.sm) {
            VStack(spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.sorayomiAccent)
                    Text("月間プレミアム")
                        .font(SorayomiTypography.eyebrow)
                        .foregroundStyle(Color.sorayomiAccent)
                }

                Text("毎月30クレジットで、気になったときにすぐ相談")
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)
            }

            Button(action: { onSubscribe?(ProductIdentifiers.monthlyPremium) }) {
                VStack(spacing: Spacing.xs) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("月間プレミアム")
                                .font(SorayomiTypography.headline)
                                .foregroundStyle(.white)
                            Text("毎月30クレジット付与（繰越上限30）")
                                .font(SorayomiTypography.caption)
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(price(for: ProductIdentifiers.monthlyPremium, fallback: "¥980"))
                                .font(SorayomiTypography.title3)
                                .fontWeight(.bold)
                            Text("/月")
                                .font(SorayomiTypography.caption)
                        }
                        .foregroundStyle(.white)
                    }

                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                        Text("パックより お得 — 履歴閲覧・繰越上限30つき")
                            .font(SorayomiTypography.caption2)
                    }
                    .foregroundStyle(Color.white.opacity(0.9))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
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
        }
    }

    // MARK: - Ad Reward Option

    private var adRewardOption: some View {
        Button(action: { onWatchAd?() }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "play.rectangle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.sorayomiAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("動画を見て1クレジット")
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)
                    Text("1日1回まで・約30秒")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.sorayomiPrimary)
            }
            .padding(Spacing.md)
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(Color.sorayomiAccent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Individual credit pack purchase option with unit pricing.
private struct CreditPackOption: View {
    let credits: Int
    let price: String
    let unitPrice: String
    let label: String
    let badge: String?
    let productId: String
    var onPurchase: ((String) -> Void)?

    var body: some View {
        Button(action: { onPurchase?(productId) }) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "sparkle")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiSecondary)
                        Text("\(credits) クレジット")
                            .font(SorayomiTypography.headline)
                            .foregroundStyle(Color.sorayomiTextPrimary)
                            .lineLimit(1)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.sorayomiAccent)
                                .clipShape(Capsule())
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    HStack(spacing: Spacing.xxs) {
                        Text(label)
                            .font(SorayomiTypography.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary)
                        Text("・")
                            .foregroundStyle(Color.sorayomiTextSecondary)
                        Text(unitPrice)
                            .font(SorayomiTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.sorayomiPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
    PaywallSheet(
        isPresented: .constant(true),
        creditsNeeded: 2,
        isSubscribed: false,
        currentBalance: 0,
        hasUsedStarterPack: false
    )
}
