import SwiftUI

/// Main tab bar interface with four Japanese-labeled tabs.
///
/// Each tab wraps its root screen in a `NavigationStack` bound to
/// the corresponding path in `NavigationRouter`, enabling both
/// declarative and programmatic navigation.
///
/// On iPad (`.regular` horizontal size class), a `NavigationSplitView`
/// sidebar replaces the tab bar for a more spacious, native experience.
struct AppTabView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        LayoutMetricsProvider {
            if sizeClass == .regular {
                iPadSidebarView
            } else {
                compactTabView
            }
        }
    }

    // MARK: - iPad Sidebar Layout

    private var iPadSidebarView: some View {
        @Bindable var router = appEnvironment.navigationRouter

        return NavigationSplitView {
            List {
                ForEach(Tab.allCases) { tab in
                    Button {
                        if tab != router.selectedTab {
                            appEnvironment.analyticsService.track(.navigationTabSwitched(tabName: tab.analyticsScreenName))
                        }
                        router.selectedTab = tab
                    } label: {
                        Label(tab.japaneseName, systemImage: tab.iconName)
                            .foregroundStyle(
                                tab == router.selectedTab
                                    ? Color.sorayomiPrimary
                                    : Color.sorayomiTextPrimary
                            )
                    }
                    .listRowBackground(
                        tab == router.selectedTab
                            ? Color.sorayomiPrimary.opacity(0.1)
                            : Color.clear
                    )
                    .accessibilityLabel(tab.accessibilityLabel)
                }
            }
            .navigationTitle("宙よみ")
            .listStyle(.sidebar)
        } detail: {
            detailContent(for: router.selectedTab, router: router)
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.sorayomiPrimary)
    }

    /// Resolves the detail pane content for the selected sidebar tab.
    @ViewBuilder
    private func detailContent(for tab: Tab, router: NavigationRouter) -> some View {
        @Bindable var router = appEnvironment.navigationRouter

        switch tab {
        case .home:
            NavigationStack(path: $router.homePath) {
                HomeScreen()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.sorayomiSurface.opacity(0.98), for: .navigationBar)

        case .reading:
            NavigationStack(path: $router.readingPath) {
                ReadingScreen()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.sorayomiSurface.opacity(0.98), for: .navigationBar)

        case .history:
            NavigationStack(path: $router.historyPath) {
                HistoryScreen()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
                    .navigationDestination(for: ReadingDetailDestination.self) { dest in
                        ReadingDetailScreen(reading: dest.reading)
                    }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.sorayomiSurface.opacity(0.98), for: .navigationBar)

        case .profile:
            NavigationStack(path: $router.profilePath) {
                ProfileScreen()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.sorayomiSurface.opacity(0.98), for: .navigationBar)
        }
    }

    // MARK: - Compact TabView Layout

    private var compactTabView: some View {
        @Bindable var router = appEnvironment.navigationRouter

        return TabView(selection: tabSelectionBinding(router: router)) {
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
                    .navigationDestination(for: ReadingDetailDestination.self) { dest in
                        ReadingDetailScreen(reading: dest.reading)
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
    }

    // MARK: - Tab Selection Binding with Re-Tap Detection

    /// 全タブ共通の選択バインディング。
    /// 同じタブを再タップしたときはそのタブのナビゲーションスタックをルートまで巻き戻す。
    /// 導きタブの場合はさらに shouldResetReading フラグも立てる。
    private func tabSelectionBinding(router: NavigationRouter) -> Binding<Tab> {
        Binding(
            get: { router.selectedTab },
            set: { newTab in
                if newTab == router.selectedTab {
                    // 現在のタブを再タップ → ルートに戻す
                    router.popToRoot(on: newTab)
                    if newTab == .reading {
                        router.shouldResetReading = true
                    }
                } else {
                    appEnvironment.analyticsService.track(.navigationTabSwitched(tabName: newTab.analyticsScreenName))
                    router.selectedTab = newTab
                }
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
