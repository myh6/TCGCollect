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

    public func save(_ ownedCards: [OwnedCard]) async throws {
        do {
            try await store.insert(ownedCards)
        } catch {
            throw SaveError.failed
        }
    }

    public func remove(ownedCardIDs: [OwnedCard.ID]) async throws {
        do {
            try await store.delete(ownedCardIDs: ownedCardIDs)
        } catch {
            throw RemoveError.failed
        }
    }

    public func removeNewestCopy(of cardID: Card.ID) async throws {
        do {
            try await store.deleteNewestCopy(of: cardID)
        } catch {
            throw RemoveError.failed
        }
    }
}
