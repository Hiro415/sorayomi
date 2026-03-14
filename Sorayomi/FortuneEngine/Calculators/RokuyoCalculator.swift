import Foundation

/// Calculates the Rokuyo (六曜) for a given date using the Chinese calendar.
///
/// The formula is: (lunar month + lunar day) % 6
/// iOS provides Calendar(identifier: .chinese) which handles the lunar conversion.
struct RokuyoCalculator {

    private static let chineseCalendar = Calendar(identifier: .chinese)

    /// Calculate the Rokuyo for a given Gregorian date.
    static func calculate(from date: Date) -> Rokuyo {
        let components = chineseCalendar.dateComponents([.month, .day], from: date)

        guard let lunarMonth = components.month,
              let lunarDay = components.day else {
            return .taian // Safe fallback
        }

        let index = (lunarMonth + lunarDay) % 6
        return Rokuyo(rawValue: index) ?? .taian
    }

    /// Get today's Rokuyo.
    static func today() -> Rokuyo {
        return calculate(from: Date())
    }

    /// Get Rokuyo for the next N days starting from a given date.
    static func upcoming(from startDate: Date = Date(), days: Int = 7) -> [(Date, Rokuyo)] {
        let calendar = Calendar(identifier: .gregorian)
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                return nil
            }
            return (date, calculate(from: date))
        }
    }
}
