import Foundation

/// Numerology profile calculated from a user's birthday.
/// Includes Life Path, Birthday, Expression-analog, and full personal cycle numbers,
/// plus Pinnacle/Challenge life stages and rich archetype data.
struct NumerologyProfile: Codable {
    let lifePathNumber: Int
    let birthdayNumber: Int
    let personalYearNumber: Int
    let personalMonthNumber: Int
    let personalDayNumber: Int

    /// Japanese description for each Life Path number.
    var lifePathDescription: String {
        Self.description(for: lifePathNumber)
    }

    var personalDayDescription: String {
        Self.dayGuidance(for: personalDayNumber)
    }

    // MARK: - Number Archetype

    /// Deep archetype data for each numerology number.
    struct NumberArchetype {
        let number: Int
        let japaneseName: String
        let title: String
        let keyword: String
        let element: NumerologyElement
        let polarity: Polarity
        let ruling: String          // 支配星（占星術対応）
        let colorHex: String        // テーマカラー
        let gemstone: String        // パワーストーン
        let personality: String     // 80-100字の性格概要
        let loveTendency: String
        let workTendency: String
        let healthAdvice: String
        let shadowSide: String      // 裏の顔・弱点
        let luckyDays: [Int]        // 相性の良い日
        let compatibleNumbers: [Int]
        let challengingNumbers: [Int]
    }

    enum NumerologyElement: String, Codable {
        case fire = "火"
        case earth = "地"
        case air = "風"
        case water = "水"

        var symbolName: String {
            switch self {
            case .fire: return "flame.fill"
            case .earth: return "mountain.2.fill"
            case .air: return "wind"
            case .water: return "drop.fill"
            }
        }

        var gradientColors: [String] {
            switch self {
            case .fire:  return ["#FF6B35", "#FF2D2D"]
            case .earth: return ["#8B6914", "#4A7C59"]
            case .air:   return ["#7EC8E3", "#A78BFA"]
            case .water: return ["#2563EB", "#06B6D4"]
            }
        }
    }

    enum Polarity: String, Codable {
        case yang = "陽"
        case yin = "陰"
    }

    // MARK: - Personal Year Theme

    struct PersonalYearTheme {
        let yearNumber: Int
        let theme: String
        let season: String       // 人生のどの季節か
        let keyword: String
        let overview: String     // 年全体の概要
        let loveAdvice: String
        let workAdvice: String
        let bestMonths: [Int]    // 好調な月
        let cautionMonths: [Int] // 注意が必要な月
    }

    // MARK: - Pinnacle & Challenge

    struct LifeStage: Codable {
        let name: String         // 第一転換期 etc.
        let number: Int
        let ageRange: String     // "0-27" etc.
        let description: String
    }

    // MARK: - Static Data

