//
//  LocalOwnedCardLoaderTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import Domain
@testable import Persistence
import TestHelpers

struct LocalOwnedCardLoaderTests {

    @Test func init_doesNotMessageStore() {
        let (_, store) = makeSUT()

        #expect(store.messages.isEmpty)
    }

    @Test func load_requestsAllOwnedCardsFromStore() async {
        let (sut, store) = makeSUT()

        _ = try? await sut.load()

        #expect(store.messages == [.retrieveAll])
    }

    @Test func load_failsOnStoreError() async {
        let (sut, store) = makeSUT()
        store.retrievalResult = .failure(anyNSError())

        await #expect(throws: LocalOwnedCardLoader.LoadError.failed) {
            try await sut.load()
        }
    }

    @Test func load_deliversNoOwnedCardsWhenStoreIsEmpty() async throws {
        let (sut, store) = makeSUT()
        store.retrievalResult = .success([])

        let ownedCards = try await sut.load()

        #expect(ownedCards.isEmpty)
    }

    @Test func load_deliversStoredOwnedCardsInStoreOrder() async throws {
        let storedCards = [makeOwnedCard(cardID: 1), makeOwnedCard(cardID: 2)]
        let (sut, store) = makeSUT()
        store.retrievalResult = .success(storedCards)

        let ownedCards = try await sut.load()

        #expect(ownedCards == storedCards)
    }

    @Test func save_insertsOwnedCardIntoStore() async {
        let ownedCard = makeOwnedCard(cardID: 1)
        let (sut, store) = makeSUT()

        try? await sut.save(ownedCard)

        #expect(store.messages == [.insert([ownedCard])])
    }

    @Test func save_failsOnStoreInsertionError() async {
        let (sut, store) = makeSUT()
        store.insertionResult = .failure(anyNSError())

        await #expect(throws: LocalOwnedCardLoader.SaveError.failed) {
            try await sut.save(makeOwnedCard(cardID: 1))
        }
    }

    @Test func save_succeedsOnStoreInsertionSuccess() async throws {
        let (sut, store) = makeSUT()
        store.insertionResult = .success(())

        try await sut.save(makeOwnedCard(cardID: 1))
    }

    @Test func remove_deletesOwnedCardWithIDFromStore() async {
        let id = UUID()
        let (sut, store) = makeSUT()

        try? await sut.remove(ownedCardID: id)

        #expect(store.messages == [.delete(id)])
    }

    @Test func remove_failsOnStoreDeletionError() async {
        let (sut, store) = makeSUT()
        store.deletionResult = .failure(anyNSError())

        await #expect(throws: LocalOwnedCardLoader.RemoveError.failed) {
            try await sut.remove(ownedCardID: UUID())
        }
    }

    @Test func remove_succeedsOnStoreDeletionSuccess() async throws {
        let (sut, store) = makeSUT()
        store.deletionResult = .success(())

        try await sut.remove(ownedCardID: UUID())
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: OwnedCardCollection, store: OwnedCardStoreSpy) {
        let store = OwnedCardStoreSpy()
        let sut = LocalOwnedCardLoader(store: store)
        return (sut, store)
    }

    private func makeOwnedCard(cardID: Int) -> OwnedCard {
        OwnedCard(card: Card(id: cardID, name: "card \(cardID)"))
    }

    private final class OwnedCardStoreSpy: OwnedCardStore {
        enum Message: Equatable {
            case retrieveAll
            case insert([OwnedCard])
            case delete(OwnedCard.ID)
        }

        private(set) var messages = [Message]()
        var retrievalResult: Result<[OwnedCard], Error> = .success([])
        var insertionResult: Result<Void, Error> = .success(())
        var deletionResult: Result<Void, Error> = .success(())

        func retrieveAll() async throws -> [OwnedCard] {
            messages.append(.retrieveAll)
            return try retrievalResult.get()
        }

        func insert(_ ownedCards: [OwnedCard]) async throws {
            messages.append(.insert(ownedCards))
            try insertionResult.get()
        }

        func delete(ownedCardID: OwnedCard.ID) async throws {
            messages.append(.delete(ownedCardID))
            try deletionResult.get()
        }
    }
}
