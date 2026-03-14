import Foundation

/// ViewModel for the onboarding flow.
@Observable
@MainActor
final class OnboardingViewModel {
    var currentPage: Int = 0
    var birthday: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var bloodType: BloodType? = nil
    var hasConsentedToAI: Bool = false
    var isCompleting: Bool = false

    func completeOnboarding(env: AppEnvironment) async {
        guard hasConsentedToAI else { return }
        isCompleting = true

        // Ensure authenticated
        let userId = await FirebaseAuthService.shared.ensureAuthenticated()

        // Build profile
        let profile = UserProfile(
            id: userId,
            nickname: nil,
            birthday: birthday,
            bloodType: bloodType,
            themeInterests: [.dailyFortune],
            hasConsentedToAI: true,
            consentTimestamp: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )

        // Save profile
        env.userProfileService.saveProfile(profile)

        // Grant initial free credits
        env.creditWalletService.grantInitialFreeCredits()

        // Load wallet state
        env.creditWalletService.loadWallet()

        // Track analytics
        env.analyticsService.trackOnboardingCompleted(profile: profile)

        // Mark onboarding complete
        env.isOnboardingComplete = true
        isCompleting = false
    }
}
