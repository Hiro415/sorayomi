import Foundation

/// The six-day cycle from the traditional Japanese calendar (六曜).
enum Rokuyo: Int, Codable, CaseIterable, Identifiable {
    case taian = 0      // 大安
    case shakkou = 1    // 赤口
    case senshou = 2    // 先勝
    case tomobiki = 3   // 友引
    case senbu = 4      // 先負
    case butsumetsu = 5 // 仏滅

    var id: Int { rawValue }

    var japaneseName: String {
        switch self {
        case .taian:      return "大安"
        case .shakkou:    return "赤口"
        case .senshou:    return "先勝"
        case .tomobiki:   return "友引"
        case .senbu:      return "先負"
        case .butsumetsu: return "仏滅"
        }
    }

    var reading: String {
        switch self {
        case .taian:      return "たいあん"
        case .shakkou:    return "しゃっこう"
        case .senshou:    return "せんしょう"
        case .tomobiki:   return "ともびき"
        case .senbu:      return "せんぶ"
        case .butsumetsu: return "ぶつめつ"
        }
    }

    var briefGuidance: String {
        switch self {
        case .taian:
            return "万事において吉とされる日。新しいことを始めるのに良い日です"
        case .shakkou:
            return "正午のみ吉。午前と午後は控えめに過ごすと良いでしょう"
        case .senshou:
            return "午前中が吉。急ぎの用事は午前中に済ませると良いでしょう"
        case .tomobiki:
            return "朝と夕方が吉。昼は控えめに。お祝い事には良い日です"
        case .senbu:
            return "午後が吉。午前中は静かに過ごし、午後から活動すると良いでしょう"
        case .butsumetsu:
            return "控えめに過ごす日。内省や準備の時間として活用しましょう"
        }
    }

    var luckyTimeOfDay: String {
        switch self {
        case .taian:      return "終日"
        case .shakkou:    return "正午（11:00-13:00）"
        case .senshou:    return "午前中"
        case .tomobiki:   return "朝・夕方"
        case .senbu:      return "午後"
        case .butsumetsu: return "特になし（静かに過ごす日）"
        }
    }

    var isAuspicious: Bool {
        switch self {
        case .taian, .tomobiki, .senshou: return true
        case .shakkou, .senbu, .butsumetsu: return false
        }
    }

    /// Overall auspiciousness score (1-5 stars).
    var auspiciousnessScore: Int {
        switch self {
        case .taian:      return 5
        case .tomobiki:   return 4
        case .senshou:    return 3
        case .senbu:      return 3
        case .shakkou:    return 2
        case .butsumetsu: return 1
        }
    }

    // MARK: - 時間帯別の吉凶（伝統的な六曜の時刻割り）

    /// 時間帯別の吉凶スコア (1=凶, 2=小凶, 3=平, 4=小吉, 5=吉)
    /// 伝統的な六曜の暦注に基づく
    var hourlyLuck: [(period: String, hours: String, score: Int)] {
        switch self {
        case .taian:
            return [
                ("早朝", "5:00-8:00", 5),
                ("午前", "8:00-12:00", 5),
                ("昼", "12:00-14:00", 5),
                ("午後", "14:00-17:00", 5),
                ("夕方", "17:00-19:00", 5),
                ("夜", "19:00-23:00", 4)
            ]
        case .shakkou:
            return [
                ("早朝", "5:00-8:00", 1),
                ("午前", "8:00-11:00", 1),
                ("昼", "11:00-13:00", 5),
                ("午後", "13:00-17:00", 1),
                ("夕方", "17:00-19:00", 1),
                ("夜", "19:00-23:00", 1)
            ]
        case .senshou:
            return [
                ("早朝", "5:00-8:00", 5),
                ("午前", "8:00-12:00", 5),
                ("昼", "12:00-14:00", 3),
                ("午後", "14:00-17:00", 2),
                ("夕方", "17:00-19:00", 2),
                ("夜", "19:00-23:00", 2)
            ]
        case .tomobiki:
            return [
                ("早朝", "5:00-8:00", 4),
                ("午前", "8:00-11:00", 4),
                ("昼", "11:00-13:00", 1),
                ("午後", "13:00-17:00", 4),
                ("夕方", "17:00-19:00", 5),
                ("夜", "19:00-23:00", 4)
            ]
        case .senbu:
            return [
                ("早朝", "5:00-8:00", 2),
                ("午前", "8:00-12:00", 2),
                ("昼", "12:00-14:00", 3),
                ("午後", "14:00-17:00", 5),
                ("夕方", "17:00-19:00", 5),
                ("夜", "19:00-23:00", 4)
            ]
        case .butsumetsu:
            return [
                ("早朝", "5:00-8:00", 1),
                ("午前", "8:00-12:00", 1),
                ("昼", "12:00-14:00", 1),
                ("午後", "14:00-17:00", 1),
                ("夕方", "17:00-19:00", 2),
                ("夜", "19:00-23:00", 2)
            ]
        }
    }

