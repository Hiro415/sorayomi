import SwiftUI
import StoreKit

// MARK: - StoreScreen

/// Credit store rebuilt around starter pack priority, monthly premium, and clear value comparison.
struct StoreScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = StoreViewModel()
    @State private var showCreditGuide = false
    @State private var showTerms = false
    @State private var showPrivacyPolicy = false

    var body: some View {
        ZStack {
            SorayomiOrnamentalBackground()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    balanceHero

                    // スターターパック（未購入時のみ）
                    if !env.storeKitManager.hasUsedStarterPack {
                        starterPackSection
                    }

                    subscriptionSection
                    productsSection
                    creditGuideButton
                    footerSection
                }
                .adaptiveScreenPadding()
                .contentWidthConstraint()
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("クレジットストア")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProducts(storeKitManager: env.storeKitManager)
        }
        .alert(
            "購入完了",
            isPresented: Binding(
                get: { viewModel.purchasedCredits != nil },
                set: { if !$0 { viewModel.dismissPurchaseConfirmation(storeKitManager: env.storeKitManager) } }
            )
        ) {
            Button("OK") { viewModel.dismissPurchaseConfirmation(storeKitManager: env.storeKitManager) }
        } message: {
            if let credits = viewModel.purchasedCredits {
                Text("\(credits)クレジットが追加されました。すぐに本格鑑定へ進めます。")
            }
        }
        .alert(
            "プレミアムパス有効",
            isPresented: Binding(
                get: { viewModel.didSubscribe },
                set: { if !$0 { viewModel.dismissPurchaseConfirmation(storeKitManager: env.storeKitManager) } }
            )
        ) {
            Button("OK") { viewModel.dismissPurchaseConfirmation(storeKitManager: env.storeKitManager) }
        } message: {
            Text("毎月30クレジットが届きます。今月分はすぐにご利用いただけます。")
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
        .sheet(isPresented: $showCreditGuide) {
            CreditGuideSheet(isPresented: $showCreditGuide)
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                TermsOfServiceScreen()
                    .environment(env)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { showTerms = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyScreen()
                    .environment(env)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { showPrivacyPolicy = false }
                        }
                    }
            }
        }
    }

    private var balanceHero: some View {
        VStack(spacing: Spacing.sm) {
            // メインの残高表示（センター寄せ）
            VStack(spacing: Spacing.xxs) {
                Image(systemName: "sparkle")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.sorayomiSecondary, .sorayomiGlow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.bottom, Spacing.xxs)

                Text("現在の残高")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                    Text("\(env.creditWalletService.totalAvailable)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("クレジット")
                        .font(SorayomiTypography.callout)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }

            // 内訳バー
            HStack(spacing: Spacing.md) {
                let purchased = env.creditWalletService.totalAvailable - env.creditWalletService.freeCreditsRemaining

                balanceBreakdownItem(
                    label: "有償クレジット",
                    value: "\(purchased)",
                    tint: Color.white.opacity(0.85)
                )

                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 28)

                balanceBreakdownItem(
                    label: "無償クレジット",
                    value: "\(env.creditWalletService.freeCreditsRemaining)",
                    tint: Color.sorayomiGlow
                )
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))

            // サブテキスト
            Text("ヒアリング付きの本格鑑定や深掘りに使えます")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.md)
        .background(
            LinearGradient(
                colors: [.sorayomiPrimary.opacity(0.9), .sorayomiAccent.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
    }

    private func balanceBreakdownItem(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
            Text(label)
                .font(SorayomiTypography.caption2)
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .frame(minWidth: 60)
    }

    // MARK: - Starter Pack

    private var starterPackSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "初回限定",
                title: "はじめてパック",
                subtitle: "いちばんお得な価格で、好きな占術を試せます。"
            )

            if let starterProduct = viewModel.products.first(where: { viewModel.isStarterPack($0) }) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await viewModel.purchase(product: starterProduct, env: env) }
                } label: {
                    starterPackCard(product: starterProduct)
                }
                .buttonStyle(SorayomiPressableButtonStyle())
                .disabled(viewModel.isPurchasing)
            } else {
                // StoreKit未設定時のフォールバック
                starterPackFallback
            }
        }
    }

    private func starterPackCard(product: Product) -> some View {
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
                    Text("5クレジットで、好きな占術をお試し")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(SorayomiTypography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("¥32/回")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }

            HStack(spacing: Spacing.xxs) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text("初回限定・いちばんお得な価格")
                    .font(SorayomiTypography.caption)
                Spacer()
            }
            .foregroundStyle(Color.white.opacity(0.9))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))
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

    private var starterPackFallback: some View {
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
                    Text("5クレジットで、好きな占術をお試し")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                Spacer()
                Text("¥160")
                    .font(SorayomiTypography.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
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

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Group {
            if viewModel.isSubscribed {
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.sorayomiSecondary, .sorayomiGlow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("月間プレミアム有効")
                                .font(SorayomiTypography.headline)
                                .foregroundStyle(Color.sorayomiTextPrimary)
                            if let name = env.storeKitManager.activeSubscriptionDisplayName {
                                Text(name)
                                    .font(SorayomiTypography.caption)
                                    .foregroundStyle(Color.sorayomiTextSecondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("毎月")
                                .font(SorayomiTypography.caption)
                                .foregroundStyle(Color.sorayomiTextSecondary)
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(env.storeKitManager.monthlyCreditsAllowance)")
                                    .font(SorayomiTypography.metricNumber)
                                    .foregroundStyle(Color.sorayomiPrimary)
                                Text("クレジット")
                                    .font(SorayomiTypography.caption)
                                    .foregroundStyle(Color.sorayomiTextSecondary)
                            }
                        }
                    }
                }
                .sorayomiPanel(tone: .spotlight)
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    sectionHeader(
                        eyebrow: "おすすめ",
                        title: "月間プレミアム",
                        subtitle: "毎月30クレジットが届くから、気になったときにすぐ相談できます。"
                    )

                    if let monthly = viewModel.subscriptions.first(where: { $0.id == ProductIdentifiers.monthlyPremium }) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            Task { await viewModel.purchaseSubscription(product: monthly, env: env) }
                        } label: {
                            VStack(spacing: Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: Spacing.xxs) {
                                            Text("月間プレミアム")
                                                .font(SorayomiTypography.headline)
                                                .foregroundStyle(.white)
                                            Text("おすすめ")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.white.opacity(0.25))
                                                .clipShape(Capsule())
                                        }
                                        Text("毎月30クレジット付与（繰越上限30）")
                                            .font(SorayomiTypography.caption)
                                            .foregroundStyle(Color.white.opacity(0.85))
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(monthly.displayPrice + "/月")
                                            .font(SorayomiTypography.title3)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                        // 1クレジットあたりの単価を product.priceFormatStyle で算出
                                        Text((monthly.price / 30).formatted(monthly.priceFormatStyle) + "/回")
                                            .font(SorayomiTypography.caption)
                                            .foregroundStyle(Color.white.opacity(0.7))
                                    }
                                }

                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption2)
                                        .foregroundStyle(Color.sorayomiGlow)
                                    Text("履歴閲覧・繰越上限30")
                                        .font(SorayomiTypography.caption)
                                        .foregroundStyle(Color.white.opacity(0.9))
                                    Spacer()
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))
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
                        .buttonStyle(SorayomiPressableButtonStyle())
                        .disabled(viewModel.isPurchasing)
                    } else if !viewModel.isLoading {
                        // StoreKit未設定時のフォールバック
                        fallbackSubscriptionCard
                    }
                }
            }
        }
    }

    private var fallbackSubscriptionCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("月間プレミアム")
                        .font(SorayomiTypography.headline)
                        .foregroundStyle(.white)
                    Text("毎月30クレジット付与（繰越上限30）")
                        .font(SorayomiTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("¥980/月")
                        .font(SorayomiTypography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
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

    // MARK: - Credit Guide Button

    private var creditGuideButton: some View {
        Button {
            showCreditGuide = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "questionmark.circle")
                    .font(.callout)
                    .foregroundStyle(Color.sorayomiPrimary)

                Text("クレジットでできること・使い方")
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.sorayomiSurface.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                eyebrow: "パック一覧",
                title: "クレジットパック",
                subtitle: "使い方に合わせて選べます。"
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
                // フォールバック表示
                VStack(spacing: Spacing.sm) {
                    fallbackPackCard(credits: 12, price: "¥480", label: "おすすめパック", badge: "人気")
                    fallbackPackCard(credits: 30, price: "¥980", label: "じっくり相談パック", badge: nil)
                    fallbackPackCard(credits: 60, price: "¥1,600", label: "たっぷり鑑定パック", badge: "最安")
                }
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.products.filter { !viewModel.isStarterPack($0) }, id: \.id) { product in
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

                Image(systemName: "sparkle")
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
                        .lineLimit(1)

                    if let badge {
                        Text(badge)
                            .font(SorayomiTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.sorayomiAccent)
                            .clipShape(Capsule())
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }

                Text(label)
                    .font(SorayomiTypography.caption)
                    .foregroundStyle(Color.sorayomiTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(price)
                .font(SorayomiTypography.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.sorayomiPrimary)
        }
        .sorayomiPanel(tone: badge == nil ? .elevated : .spotlight, padding: Spacing.md)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(
                eyebrow: "購入ガイド",
                title: "購入と利用について",
                subtitle: "復元や注意事項はこちらから。"
            )

            Button {
                Task { await viewModel.restorePurchases(storeKitManager: env.storeKitManager) }
            } label: {
                Text("購入を復元")
                    .sorayomiSecondaryButton()
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("※ クレジットは消耗型のアプリ内課金です")
                Text("※ 未使用分の払い戻しはできません")
                Text("※ 月間プレミアムは自動更新サブスクリプションです")
                Text("※ 月次クレジットの繰越上限は30クレジットです")
                Text("※ 価格は税込みです")
            }
            .font(SorayomiTypography.caption)
            .foregroundStyle(Color.sorayomiTextSecondary)

            HStack(spacing: Spacing.md) {
                Button("利用規約") { showTerms = true }
                Button("プライバシーポリシー") { showPrivacyPolicy = true }
            }
            .font(SorayomiTypography.caption)
            .foregroundStyle(Color.sorayomiPrimary)
        }
        .sorayomiPanel(tone: .elevated)
    }

    // MARK: - Reusable Components

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

// MARK: - CreditGuideSheet

/// クレジットの役割と使い方を説明するシート
private struct CreditGuideSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // できること
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        guideSectionHeader(
                            eyebrow: "クレジットの役割",
                            title: "クレジットでできること",
                            subtitle: "対話しながら深める鑑定体験に使われます。"
                        )

                        HStack(spacing: Spacing.sm) {
                            guideBenefitCard(
                                title: "対話鑑定",
                                detail: "まず状況を聞いてから見立てる",
                                icon: "bubble.left.and.bubble.right.fill",
                                tint: .sorayomiAccent
                            )
                            guideBenefitCard(
                                title: "保存",
                                detail: "履歴に残して、あとから振り返る",
                                icon: "book.closed.fill",
                                tint: .sorayomiPrimary
                            )
                            guideBenefitCard(
                                title: "深掘り",
                                detail: "気になる点を続けて質問できる",
                                icon: "sparkles",
                                tint: .sorayomiSecondary
                            )
                        }
                    }

                    // 使い方の目安
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        guideSectionHeader(
                            eyebrow: "使い方",
                            title: "使い方の目安",
                            subtitle: "占術によって消費クレジットが異なります。"
                        )

                        VStack(spacing: Spacing.sm) {
                            guideUsageRow(
                                icon: "sun.max.fill",
                                label: "デイリー系の確認",
                                cost: "無料",
                                detail: "今日の流れや気分をさっと整えたいとき",
                                color: .sorayomiSuccess
                            )
                            guideUsageRow(
                                icon: "rectangle.portrait.on.rectangle.portrait.fill",
                                label: "タロット・星座の相談",
                                cost: "1 クレジット",
                                detail: "恋愛や対人のニュアンスを会話つきで見たいとき",
                                color: .sorayomiSecondary
                            )
                            guideUsageRow(
                                icon: "number",
                                label: "数秘術・九星気学の深読み",
                                cost: "2 クレジット",
                                detail: "転機や方向性までじっくり見立てたいとき",
                                color: .sorayomiAccent
                            )
                        }
                        .padding(Spacing.md)
                        .background(Color.sorayomiSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.sorayomiBackground)
            .navigationTitle("クレジットガイド")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { isPresented = false }
                }
            }
        }
    }

    private func guideSectionHeader(eyebrow: String, title: String, subtitle: String) -> some View {
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

    private func guideBenefitCard(title: String, detail: String, icon: String, tint: Color) -> some View {
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
        .padding(Spacing.md)
        .background(Color.sorayomiSurface)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    }

    private func guideUsageRow(icon: String, label: String, cost: String, detail: String, color: Color) -> some View {
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StoreScreen()
            .environment(AppEnvironment())
    }
}
