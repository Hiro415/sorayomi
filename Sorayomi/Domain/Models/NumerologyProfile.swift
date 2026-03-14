import Foundation

/// Numerology profile calculated from a user's birthday.
struct NumerologyProfile: Codable {
    let lifePathNumber: Int
    let birthdayNumber: Int
    let personalYearNumber: Int
    let personalMonthNumber: Int
    let personalDayNumber: Int

    /// Japanese description for each Life Path number.
    var lifePathDescription: String {
        return Self.description(for: lifePathNumber)
    }

    var personalDayDescription: String {
        return Self.dayGuidance(for: personalDayNumber)
    }

    static func description(for number: Int) -> String {
        switch number {
        case 1:  return "リーダーシップと独立心の持ち主。自分の道を切り開く力があります"
        case 2:  return "協調性と繊細さの持ち主。人と人を繋ぐ架け橋になれます"
        case 3:  return "創造力と表現力の持ち主。周囲を明るくする太陽のような存在です"
        case 4:  return "安定感と実直さの持ち主。確実に物事を築き上げる力があります"
        case 5:  return "自由と冒険を愛する方。変化を恐れず新しい可能性を追求できます"
        case 6:  return "愛情深く責任感の強い方。家族やコミュニティを大切にします"
        case 7:  return "探究心と知性の持ち主。深い洞察力で真実を見抜く力があります"
        case 8:  return "実行力と豊かさの持ち主。目標を達成し成功を手にする力があります"
        case 9:  return "博愛精神と理想の持ち主。広い視野で世界をより良くしたいと願う方です"
        case 11: return "直感力と霊感に優れたマスターナンバー。人々にインスピレーションを与えます"
        case 22: return "大きなビジョンを形にするマスターナンバー。壮大な夢を実現する力があります"
        case 33: return "無条件の愛を持つマスターナンバー。深い慈悲と教えの力を持っています"
        default: return "特別な数字のエネルギーを持っています"
        }
    }

    static func dayGuidance(for number: Int) -> String {
        switch number {
        case 1:  return "新しいことを始めるのに良い日。自分から行動を起こしましょう"
        case 2:  return "協力と調和の日。誰かと一緒に過ごすと良い成果が生まれます"
        case 3:  return "創造力が高まる日。楽しいことや表現活動に時間を使いましょう"
        case 4:  return "地道な作業が実を結ぶ日。計画を立てて着実に進みましょう"
        case 5:  return "変化と自由の日。新しい場所や人との出会いがありそうです"
        case 6:  return "愛と奉仕の日。大切な人への思いやりが幸運を呼びます"
        case 7:  return "内省と学びの日。静かに考える時間が新しい気づきをもたらします"
        case 8:  return "達成と成功の日。大きな目標に向かって力強く進めます"
        case 9:  return "完成と手放しの日。終わりは新しい始まりへの準備です"
        case 11: return "直感が冴える日。心の声に耳を傾けてみてください"
        case 22: return "大きなビジョンが開ける日。理想を具体的な行動に移しましょう"
        case 33: return "深い愛と慈悲の日。周囲の人を思いやる気持ちが大切です"
        default: return "穏やかに自分のペースで過ごしましょう"
        }
    }
}
