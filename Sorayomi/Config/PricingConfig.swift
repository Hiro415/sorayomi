import Foundation

/// Centralized pricing configuration with remote config fallback.
@Observable
final class PricingConfig {

    // MARK: - Credit Pack Sizes

    var creditsStarter: Int = 5
    var creditsPack12: Int = 12
    var creditsPack30: Int = 30
    var creditsPack60: Int = 60

    // MARK: - Credit Costs Per System

    var costHoroscope: Int = 1
    var costBloodType: Int = 1
    var costBirthdayPersonality: Int = 1
    var costOmikuji: Int = 0
    var costRokuyo: Int = 0
    var costTarot: Int = 2
    var costNumerology: Int = 2
    var costNineStarKi: Int = 2
    var costGeneralConsultation: Int = 1
    var costFlowerFortune: Int = 1
    var costStoneFortune: Int = 1

    // MARK: - Free Credits

    var freeCreditsInitial: Int = 3

    // MARK: - Premium Subscription

    /// 月間プレミアムの月次クレジット付与数
    var premiumMonthlyCredits: Int = 30

    /// クレジット繰越上限（超過分は切り捨て）
    var creditCarryoverCap: Int = 30

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
        case .generalConsultation: return costGeneralConsultation
        case .flowerFortune:       return costFlowerFortune
        case .stoneFortune:        return costStoneFortune
        }
    }

    func creditsForPack(productId: String) -> Int {
        ProductIdentifiers.creditsFor(productId: productId)
    }

    // TODO: Load from RemoteConfigService
    func loadFromRemoteConfig() async {
        // Will fetch and apply remote config values
    }
}
