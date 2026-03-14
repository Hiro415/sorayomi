import Foundation

/// Calculates zodiac sign from a given date.
/// Uses standard Western astrology date ranges.
struct ZodiacCalculator {

    /// Determine the zodiac sign for a given birthday.
    static func calculate(from date: Date) -> ZodiacSign {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        switch (month, day) {
        case (3, 21...31), (4, 1...19):   return .aries
        case (4, 20...30), (5, 1...20):   return .taurus
        case (5, 21...31), (6, 1...21):   return .gemini
        case (6, 22...30), (7, 1...22):   return .cancer
        case (7, 23...31), (8, 1...22):   return .leo
        case (8, 23...31), (9, 1...22):   return .virgo
        case (9, 23...30), (10, 1...23):  return .libra
        case (10, 24...31), (11, 1...22): return .scorpio
        case (11, 23...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19):  return .capricorn
        case (1, 20...31), (2, 1...18):   return .aquarius
        case (2, 19...29), (3, 1...20):   return .pisces
        default:                           return .aries
        }
    }

    /// Get the current zodiac season (what sign the sun is currently in).
    static func currentSeason(on date: Date = Date()) -> ZodiacSign {
        return calculate(from: date)
    }
}
