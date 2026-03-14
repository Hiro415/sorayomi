import Foundation

/// Centralized pricing configuration with remote config fallback.
@Observable
final class PricingConfig {

    // MARK: - Credit Pack Sizes

    var creditsPack4: Int = 4
    var creditsPack12: Int = 12
    var creditsPack24: Int = 24

    // MARK: - Credit Costs Per System

    var costHoroscope: Int = 1
    var costBloodType: Int = 1
    var costBirthdayPersonality: Int = 1
    var costOmikuji: Int = 0
    var costRokuyo: Int = 0
    var costTarot: Int = 1
    var costNumerology: Int = 2
    var costNineStarKi: Int = 2

    // MARK: - Free Credits

    var freeCreditsInitial: Int = 3

    // MARK: - Lookup

    func creditCost(for system: FortuneSystem) -> Int {
        switch system {
        case .omikuji:             return costOmikuji
        case .horoscope:           return costHoroscope
        case .bloodType:           return costBloodType
        case .birthdayPersonality: return costBirthdayPersonality
        case .rokuyo:              return costRokuyo
        case .tarot:               return costTarot
        case .numerology:          return costNumerology
        case .nineStarKi:          return costNineStarKi
        }
    }

    func creditsForPack(productId: String) -> Int {
        switch productId {
        case "com.sorayomi.credits.pack4":  return creditsPack4
        case "com.sorayomi.credits.pack12": return creditsPack12
        case "com.sorayomi.credits.pack24": return creditsPack24
        default: return 0
        }
    }

    // TODO: Load from RemoteConfigService
    func loadFromRemoteConfig() async {
        // Will fetch and apply remote config values
    }
}
