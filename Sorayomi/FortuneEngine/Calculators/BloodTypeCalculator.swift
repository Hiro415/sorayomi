import Foundation

/// Simple lookup-based blood type trait calculator.
struct BloodTypeCalculator {

    struct BloodTypeTraits {
        let type: BloodType
        let personality: String
        let strengths: String
        let weaknesses: String
        let compatibility: [BloodType]
        let loveTendency: String
        let workTendency: String
        let moneySense: String
        let healthTendency: String
    }

    static func traits(for bloodType: BloodType) -> BloodTypeTraits {
        switch bloodType {
        case .a:
            return BloodTypeTraits(
                type: .a,
                personality: bloodType.shortDescription,
                strengths: "責任感が強く、計画的に物事を進められます",
                weaknesses: "心配性になりやすく、ストレスを溜め込みがちです",
                compatibility: [.o, .ab],
                loveTendency: bloodType.loveTendency,
                workTendency: bloodType.workTendency,
                moneySense: bloodType.moneySense,
                healthTendency: bloodType.healthTendency
            )
        case .b:
            return BloodTypeTraits(
                type: .b,
                personality: bloodType.shortDescription,
                strengths: "好奇心旺盛で、新しいことへの挑戦を恐れません",
                weaknesses: "マイペースすぎて周囲との調和に苦労することがあります",
                compatibility: [.o, .ab],
                loveTendency: bloodType.loveTendency,
                workTendency: bloodType.workTendency,
                moneySense: bloodType.moneySense,
                healthTendency: bloodType.healthTendency
            )
        case .o:
            return BloodTypeTraits(
                type: .o,
                personality: bloodType.shortDescription,
                strengths: "目標に向かって力強く進み、困難に立ち向かえます",
                weaknesses: "大雑把になりやすく、細かい作業が苦手な面があります",
                compatibility: [.b, .a],
                loveTendency: bloodType.loveTendency,
                workTendency: bloodType.workTendency,
                moneySense: bloodType.moneySense,
                healthTendency: bloodType.healthTendency
            )
        case .ab:
            return BloodTypeTraits(
                type: .ab,
                personality: bloodType.shortDescription,
                strengths: "分析力に優れ、複数の視点から物事を捉えられます",
                weaknesses: "気分の波があり、周囲から理解されにくいことがあります",
                compatibility: [.a, .b],
                loveTendency: bloodType.loveTendency,
                workTendency: bloodType.workTendency,
                moneySense: bloodType.moneySense,
                healthTendency: bloodType.healthTendency
            )
        }
    }
}
