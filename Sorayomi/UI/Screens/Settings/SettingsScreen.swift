import SwiftUI

// MARK: - SettingsScreen

/// アプリ設定画面
/// Displays app settings, legal links, debug options, and app information.
struct SettingsScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // General section
                generalSection

                // Legal section
                legalSection

                // App info
                appInfoSection
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.sorayomiBackground)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.loadSettings(env: env)
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

                Divider()
                    .foregroundStyle(Color.sorayomiDivider)

                // Cache clear
                Button {
                    viewModel.clearCache()
                } label: {
                    HStack {
                        settingsLabel(title: "キャッシュをクリア", icon: "trash", color: .sorayomiTextSecondary)
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

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "法的情報", icon: "doc.text")

            VStack(spacing: 0) {
                Link(destination: AppConstants.termsURL) {
                    HStack {
                        settingsLabel(title: "利用規約", icon: "doc.plaintext", color: .sorayomiPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
                    }
                    .padding(Spacing.md)
                }

                Divider()
                    .foregroundStyle(Color.sorayomiDivider)

                Link(destination: AppConstants.privacyPolicyURL) {
                    HStack {
                        settingsLabel(title: "プライバシーポリシー", icon: "hand.raised", color: .sorayomiPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
                    }
                    .padding(Spacing.md)
                }

                Divider()
                    .foregroundStyle(Color.sorayomiDivider)

                // Contact support
                Link(destination: URL(string: "mailto:\(AppConstants.supportEmail)")!) {
                    HStack {
                        settingsLabel(title: "お問い合わせ", icon: "envelope", color: .sorayomiPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(Color.sorayomiTextSecondary.opacity(0.5))
                    }
                    .padding(Spacing.md)
                }
            }
            .background(Color.sorayomiSurface)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
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
