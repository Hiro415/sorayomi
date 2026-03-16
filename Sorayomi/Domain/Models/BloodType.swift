import Foundation

/// Japanese blood type classification with personality associations.
enum BloodType: String, Codable, CaseIterable, Identifiable {
    case a = "A"
    case b = "B"
    case o = "O"
    case ab = "AB"

    var id: String { rawValue }

    var japaneseName: String {
        return "\(rawValue)型"
    }

    var shortDescription: String {
        switch self {
        case .a:  return "几帳面で誠実"
        case .b:  return "自由奔放でマイペース"
        case .o:  return "おおらかでリーダー気質"
        case .ab: return "理知的で多面的"
        }
    }

    var loveTendency: String {
        switch self {
        case .a:  return "一途で慎重。信頼関係を大切にし、ゆっくり距離を縮めるタイプ"
        case .b:  return "自分の感覚を大事にする恋愛スタイル。好きになると一直線"
        case .o:  return "包容力があり、好きな人には惜しみなく尽くすタイプ"
        case .ab: return "独自の距離感を保ちつつ、知的なつながりを大切にするタイプ"
        }
    }

    var workTendency: String {
        switch self {
        case .a:  return "計画性が高く細部まで丁寧。チームの要になれる堅実派"
        case .b:  return "独創的なアイデアと集中力で突破口を開くクリエイター気質"
        case .o:  return "目標を定めたら一気に突き進む。統率力に優れたリーダー気質"
        case .ab: return "分析力と多角的視点で複雑な課題を整理できる参謀タイプ"
        }
    }

    var moneySense: String {
        switch self {
        case .a:  return "堅実で計画的。無駄遣いを嫌い、コツコツと着実に蓄える"
        case .b:  return "好きなことには惜しまないが、興味のないものには財布の紐が固い"
        case .o:  return "大きな買い物も決断が早い。稼ぐ力もあるが出費も大きくなりがち"
        case .ab: return "合理的な判断で無駄を省く。情報を集めてから慎重に使う"
        }
    }

    var healthTendency: String {
        switch self {
        case .a:  return "ストレスを溜め込みやすい。リラックスの時間を意識的に確保することが大切"
        case .b:  return "好きなことに没頭しすぎて不規則になりがち。生活リズムの安定がカギ"
        case .o:  return "体力に自信があるが過信は禁物。定期的な休息で長期的な健康を"
        case .ab: return "繊細な面があり環境変化に敏感。睡眠の質を高めることが重要"
        }
    }

    func seasonalTendency(for season: String) -> String {
        switch (self, season) {
        case (.a, "春"):  return "変化への適応が試される季節。計画を立てて一歩ずつ進むと吉"
        case (.a, "夏"):  return "人間関係が活発に。気配り上手な面が評価されやすい時期"
        case (.a, "秋"):  return "内省が深まる季節。自分を見つめ直すことで新たな発見が"
        case (.a, "冬"):  return "計画力が最も発揮される季節。来年への準備を丁寧に"
        case (.b, "春"):  return "新しいことへの好奇心が全開。直感を信じて動くと良い流れに"
        case (.b, "夏"):  return "エネルギーが最大化する季節。やりたいことに集中すると大きな成果"
        case (.b, "秋"):  return "クリエイティブな面が冴える。作品づくりや趣味に没頭すると吉"
        case (.b, "冬"):  return "マイペースが崩れやすい時期。自分のリズムを大切に"
        case (.o, "春"):  return "リーダーシップを発揮する好機。新しいプロジェクトの立ち上げに最適"
        case (.o, "夏"):  return "行動力が冴え渡る。大きな決断にも向いている時期"
        case (.o, "秋"):  return "周囲への包容力を見せる季節。感謝を伝えると運気上昇"
        case (.o, "冬"):  return "エネルギーの充電期。ゆったり過ごすことで春に大きく飛躍"
        case (.ab, "春"): return "多面的な才能が花開く季節。新しい人脈が広がりやすい"
        case (.ab, "夏"): return "知的活動が充実。学びや情報収集が成果につながる"
        case (.ab, "秋"): return "分析力が最大限に発揮される。仕事面での評価が高まりやすい"
        case (.ab, "冬"): return "感性が研ぎ澄まされる時期。芸術や文化に触れると吉"
        default:          return "自分の型の長所を活かして過ごしましょう"
        }
    }
}
