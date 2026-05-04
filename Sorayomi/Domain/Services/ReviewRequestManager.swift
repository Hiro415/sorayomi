import Foundation
import StoreKit
import UIKit

// MARK: - ReviewRequestManager

/// App Storeレビュー依頼の管理
/// 鑑定完了後に適切なタイミングでレビューを依頼する。
///
/// ルール:
/// - 鑑定完了3回目 or 5回目にSKStoreReviewControllerを表示
/// - 同一バージョンでは1回のみ表示
/// - FeatureFlagManager.isReviewRequestEnabled で制御
@Observable
@MainActor
final class ReviewRequestManager {

    // MARK: - Properties

    /// レビュー依頼を表示すべきかどうか
    private(set) var shouldRequestReview: Bool = false

    // MARK: - Keys

    private let completedReadingsKey = "sorayomi_completed_readings_count"
    private let lastReviewVersionKey = "sorayomi_last_review_version"

    // MARK: - Dependencies

    private let analyticsService: AnalyticsService
    private let featureFlags: FeatureFlagManager

    // MARK: - Init

    init(
        analyticsService: AnalyticsService = .shared,
        featureFlags: FeatureFlagManager = FeatureFlagManager()
    ) {
        self.analyticsService = analyticsService
        self.featureFlags = featureFlags
    }

    // MARK: - Public API

    /// 鑑定完了時に呼び出す。条件を満たした場合レビュー依頼を表示。
    func recordReadingCompletion() {
        guard featureFlags.isReviewRequestEnabled else { return }

        let count = incrementCompletedReadings()

        // 3回目 or 5回目にレビュー依頼
        let triggerCounts: Set<Int> = [3, 5]
        guard triggerCounts.contains(count) else { return }

        // 同一バージョンで既にレビュー済みの場合はスキップ
        guard !hasRequestedForCurrentVersion() else { return }

        requestReview(readingCount: count)
    }

    /// レビュー依頼を実行
    private func requestReview(readingCount: Int) {
        analyticsService.track(.reviewRequestShown(readingCount: readingCount))

        // SKStoreReviewController を使用
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            SKStoreReviewController.requestReview(in: windowScene)
            analyticsService.track(.reviewRequestPresented)
            markReviewRequestedForCurrentVersion()
        }
    }

    // MARK: - Persistence

    private func incrementCompletedReadings() -> Int {
        let current = UserDefaults.standard.integer(forKey: completedReadingsKey)
        let next = current + 1
        UserDefaults.standard.set(next, forKey: completedReadingsKey)
        return next
    }

    private func hasRequestedForCurrentVersion() -> Bool {
        let lastVersion = UserDefaults.standard.string(forKey: lastReviewVersionKey)
        return lastVersion == currentAppVersion
    }

    private func markReviewRequestedForCurrentVersion() {
        UserDefaults.standard.set(currentAppVersion, forKey: lastReviewVersionKey)
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
}
