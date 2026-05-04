import SwiftUI

// MARK: - SettingsScreen

/// アプリ設定画面
/// Displays app settings, legal links, debug options, and app information.
struct SettingsScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = SettingsViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showDeletedFeedback = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // General section
                generalSection

                // Legal section
                legalSection

                // Data management section
                dataManagementSection

                // App info
                appInfoSection
            }
            .adaptiveScreenPadding()
            .contentWidthConstraint()
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.sorayomiBackground)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.loadSettings(env: env)
        }
        .alert("データをすべて削除しますか？", isPresented: $showDeleteConfirmation) {
            Button("削除する", role: .destructive) {
                env.userProfileService.deleteAllUserData(
                    readingHistoryService: env.readingHistoryService,
                    creditWalletService: env.creditWalletService,
                    freeTrialManager: env.freeTrialManager
                )
                showDeletedFeedback = true
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("プロフィール、鑑定履歴、クレジット残高を含むすべてのデータが端末から削除されます。この操作は取り消せません。")
        }
        .alert("データを削除しました", isPresented: $showDeletedFeedback) {
            Button("OK") {}
        } message: {
            Text("すべてのデータが端末から削除されました。")
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "一般", icon: "gearshape")

            VStack(spacing: 0) {
                // Notifications toggle
                Toggle(isOn: Binding(
                    get: { env.notificationManager.isEnabled },
                    set: { newValue in
                        env.notificationManager.isEnabled = newValue
                        if newValue {
                            Task { await env.notificationManager.requestAuthorization() }
                        }
                    }
                )) {
                    settingsLabel(title: "通知", icon: "bell", color: .sorayomiAccent)
                }
                .tint(Color.sorayomiPrimary)
                .padding(Spacing.md)


            }
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "法的情報", icon: "doc.text")

            VStack(spacing: 0) {
                NavigationLink {
                    TermsOfServiceScreen()
                        .environment(env)
                } label: {
                    HStack {
                        settingsLabel(title: "利用規約", icon: "doc.plaintext", color: .sorayomiPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(.plain)

                Divider()
                    .foregroundStyle(Color.sorayomiDivider)

                NavigationLink {
                    PrivacyPolicyScreen()
                        .environment(env)
                } label: {
                    HStack {
                        settingsLabel(title: "プライバシーポリシー", icon: "hand.raised", color: .sorayomiPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(.plain)

            }
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }



    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "データ管理", icon: "person.crop.circle.badge.minus")

            VStack(spacing: 0) {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        settingsLabel(title: "アカウントとデータを削除", icon: "trash.fill", color: .sorayomiError)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiError.opacity(0.5))
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(.plain)
            }
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

            Text("プロフィール、鑑定履歴、クレジット残高をこの端末から削除します。App Storeでの購入履歴は残ります。")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xs)
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sorayomiSecondary, .sorayomiAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(viewModel.appDisplayName)
                .font(SorayomiTypography.headline)
                .foregroundStyle(Color.sorayomiTextPrimary)

            Text("Version \(viewModel.appVersion)")
                .font(SorayomiTypography.caption)
                .foregroundStyle(Color.sorayomiTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Subviews

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(Color.sorayomiPrimary)
            Text(title)
                .font(SorayomiTypography.headline)
                .foregroundStyle(Color.sorayomiTextPrimary)
            Spacer()
        }
    }

    private func settingsLabel(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(SorayomiTypography.body)
                .foregroundStyle(Color.sorayomiTextPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsScreen()
            .environment(AppEnvironment())
    }
}
