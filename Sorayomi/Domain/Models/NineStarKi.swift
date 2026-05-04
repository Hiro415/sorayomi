import Foundation

/// The nine stars of Nine Star Ki (九星気学).
/// Enhanced with detailed traits, Five Element relationships, auspicious directions,
/// and ki-grid (九宮格/後天定位盤) awareness.
enum NineStarKiStar: Int, Codable, CaseIterable, Identifiable {
    case ippakuSuisei = 1       // 一白水星
    case jikokuDosei = 2        // 二黒土星
    case sanpekiMokusei = 3     // 三碧木星
    case shirokuMokusei = 4     // 四緑木星
    case goouDosei = 5          // 五黄土星
    case roppakuKinsei = 6      // 六白金星
    case shichisekiKinsei = 7   // 七赤金星
    case happakuDosei = 8       // 八白土星
    case kyushiKasei = 9        // 九紫火星

    var id: Int { rawValue }

    // MARK: - Basic Properties

    var japaneseName: String {
        switch self {
        case .ippakuSuisei:      return "一白水星"
        case .jikokuDosei:       return "二黒土星"
        case .sanpekiMokusei:    return "三碧木星"
        case .shirokuMokusei:    return "四緑木星"
        case .goouDosei:         return "五黄土星"
        case .roppakuKinsei:     return "六白金星"
        case .shichisekiKinsei:  return "七赤金星"
        case .happakuDosei:      return "八白土星"
        case .kyushiKasei:       return "九紫火星"
        }
    }

    var shortName: String {
        switch self {
        case .ippakuSuisei:      return "一白"
        case .jikokuDosei:       return "二黒"
        case .sanpekiMokusei:    return "三碧"
        case .shirokuMokusei:    return "四緑"
        case .goouDosei:         return "五黄"
        case .roppakuKinsei:     return "六白"
        case .shichisekiKinsei:  return "七赤"
        case .happakuDosei:      return "八白"
        case .kyushiKasei:       return "九紫"
        }
    }

    // MARK: - Five Elements (五行)

    var element: String {
        switch self {
        case .ippakuSuisei:                          return "水"
        case .jikokuDosei, .goouDosei, .happakuDosei: return "土"
        case .sanpekiMokusei, .shirokuMokusei:        return "木"
        case .roppakuKinsei, .shichisekiKinsei:       return "金"
        case .kyushiKasei:                            return "火"
        }
    }

    var elementDescription: String {
        switch element {
        case "水": return "水は流れるように柔軟に適応する力。知恵と交際の象徴"
        case "土": return "土は万物を育む大地の力。安定と包容の象徴"
        case "木": return "木は上へ伸びる成長の力。発展と生命力の象徴"
        case "金": return "金は収斂し結実する力。実りと決断の象徴"
        case "火": return "火は明るく照らす知の力。華やかさと明晰さの象徴"
        default:   return ""
        }
    }

    // MARK: - Direction & Color

    var color: String {
        switch self {
        case .ippakuSuisei:      return "白"
        case .jikokuDosei:       return "黒"
        case .sanpekiMokusei:    return "碧（青緑）"
        case .shirokuMokusei:    return "緑"
        case .goouDosei:         return "黄"
        case .roppakuKinsei:     return "白（銀）"
        case .shichisekiKinsei:  return "赤"
        case .happakuDosei:      return "白（山）"
        case .kyushiKasei:       return "紫"
        }
    }

    /// 後天定位（本来の定位置の方角）
    var direction: String {
        switch self {
        case .ippakuSuisei:      return "北"
        case .jikokuDosei:       return "南西"
        case .sanpekiMokusei:    return "東"
        case .shirokuMokusei:    return "南東"
        case .goouDosei:         return "中央"
        case .roppakuKinsei:     return "北西"
        case .shichisekiKinsei:  return "西"
        case .happakuDosei:      return "北東"
        case .kyushiKasei:       return "南"
        }
    }

    // MARK: - Personality (詳細)

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

