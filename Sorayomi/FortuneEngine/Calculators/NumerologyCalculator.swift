import Foundation

/// Calculates numerology numbers from birthday using Pythagorean method.
struct NumerologyCalculator {

    /// Calculate the Life Path Number from a birthday.
    /// Reduces month + day + year digits to a single digit (or master number 11, 22, 33).
    static func lifePathNumber(from date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let monthReduced = reduceToSingle(month)
        let dayReduced = reduceToSingle(day)
        let yearReduced = reduceToSingle(year)

        return reduceToSingle(monthReduced + dayReduced + yearReduced)
    }

    /// Calculate the Birthday Number (just the day reduced).
    static func birthdayNumber(from date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: date)
        return reduceToSingle(day)
    }

    /// Calculate the Personal Year Number for a given year.
    /// Personal Year = reduce(birth month + birth day + current year)
    static func personalYearNumber(from birthday: Date, year: Int) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)
        return reduceToSingle(month + day + reduceToSingle(year))
    }

    /// Calculate the Personal Month Number.
    static func personalMonthNumber(from birthday: Date, year: Int, month: Int) -> Int {
        let personalYear = personalYearNumber(from: birthday, year: year)
        return reduceToSingle(personalYear + month)
    }

    /// Calculate the Personal Day Number.
    static func personalDayNumber(from birthday: Date, on date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let personalMonth = personalMonthNumber(from: birthday, year: year, month: month)
        return reduceToSingle(personalMonth + day)
    }

    /// Build a full numerology profile.
    static func profile(from birthday: Date, currentDate: Date = Date()) -> NumerologyProfile {
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)

        return NumerologyProfile(
            lifePathNumber: lifePathNumber(from: birthday),
            birthdayNumber: birthdayNumber(from: birthday),
            personalYearNumber: personalYearNumber(from: birthday, year: currentYear),
            personalMonthNumber: personalMonthNumber(from: birthday, year: currentYear, month: currentMonth),
            personalDayNumber: personalDayNumber(from: birthday, on: currentDate)
        )
    }

    // MARK: - Digit Reduction

    /// Reduce a number to a single digit, preserving master numbers (11, 22, 33).
    static func reduceToSingle(_ number: Int) -> Int {
        var n = abs(number)
        while n > 9 && n != 11 && n != 22 && n != 33 {
            n = digitSum(n)
        }
        return n
    }

    private static func digitSum(_ number: Int) -> Int {
        var sum = 0
        var n = abs(number)
        while n > 0 {
            sum += n % 10
            n /= 10
        }
        return sum
    }
}
