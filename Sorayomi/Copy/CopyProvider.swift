// CopyProvider.swift
// Sorayomi
//
// Central provider for all user-facing copy strings.
// Supports variant switching and remote config overrides.

import Foundation
import SwiftUI

/// The single source of truth for all user-facing copy in the app.
///
/// `CopyProvider` resolves copy strings by:
/// 1. Checking for a remote config override (highest priority).
/// 2. Falling back to the local Japanese copy deck for the active variant.
///
/// Usage:
/// ```swift
/// let title = CopyProvider.shared.get(.appTitle)
/// ```
///
/// The provider is `@Observable` so SwiftUI views automatically re-render
/// when the variant or overrides change.
@Observable
final class CopyProvider: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared instance used throughout the app.
    static let shared = CopyProvider()

    // MARK: - State

    /// The currently active copy variant.
    /// Changing this causes all resolved copy to update.
    var currentVariant: CopyVariant = .safe

    /// Remote config overrides keyed by `CopyKey.remoteConfigKey`.
    /// When a key is present here its value takes precedence over the local copy deck.
    private var remoteOverrides: [String: String] = [:]

    /// In-memory cache keyed by "\(variant.rawValue)_\(key.rawValue)".
    /// Cleared whenever variant or overrides change.
    private var cache: [String: String] = [:]

    // MARK: - Init

    private init() {}

    // MARK: - Public API

    /// Returns the resolved copy string for the given key under the current variant.
    ///
    /// Resolution order:
    /// 1. Remote config override (if present for this key).
    /// 2. Local Japanese copy deck value for current variant.
    ///
    /// - Parameter key: The copy key to resolve.
    /// - Returns: The fully resolved, user-facing string.
    func get(_ key: CopyKey) -> String {
        let cacheKey = "\(currentVariant.rawValue)_\(key.rawValue)"

        if let cached = cache[cacheKey] {
            return cached
        }

        let resolved: String
        if let remoteValue = remoteOverrides[key.remoteConfigKey] {
            resolved = remoteValue
        } else {
            resolved = key.defaultValue(for: currentVariant)
        }

        cache[cacheKey] = resolved
        return resolved
    }

    /// Convenience subscript for SwiftUI-friendly access.
    subscript(key: CopyKey) -> String {
        return self.get(key)
    }

    // MARK: - Variant Switching

    /// Updates the active variant and clears the cache.
    func setVariant(_ variant: CopyVariant) {
        currentVariant = variant
        cache.removeAll()
    }

    // MARK: - Remote Config Integration

    /// Applies a batch of remote config overrides.
    ///
    /// Call this after fetching remote config values. Keys that are not
    /// present in the dictionary are left unchanged; pass `nil` to clear
    /// a single override.
    ///
    /// - Parameter overrides: Dictionary keyed by remote config key strings.
    func applyRemoteOverrides(_ overrides: [String: String?]) {
        for (key, value) in overrides {
            if let value {
                remoteOverrides[key] = value
            } else {
                remoteOverrides.removeValue(forKey: key)
            }
        }
        cache.removeAll()
    }

    /// Clears all remote config overrides, reverting to the local copy deck.
    func clearRemoteOverrides() {
        remoteOverrides.removeAll()
        cache.removeAll()
    }

    /// Checks whether a remote override is active for the given key.
    func hasRemoteOverride(for key: CopyKey) -> Bool {
        remoteOverrides[key.remoteConfigKey] != nil
    }

    // MARK: - Bulk Access

    /// Returns all copy key-value pairs for the current variant.
    /// Useful for debugging and copy review tools.
    func allCopy() -> [(key: CopyKey, value: String)] {
        CopyKey.allCases.map { key in
            (key: key, value: get(key))
        }
    }

    // MARK: - Stub: Future Remote Config Fetch

    /// Stub for remote config fetch integration.
    ///
    /// Replace this implementation with actual Remote Config SDK calls
    /// (e.g., Firebase Remote Config) when the backend is connected.
    ///
    /// - Parameter completion: Called with `true` on successful fetch.
    func fetchRemoteConfig(completion: @escaping (Bool) -> Void) {
        // TODO: Replace with actual remote config fetch.
        // Example Firebase implementation:
        // ```
        // let remoteConfig = RemoteConfig.remoteConfig()
        // remoteConfig.fetch(withExpirationDuration: 3600) { status, error in
        //     guard status == .success, error == nil else {
        //         completion(false)
        //         return
        //     }
        //     remoteConfig.activate { _, _ in
        //         var overrides: [String: String?] = [:]
        //         for key in CopyKey.allCases {
        //             let value = remoteConfig[key.remoteConfigKey].stringValue
        //             overrides[key.remoteConfigKey] = value.isEmpty ? nil : value
        //         }
        //         self.applyRemoteOverrides(overrides)
        //
        //         if let variantString = remoteConfig[CopyVariant.remoteConfigKey].stringValue {
        //             self.setVariant(CopyVariant(remoteValue: variantString))
        //         }
        //         completion(true)
        //     }
        // }
        completion(false)
    }

    /// Async wrapper for remote config fetch.
    func fetchRemoteConfig() async -> Bool {
        await withCheckedContinuation { continuation in
            fetchRemoteConfig { success in
                continuation.resume(returning: success)
            }
        }
    }
}

// MARK: - SwiftUI Environment Integration

/// Environment key for injecting CopyProvider into the SwiftUI view hierarchy.
private struct CopyProviderEnvironmentKey: EnvironmentKey {
    static let defaultValue: CopyProvider = .shared
}

extension EnvironmentValues {
    var copyProvider: CopyProvider {
        get { self[CopyProviderEnvironmentKey.self] }
        set { self[CopyProviderEnvironmentKey.self] = newValue }
    }
}
