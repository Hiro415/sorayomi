import Foundation

// MARK: - FirestoreServiceProtocol

/// Firestore 操作のプロトコル
/// Defines the contract for document-level Firestore operations.
/// MVP uses a local UserDefaults-backed implementation.
@MainActor
protocol FirestoreServiceProtocol {

    /// ドキュメントを保存
    func save<T: Codable>(collection: String, documentId: String, data: T) throws

    /// ドキュメントを取得
    func get<T: Codable>(collection: String, documentId: String) throws -> T?

    /// ドキュメントを削除
    func delete(collection: String, documentId: String)

    /// コレクション内の全ドキュメントを取得
    func getAll<T: Codable>(collection: String) throws -> [T]

    /// ドキュメントの変更を監視（コールバック方式）
    func observe<T: Codable>(
        collection: String,
        documentId: String,
        onChange: @escaping @Sendable (T?) -> Void
    ) -> ObservationToken
}

// MARK: - ObservationToken

/// 監視のキャンセル用トークン
final class ObservationToken {
    private let cancellation: () -> Void

    init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    func cancel() {
        cancellation()
    }

    deinit {
        cancel()
    }
}

// MARK: - LocalFirestoreService

/// UserDefaults ベースの Firestore スタブ実装
/// TODO: Replace with Firebase Firestore implementation
@MainActor
final class LocalFirestoreService: FirestoreServiceProtocol {

    // MARK: - Singleton

    static let shared = LocalFirestoreService()

    // MARK: - Properties

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var observers: [String: [UUID: Any]] = [:]

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.encoder = JSONEncoder.sorayomiEncoder
        self.decoder = JSONDecoder.sorayomiDecoder
    }

    // MARK: - FirestoreServiceProtocol

    func save<T: Codable>(collection: String, documentId: String, data: T) throws {
        let key = storageKey(collection: collection, documentId: documentId)
        let encodedData = try encoder.encode(data)
        defaults.set(encodedData, forKey: key)

        // ドキュメントIDをコレクションのインデックスに追加
        addToIndex(collection: collection, documentId: documentId)

        // 監視者に通知
        notifyObservers(collection: collection, documentId: documentId, value: data)

        #if DEBUG
        print("[LocalFirestore] Saved \(collection)/\(documentId)")
        #endif
    }

    func get<T: Codable>(collection: String, documentId: String) throws -> T? {
        let key = storageKey(collection: collection, documentId: documentId)
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }

    func delete(collection: String, documentId: String) {
        let key = storageKey(collection: collection, documentId: documentId)
        defaults.removeObject(forKey: key)

        // コレクションインデックスから削除
        removeFromIndex(collection: collection, documentId: documentId)

        #if DEBUG
        print("[LocalFirestore] Deleted \(collection)/\(documentId)")
        #endif
    }

    func getAll<T: Codable>(collection: String) throws -> [T] {
        let documentIds = getIndex(collection: collection)
        var results: [T] = []

        for documentId in documentIds {
            if let item: T = try get(collection: collection, documentId: documentId) {
                results.append(item)
            }
        }

        return results
    }

    func observe<T: Codable>(
        collection: String,
        documentId: String,
        onChange: @escaping @Sendable (T?) -> Void
    ) -> ObservationToken {
        let observerKey = storageKey(collection: collection, documentId: documentId)
        let observerId = UUID()

        if observers[observerKey] == nil {
            observers[observerKey] = [:]
        }
        observers[observerKey]?[observerId] = onChange

        // 現在の値で即座にコールバック
        if let current: T = try? get(collection: collection, documentId: documentId) {
            onChange(current)
        }

        return ObservationToken { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.observers[observerKey]?.removeValue(forKey: observerId)
            }
        }
    }

    // MARK: - Private Helpers

    private func storageKey(collection: String, documentId: String) -> String {
        "firestore_\(collection)_\(documentId)"
    }

    private func indexKey(collection: String) -> String {
        "firestore_index_\(collection)"
    }

    private func getIndex(collection: String) -> [String] {
        defaults.stringArray(forKey: indexKey(collection: collection)) ?? []
    }

    private func addToIndex(collection: String, documentId: String) {
        var index = getIndex(collection: collection)
        if !index.contains(documentId) {
            index.append(documentId)
            defaults.set(index, forKey: indexKey(collection: collection))
        }
    }

    private func removeFromIndex(collection: String, documentId: String) {
        var index = getIndex(collection: collection)
        index.removeAll { $0 == documentId }
        defaults.set(index, forKey: indexKey(collection: collection))
    }

    private func notifyObservers<T: Codable>(collection: String, documentId: String, value: T) {
        let key = storageKey(collection: collection, documentId: documentId)
        let callbacks = observers[key]

        guard let callbacks else { return }

        for (_, callback) in callbacks {
            if let typedCallback = callback as? (T?) -> Void {
                typedCallback(value)
            }
        }
    }
}

// MARK: - Firestore Collection Names

/// Firestore コレクション名の定数
enum FirestoreCollection {
    static let users = "users"
    static let readings = "readings"
    static let wallets = "wallets"
    static let transactions = "transactions"
}