    /// 現在時刻の吉凶
    var currentTimeLuck: (period: String, score: Int) {
        let hour = Calendar.current.component(.hour, from: Date())
        let slot = hourlyLuck.first { entry in
            let parts = entry.hours.split(separator: "-")
            guard parts.count == 2,
                  let startHour = Int(parts[0].prefix(while: { $0 != ":" })),
                  let endHour = Int(parts[1].prefix(while: { $0 != ":" })) else { return false }
            return hour >= startHour && hour < endHour
        }
        return slot.map { ($0.period, $0.score) } ?? ("不明", 3)
    }

    // MARK: - 行事の適否（伝統的な六曜の行事判断）

    struct EventSuitability: Identifiable {
        let id = UUID()
        let event: String
        let suitability: Int  // 1=避けるべき, 2=やや不向き, 3=可, 4=良い, 5=最適
        let note: String
    }

    /// 各行事の適否一覧
    var eventSuitabilities: [EventSuitability] {
        switch self {
        case .taian:
            return [
                EventSuitability(event: "結婚・婚姻届", suitability: 5, note: "最も適した日。万事大吉"),
                EventSuitability(event: "入籍", suitability: 5, note: "終日吉。安心して届出を"),
                EventSuitability(event: "開業・起業", suitability: 5, note: "新しい門出に最良の日"),
                EventSuitability(event: "引越し", suitability: 5, note: "移転に最適な日取り"),
                EventSuitability(event: "契約・署名", suitability: 5, note: "重要な契約に吉"),
                EventSuitability(event: "旅行・出発", suitability: 5, note: "旅立ちに良い日"),
                EventSuitability(event: "お見舞い", suitability: 4, note: "問題なし"),
                EventSuitability(event: "葬儀・法事", suitability: 3, note: "可。特に問題なし"),
                EventSuitability(event: "納車", suitability: 5, note: "最良の日取り"),
                EventSuitability(event: "財布の使い始め", suitability: 5, note: "金運アップに最適"),
            ]
        case .shakkou:
            return [
                EventSuitability(event: "結婚・婚姻届", suitability: 2, note: "正午なら可。他の時間帯は避けるのが無難"),
                EventSuitability(event: "入籍", suitability: 2, note: "11:00-13:00の間なら吉"),
                EventSuitability(event: "開業・起業", suitability: 2, note: "正午前後のみ可"),
                EventSuitability(event: "引越し", suitability: 2, note: "日中の短時間なら可"),
                EventSuitability(event: "契約・署名", suitability: 2, note: "正午に行うなら問題なし"),
                EventSuitability(event: "旅行・出発", suitability: 2, note: "昼発なら吉"),
                EventSuitability(event: "お見舞い", suitability: 1, note: "避けるべき。「赤」は血を連想させるため"),
                EventSuitability(event: "葬儀・法事", suitability: 3, note: "問題なし"),
                EventSuitability(event: "納車", suitability: 2, note: "正午前後なら可"),
                EventSuitability(event: "財布の使い始め", suitability: 1, note: "避けた方が良い"),
            ]
        case .senshou:
            return [
                EventSuitability(event: "結婚・婚姻届", suitability: 4, note: "午前中に届出すれば吉"),
                EventSuitability(event: "入籍", suitability: 4, note: "午前中がベスト"),
                EventSuitability(event: "開業・起業", suitability: 4, note: "朝イチの行動が吉"),
                EventSuitability(event: "引越し", suitability: 4, note: "午前中に作業開始が◎"),
                EventSuitability(event: "契約・署名", suitability: 4, note: "午前中の署名が吉"),
                EventSuitability(event: "旅行・出発", suitability: 4, note: "早朝出発が最良"),
                EventSuitability(event: "お見舞い", suitability: 3, note: "午前中なら良い"),
                EventSuitability(event: "葬儀・法事", suitability: 3, note: "可。時間帯を問わない"),
                EventSuitability(event: "納車", suitability: 4, note: "午前中の受け取りが吉"),
                EventSuitability(event: "財布の使い始め", suitability: 4, note: "午前中に使い始めると吉"),
            ]
        case .tomobiki:
            return [
                EventSuitability(event: "結婚・婚姻届", suitability: 4, note: "「友を引く」でお祝い事に良い日"),
                EventSuitability(event: "入籍", suitability: 4, note: "幸せのおすそ分けの意味で吉"),
                EventSuitability(event: "開業・起業", suitability: 4, note: "仲間・顧客を引き寄せる意味で吉"),
                EventSuitability(event: "引越し", suitability: 3, note: "昼を避ければ良い"),
                EventSuitability(event: "契約・署名", suitability: 4, note: "朝か夕方が最適"),
                EventSuitability(event: "旅行・出発", suitability: 4, note: "良い出会いを引き寄せる"),
                EventSuitability(event: "お見舞い", suitability: 2, note: "「病を引く」と解釈されるため避けるのが無難"),
                EventSuitability(event: "葬儀・法事", suitability: 1, note: "「死を友に引く」として最も避けるべき日"),
                EventSuitability(event: "納車", suitability: 4, note: "良い日取り"),
                EventSuitability(event: "財布の使い始め", suitability: 3, note: "問題なし"),
            ]
        case .senbu:
            return [
                EventSuitability(event: "結婚・婚姻届", suitability: 3, note: "午後からなら吉"),
                EventSuitability(event: "入籍", suitability: 3, note: "午後に届出を"),
                EventSuitability(event: "開業・起業", suitability: 3, note: "午後の開業が吉"),
                EventSuitability(event: "引越し", suitability: 3, note: "午後から作業を"),
                EventSuitability(event: "契約・署名", suitability: 3, note: "午後の調印が良い"),
                EventSuitability(event: "旅行・出発", suitability: 3, note: "午後出発が安心"),
                EventSuitability(event: "お見舞い", suitability: 3, note: "午後なら問題なし"),
                EventSuitability(event: "葬儀・法事", suitability: 4, note: "問題なし。静かな日柄が合う"),
                EventSuitability(event: "納車", suitability: 3, note: "午後の受け取りが良い"),
                EventSuitability(event: "財布の使い始め", suitability: 3, note: "午後から使い始めると吉"),
            ]
        case .butsumetsu:
            return [
                EventSuitability(event: "結婚・婚姻届", suitability: 1, note: "伝統的に最も避けるべき日"),
                EventSuitability(event: "入籍", suitability: 1, note: "避けるのが一般的"),
                EventSuitability(event: "開業・起業", suitability: 1, note: "新規事業の開始は避けるのが無難"),
                EventSuitability(event: "引越し", suitability: 2, note: "できれば避けたい日取り"),
                EventSuitability(event: "契約・署名", suitability: 2, note: "重要な契約は別の日に"),
                EventSuitability(event: "旅行・出発", suitability: 2, note: "出発は避けるのが無難"),
                EventSuitability(event: "お見舞い", suitability: 2, note: "避けた方が良い"),
                EventSuitability(event: "葬儀・法事", suitability: 5, note: "仏滅は元々「物滅」。物が滅し新たに始まる日。法事に最適"),
                EventSuitability(event: "納車", suitability: 1, note: "避けるのが一般的"),
                EventSuitability(event: "財布の使い始め", suitability: 1, note: "避けるべき日"),
            ]
        }
    }