    static func archetype(for number: Int) -> NumberArchetype {
        switch number {
        case 1: return NumberArchetype(
            number: 1,
            japaneseName: "一",
            title: "開拓者",
            keyword: "始まり・独立・意志",
            element: .fire,
            polarity: .yang,
            ruling: "太陽",
            colorHex: "#FF6B35",
            gemstone: "ルビー",
            personality: "独立心に満ちたパイオニア。新しい道を切り開く勇気と決断力を備え、自分の信念を貫く強さがあります。困難にぶつかっても折れない意志の力が最大の武器です",
            loveTendency: "リードするタイプ。対等な関係を築ける相手を求め、自分のペースを大切にします。情熱的ですが束縛を嫌います",
            workTendency: "起業家タイプ。自ら立案して実行する環境で輝き、指示待ちの立場には向きません。先見性を活かした仕事が天職",
            healthAdvice: "頭痛・目の疲れに注意。エネルギーを使いすぎる傾向があり、意識的な休息が必要です",
            shadowSide: "自己中心的・孤立しやすい。他者の意見を聞く姿勢が成長の鍵",
            luckyDays: [1, 10, 19, 28],
            compatibleNumbers: [1, 3, 5],
            challengingNumbers: [4, 8]
        )
        case 2: return NumberArchetype(
            number: 2,
            japaneseName: "二",
            title: "調停者",
            keyword: "協調・直感・受容",
            element: .water,
            polarity: .yin,
            ruling: "月",
            colorHex: "#7EC8E3",
            gemstone: "ムーンストーン",
            personality: "繊細な感受性と共感力を持つ調和の人。場の空気を読み、人と人を繋ぐ架け橋の役割を自然に果たします。静かな強さと深い直感力が隠れた才能です",
            loveTendency: "献身的で気配り上手。相手を支える関係に喜びを感じますが、自分の気持ちを抑えすぎる傾向も。言葉で伝える勇気が大切",
            workTendency: "サポーターとして真価を発揮。チームの潤滑油となり、調整・交渉の場面で力を発揮します。一人作業より協働向き",
            healthAdvice: "ストレスを溜め込みやすい体質。胃腸の不調が出やすいので、感情のデトックスを意識して",
            shadowSide: "依存的・優柔不断。自分軸を持つことが課題",
            luckyDays: [2, 11, 20, 29],
            compatibleNumbers: [2, 4, 6],
            challengingNumbers: [5, 9]
        )
        case 3: return NumberArchetype(
            number: 3,
            japaneseName: "三",
            title: "表現者",
            keyword: "創造・喜び・自己表現",
            element: .fire,
            polarity: .yang,
            ruling: "木星",
            colorHex: "#F59E0B",
            gemstone: "シトリン",
            personality: "豊かな想像力と表現力に恵まれた創造の人。言葉、芸術、ユーモアで周囲を照らし、人生を楽しむことの天才。多才で好奇心旺盛",
            loveTendency: "楽しさと笑いを重視。一緒にいて楽しい相手に惹かれます。飽きっぽさが弱点になることも。深い絆を意識して",
            workTendency: "クリエイティブ分野の才能。デザイン、執筆、エンタメなど表現の場で輝きます。ルーティンワークはモチベーション低下に注意",
            healthAdvice: "喉・気管支に注意。エネルギーの浮き沈みが激しいので、規則正しい生活リズムが肝心",
            shadowSide: "散漫・表面的。集中力を養い、一つのことをやり遂げる経験が成長に繋がります",
            luckyDays: [3, 12, 21, 30],
            compatibleNumbers: [1, 3, 5, 9],
            challengingNumbers: [4, 7]
        )
        case 4: return NumberArchetype(
            number: 4,
            japaneseName: "四",
            title: "建設者",
            keyword: "安定・秩序・勤勉",
            element: .earth,
            polarity: .yin,
            ruling: "天王星",
            colorHex: "#4A7C59",
            gemstone: "エメラルド",
            personality: "堅実さと忍耐力を持つ基盤の人。物事を一つずつ着実に積み上げる力があり、約束を守り信頼される存在。実務能力は数秘最強クラス",
            loveTendency: "安定した関係を好み、信頼できるパートナーを求めます。表現は不器用でも誠実さは折り紙付き。安心感が最大の魅力",
            workTendency: "組織の屋台骨タイプ。管理、建築、財務など形あるものを作る仕事で才能を発揮。確実な成果を積み上げます",
            healthAdvice: "骨・関節・腰に注意。体が固くなりやすいので、柔軟運動とリラクゼーションを",
            shadowSide: "頑固・融通が利かない。変化を受け入れる柔軟さが人生を広げます",
            luckyDays: [4, 13, 22, 31],
            compatibleNumbers: [2, 4, 6, 8],
            challengingNumbers: [1, 3, 5]
        )
        case 5: return NumberArchetype(
            number: 5,
            japaneseName: "五",
            title: "冒険者",
            keyword: "自由・変化・体験",
            element: .air,
            polarity: .yang,
            ruling: "水星",
            colorHex: "#06B6D4",
            gemstone: "アクアマリン",
            personality: "自由と変化を愛する冒険の人。五感が鋭く、多様な体験を通じて成長するタイプ。適応力が高く、どんな環境でも生きる知恵を持っています",
            loveTendency: "刺激と新鮮さを求める恋愛スタイル。束縛を嫌い、お互いの自由を尊重できる関係を好みます。マンネリが最大の敵",
            workTendency: "変化のある環境が適所。旅行、営業、メディア、コンサルなど動きのある仕事で才能開花。デスクワークのみは苦手",
            healthAdvice: "神経系の疲労に注意。刺激の取りすぎで燃え尽きやすいので、五感を休める静の時間を",
            shadowSide: "落ち着きがない・無責任。コミットメントを学ぶことが人生のテーマ",
            luckyDays: [5, 14, 23],
            compatibleNumbers: [1, 3, 5, 7],
            challengingNumbers: [2, 4]
        )
        case 6: return NumberArchetype(
            number: 6,
            japaneseName: "六",
            title: "守護者",
            keyword: "愛・責任・調和",
            element: .earth,
            polarity: .yin,
            ruling: "金星",
            colorHex: "#EC4899",
            gemstone: "ローズクォーツ",
            personality: "深い愛情と責任感を持つ守護の人。家族やコミュニティの中心となり、美と調和を大切にします。面倒見が良く、人から頼られる存在",
            loveTendency: "献身的な愛を注ぐタイプ。理想のパートナーシップを追求し、家庭を大切にします。相手に尽くしすぎて疲れることも",
            workTendency: "教育、医療、カウンセリング、デザインなど人の役に立つ仕事が天職。美的センスも高く、芸術分野でも成功の可能性",
            healthAdvice: "心臓・循環器に注意。他者のために頑張りすぎて自分を犠牲にしやすいので、セルフケアを忘れずに",
            shadowSide: "過干渉・自己犠牲。相手の自立を信じて任せる勇気が必要",
            luckyDays: [6, 15, 24],
            compatibleNumbers: [2, 4, 6, 9],
            challengingNumbers: [1, 5]
        )
        case 7: return NumberArchetype(
            number: 7,
            japaneseName: "七",
            title: "探究者",
            keyword: "知恵・直感・内省",
            element: .water,
            polarity: .yang,
            ruling: "海王星",
            colorHex: "#6366F1",
            gemstone: "アメジスト",
            personality: "深い知性と神秘的な直感を持つ探究の人。真理を追い求め、表面的な答えに満足しない哲学者肌。孤独を恐れず、内なる声に従う強さがあります",
            loveTendency: "精神的な繋がりを重視。心を許すまでに時間がかかりますが、信頼した相手には深い愛情を見せます。一人の時間も大切",
            workTendency: "研究、分析、IT、スピリチュアル、執筆など深く掘り下げる仕事に適性。専門性を極めることで大きな成功を得ます",
            healthAdvice: "神経系・睡眠の質に注意。考えすぎて眠れなくなる傾向あり。瞑想や自然の中での時間が回復に効果的",
            shadowSide: "引きこもり・猜疑心。信頼して心を開くことが人生の課題",
            luckyDays: [7, 16, 25],
            compatibleNumbers: [3, 5, 7],
            challengingNumbers: [2, 8]
        )
        case 8: return NumberArchetype(
            number: 8,
            japaneseName: "八",
            title: "実現者",
            keyword: "達成・豊穣・力",
            element: .earth,
            polarity: .yin,
            ruling: "土星",
            colorHex: "#854D0E",
            gemstone: "タイガーアイ",
            personality: "強い実行力と豊かさを引き寄せる力を持つ実現の人。目標に向かって突き進む粘り強さがあり、物質的な成功を手にする才能に恵まれています",
            loveTendency: "力強く頼れるパートナーを求める傾向。仕事と恋愛のバランスが課題。成功を分かち合える対等な関係が理想",
            workTendency: "経営、金融、不動産、法律など権限と責任のある仕事で真価を発揮。リーダーシップと実務能力の両方を持つ稀有な存在",
            healthAdvice: "血圧・心臓に注意。プレッシャーを背負いすぎる傾向。定期的なリフレッシュと運動が不可欠",
            shadowSide: "支配的・物質主義。精神的な豊かさにも目を向けることで真の成功に近づきます",
            luckyDays: [8, 17, 26],
            compatibleNumbers: [2, 4, 6, 8],
            challengingNumbers: [1, 7]
        )
        case 9: return NumberArchetype(
            number: 9,
            japaneseName: "九",
            title: "賢者",
            keyword: "完成・博愛・叡智",
            element: .fire,
            polarity: .yang,
            ruling: "火星",
            colorHex: "#DC2626",
            gemstone: "ガーネット",
            personality: "全ての数字のエネルギーを内包する完成の人。広い視野と深い共感力を持ち、人類全体への愛を感じる理想主義者。手放すことで新しいものを得る循環の力",
            loveTendency: "理想が高く、魂レベルでの繋がりを求めます。過去の恋愛から学ぶ力が強く、成熟した愛の形を追求。執着を手放すことで本当の愛に出会えます",
            workTendency: "教育、芸術、社会貢献、国際関係など広い視野が活きる仕事が天職。自分のためだけでなく世界のために働くとき最大の力を発揮",
            healthAdvice: "免疫系・アレルギーに注意。感情を溜め込みやすいので、表現の場（芸術・音楽）でのデトックスが効果的",
            shadowSide: "自己犠牲・現実逃避。夢と現実のバランスを取ることが課題",
            luckyDays: [9, 18, 27],
            compatibleNumbers: [3, 6, 9],
            challengingNumbers: [4, 8]
        )
        case 11: return NumberArchetype(
            number: 11,
            japaneseName: "十一",
            title: "霊感者",
            keyword: "閃き・啓示・使命",
            element: .air,
            polarity: .yang,
            ruling: "天王星",
            colorHex: "#A78BFA",
            gemstone: "ラブラドライト",
            personality: "マスターナンバー11は霊感と閃きの持ち主。常人には見えないものを感じ取り、人々にインスピレーションを与える使命を持っています。2の協調性を高次で発揮する存在",
            loveTendency: "魂の繋がりを感じられる相手に強く惹かれます。ツインソウル的な関係を求め、精神的な深さのない関係には満足できません",
            workTendency: "カウンセラー、アーティスト、スピリチュアルリーダー、発明家など閃きを形にする仕事で特別な才能を発揮",
            healthAdvice: "神経が繊細で過敏になりやすい。エネルギーワーク、グラウンディング、十分な睡眠が不可欠",
            shadowSide: "空想癖・現実逃避。理想を地上に降ろす力を養うことが使命の完成に繋がります",
            luckyDays: [2, 11, 20, 29],
            compatibleNumbers: [2, 4, 6, 11, 22],
            challengingNumbers: [5, 8]
        )
        case 22: return NumberArchetype(
            number: 22,
            japaneseName: "二十二",
            title: "建築家",
            keyword: "壮大・実現・変革",
            element: .earth,
            polarity: .yin,
            ruling: "冥王星",
            colorHex: "#B45309",
            gemstone: "ラピスラズリ",
            personality: "マスターナンバー22は壮大なビジョンを現実にする力の持ち主。4の実務能力を宇宙規模で発揮し、世界を変えるプロジェクトを完遂する才能があります",
            loveTendency: "人生のパートナーを重視。共にビジョンを実現できる相手を求め、関係も「建設」していくタイプ。忍耐強い愛",
            workTendency: "大規模プロジェクト、組織改革、社会インフラ構築など壮大な仕事で最大の力を発揮。小さな仕事ではエネルギーを持て余します",
            healthAdvice: "プレッシャーによる疲労に注意。大きな責任を背負いすぎず、定期的な完全オフが必要",
            shadowSide: "完璧主義・プレッシャーに潰される危険。自分も人間であることを忘れないで",
            luckyDays: [4, 13, 22, 31],
            compatibleNumbers: [4, 6, 8, 11, 22, 33],
            challengingNumbers: [3, 5]
        )
        case 33: return NumberArchetype(
            number: 33,
            japaneseName: "三十三",
            title: "慈愛者",
            keyword: "無償・奉仕・癒し",
            element: .water,
            polarity: .yin,
            ruling: "海王星",
            colorHex: "#14B8A6",
            gemstone: "ターコイズ",
            personality: "マスターナンバー33は無条件の愛と癒しの力を持つ存在。6の奉仕精神を宇宙規模で発揮し、存在そのものが周囲を癒す稀有な人。深い慈悲と教えの力",
            loveTendency: "愛そのものを体現する存在。見返りを求めない深い愛を注ぎますが、自分も愛を受け取ることを学ぶ必要があります",
            workTendency: "ヒーリング、教育、慈善事業、宗教的指導など魂の成長に関わる仕事で唯一無二の貢献。日常でも「場を癒す」存在",
            healthAdvice: "エンパス体質で他者の感情を吸収しやすい。エネルギーの境界線を学び、浄化の習慣を持つことが必須",
            shadowSide: "殉教者意識・燃え尽き。自分を満たすことが人を満たす前提であることを忘れないで",
            luckyDays: [6, 15, 24, 33],
            compatibleNumbers: [6, 9, 11, 22, 33],
            challengingNumbers: [1, 8]
        )
        default: return archetype(for: NumerologyCalculator.reduceToSingle(number))
        }
    }

