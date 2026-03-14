import Foundation

/// Calculates Nine Star Ki (九星気学) stars from birthday.
///
/// The system assigns one of 9 stars based on birth year (本命星 Honmeisei)
/// and birth month (月命星 Getsumeisei). The year boundary is 立春 (Risshun),
/// approximately February 3-4, NOT January 1.
struct NineStarKiCalculator {

    // MARK: - Public API

    /// Calculate the Nine Star Ki profile from a birthday.
    static func calculate(from date: Date) -> NineStarKiProfile {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Adjust for Risshun (立春) boundary — around Feb 3-4
        // Before Risshun, the person belongs to the previous year
        let risshunDay = risshunDate(for: year)
        let adjustedYear: Int
        if month < 2 || (month == 2 && day < risshunDay) {
            adjustedYear = year - 1
        } else {
            adjustedYear = year
        }

        let honmeisei = calculateHonmeisei(year: adjustedYear)

        // Adjusted month for Getsumeisei (月命星)
        // Month boundaries also shift at setsubun
        let adjustedMonth: Int
        if day < risshunDay && month == 2 {
            adjustedMonth = 1 // Still counts as previous month
        } else if month == 1 {
            adjustedMonth = 1
        } else {
            adjustedMonth = month
        }

        let getsumeisei = calculateGetsumeisei(honmeisei: honmeisei, month: adjustedMonth)

        return NineStarKiProfile(
            honmeisei: honmeisei,
            getsumeisei: getsumeisei,
            birthYear: year
        )
    }

    /// Calculate today's daily star (日命星).
    static func dailyStar(for date: Date = Date()) -> NineStarKiStar {
        // Simplified daily star calculation
        // Uses a cycle of 9 days, with the starting point anchored to a known date
        let calendar = Calendar(identifier: .gregorian)
        // Known anchor: January 1, 2000 was 一白水星 day
        let anchor = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let daysBetween = calendar.dateComponents([.day], from: anchor, to: date).day ?? 0
        // The cycle goes in reverse order (9, 8, 7... 1, 9, 8...)
        let index = ((9 - (daysBetween % 9)) % 9) + 1
        return NineStarKiStar(rawValue: index) ?? .ippakuSuisei
    }

    // MARK: - Core Calculations

    /// Calculate 本命星 (Honmeisei / Birth Year Star)
    /// Formula: Sum digits of year repeatedly until single digit, then subtract from 11.
    /// If result > 9, subtract 9.
    private static func calculateHonmeisei(year: Int) -> NineStarKiStar {
        var digitSum = year
        while digitSum > 9 {
            digitSum = String(digitSum).compactMap { $0.wholeNumberValue }.reduce(0, +)
        }
        var starNumber = 11 - digitSum
        if starNumber > 9 {
            starNumber -= 9
        }
        return NineStarKiStar(rawValue: starNumber) ?? .ippakuSuisei
    }

    /// Calculate 月命星 (Getsumeisei / Birth Month Star)
    /// Uses lookup table based on the Honmeisei group and birth month.
    private static func calculateGetsumeisei(honmeisei: NineStarKiStar, month: Int) -> NineStarKiStar {
        let group = honmeiseiGroup(honmeisei)
        let monthIndex = max(0, min(11, month - 1))
        let starNumber = monthStarTable[group][monthIndex]
        return NineStarKiStar(rawValue: starNumber) ?? .ippakuSuisei
    }

    /// Determine which of 3 groups the Honmeisei belongs to.
    /// Group 0: 一白, 四緑, 七赤 (1, 4, 7)
    /// Group 1: 三碧, 六白, 九紫 (3, 6, 9)
    /// Group 2: 二黒, 五黄, 八白 (2, 5, 8)
    private static func honmeiseiGroup(_ star: NineStarKiStar) -> Int {
        switch star.rawValue {
        case 1, 4, 7: return 0
        case 3, 6, 9: return 1
        case 2, 5, 8: return 2
        default: return 0
        }
    }

    /// Lookup table for Getsumeisei by group and month (0-indexed).
    /// Each inner array has 12 values for months Feb through Jan.
    private static let monthStarTable: [[Int]] = [
        // Group 0 (1,4,7): Feb=8, Mar=7, Apr=6, May=5, Jun=4, Jul=3, Aug=2, Sep=1, Oct=9, Nov=8, Dec=7, Jan=6
        [8, 7, 6, 5, 4, 3, 2, 1, 9, 8, 7, 6],
        // Group 1 (3,6,9): Feb=2, Mar=1, Apr=9, May=8, Jun=7, Jul=6, Aug=5, Sep=4, Oct=3, Nov=2, Dec=1, Jan=9
        [2, 1, 9, 8, 7, 6, 5, 4, 3, 2, 1, 9],
        // Group 2 (2,5,8): Feb=5, Mar=4, Apr=3, May=2, Jun=1, Jul=9, Aug=8, Sep=7, Oct=6, Nov=5, Dec=4, Jan=3
        [5, 4, 3, 2, 1, 9, 8, 7, 6, 5, 4, 3],
    ]

    /// Approximate Risshun date for a given year (usually Feb 3 or 4).
    private static func risshunDate(for year: Int) -> Int {
        // Risshun falls on Feb 3 or Feb 4 in most years.
        // Simplified: Use Feb 4 as the standard boundary.
        // For precise astronomical calculation, a more complex formula would be needed.
        return 4
    }
}
