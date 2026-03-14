import SwiftUI

/// Represents each tab in the main `TabView`.
///
/// The raw value doubles as a stable identifier for state restoration.
/// Japanese labels are exposed through `japaneseName` so the tab bar
/// renders entirely in Japanese.
enum Tab: String, CaseIterable, Hashable, Identifiable, Sendable {
    case home
    case reading
    case history
    case profile

    var id: String { rawValue }

    // MARK: - Display

    /// Localized Japanese label shown beneath the tab icon.
    var japaneseName: String {
        switch self {
        case .home:    return "ホーム"
        case .reading: return "導き"
        case .history: return "記録"
        case .profile: return "マイページ"
        }
    }

    /// SF Symbol name for the tab icon.
    var iconName: String {
        switch self {
        case .home:    return "house.fill"
        case .reading: return "sparkles"
        case .history: return "book.closed.fill"
        case .profile: return "person.fill"
        }
    }

    /// Accessibility label in Japanese.
    var accessibilityLabel: String {
        switch self {
        case .home:    return "ホーム画面"
        case .reading: return "占い導き画面"
        case .history: return "鑑定記録画面"
        case .profile: return "マイページ画面"
        }
    }

    // MARK: - Analytics

    /// Screen name sent to analytics when the tab is selected.
    var analyticsScreenName: String {
        switch self {
        case .home:    return "home"
        case .reading: return "reading"
        case .history: return "history"
        case .profile: return "profile"
        }
    }
}
