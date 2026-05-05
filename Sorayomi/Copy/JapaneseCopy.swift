// JapaneseCopy.swift
// Sorayomi
//
// The complete Japanese copy deck for every CopyKey, with variant-specific
// text where the compliance level requires distinct wording.
//
// Style guide:
// - Natural Japanese in polite form (ですます調)
// - Warm, premium-feeling tone throughout
// - No fake-human implications (the app never pretends to be a real fortune teller)
// - No guaranteed predictions or absolute language
// - Compliance-aware: AI attribution, entertainment disclaimers, no professional advice

import Foundation

extension CopyKey {

    /// Returns the default Japanese copy for this key under the given variant.
    ///
    /// For most keys the copy is identical across variants. Where compliance
    /// requirements diverge the method returns variant-specific text:
    /// - `.safe` — warm, concise disclosure
    /// - `.stricter` — explicit AI attribution and entertainment framing
    /// - `.legalReview` — full legal language with provider names
    func defaultValue(for variant: CopyVariant) -> String {
        switch self {

        // =====================================================================
        // MARK: - App Identity
        // =====================================================================

        case .appTitle:
            return "宙よみ"

        case .appSubtitle:
            switch variant {
            case .safe:
                return "あなただけの導きを"
            case .stricter:
                return "AIがお届けする、あなただけの導き"
            case .legalReview:
                return "AI自動生成による占いエンターテインメント"
            }

        // =====================================================================
        // MARK: - Onboarding
        // =====================================================================

        case .onboardingWelcomeTitle:
            return "ようこそ、宙よみへ"

        case .onboardingWelcomeBody:
            switch variant {
            case .safe:
                return "あなたの生年月日や血液型をもとに、パーソナライズされた導きをお届けします。毎日のヒントや気づきを、ぜひお楽しみください。"
            case .stricter:
                return "あなたの生年月日や血液型をもとに、AIによるパーソナライズされた自動生成コンテンツをお届けします。占いエンターテインメントとしてお楽しみください。"
            case .legalReview:
                return "本アプリは、お客様の生年月日・血液型等の情報をもとに、AI（人工知能）が自動生成したパーソナライズコンテンツを提供する占いエンターテインメントサービスです。専門的な助言を提供するものではありません。"
            }

        case .onboardingValueProp:
            switch variant {
            case .safe:
                return "日々の暮らしに、小さなインスピレーションを。宙よみがあなたの毎日にそっと寄り添います。"
            case .stricter:
                return "日々の暮らしに、AIが生成するインスピレーションを。占いエンターテインメントとして、あなたの毎日に彩りを添えます。"
            case .legalReview:
                return "本サービスはAI自動生成による占いエンターテインメントです。提供されるコンテンツは娯楽目的であり、専門家による助言・診断・予測を行うものではありません。"
            }

        case .onboardingBirthdayTitle:
            return "生年月日を教えてください"

        case .onboardingBloodTypeTitle:
            return "血液型を選んでください"

        case .onboardingAIConsentTitle:
            switch variant {
            case .safe:
                return "AIコンテンツについて"
            case .stricter:
                return "AI自動生成コンテンツのご利用について"
            case .legalReview:
                return "AI自動生成コンテンツの利用に関する同意"
            }

        case .onboardingAIConsentBody:
            switch variant {
            case .safe:
                return "宙よみでは、あなたの情報をもとにAIがパーソナライズされた導きを生成します。結果はエンターテインメントとしてお楽しみください。いつでも設定から変更できます。"
            case .stricter:
                return "本アプリはAI（人工知能）を使用して、お客様の入力情報に基づく自動生成コンテンツを提供します。生成結果は占いエンターテインメントであり、いかなる専門的助言にも該当しません。同意のうえご利用ください。"
            case .legalReview:
                return "本サービスはAnthropic社の生成AI「Claude」を使用し、お客様が提供する生年月日・血液型等の個人情報に基づいて占いコンテンツを自動生成します。生成されるコンテンツは娯楽目的のものであり、医療・法律・金融・心理等の専門的助言を構成するものではありません。お客様は本サービスの利用に同意することで、これらの条件を承諾したものとみなされます。"
            }

        case .onboardingAIProviderName:
            switch variant {
            case .safe:
                return "AI技術提供"
            case .stricter:
                return "AI技術提供: Anthropic"
            case .legalReview:
                return "AI技術提供: Anthropic社「Claude」"
            }

        // =====================================================================
        // MARK: - Reading (Fortune Result)
        // =====================================================================

        case .readingDisclaimer:
            switch variant {
            case .safe:
                return "この導きはエンターテインメントとしてお楽しみください。"
            case .stricter:
                return "この結果はAIが自動生成した占いエンターテインメントです。専門的な助言ではありません。"
            case .legalReview:
                return "本コンテンツはAI（Anthropic社Claude）による自動生成であり、占いエンターテインメントとして提供されています。医療・法律・金融等の専門的助言を構成するものではなく、重要な判断の根拠としないでください。"
            }

        case .readingPlaceholder:
            return "あなたへの導きを準備しています..."

        case .readingAIAttribution:
            switch variant {
            case .safe:
                return "AIによる生成コンテンツ"
            case .stricter:
                return "AI自動生成コンテンツ（Anthropic提供）"
            case .legalReview:
                return "本コンテンツはAnthropic社のAI「Claude」により自動生成されています"
            }

        case .readingGenerating:
            return "あなたの星を読み解いています..."

        // =====================================================================
        // MARK: - Safety Refusals
        // =====================================================================

        case .safeRefusalCrisis:
            return "あなたのお気持ちを大切に受け止めています。\n\nおつらい状況にあるとき、専門の相談窓口がお力になれます。\n\nいのちの電話: 0120-783-556（24時間対応）\nよりそいホットライン: 0120-279-338（24時間対応）\n\nひとりで抱え込まないでください。あなたの安全が何より大切です。"

        case .safeRefusalMedical:
            switch variant {
            case .safe:
                return "健康に関するご質問をいただきありがとうございます。\n\n宙よみは占いエンターテインメントのため、医療に関するアドバイスを行うことができません。お体のことは、かかりつけ医や医療機関にご相談ください。"
            case .stricter:
                return "医療に関するご質問にはお答えすることができません。\n\n本アプリはAI自動生成による占いエンターテインメントであり、医療的助言を提供する機能はありません。必ず医療の専門家にご相談ください。"
            case .legalReview:
                return "本サービスは占いエンターテインメントであり、医療的助言・診断・治療の提案を行う機能を有しておりません。\n\n健康上のご不安がある場合は、必ず医師等の医療専門家にご相談ください。AI生成コンテンツを医療判断の根拠にしないでください。"
            }

        case .safeRefusalLegal:
            switch variant {
            case .safe:
                return "法律に関するご質問をいただきありがとうございます。\n\n宙よみは占いエンターテインメントのため、法的なアドバイスを行うことができません。法律のご相談は、弁護士や法テラス（0570-078374）にお問い合わせください。"
            case .stricter:
                return "法律に関するご質問にはお答えすることができません。\n\n本アプリはAI自動生成による占いエンターテインメントであり、法的助言を提供する機能はありません。弁護士等の法律の専門家にご相談ください。"
            case .legalReview:
                return "本サービスは占いエンターテインメントであり、法的助言・法律相談・法的見解の提供を行う機能を有しておりません。\n\n法的問題については、必ず弁護士等の資格を有する専門家にご相談ください。AI生成コンテンツを法的判断の根拠にしないでください。"
            }

        case .safeRefusalFinancial:
            switch variant {
            case .safe:
                return "お金に関するご質問をいただきありがとうございます。\n\n宙よみは占いエンターテインメントのため、投資や金融に関するアドバイスを行うことができません。資産運用のご相談は、ファイナンシャルプランナーや金融機関にお問い合わせください。"
            case .stricter:
                return "金融・投資に関するご質問にはお答えすることができません。\n\n本アプリはAI自動生成による占いエンターテインメントであり、金融的助言を提供する機能はありません。ファイナンシャルプランナー等の専門家にご相談ください。"
            case .legalReview:
                return "本サービスは占いエンターテインメントであり、金融商品取引法に定める投資助言・投資運用業務、またはその他の金融的助言を行う機能を有しておりません。\n\n金融・投資に関する判断は、必ず資格を有する金融の専門家にご相談ください。AI生成コンテンツを投資判断の根拠にしないでください。"
            }

        // =====================================================================
        // MARK: - Store
        // =====================================================================

        case .storeTitle:
            return "クレジットストア"

        case .storeSubtitle:
            switch variant {
            case .safe:
                return "クレジットを使って、より深い導きを受けましょう"
            case .stricter:
                return "クレジットを購入して、AI生成の占いコンテンツをお楽しみください"
            case .legalReview:
                return "クレジットを購入してAI自動生成の占いエンターテインメントをご利用ください"
            }

        case .storeConsumableNotice:
            return "クレジットは消費型のアプリ内課金です。使用後の返金はできません。未使用クレジットに有効期限はありません。"

        // =====================================================================
        // MARK: - Paywall
        // =====================================================================

        case .paywallTitle:
            return "クレジットが必要です"

        case .paywallSubtitle:
            switch variant {
            case .safe:
                return "この導きを受けるにはクレジットが必要です。ストアでクレジットを追加しましょう。"
            case .stricter:
                return "このAI生成コンテンツの利用にはクレジットが必要です。ストアでクレジットをご購入ください。"
            case .legalReview:
                return "本AI自動生成コンテンツの利用にはクレジット（消費型アプリ内課金）が必要です。ストアよりご購入ください。"
            }

        case .paywallCreditsNeeded:
            return "必要クレジット: 1"

        // =====================================================================
        // MARK: - Home
        // =====================================================================

        case .homeTitle:
            return "ホーム"

        case .homeDailyCardTitle:
            return "今日の導き"

        case .homeQuickAccessTitle:
            return "クイックアクセス"

        // =====================================================================
        // MARK: - History
        // =====================================================================

        case .historyTitle:
            return "履歴"

        case .historyEmpty:
            return "まだ導きの記録がありません。\n最初の占いを試してみましょう。"

        // =====================================================================
        // MARK: - Profile
        // =====================================================================

        case .profileTitle:
            return "プロフィール"

        case .profileCreditsLabel:
            return "保有クレジット"

        case .profileEditButton:
            return "プロフィールを編集"

        // =====================================================================
        // MARK: - Settings
        // =====================================================================

        case .settingsTitle:
            return "設定"

        case .settingsPrivacy:
            return "プライバシーポリシー"

        case .settingsTerms:
            return "利用規約"

        case .settingsRestore:
            return "購入を復元"

        case .settingsLogout:
            return "ログアウト"

        case .settingsDataDeletion:
            return "アカウントとデータの削除"

        // =====================================================================
        // MARK: - Errors
        // =====================================================================

        case .errorNetwork:
            return "通信エラーが発生しました。インターネット接続を確認して、もう一度お試しください。"

        case .errorInsufficientCredits:
            return "クレジットが不足しています。ストアでクレジットを追加して、もう一度お試しください。"

        case .errorGeneric:
            return "問題が発生しました。しばらく時間をおいて、もう一度お試しください。"

        case .errorTimeout:
            return "応答に時間がかかっています。通信環境をご確認のうえ、もう一度お試しください。"

        case .errorSafetyBlock:
            switch variant {
            case .safe:
                return "この内容にはお答えすることができません。別のご質問をお試しください。"
            case .stricter:
                return "安全基準により、この内容に対するコンテンツ生成を行うことができません。別のご質問をお試しください。"
            case .legalReview:
                return "コンテンツ安全基準に基づき、このリクエストに対するAI生成コンテンツの提供を制限しました。別のご質問をお試しください。"
            }

        // =====================================================================
        // MARK: - Credit Badge
        // =====================================================================

        case .creditBadgeLabel:
            return "クレジット"

        case .creditFreeLabel:
            return "無料"

        // =====================================================================
        // MARK: - Disclaimers
        // =====================================================================

        case .disclaimerEntertainment:
            switch variant {
            case .safe:
                return "宙よみは占いエンターテインメントです。結果を重要な判断の根拠にしないでください。"
            case .stricter:
                return "本アプリはAI自動生成による占いエンターテインメントです。生成結果はいかなる専門的助言にも該当しません。重要な判断の根拠にしないでください。"
            case .legalReview:
                return "本サービスはAnthropic社のAI「Claude」による自動生成コンテンツを提供する占いエンターテインメントです。医療・法律・金融・心理等の専門的助言を構成するものではありません。重要な意思決定の根拠として使用しないでください。"
            }

        case .disclaimerNotAdvice:
            switch variant {
            case .safe:
                return "専門的なアドバイスが必要な場合は、資格を持つ専門家にご相談ください。"
            case .stricter:
                return "本アプリのAI生成コンテンツは専門的助言ではありません。医療・法律・金融等の問題については、必ず資格を持つ専門家にご相談ください。"
            case .legalReview:
                return "本サービスのAI自動生成コンテンツは、いかなる分野においても専門的助言を構成するものではありません。医療・法律・金融・心理等の問題については、必ずそれぞれの分野の資格を有する専門家にご相談ください。AI生成コンテンツに基づく行動により生じた結果について、当社は責任を負いかねます。"
            }
        }
    }
}