    /// 詳細な性格解説
    var detailedPersonality: String {
        switch self {
        case .ippakuSuisei:
            return "水のように形を変えながらも本質は変わらない方。一見おとなしく見えますが、内面には深い情熱と知恵を秘めています。人の気持ちを察する力に優れ、交際上手。困難な時も水のようにしなやかに乗り越えます"
        case .jikokuDosei:
            return "大地のように周囲を受け止め、育てる母なる星。地道な努力を惜しまず、コツコツと積み上げる堅実さが魅力。人からの信頼が厚く、組織の縁の下の力持ちとして欠かせない存在です"
        case .sanpekiMokusei:
            return "春の雷のように活気に満ちたエネルギーの持ち主。好奇心旺盛で新しいことへの挑戦を恐れません。声が大きく、周囲を元気づける力がありますが、短気になりやすい面も。若々しさを生涯保つ星です"
        case .shirokuMokusei:
            return "そよ風のように穏やかで、人の心に寄り添う力がある星。信用と人望に恵まれ、人間関係を通じて運が開けます。優柔不断に見えることもありますが、実は芯の強さを持っています"
        case .goouDosei:
            return "九星の中心に位置する帝王の星。強い意志力と統率力で周囲を動かします。自分が中心となって物事を回す力がありますが、横暴にならないよう注意。人を従えるより、人望を集めるリーダーを目指すと大成します"
        case .roppakuKinsei:
            return "天を象徴する気高い星。完璧主義で品格を重んじ、常に高い理想を掲げます。リーダーシップと決断力に優れますが、プライドが高く頑固な面も。晩年運が強く、年齢を重ねるほど輝きを増します"
        case .shichisekiKinsei:
            return "秋の実りと喜びを象徴する楽天的な星。話術に優れ、社交的で人を楽しませる才能があります。美食・美酒を愛し人生を楽しむ一方、金銭面での浪費には注意。口の達者さを活かせる仕事で開運"
        case .happakuDosei:
            return "山のように動じない安定感と、変化の予兆を感じ取る敏感さを併せ持つ星。ひとつの時代の終わりと始まりを司り、変革期に強い力を発揮します。蓄財運に恵まれ、不動産との縁が深い方です"
        case .kyushiKasei:
            return "太陽のように明るく輝く知性と美の星。頭脳明晰で芸術的センスに優れ、華やかな世界で力を発揮します。二面性を持ち、表と裏の顔が大きく異なることも。名誉運が強く、社会的地位を得やすい方です"
        }
    }

    // MARK: - Love & Work Tendencies

    var loveTendency: String {
        switch self {
        case .ippakuSuisei:      return "包容力がありモテるが、流されやすい面も。深い信頼関係を築くことが鍵"
        case .jikokuDosei:       return "献身的で家庭的。相手を支える愛情だが、自分の気持ちを抑えすぎないこと"
        case .sanpekiMokusei:    return "情熱的で積極的。恋に落ちるのは早いが、持続力を意識すると吉"
        case .shirokuMokusei:    return "穏やかで優しい恋愛。縁を大切にし、人の紹介から良縁に恵まれやすい"
        case .goouDosei:         return "強い魅力で相手を惹きつける。主導権を握りたいが、相手を尊重する姿勢が開運"
        case .roppakuKinsei:     return "理想が高く妥協しない。晩婚の傾向だが、見つけた相手とは深い絆で結ばれる"
        case .shichisekiKinsei:  return "華やかな恋愛を好む。楽しさの中にも誠実さを忘れなければ良縁が続く"
        case .happakuDosei:      return "慎重だが一途。時間をかけて信頼を築く関係が合う。不動産購入がきっかけの出会いも"
        case .kyushiKasei:       return "華やかで情熱的。二つの恋に揺れることも。直感を信じつつ冷静さも保って"
        }
    }

    var workTendency: String {
        switch self {
        case .ippakuSuisei:      return "企画・コンサル・水商売・流通業に適性。柔軟な対応力が武器"
        case .jikokuDosei:       return "農業・不動産・介護・教育に適性。地道な仕事で信頼を積む"
        case .sanpekiMokusei:    return "音楽・IT・電機・スポーツに適性。新しい分野の開拓者"
        case .shirokuMokusei:    return "貿易・旅行・通信・ファッションに適性。人脈が財産になる"
        case .goouDosei:         return "経営・政治・金融に適性。トップに立つ器だが、独善を避けること"
        case .roppakuKinsei:     return "官公庁・法律・宝石・自動車に適性。品格を活かした仕事"
        case .shichisekiKinsei:  return "飲食・芸能・金融・弁護に適性。話術と社交性が最大の武器"
        case .happakuDosei:      return "不動産・建築・山岳・宗教に適性。蓄積と変革の両面を活かす"
        case .kyushiKasei:       return "芸術・学問・美容・出版に適性。知性と美意識を活かす仕事"
        }
    }

