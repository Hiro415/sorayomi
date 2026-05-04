import SwiftUI

// MARK: - PrivacyPolicyScreen

/// アプリ内プライバシーポリシー表示画面
struct PrivacyPolicyScreen: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                policyHeader

                ForEach(sections) { section in
                    PolicySection(section: section)
                }
            }
            .padding(Spacing.lg)
            .contentWidthConstraint()
        }
        .background(Color.sorayomiBackground)
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var policyHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("最終更新日：2026年4月27日")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)

            Text("""
            宙よみ（以下「本アプリ」）は、ユーザーのプライバシーを最優先に設計されています。\
            本ポリシーは、本アプリがどのような情報を取り扱い、どのように保護しているかをご説明します。
            """)
            .font(SorayomiTypography.body)
            .foregroundStyle(Color.sorayomiTextPrimary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Content

    private var sections: [PolicySectionData] {
        [
            PolicySectionData(
                id: "1",
                title: "1. 収集する情報",
                body: """
                本アプリは以下の情報をお客様の端末内にのみ保存します。外部サーバーに個人情報を送信することはありません。

                【お客様が任意で入力する情報】
                ・ニックネーム
                ・誕生日（星座・数秘術・花占い・ストーン占いの計算に使用）
                ・血液型（血液型占いに使用）
                ・プロフィール写真（端末内にのみ保存）

                【自動的に収集される情報】
                ・鑑定履歴（端末内にのみ保存）
                ・クレジット残高と取引記録（端末内にのみ保存）
                ・アプリの利用状況（クラッシュレポートなど、個人を特定しない形式）

                いずれの情報も端末外に送信・共有されることはありません。
                """
            ),
            PolicySectionData(
                id: "2",
                title: "2. 情報の利用目的",
                body: """
                収集した情報は以下の目的のみに使用します。

                ・占い結果の計算と表示
                ・鑑定履歴の表示
                ・クレジット残高の管理
                ・アプリの機能改善（個人を特定しない集計データのみ）

                マーケティング目的での利用、第三者への販売・提供は一切行いません。
                """
            ),
            PolicySectionData(
                id: "3",
                title: "3. データの保存と削除",
                body: """
                【保存場所】
                すべてのデータはお客様の端末内にのみ保存されます。クラウドへのバックアップは行いません。

                【データの削除】
                設定画面の「アカウントとデータを削除」から、いつでもすべてのデータを削除できます。削除後のデータは復元できません。

                【アプリ削除時】
                アプリを削除すると、端末内に保存されたデータは自動的に削除されます。
                """
            ),
            PolicySectionData(
                id: "4",
                title: "4. 購入とお支払い",
                body: """
                アプリ内購入はApp Store（Apple Inc.）を通じて処理されます。クレジットカード情報などの決済情報は本アプリには一切保存されません。

                App StoreおよびApple社のプライバシーポリシーが適用されます。
                """
            ),
            PolicySectionData(
                id: "5",
                title: "5. 未成年者の利用",
                body: """
                本アプリは13歳以上を対象としています。13歳未満の方はご利用いただけません。オンボーディング時に生年月日を確認し、13歳未満の入力を制限しています。

                18歳未満の方がアプリ内課金を行う場合は、保護者の同意のもとでご利用ください。
                """
            ),
            PolicySectionData(
                id: "6",
                title: "6. セキュリティ",
                body: """
                お客様のデータ保護のために以下の対策を講じています。

                ・重要データはiOSのKeychainに暗号化して保存
                ・App Attestによるアプリ正規性検証
                ・通信はすべてHTTPS（TLS）で暗号化
                ・不正利用防止のためのレート制限
                ・入力内容のセーフティフィルタリング
                """
            ),
            PolicySectionData(
                id: "7",
                title: "7. ポリシーの変更",
                body: """
                本ポリシーを変更する場合は、アプリのアップデートとともに改訂日を更新します。重要な変更がある場合は、アプリ内で通知します。

                継続してアプリをご利用いただくことで、改訂後のポリシーへの同意とみなします。
                """
            ),
            PolicySectionData(
                id: "8",
                title: "8. 外部サービスの利用について",
                body: """
                本アプリは鑑定コンテンツの生成にあたり、一部の処理を外部サービスに委託しています。

                【送信される情報】
                占いの種別・カテゴリ・お客様が入力した相談内容のみ。氏名・メールアドレス・誕生日・血液型など、個人を直接特定できる情報は送信前に自動的に除去されます。

                【データの取り扱い】
                外部サービスへの送信内容は処理後に保存されない設定としています。
                """
            ),
        ]
    }
}

// MARK: - PolicySectionData

private struct PolicySectionData: Identifiable {
    let id: String
    let title: String
    let body: String
}

// MARK: - PolicySection View

private struct PolicySection: View {
    let section: PolicySectionData

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
        PrivacyPolicyScreen()
            .environment(AppEnvironment())
    }
}