    /// 指定イベントの適否を取得
    func suitability(for event: String) -> EventSuitability? {
        eventSuitabilities.first { $0.event.contains(event) }
    }

    // MARK: - 伝統的な詳細解説

    /// 六曜の由来・意味の詳細解説
    var detailedMeaning: String {
        switch self {
        case .taian:
            return "「大いに安し」の意。六曜の中で最も縁起の良い日とされ、結婚式・入籍・開業など人生の重要な門出に選ばれる。終日を通して吉であり、何事にも積極的に動いて良い一日。"
        case .shakkou:
            return "「赤舌日」に由来。陰陽道の赤舌神が支配する日で、正午（11時〜13時）のみ吉。「赤」が火事や血を連想させるため、慶事は避ける傾向がある。ただし正午の行動は吉。"
        case .senshou:
            return "「先んずれば即ち勝つ」の意。午前中に行動すれば万事うまくいくとされる。急ぎの用事、勝負事、訴訟は午前中が吉。午後は「負」に転じるため、大事な判断は午前に。"
        case .tomobiki:
            return "「友を引く」の意。朝夕は吉、昼は凶。慶事には「幸せを友に引く」として好まれるが、弔事は「死を友に引く」として忌避される。最も注意すべきは葬儀をこの日に行わないこと。"
        case .senbu:
            return "「先んずれば即ち負ける」の意。先勝の反対で、午前中は凶、午後からが吉。急いで動くと失敗しやすいため、慎重に構えて午後から行動するのが良い。控えめな姿勢が運を開く。"
        case .butsumetsu:
            return "元は「物滅」と書き、「物事が一旦滅び、新たに始まる」の意。六曜で最も凶とされるが、仏事（葬儀・法要）には逆に適するとされる。物事のリセット・浄化の日と捉える解釈もある。"
        }
    }

    /// 陰陽五行との対応
    var elementCorrespondence: String {
        switch self {
        case .taian:      return "土（安定・大地の力）"
        case .shakkou:    return "火（正午の太陽・浄化）"
        case .senshou:    return "木（朝の成長力・前進）"
        case .tomobiki:   return "金（人を引き寄せる力）"
        case .senbu:      return "水（午後の静寂・流れに任せる）"
        case .butsumetsu: return "無（滅び→再生のサイクル）"
        }
    }
}
