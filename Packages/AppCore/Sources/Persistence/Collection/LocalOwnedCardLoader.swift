//
//  LocalOwnedCardLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

/// The owned cards kept on this device. Store errors become this type's own errors,
/// so callers never depend on how the store keeps them.
public struct LocalOwnedCardLoader: OwnedCardLoader, OwnedCardSaver, OwnedCardRemover {
    public enum LoadError: Error, Equatable {
        case failed
    }

    public enum SaveError: Error, Equatable {
        case failed
    }

    public enum RemoveError: Error, Equatable {
        case failed
    }

    private let store: OwnedCardStore

    public init(store: OwnedCardStore) {
        self.store = store
    }

    public func load() async throws -> [OwnedCard] {
        do {
            return try await store.retrieveAll()
        } catch {
            throw LoadError.failed
        }
    }

    public func save(_ ownedCard: OwnedCard) async throws {
        do {
            try await store.insert(ownedCard)
        } catch {
            throw SaveError.failed
        }
    }

    public func remove(ownedCardID: OwnedCard.ID) async throws {
        do {
            try await store.delete(ownedCardID: ownedCardID)
        } catch {
            throw RemoveError.failed
        }
    }
}
