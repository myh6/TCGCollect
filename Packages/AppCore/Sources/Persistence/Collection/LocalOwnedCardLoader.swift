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
public struct LocalOwnedCardLoader: OwnedCardLoader, OwnedCardCopyCounter, OwnedCardAdder, OwnedCardSaver, OwnedCardRemover, OwnedCardChangeObserver {
    public enum LoadError: Error, Equatable {
        case failed
    }

    public enum SaveError: Error, Equatable {
        case failed
        case invalidCopyCount
    }

    public enum RemoveError: Error, Equatable {
        case failed
    }

    private let store: OwnedCardStore
    private let broadcaster = OwnedCardChangeBroadcaster()

    public init(store: OwnedCardStore) {
        self.store = store
    }

    public func changes() -> AsyncStream<Void> {
        broadcaster.changes()
    }

    public func load() async throws -> [OwnedCard] {
        do {
            return try await store.retrieveAll()
        } catch {
            throw LoadError.failed
        }
    }

    public func countCopies(of cardID: Card.ID) async throws -> Int {
        do {
            return try await store.countCopies(of: cardID)
        } catch {
            throw LoadError.failed
        }
    }

    public func addCopies(of card: Card, count: Int) async throws {
        guard count >= 1 else { throw SaveError.invalidCopyCount }
        do {
            try await store.insert((1...count).map { _ in OwnedCard(card: card) })
        } catch {
            throw SaveError.failed
        }
        broadcaster.announce()
    }

    public func save(_ ownedCards: [OwnedCard]) async throws {
        do {
            try await store.insert(ownedCards)
        } catch {
            throw SaveError.failed
        }
        broadcaster.announce()
    }

    public func remove(ownedCardIDs: [OwnedCard.ID]) async throws {
        do {
            try await store.delete(ownedCardIDs: ownedCardIDs)
        } catch {
            throw RemoveError.failed
        }
        broadcaster.announce()
    }

    public func removeNewestCopy(of cardID: Card.ID) async throws {
        do {
            try await store.deleteNewestCopy(of: cardID)
        } catch {
            throw RemoveError.failed
        }
        broadcaster.announce()
    }
}
