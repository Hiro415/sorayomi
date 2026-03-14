import Foundation

// MARK: - Date Extensions

extension Date {

    // MARK: - JST Calendar

    /// 日本標準時（JST）のカレンダー
    static let jstCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }()

    // MARK: - Formatting

    /// 日本語フォーマット: yyyy年M月d日
    var japaneseFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: self)
    }

    /// 短縮フォーマット: M/d
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "M/d"
        return formatter.string(from: self)
    }

    /// 時刻フォーマット: HH:mm
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// 年月日＋時刻フォーマット: yyyy年M月d日 HH:mm
    var japaneseFullFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: self)
    }

    /// 曜日の日本語表示（月、火、水...）
    var japaneseDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }

    // MARK: - JST Day Calculations

    /// JSTでの日の開始時刻（00:00:00）
    var startOfDayJST: Date {
        Date.jstCalendar.startOfDay(for: self)
    }

    /// 指定日とJSTで同じ日かどうか
    func isSameDayAs(_ other: Date) -> Bool {
        Date.jstCalendar.isDate(self, inSameDayAs: other)
    }

    /// JSTで今日かどうか
    var isTodayJST: Bool {
        isSameDayAs(Date())
    }

    /// JSTでの年
    var yearJST: Int {
        Date.jstCalendar.component(.year, from: self)
    }

    /// JSTでの月
    var monthJST: Int {
        Date.jstCalendar.component(.month, from: self)
    }

    /// JSTでの日
    var dayJST: Int {
        Date.jstCalendar.component(.day, from: self)
    }

    // MARK: - Seasonal Information

    /// 現在の季節（日本語）
    var season: String {
        let month = Date.jstCalendar.component(.month, from: self)
        switch month {
        case 3, 4, 5:   return "春"
        case 6, 7, 8:   return "夏"
        case 9, 10, 11: return "秋"
        default:         return "冬"
        }
    }

    /// 二十四節気（近似値）
    /// Approximate seasonal term based on the solar calendar.
    var seasonalTerm: String {
        let month = Date.jstCalendar.component(.month, from: self)
        let day = Date.jstCalendar.component(.day, from: self)

        switch (month, day) {
        case (1, 1...5):   return "小寒"
        case (1, 6...19):  return "小寒"
        case (1, 20...31): return "大寒"
        case (2, 1...3):   return "大寒"
        case (2, 4...18):  return "立春"
        case (2, 19...29): return "雨水"
        case (3, 1...5):   return "雨水"
        case (3, 6...20):  return "啓蟄"
        case (3, 21...31): return "春分"
        case (4, 1...4):   return "春分"
        case (4, 5...19):  return "清明"
        case (4, 20...30): return "穀雨"
        case (5, 1...5):   return "穀雨"
        case (5, 6...20):  return "立夏"
        case (5, 21...31): return "小満"
        case (6, 1...5):   return "小満"
        case (6, 6...20):  return "芒種"
        case (6, 21...30): return "夏至"
        case (7, 1...6):   return "夏至"
        case (7, 7...22):  return "小暑"
        case (7, 23...31): return "大暑"
        case (8, 1...6):   return "大暑"
        case (8, 7...22):  return "立秋"
        case (8, 23...31): return "処暑"
        case (9, 1...7):   return "処暑"
        case (9, 8...22):  return "白露"
        case (9, 23...30): return "秋分"
        case (10, 1...7):  return "秋分"
        case (10, 8...22): return "寒露"
        case (10, 23...31): return "霜降"
        case (11, 1...6):  return "霜降"
        case (11, 7...21): return "立冬"
        case (11, 22...30): return "小雪"
        case (12, 1...6):  return "小雪"
        case (12, 7...21): return "大雪"
        case (12, 22...31): return "冬至"
        default:            return "不明"
        }
    }

    // MARK: - Relative Date Descriptions

    /// 相対的な日付表現（今日、昨日、〇日前）
    var relativeJapanese: String {
        let calendar = Date.jstCalendar
        let now = Date()

        if calendar.isDate(self, inSameDayAs: now) {
            return "今日"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(self, inSameDayAs: yesterday) {
            return "昨日"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(self, inSameDayAs: tomorrow) {
            return "明日"
        }

        let components = calendar.dateComponents([.day], from: self.startOfDayJST, to: now.startOfDayJST)
        if let days = components.day, days > 0 {
            return "\(days)日前"
        }

        return japaneseFormatted
    }
}