    static func personalYearTheme(for yearNumber: Int) -> PersonalYearTheme {
        switch yearNumber {
        case 1: return PersonalYearTheme(
            yearNumber: 1, theme: "新しい始まりの年", season: "春の芽吹き",
            keyword: "種まき",
            overview: "9年サイクルの起点。新しいプロジェクト、人間関係、生き方を始めるのに最適な年。過去の執着を手放し、未来に向かって一歩を踏み出す勇気が幸運を呼びます",
            loveAdvice: "新しい出会いの可能性が高い年。自分から動くことが鍵。既存の関係も新鮮な目で見直す好機",
            workAdvice: "起業・転職・新プロジェクト開始に最適。行動力が評価される年。迷うより先に動きましょう",
            bestMonths: [1, 3, 5], cautionMonths: [7, 10]
        )
        case 2: return PersonalYearTheme(
            yearNumber: 2, theme: "忍耐と協調の年", season: "春の根張り",
            keyword: "育成",
            overview: "1年目に蒔いた種を育てる年。焦らず丁寧に関係性を築くことが求められます。目に見える成果は少なくても、水面下で大きく成長している時期",
            loveAdvice: "パートナーとの絆を深める年。コミュニケーションを丁寧に。シングルの方は焦らず自然な出会いを待って",
            workAdvice: "チームワークが鍵。個人プレーより協力関係を重視。細やかな気配りが後の大きな成果に繋がります",
            bestMonths: [2, 6, 9], cautionMonths: [4, 11]
        )
        case 3: return PersonalYearTheme(
            yearNumber: 3, theme: "創造と拡張の年", season: "初夏の開花",
            keyword: "表現",
            overview: "創造力が最高潮に達する年。自己表現、交流、楽しみを積極的に追求するべき時期。人脈が広がり、社交が幸運を呼びます",
            loveAdvice: "恋愛運は好調。楽しいデート、旅行、共通の趣味を通じて絆が深まります。新しい出会いもパーティーやイベントから",
            workAdvice: "プレゼン、企画、マーケティングで力を発揮。アイデアを形にする年。副業やクリエイティブ活動も吉",
            bestMonths: [3, 5, 8], cautionMonths: [1, 10]
        )
        case 4: return PersonalYearTheme(
            yearNumber: 4, theme: "基盤固めの年", season: "夏の実直",
            keyword: "構築",
            overview: "地道な努力が問われる年。華やかさはないが、ここで築いた基盤が将来を支えます。健康管理、財務整理、スキルアップに最適",
            loveAdvice: "安定した関係づくりの年。派手さより誠実さが大切。結婚や同棲など「形にする」決断も吉",
            workAdvice: "資格取得、スキルアップ、業務改善に集中。コツコツ積み上げる年。転職は慎重に",
            bestMonths: [4, 6, 11], cautionMonths: [2, 8]
        )
        case 5: return PersonalYearTheme(
            yearNumber: 5, theme: "変化と自由の年", season: "夏の嵐",
            keyword: "変革",
            overview: "9年サイクルの折り返し地点。大きな変化が訪れやすい年。転職、引越し、旅行など動きのある年。変化を恐れず柔軟に対応することが幸運の鍵",
            loveAdvice: "恋愛に刺激的な変化あり。マンネリを打破する好機。思いがけない出会いや関係の転換期",
            workAdvice: "環境の変化を積極的に受け入れて。新しい分野への挑戦が将来の可能性を広げます",
            bestMonths: [5, 7, 9], cautionMonths: [3, 12]
        )
        case 6: return PersonalYearTheme(
            yearNumber: 6, theme: "愛と責任の年", season: "秋の実り",
            keyword: "奉仕",
            overview: "家庭、愛、責任がテーマの年。大切な人との関係を深め、コミュニティに貢献する時期。美しいものに囲まれることで運気上昇",
            loveAdvice: "結婚・妊娠に最適な年。既存の関係に新たな深みが生まれます。家族との絆も強まる年",
            workAdvice: "人を育てる・教える仕事で評価上昇。リーダーとしてチームの面倒を見る年。美容・デザイン関連も好調",
            bestMonths: [6, 9, 12], cautionMonths: [1, 5]
        )
        case 7: return PersonalYearTheme(
            yearNumber: 7, theme: "内省と学びの年", season: "秋の深まり",
            keyword: "探究",
            overview: "内面を深める年。学び、研究、瞑想、一人の時間が重要。表面的な付き合いより本質的な繋がりを求める時期。自分と向き合うことで大きな気づきを得ます",
            loveAdvice: "精神的な深まりを求める年。表面的な出会いより魂レベルの繋がりを。既存の関係も本質的な会話が増えます",
            workAdvice: "スキルの深掘り、研究、執筆に最適。派手な活動より地道な専門性の追求が将来の飛躍に繋がります",
            bestMonths: [3, 7, 11], cautionMonths: [2, 6]
        )
        case 8: return PersonalYearTheme(
            yearNumber: 8, theme: "収穫と達成の年", season: "実りの秋",
            keyword: "成就",
            overview: "物質的・精神的に大きな実りを得る年。過去7年間の努力が形になります。金運・仕事運が上昇し、権限と影響力が増す時期",
            loveAdvice: "パートナーとの関係が安定し、物質的にも精神的にも豊かな時期。プロポーズや大きな決断に向いています",
            workAdvice: "昇進、昇給、事業拡大のチャンス。交渉力が高まり、大きな契約を獲得できる年。投資にも好機",
            bestMonths: [1, 4, 8], cautionMonths: [3, 9]
        )
        case 9: return PersonalYearTheme(
            yearNumber: 9, theme: "完成と手放しの年", season: "冬の支度",
            keyword: "浄化",
            overview: "9年サイクルの最終年。完成と手放しの年。不要なものを整理し、新しいサイクルに備えます。人間関係の整理、過去の清算がテーマ",
            loveAdvice: "関係の見直しの年。続けるべきか手放すべきか、心の声に従って。執着を手放すことで本当に必要な縁が残ります",
            workAdvice: "プロジェクトの完遂、引き継ぎ、整理に集中。新しいことを始めるより、今あるものを仕上げる年",
            bestMonths: [2, 6, 9], cautionMonths: [4, 8]
        )
        case 11: return PersonalYearTheme(
            yearNumber: 11, theme: "霊的覚醒の年", season: "夜明け前",
            keyword: "覚醒",
            overview: "マスターイヤー。直感とインスピレーションが極めて高まる年。シンクロニシティが増え、人生の大きな転換点になりやすい。内なる声に従う勇気を",
            loveAdvice: "運命的な出会いの可能性。魂の繋がりを感じる人が現れるかもしれません。直感を信じて",
            workAdvice: "創造的な閃きが次々と降りてくる年。アイデアを形にする行動力と組み合わせれば大きな成果に",
            bestMonths: [2, 7, 11], cautionMonths: [5, 8]
        )
        case 22: return PersonalYearTheme(
            yearNumber: 22, theme: "大志実現の年", season: "建設の季節",
            keyword: "実現",
            overview: "マスターイヤー。壮大なビジョンを形にする力が最大化する年。大きなプロジェクトの完遂、組織の構築、人生を変える決断に最適",
            loveAdvice: "パートナーと共に大きな目標に向かう年。関係を「建設」する意識が大切。共同作業が絆を強めます",
            workAdvice: "大規模事業、起業、社会貢献プロジェクトに最適。ビジョンと実行力の両輪で動ける稀有な年",
            bestMonths: [4, 8, 11], cautionMonths: [2, 6]
        )
        case 33: return PersonalYearTheme(
            yearNumber: 33, theme: "慈愛と奉仕の年", season: "光の季節",
            keyword: "献身",
            overview: "マスターイヤー。無条件の愛と癒しの力が極まる年。自分の利益を超えた奉仕と教えの使命が明確になります。存在そのものが周囲を癒す年",
            loveAdvice: "見返りのない深い愛を体験する年。与えることの喜びが最大の幸福に。ただし自分も愛を受け取ることを忘れずに",
            workAdvice: "ヒーリング、教育、慈善活動に最大の意義を感じる年。魂の使命に従った仕事が天職として開花",
            bestMonths: [6, 9, 12], cautionMonths: [1, 3]
        )
        default: return personalYearTheme(for: NumerologyCalculator.reduceToSingle(yearNumber))
        }
    }

