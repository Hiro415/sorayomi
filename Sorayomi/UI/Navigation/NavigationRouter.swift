import SwiftUI

/// Centralized, programmatic navigation controller for the Sorayomi app.
///
/// Each tab owns its own `NavigationPath` so pushing / popping is
/// scoped per-tab.  The router is placed in the SwiftUI environment
/// via `AppEnvironment` and can be accessed from any view.
@Observable
@MainActor
final class NavigationRouter {

    // MARK: - Selected Tab

    var selectedTab: Tab = .home

    // MARK: - Cross-Tab Handoff

    /// ホーム画面から導きタブへのシステム引き渡し用
    /// Home→Reading tab handoff. Set by HomeScreen, consumed by ReadingScreen.
    var pendingFortuneSystem: FortuneSystem?
    var pendingReadingCategory: ReadingCategory?

    /// 導きタブの再タップ検出用（メニューに戻る）
    var shouldResetReading: Bool = false

    // MARK: - Per-Tab Navigation Paths

    var homePath = NavigationPath()
    var readingPath = NavigationPath()
    var historyPath = NavigationPath()
    var profilePath = NavigationPath()

    // MARK: - Convenience Accessors

    /// Returns the `NavigationPath` binding for the currently selected tab.
    func path(for tab: Tab) -> NavigationPath {
        switch tab {
        case .home:    return homePath
        case .reading: return readingPath
        case .history: return historyPath
        case .profile: return profilePath
        }
    }

    // MARK: - Programmatic Navigation

    /// Switches to a specific tab and optionally pushes a destination.
    func navigate(to tab: Tab) {
        selectedTab = tab
    }

    /// Pushes a `Hashable` value onto the current tab's navigation stack.
    func push<D: Hashable>(_ destination: D, on tab: Tab? = nil) {
        let target = tab ?? selectedTab
        switch target {
        case .home:    homePath.append(destination)
        case .reading: readingPath.append(destination)
        case .history: historyPath.append(destination)
        case .profile: profilePath.append(destination)
        }
        if let tab { selectedTab = tab }
    }

    /// Pops the top destination from the given (or current) tab.
    func pop(on tab: Tab? = nil) {
        let target = tab ?? selectedTab
        switch target {
        case .home:    if !homePath.isEmpty    { homePath.removeLast() }
        case .reading: if !readingPath.isEmpty { readingPath.removeLast() }
        case .history: if !historyPath.isEmpty { historyPath.removeLast() }
        case .profile: if !profilePath.isEmpty { profilePath.removeLast() }
        }
    }

    /// Pops to the root of the given (or current) tab.
    func popToRoot(on tab: Tab? = nil) {
        let target = tab ?? selectedTab
        switch target {
        case .home:    homePath = NavigationPath()
        case .reading: readingPath = NavigationPath()
        case .history: historyPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }

    /// Resets all navigation state (useful after sign-out).
    func resetAll() {
        selectedTab = .home
        pendingFortuneSystem = nil
        pendingReadingCategory = nil
        homePath = NavigationPath()
        readingPath = NavigationPath()
        historyPath = NavigationPath()
        profilePath = NavigationPath()
    }
}

// MARK: - Navigation Destinations

/// Well-known navigation destinations that can be pushed onto any stack.
/// Add new cases here as screens are created.
enum NavigationDestination: Hashable {
    case readingDetail(id: String)
    case readingResult(id: String)
    case settings
    case creditStore
    case about
}

/// FortuneReading をNavigationPathで直接渡すためのラッパー
struct ReadingDetailDestination: Hashable {
    let reading: FortuneReading

    func hash(into hasher: inout Hasher) {
        hasher.combine(reading.id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reading.id == rhs.reading.id
    }
}
