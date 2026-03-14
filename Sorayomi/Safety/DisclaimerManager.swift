import Foundation

/// Manages when and where disclaimers should be displayed.
@Observable
@MainActor
final class DisclaimerManager {

    var copyProvider: CopyProvider

    init(copyProvider: CopyProvider = .shared) {
        self.copyProvider = copyProvider
    }

    /// Whether to show the reading disclaimer after each response.
    var shouldShowReadingDisclaimer: Bool { true }

    /// Whether to show AI attribution text.
    var shouldShowAIAttribution: Bool { true }

    /// Whether to show the entertainment notice on the home screen.
    var shouldShowEntertainmentNotice: Bool { true }

    // MARK: - Disclaimer Text

    func readingDisclaimer() -> String {
        copyProvider.get(.readingDisclaimer)
    }

    func aiAttribution() -> String {
        copyProvider.get(.readingAIAttribution)
    }

    func entertainmentNotice() -> String {
        copyProvider.get(.disclaimerEntertainment)
    }

    func notAdviceDisclaimer() -> String {
        copyProvider.get(.disclaimerNotAdvice)
    }

    /// Full disclaimer block for display after a reading.
    func fullReadingDisclaimer() -> String {
        var parts: [String] = []
        if shouldShowReadingDisclaimer {
            parts.append(readingDisclaimer())
        }
        if shouldShowAIAttribution {
            parts.append(aiAttribution())
        }
        return parts.joined(separator: "\n")
    }
}
