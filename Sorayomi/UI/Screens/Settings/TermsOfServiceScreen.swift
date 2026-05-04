import SwiftUI

// MARK: - TermsOfServiceScreen

/// アプリ内利用規約表示画面
struct TermsOfServiceScreen: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                tosHeader

                ForEach(sections) { section in
                    ToSSection(section: section)
                }
            }
            .padding(Spacing.lg)
            .contentWidthConstraint()
        }
        .background(Color.sorayomiBackground)
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var tosHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("最終更新日：2026年4月27日")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)

            Text("""
            本利用規約（以下「本規約」）は、宙よみ（以下「本アプリ」）の利用条件を定めるものです。\
            本アプリをご利用いただく前に、必ずお読みください。
            """)
            .font(SorayomiTypography.body)
            .foregroundStyle(Color.sorayomiTextPrimary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Content

    private var sections: [ToSSectionData] {
        [
            ToSSectionData(
                id: "1",
                title: "第1条　サービスの性質",
                body: """
                本アプリが提供する占いコンテンツは、すべてエンターテインメント目的です。

                ・占い結果は娯楽・参考情報として提供するものであり、将来の出来事を保証・予測するものではありません
                ・重要な判断（医療・法律・財務・人間関係など）を本アプリの結果のみに基づいて行わないでください
                ・医療・法律・財務に関するご相談は、必ず専門家にご依頼ください

                本アプリは「占い師」ではなく「占いエンターテインメントアプリ」です。
                """
            ),
            ToSSectionData(
                id: "2",
                title: "第2条　利用資格",
                body: """
                本アプリは以下の方がご利用いただけます。

                ・13歳以上の方
                ・日本国内在住の方（現時点では日本語のみ対応）
                ・本規約に同意いただける方

                13歳未満の方のご利用はできません。18歳未満の方がアプリ内課金を行う場合は、保護者の同意のもとでご利用ください。
                """
            ),
            ToSSectionData(
                id: "3",
                title: "第3条　クレジットシステム",
                body: """
                本アプリはクレジット制の鑑定サービスを提供しています。

                【無料クレジット】
                ・新規ユーザーに初回無料クレジットを付与します
                ・一部の占いは無料でご利用いただけます（おみくじ、六曜など）

                【有料クレジット】
                ・App Storeを通じてクレジットパックを購入できます
                ・購入済みクレジットは返金できません（App Storeの返金ポリシーが適用されます）
                ・クレジットに有効期限はありません

                【サブスクリプション（プレミアムパス）】
                ・月額自動更新サブスクリプションです
                ・毎月クレジットが付与されます（繰越上限あり）
                ・解約はApp Store「サブスクリプション管理」から行えます
                ・解約後も当月末まではご利用いただけます
                ・無料トライアル期間終了前に解約した場合、課金は発生しません
                """
            ),
            ToSSectionData(
                id: "4",
                title: "第4条　禁止事項",
                body: """
                以下の行為を禁止します。

                ・本アプリの逆コンパイル、リバースエンジニアリング
                ・本アプリを通じた違法行為
                ・本アプリのサービスを商業目的で再販売・再配布すること
                ・本サービスのシステムを意図的に不適切な目的で使用すること
                ・レート制限を回避しようとする行為
                ・他者になりすます行為
                """
            ),
            ToSSectionData(
                id: "5",
                title: "第5条　知的財産権",
                body: """
                本アプリに含まれるすべてのコンテンツ（テキスト、グラフィック、占いロジック、鑑定コンテンツなど）の著作権は開発者に帰属します。

                ・個人的な利用目的での画面共有は許可します
                ・商業目的での無断転載・複製は禁止します
                ・鑑定テキストは個人利用の範囲でシェア機能をご利用いただけます
                """
            ),
            ToSSectionData(
                id: "6",
                title: "第6条　免責事項",
                body: """
                本アプリは以下について責任を負いません。

                ・占い結果に基づいてユーザーが行った判断・行動の結果
                ・通信障害、システム障害によるサービスの中断
                ・本サービスが生成するコンテンツの内容
                ・第三者サービスに起因する問題

                本アプリのサービスは「現状有姿」で提供されます。
                """
            ),
            ToSSectionData(
                id: "7",
                title: "第7条　サービスの変更・終了",
                body: """
                本アプリは事前の予告なしにサービス内容を変更、または提供を終了することがあります。

                サービス終了時に未使用の有料クレジットが残っている場合、App Storeの返金ポリシーに従って対応します。
                """
            ),
            ToSSectionData(
                id: "8",
                title: "第8条　規約の変更",
                body: """
                本規約は予告なく変更される場合があります。変更後に本アプリを継続してご利用いただいた場合、変更後の規約に同意したものとみなします。

                重要な変更がある場合は、アプリ内でお知らせします。
                """
            ),
            ToSSectionData(
                id: "9",
                title: "第9条　準拠法・管轄",
                body: """
                本規約は日本法に準拠します。本アプリに関する紛争については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。
                """
            ),
            ToSSectionData(
                id: "10",
                title: "第10条　外部技術の利用",
                body: """
                本アプリは鑑定コンテンツの生成にあたり、外部の技術サービスを利用しています。これにより、一部の占い鑑定ではお客様が入力した相談内容が外部サービスに送信されることがあります。

                送信される情報は占いの種別・カテゴリ・相談内容のみとなります。氏名・誕生日・血液型等の個人識別情報は送信前に自動除去されます。

                外部技術サービスの利用に関する詳細はプライバシーポリシーをご参照ください。
                """
            ),
        ]
    }
}

// MARK: - ToSSectionData

private struct ToSSectionData: Identifiable {
    let id: String
    let title: String
    let body: String
}

// MARK: - ToSSection View

private struct ToSSection: View {
    let section: ToSSectionData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(section.title)
                .font(SorayomiTypography.headline)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Text(section.body)
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.sorayomiTextPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sorayomiSurface)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TermsOfServiceScreen()
            .environment(AppEnvironment())
    }
}
