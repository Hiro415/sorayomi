import Foundation

// MARK: - HomeViewModel

/// ホーム画面のビューモデル
/// Composes the daily fortune overview from multiple subsystems (horoscope,
/// blood type, rokuyo) and exposes it for display on the home screen.
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Published State

    private(set) var dailyFortune: DailyFortune?
    private(set) var todayRokuyo: Rokuyo = RokuyoCalculator.calculate(from: Date())
    private(set) var todayOmikuji: Omikuji = OmikujiCalculator.draw()
    private(set) var seasonalContext: SeasonalContext = SeasonalContext.from(date: Date())
    private(set) var isLoading = false
    var selectedSystem: FortuneSystem?

    // MARK: - Load

    /// Fetches and assembles the daily fortune from local calculators.
    func loadDailyFortune(env: AppEnvironment) async {
        guard dailyFortune == nil else { return }
        isLoading = true

        let profile = env.userProfileService.currentProfile
        let zodiac = profile?.birthday.flatMap { ZodiacCalculator.calculate(from: $0) } ?? .aries
        let bloodType = profile?.bloodType
        let rokuyo = RokuyoCalculator.calculate(from: Date())
        let omikuji = OmikujiCalculator.draw(
            for: Date(),
            birthday: profile?.birthday,
            bloodType: profile?.bloodType
        )
        todayRokuyo = rokuyo
        todayOmikuji = omikuji
        seasonalContext = SeasonalContext.from(date: Date())

        let score = calculateOverallScore(rokuyo: rokuyo, omikuji: omikuji)
        let luckyPair = (color: omikuji.luckyColor, item: omikuji.luckyItem)

        dailyFortune = DailyFortune(
            date: Date(),
            zodiacSign: zodiac,
            bloodType: bloodType,
            rokuyo: rokuyo,
            horoscopeSnippet: snippetForZodiac(zodiac),
            bloodTypeSnippet: snippetForBloodType(bloodType),
            luckyColor: luckyPair.color,
            luckyItem: luckyPair.item,
            overallScore: score,
            numerologyDay: nil
        )

        isLoading = false
    }

    // MARK: - Private Helpers

    private func calculateOverallScore(rokuyo: Rokuyo, omikuji: Omikuji) -> Int {
        let combined = Double(rokuyo.auspiciousnessScore + omikuji.rank.starScore) / 2.0
        return min(max(Int(combined.rounded()), 1), 5)
    }

    private func snippetForZodiac(_ sign: ZodiacSign) -> String {
        "今日の\(sign.japaneseName)は、気持ちを整えるほど魅力が伝わりやすい一日です。急がず、心地よい選択を重ねてみましょう。"
    }

    private func snippetForBloodType(_ type: BloodType?) -> String {
        guard let type else { return "" }
        return "\(type.japaneseName)の今日の傾向：丁寧なひと言や段取りの良さが、対人運と仕事運の追い風になりそうです。"
    }
}
