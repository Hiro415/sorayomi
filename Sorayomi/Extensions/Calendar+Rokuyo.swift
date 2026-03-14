import Foundation

// MARK: - Calendar + Rokuyo

extension Calendar {

    // MARK: - Chinese Calendar

    /// 中国暦（旧暦）カレンダー
    /// 六曜の計算に使用される。六曜は旧暦の月と日の合計を6で割った余りで決定される。
    static let chineseCalendar: Calendar = {
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }()

    // MARK: - Rokuyo Calculation

    /// 指定日の六曜を計算する
    /// 計算方法: (旧暦の月 + 旧暦の日) % 6
    /// 0=大安, 1=赤口, 2=先勝, 3=友引, 4=先負, 5=仏滅
    static func rokuyo(for date: Date) -> Rokuyo {
        let chineseComponents = chineseCalendar.dateComponents([.month, .day], from: date)
        guard let month = chineseComponents.month,
              let day = chineseComponents.day else {
            return .taian // フォールバック
        }

        let index = (month + day) % 6
        return Rokuyo(rawValue: index) ?? .taian
    }

    /// 指定期間内の特定六曜の日付一覧を取得
    static func dates(
        withRokuyo targetRokuyo: Rokuyo,
        from startDate: Date,
        to endDate: Date
    ) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate

        let gregorian = Calendar(identifier: .gregorian)

        while currentDate <= endDate {
            if rokuyo(for: currentDate) == targetRokuyo {
                dates.append(currentDate)
            }
            guard let nextDate = gregorian.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates
    }

    /// 指定日から次の大安の日を取得
    static func nextTaian(from date: Date) -> Date? {
        let gregorian = Calendar(identifier: .gregorian)
        var currentDate = date

        // 最大60日先まで探索（六曜は6日周期）
        for _ in 0..<60 {
            guard let nextDate = gregorian.date(byAdding: .day, value: 1, to: currentDate) else {
                return nil
            }
            currentDate = nextDate

            if rokuyo(for: currentDate) == .taian {
                return currentDate
            }
        }

        return nil
    }

    /// 旧暦の月と日を取得（表示用）
    static func lunarDateComponents(for date: Date) -> (month: Int, day: Int)? {
        let components = chineseCalendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return nil
        }
        return (month, day)
    }

    /// 旧暦の日付を日本語で表示
    static func lunarDateString(for date: Date) -> String {
        guard let (month, day) = lunarDateComponents(for: date) else {
            return "不明"
        }
        return "旧暦\(month)月\(day)日"
    }
}