    static func description(for number: Int) -> String {
        archetype(for: number).personality
    }

    static func dayGuidance(for number: Int) -> String {
        let arch = archetype(for: number)
        switch number {
        case 1:  return "新しいことを始めるのに最良の日。\(arch.title)のエネルギーが後押しします。自分から行動を起こし、決断する勇気を"
        case 2:  return "協力と調和の日。\(arch.title)の感受性が冴え、人との繋がりが幸運を呼びます。相手の気持ちに寄り添って"
        case 3:  return "創造力が最高潮の日。\(arch.title)の表現力が輝き、言葉や作品が人の心を動かします。楽しむことが幸運の鍵"
        case 4:  return "地道な作業が実を結ぶ日。\(arch.title)の堅実さで基盤を固めましょう。計画を立て、着実に進むと大きな成果に"
        case 5:  return "変化と自由の日。\(arch.title)の適応力で新しい風を取り込みましょう。いつもと違う道、新しい体験が幸運を運びます"
        case 6:  return "愛と奉仕の日。\(arch.title)の温かさで大切な人に思いやりを。家族との時間が心を満たし、美しいものが運気を上げます"
        case 7:  return "内省と学びの日。\(arch.title)の知性で深い気づきを得ましょう。静かに考える時間が新しい道を照らします"
        case 8:  return "達成と成功の日。\(arch.title)のパワーで目標に力強く進めます。大きな決断、交渉、契約に好タイミング"
        case 9:  return "完成と浄化の日。\(arch.title)の叡智で不要なものを手放す好機。終わりは新しい始まりの準備です"
        case 11: return "直感が冴えわたるマスターデイ。心の奥から湧き上がる閃きに従ってください。シンクロニシティに注目"
        case 22: return "壮大なビジョンが形になるマスターデイ。大きな計画を具体的な行動に移す力が最大化します"
        case 33: return "深い愛と慈悲が溢れるマスターデイ。あなたの存在そのものが周囲を癒します。奉仕の精神で過ごして"
        default: return "穏やかに自分のペースで過ごしましょう"
        }
    }
}