    // MARK: - Compatibility (五行相生相剋)

    /// 相生（生む関係）の星
    var generatingStars: [NineStarKiStar] {
        switch element {
        case "水": return Self.allCases.filter { $0.element == "木" } // 水生木
        case "木": return Self.allCases.filter { $0.element == "火" } // 木生火
        case "火": return Self.allCases.filter { $0.element == "土" } // 火生土
        case "土": return Self.allCases.filter { $0.element == "金" } // 土生金
        case "金": return Self.allCases.filter { $0.element == "水" } // 金生水
        default:   return []
        }
    }

    /// 相生（生まれる関係）の星
    var generatedByStars: [NineStarKiStar] {
        switch element {
        case "水": return Self.allCases.filter { $0.element == "金" } // 金生水
        case "木": return Self.allCases.filter { $0.element == "水" } // 水生木
        case "火": return Self.allCases.filter { $0.element == "木" } // 木生火
        case "土": return Self.allCases.filter { $0.element == "火" } // 火生土
        case "金": return Self.allCases.filter { $0.element == "土" } // 土生金
        default:   return []
        }
    }

    /// 相剋（剋す関係）の星
    var controllingStars: [NineStarKiStar] {
        switch element {
        case "水": return Self.allCases.filter { $0.element == "火" } // 水剋火
        case "木": return Self.allCases.filter { $0.element == "土" } // 木剋土
        case "火": return Self.allCases.filter { $0.element == "金" } // 火剋金
        case "土": return Self.allCases.filter { $0.element == "水" } // 土剋水
        case "金": return Self.allCases.filter { $0.element == "木" } // 金剋木
        default:   return []
        }
    }

    /// 九宮格の定位置番号（後天定位盤）
    var gridPosition: Int { rawValue }
}

// MARK: - Five Element Relationship

/// 五行の関係性
enum FiveElementRelation: String {
    case same       = "比和"     // 同じ五行
    case generating = "相生"     // 生む
    case generated  = "相生（受）" // 生まれる
    case controlling = "相剋"    // 剋す
    case controlled  = "相剋（受）" // 剋される

    var description: String {
        switch self {
        case .same:        return "同じ気が共鳴し、安定した関係。穏やかな運気の日"
        case .generating:  return "あなたの気が相手を生む関係。エネルギーを与える立場で、周囲を活かせる日"
        case .generated:   return "相手の気があなたを育む関係。周囲からの支援に恵まれやすい日"
        case .controlling: return "あなたの気が優位な関係。主導的に動くと成果が出やすい日"
        case .controlled:  return "相手の気が優位な関係。慎重に行動し、無理をしない方が吉の日"
        }
    }

    var score: Int {
        switch self {
        case .same:        return 3
        case .generating:  return 4
        case .generated:   return 5 // Most auspicious
        case .controlling: return 2
        case .controlled:  return 1
        }
    }
}

// MARK: - Enhanced Profile

/// A user's Nine Star Ki profile with birth year and month stars.
struct NineStarKiProfile: Codable {
    let honmeisei: NineStarKiStar   // 本命星 (birth year star)
    let getsumeisei: NineStarKiStar // 月命星 (birth month star)
    let birthYear: Int

    var japaneseSummary: String {
        return "\(honmeisei.japaneseName)・\(getsumeisei.japaneseName)"
    }
}

// MARK: - Daily Ki Energy

/// 今日の九星気学エネルギー
struct NineStarKiDailyEnergy {
    let dailyStar: NineStarKiStar               // 日命星
    let monthlyStar: NineStarKiStar              // 月命星（今月）
    let yearlyStar: NineStarKiStar               // 年命星（今年）
    let honmeiseiRelation: FiveElementRelation   // 本命星との関係
    let auspiciousDirections: [String]           // 吉方位
    let inauspiciousDirections: [String]         // 凶方位
    let overallScore: Int                        // 1-5
    let advice: String                           // 今日のアドバイス
}
