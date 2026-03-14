import Foundation

/// The nine stars of Nine Star Ki (九星気学).
enum NineStarKiStar: Int, Codable, CaseIterable, Identifiable {
    case ippakuSuisei = 1   // 一白水星
    case jikokuDosei = 2    // 二黒土星
    case sanpekiMokusei = 3 // 三碧木星
    case shirokuMokusei = 4 // 四緑木星
    case goouDosei = 5      // 五黄土星
    case roppakuKinsei = 6  // 六白金星
    case shichisekiKinsei = 7 // 七赤金星
    case happakuDosei = 8   // 八白土星
    case kyushiKasei = 9    // 九紫火星

    var id: Int { rawValue }

    var japaneseName: String {
        switch self {
        case .ippakuSuisei:    return "一白水星"
        case .jikokuDosei:     return "二黒土星"
        case .sanpekiMokusei:  return "三碧木星"
        case .shirokuMokusei:  return "四緑木星"
        case .goouDosei:       return "五黄土星"
        case .roppakuKinsei:   return "六白金星"
        case .shichisekiKinsei: return "七赤金星"
        case .happakuDosei:    return "八白土星"
        case .kyushiKasei:     return "九紫火星"
        }
    }

    var element: String {
        switch self {
        case .ippakuSuisei:                          return "水"
        case .jikokuDosei, .goouDosei, .happakuDosei: return "土"
        case .sanpekiMokusei, .shirokuMokusei:        return "木"
        case .roppakuKinsei, .shichisekiKinsei:       return "金"
        case .kyushiKasei:                            return "火"
        }
    }

    var color: String {
        switch self {
        case .ippakuSuisei:     return "白"
        case .jikokuDosei:      return "黒"
        case .sanpekiMokusei:   return "碧（青緑）"
        case .shirokuMokusei:   return "緑"
        case .goouDosei:        return "黄"
        case .roppakuKinsei:    return "白（銀）"
        case .shichisekiKinsei: return "赤"
        case .happakuDosei:     return "白（山）"
        case .kyushiKasei:      return "紫"
        }
    }

    var direction: String {
        switch self {
        case .ippakuSuisei:     return "北"
        case .jikokuDosei:      return "南西"
        case .sanpekiMokusei:   return "東"
        case .shirokuMokusei:   return "南東"
        case .goouDosei:        return "中央"
        case .roppakuKinsei:    return "北西"
        case .shichisekiKinsei: return "西"
        case .happakuDosei:     return "北東"
        case .kyushiKasei:      return "南"
        }
    }

    var personality: String {
        switch self {
        case .ippakuSuisei:
            return "柔軟で適応力があり、周囲と調和する力を持っています"
        case .jikokuDosei:
            return "忍耐強く堅実で、人を支える母のような包容力があります"
        case .sanpekiMokusei:
            return "活動的で若々しく、新しいことに挑戦する勇気があります"
        case .shirokuMokusei:
            return "穏やかで信頼され、人間関係を大切にする方です"
        case .goouDosei:
            return "強い意志と中心力を持ち、周囲を動かすリーダーです"
        case .roppakuKinsei:
            return "高い理想と品格を持ち、完璧を追求する方です"
        case .shichisekiKinsei:
            return "社交的で楽しいことが好きな、人を惹きつける魅力の持ち主です"
        case .happakuDosei:
            return "意志が固く、変化を受け入れながら着実に前進する方です"
        case .kyushiKasei:
            return "知性と感性に優れ、華やかさと情熱を持ち合わせています"
        }
    }
}

/// A user's Nine Star Ki profile with birth year and month stars.
struct NineStarKiProfile: Codable {
    let honmeisei: NineStarKiStar   // 本命星 (birth year star)
    let getsumeisei: NineStarKiStar // 月命星 (birth month star)
    let birthYear: Int

    var japaneseSummary: String {
        return "\(honmeisei.japaneseName)・\(getsumeisei.japaneseName)"
    }
}
