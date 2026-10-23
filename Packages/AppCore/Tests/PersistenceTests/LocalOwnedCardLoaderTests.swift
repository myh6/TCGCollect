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

    // MARK: - Helpers
    private func makeSUT() -> (sut: LocalOwnedCardLoader, store: OwnedCardStoreSpy) {
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
        }

        private(set) var messages = [Message]()
        var retrievalResult: Result<[OwnedCard], Error> = .success([])

        func retrieveAll() async throws -> [OwnedCard] {
            messages.append(.retrieveAll)
            return try retrievalResult.get()
        }
    }
}
