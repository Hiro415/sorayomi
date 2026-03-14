import SwiftUI

// MARK: - StoreScreen

/// Credit store rebuilt around clarity, trust, and pack comparison.
struct StoreScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = StoreViewModel()

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    purchaseHero
                    balanceCard
                    benefitSection
                    usageGuide
                    productsSection
                    footerSection
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("クレジットストア")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadProducts()
        }
        .alert(
            "購入完了",
            isPresented: Binding(
                get: { viewModel.purchasedCredits != nil },
                set: { if !$0 { viewModel.dismissPurchaseConfirmation() } }
            )
        ) {
            Button("OK") { viewModel.dismissPurchaseConfirmation() }
        } message: {
            if let credits = viewModel.purchasedCredits {
                Text("\(credits)クレジットが追加されました。すぐに本格鑑定へ進めます。")
            }
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    private var purchaseHero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("クレジット案内")
                .font(SorayomiTypography.eyebrow)
                .foregroundStyle(Color.white.opacity(0.72))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("必要なときに、深く聞ける鑑定体験を。")
                    .font(SorayomiTypography.title)
                    .foregroundStyle(.white)

                Text("クレジットは、ヒアリング付きの本格鑑定や追加の深掘りに使います。まとめて持っておくと、気になるときにすぐ相談を始められます。")
                    .font(SorayomiTypography.callout)
                    .foregroundStyle(Color.white.opacity(0.86))
                    .lineSpacing(5)
            }

            HStack(spacing: Spacing.xs) {
                storeBadge(title: "無料分", value: "\(env.creditWalletService.freeCreditsRemaining)回")
                storeBadge(title: "残高", value: "\(env.creditWalletService.totalAvailable)クレジット")
                storeBadge(title: "復元", value: "対応")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sorayomiPanel(tone: .night, padding: Spacing.lg)
    }

    private var balanceCard: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("現在の残高")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)

                HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                    Text("\(env.creditWalletService.totalAvailable)")
                        .font(SorayomiTypography.metricNumber)
                        .foregroundStyle(Color.sorayomiPrimary)
                    Text("クレジット")
                        .font(SorayomiTypography.callout)
                        .foregroundStyle(Color.sorayomiTextSecondary)
                }

                if env.creditWalletService.freeCreditsRemaining > 0 {
                    Text("無料クレジット残り \(env.creditWalletService.freeCreditsRemaining) 回")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.sorayomiSuccess)
                }
            }

            Spacer()

            Image(systemName: "diamond.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sorayomiSecondary, .sorayomiGlow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .sorayomiPanel(tone: .spotlight)
    }

    private var benefitSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "クレジットの役割",
                title: "クレジットでできること",
                subtitle: "一方的に結果を返すだけでなく、対話しながら深める体験に使われます。"
            )

            HStack(spacing: Spacing.sm) {
                benefitCard(
                    title: "対話鑑定",
                    detail: "まず状況を聞いてから見立てる",
                    icon: "bubble.left.and.bubble.right.fill",
                    tint: .sorayomiAccent
                )
                benefitCard(
                    title: "保存",
                    detail: "履歴に残して、あとから振り返る",
                    icon: "book.closed.fill",
                    tint: .sorayomiPrimary
                )
                benefitCard(
                    title: "深掘り",
                    detail: "気になる点を続けて質問できる",
                    icon: "sparkles",
                    tint: .sorayomiSecondary
                )
            }
        }
    }

    private var usageGuide: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "使い方",
                title: "使い方の目安",
                subtitle: "占術の深さに応じてクレジット消費の目安をまとめています。"
            )

            VStack(spacing: Spacing.sm) {
                usageRow(
                    icon: "sun.max.fill",
                    label: "デイリー系の確認",
                    cost: "無料",
                    detail: "今日の流れや気分をさっと整えたいとき",
                    color: .sorayomiSuccess
                )
                usageRow(
                    icon: "rectangle.portrait.on.rectangle.portrait.fill",
                    label: "タロット・星座の相談",
                    cost: "1 クレジット",
                    detail: "恋愛や対人のニュアンスを会話つきで見たいとき",
                    color: .sorayomiSecondary
                )
                usageRow(
                    icon: "number",
                    label: "数秘術・九星気学の深読み",
                    cost: "2 クレジット",
                    detail: "転機や方向性までじっくり見立てたいとき",
                    color: .sorayomiAccent
                )
            }
        }
        .sorayomiPanel(tone: .elevated)
    }

    private func usageRow(icon: String, label: String, cost: String, detail: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(SorayomiTypography.headline)
                    .foregroundStyle(Color.sorayomiTextPrimary)

                Text(detail)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
                    .lineSpacing(4)
            }

            Spacer()

            Text(cost)
                .font(SorayomiTypography.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color.opacity(0.10))
                .clipShape(Capsule())
        }
        .padding(.vertical, Spacing.xs)
    }

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "パック一覧",
                title: "クレジットパック",
                subtitle: "使用頻度に合わせて選べるよう、開発時のフォールバック表示も含めて見やすく整えています。"
            )

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.sorayomiPrimary)
                    Spacer()
                }
                .padding(.vertical, Spacing.xl)
            } else if viewModel.products.isEmpty {
                VStack(spacing: Spacing.sm) {
                    fallbackPackCard(credits: 4, price: "¥160", label: "おためしパック", badge: nil)
                    fallbackPackCard(credits: 12, price: "¥400", label: "おすすめパック", badge: "人気")
                    fallbackPackCard(credits: 24, price: "¥800", label: "じっくり相談パック", badge: "お得")
                }
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.products, id: \.id) { product in
                        CreditPackCard(
                            product: product,
                            credits: viewModel.credits(for: product),
                            label: viewModel.label(for: product),
                            badge: viewModel.badge(for: product),
                            isPurchasing: viewModel.isPurchasing,
                            onPurchase: {
                                Task {
                                    await viewModel.purchase(product: product, env: env)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    private func fallbackPackCard(credits: Int, price: String, label: String, badge: String?) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.sorayomiSecondary.opacity(0.20), .sorayomiAccent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)

                Image(systemName: "diamond.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.sorayomiSecondary, .sorayomiGlow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxs) {
                    Text("\(credits) クレジット")
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(Color.sorayomiTextPrimary)

                    if let badge {
                        Text(badge)
                            .font(SorayomiTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
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
        .sorayomiPanel(tone: badge == nil ? .elevated : .spotlight, padding: Spacing.md)
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(
                eyebrow: "購入ガイド",
                title: "購入と利用について",
                subtitle: "安心して使えるように、復元と注意事項をまとめています。"
            )

            Button {
                Task { await viewModel.restorePurchases() }
            } label: {
                Text("購入を復元")
                    .sorayomiSecondaryButton()
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("※ クレジットは消耗型のアプリ内課金です")
                Text("※ 未使用分の払い戻しはできません")
                Text("※ 価格は税込みです")
            }
            .font(SorayomiTypography.caption)
            .foregroundStyle(Color.sorayomiTextSecondary)

            HStack(spacing: Spacing.md) {
                Link("利用規約", destination: AppConstants.termsURL)
                Link("プライバシーポリシー", destination: AppConstants.privacyPolicyURL)
            }
            .font(SorayomiTypography.caption)
            .foregroundStyle(Color.sorayomiPrimary)
        }
        .sorayomiPanel(tone: .elevated)
    }

    private func sectionHeader(eyebrow: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(eyebrow.uppercased())
                .font(SorayomiTypography.eyebrow)
                .foregroundStyle(Color.sorayomiAccent)

            Text(title)
                .font(SorayomiTypography.title2)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Text(subtitle)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func benefitCard(title: String, detail: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.10))
                .clipShape(Circle())

            Text(title)
                .font(SorayomiTypography.headline)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Text(detail)
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .sorayomiPanel(tone: .elevated, padding: Spacing.md)
    }

    private func storeBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.white.opacity(0.68))
            Text(value)
                .font(SorayomiTypography.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.white.opacity(0.10))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StoreScreen()
            .environment(AppEnvironment())
    }
}
