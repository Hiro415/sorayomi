import SwiftUI

/// Main tab bar interface with four Japanese-labeled tabs.
///
/// Each tab wraps its root screen in a `NavigationStack` bound to
/// the corresponding path in `NavigationRouter`, enabling both
/// declarative and programmatic navigation.
struct AppTabView: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        @Bindable var router = appEnvironment.navigationRouter

        TabView(selection: readingTabResetBinding(router: router)) {
            // MARK: - Home

            NavigationStack(path: $router.homePath) {
                HomeScreen()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tag(Tab.home)
            .tabItem {
                Label(Tab.home.japaneseName, systemImage: Tab.home.iconName)
            }
            .accessibilityLabel(Tab.home.accessibilityLabel)

            // MARK: - Reading

            NavigationStack(path: $router.readingPath) {
                ReadingScreen()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tag(Tab.reading)
            .tabItem {
                Label(Tab.reading.japaneseName, systemImage: Tab.reading.iconName)
            }
            .accessibilityLabel(Tab.reading.accessibilityLabel)

            // MARK: - History

            NavigationStack(path: $router.historyPath) {
                HistoryScreen()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tag(Tab.history)
            .tabItem {
                Label(Tab.history.japaneseName, systemImage: Tab.history.iconName)
            }
            .accessibilityLabel(Tab.history.accessibilityLabel)

            // MARK: - Profile

            NavigationStack(path: $router.profilePath) {
                ProfileScreen()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tag(Tab.profile)
            .tabItem {
                Label(Tab.profile.japaneseName, systemImage: Tab.profile.iconName)
            }
            .accessibilityLabel(Tab.profile.accessibilityLabel)
        }
        .tint(Color.sorayomiPrimary)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.sorayomiSurface.opacity(0.98), for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
    }

    // MARK: - Tab Selection Binding with Re-Tap Detection

    /// 導きタブの再タップを検出するカスタムバインディング
    /// 同じタブを再度選択した場合、shouldResetReadingフラグをセットする
    private func readingTabResetBinding(router: NavigationRouter) -> Binding<Tab> {
        Binding(
            get: { router.selectedTab },
            set: { newTab in
                if newTab == .reading && router.selectedTab == .reading {
                    // 導きタブを再タップ → リセットフラグ
                    router.shouldResetReading = true
                }
                if newTab != router.selectedTab {
                    appEnvironment.analyticsService.track(.navigationTabSwitched(tabName: newTab.analyticsScreenName))
                }
                router.selectedTab = newTab
            }
        )
    }

    // MARK: - Destination Resolver

    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .readingDetail(let id):
            Text("Reading Detail: \(id)")
                .navigationTitle("鑑定詳細")
        case .readingResult(let id):
            Text("Reading Result: \(id)")
                .navigationTitle("鑑定結果")
        case .settings:
            SettingsScreen()
        case .creditStore:
            StoreScreen()
        case .about:
            Text("About \(AppConstants.appVersion)")
                .navigationTitle("アプリについて")
        }
    }
}

#Preview {
    AppTabView()
        .environment(AppEnvironment())
}
