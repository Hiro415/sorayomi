import Foundation

/// Simple lookup-based blood type trait calculator.
struct BloodTypeCalculator {

    struct BloodTypeTraits {
        let type: BloodType
        let personality: String
        let strengths: String
        let weaknesses: String
        let compatibility: [BloodType]
    }

    static func traits(for bloodType: BloodType) -> BloodTypeTraits {
        switch bloodType {
        case .a:
            return BloodTypeTraits(
                type: .a,
                personality: "几帳面で誠実、周囲に気を配る繊細な心の持ち主です",
                strengths: "責任感が強く、計画的に物事を進められます",
                weaknesses: "心配性になりやすく、ストレスを溜め込みがちです",
                compatibility: [.a, .ab]
            )
        case .b:
            return BloodTypeTraits(
                type: .b,
                personality: "自由奔放でクリエイティブ、独自の道を切り開く開拓者です",
                strengths: "好奇心旺盛で、新しいことへの挑戦を恐れません",
                weaknesses: "マイペースすぎて周囲との調和に苦労することがあります",
                compatibility: [.b, .ab]
            )
        case .o:
            return BloodTypeTraits(
                type: .o,
                personality: "おおらかでリーダーシップがあり、人を惹きつける魅力の持ち主です",
                strengths: "目標に向かって力強く進み、困難に立ち向かえます",
                weaknesses: "大雑把になりやすく、細かい作業が苦手な面があります",
                compatibility: [.o, .a]
            )
        case .ab:
            return BloodTypeTraits(
                type: .ab,
                personality: "理知的で多面的、独特の感性を持つバランスの取れた方です",
                strengths: "分析力に優れ、複数の視点から物事を捉えられます",
                weaknesses: "気分の波があり、周囲から理解されにくいことがあります",
                compatibility: [.ab, .b]
            )
        }
    }
}
