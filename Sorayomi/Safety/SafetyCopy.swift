import Foundation

/// Crisis resources and helpline information for Japanese users.
struct CrisisResource: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let hours: String
    let description: String
    let url: String?

    /// Japanese crisis helplines.
    static let japanese: [CrisisResource] = [
        CrisisResource(
            name: "いのちの電話",
            phone: "0120-783-556",
            hours: "24時間対応",
            description: "自殺予防いのちの電話（無料）",
            url: "https://www.inochinodenwa.org"
        ),
        CrisisResource(
            name: "よりそいホットライン",
            phone: "0120-279-338",
            hours: "24時間対応",
            description: "生活全般の悩み相談（無料）",
            url: "https://www.since2011.net/yorisoi/"
        ),
        CrisisResource(
            name: "こころの健康相談統一ダイヤル",
            phone: "0570-064-556",
            hours: "各都道府県により異なる",
            description: "精神保健福祉センター",
            url: nil
        ),
    ]

    static let legalHotline = CrisisResource(
        name: "日弁連 法律相談",
        phone: "0570-783-110",
        hours: "平日 9:30-16:30",
        description: "弁護士による法律相談",
        url: "https://www.nichibenren.or.jp"
    )
}

/// Words and phrases that must never appear in app copy or AI output.
struct ProhibitedWording {
    static let absolutePredictions = [
        "必ず", "絶対に", "確実に", "間違いなく", "100%",
    ]

    static let medicalClaims = [
        "治る", "治療法", "処方", "服用してください",
        "診断します", "病気が", "薬を",
    ]

    static let financialAdvice = [
        "儲かる", "投資すべき", "買うべき", "売るべき",
        "確実に利益", "必ず儲かる",
    ]

    static let legalAdvice = [
        "有罪", "無罪", "訴えるべき", "裁判で勝てる",
    ]

    static let manipulative = [
        "今すぐ課金", "支払わないと", "運気が下がる",
        "手遅れになる", "今だけ", "限定",
    ]

    static let impersonation = [
        "占い師が", "鑑定師が", "霊能者が",
        "カウンセラーが", "専門家が回答",
    ]

    static let allProhibited: [String] = {
        absolutePredictions + medicalClaims + financialAdvice +
        legalAdvice + manipulative + impersonation
    }()
}
