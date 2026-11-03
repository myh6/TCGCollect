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

@Suite(.timeLimit(.minutes(1)))
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

    @Test func countCopies_requestsCopiesOfCardFromStore() async {
        let (sut, store) = makeSUT()

        _ = try? await sut.countCopies(of: 7)

        #expect(store.messages == [.countCopies(7)])
    }

    @Test func countCopies_failsOnStoreError() async {
        let (sut, store) = makeSUT()
        store.countResult = .failure(anyNSError())

        await #expect(throws: LocalOwnedCardLoader.LoadError.failed) {
            try await sut.countCopies(of: 7)
        }
    }

    @Test func countCopies_deliversStoreCount() async throws {
        let (sut, store) = makeSUT()
        store.countResult = .success(3)

        #expect(try await sut.countCopies(of: 7) == 3)
    }

    @Test func addCopies_insertsOneNewOwnedCardPerCopyIntoStoreAsOneBatch() async throws {
        let card = Card(id: 7, name: "a card")
        let (sut, store) = makeSUT()

        try await sut.addCopies(of: card, count: 3)

        guard case let .insert(inserted) = try #require(store.messages.first) else {
            Issue.record("Expected one insert, got \(store.messages)")
            return
        }
        #expect(store.messages.count == 1)
        #expect(inserted.map(\.card) == [card, card, card])
        #expect(Set(inserted.map(\.id)).count == 3)
    }

    @Test(arguments: [0, -1])
    func addCopies_rejectsCountBelowOneWithoutMessagingStore(count: Int) async {
        let (sut, store) = makeSUT()

        await #expect(throws: LocalOwnedCardLoader.SaveError.invalidCopyCount) {
            try await sut.addCopies(of: Card(id: 7, name: "a card"), count: count)
        }
        #expect(store.messages.isEmpty)
    }

    @Test func addCopies_failsOnStoreInsertionError() async {
        let (sut, store) = makeSUT()
        store.insertionResult = .failure(anyNSError())

        await #expect(throws: LocalOwnedCardLoader.SaveError.failed) {
            try await sut.addCopies(of: Card(id: 7, name: "a card"), count: 1)
        }
    }

    @Test func remove_deletesOwnedCardsWithIDsFromStoreAsOneBatch() async {
        let ids = [UUID(), UUID()]
        let (sut, store) = makeSUT()

        try? await sut.remove(ownedCardIDs: ids)

        #expect(store.messages == [.delete(ids)])
    }

    @Test func remove_failsOnStoreDeletionError() async {
        let (sut, store) = makeSUT()
        store.deletionResult = .failure(anyNSError())

        await #expect(throws: LocalOwnedCardLoader.RemoveError.failed) {
            try await sut.remove(ownedCardIDs: [UUID()])
        }
    }

    @Test func remove_succeedsOnStoreDeletionSuccess() async throws {
        let (sut, store) = makeSUT()
        store.deletionResult = .success(())

        try await sut.remove(ownedCardIDs: [UUID()])
    }

    @Test func removeNewestCopy_deletesNewestCopyOfCardFromStore() async {
        let (sut, store) = makeSUT()

        try? await sut.removeNewestCopy(of: 7)

        #expect(store.messages == [.deleteNewestCopy(7)])
    }

    @Test func removeNewestCopy_failsOnStoreDeletionError() async {
        let (sut, store) = makeSUT()
        store.newestCopyDeletionResult = .failure(anyNSError())

        await #expect(throws: LocalOwnedCardLoader.RemoveError.failed) {
            try await sut.removeNewestCopy(of: 7)
        }
    }

    @Test func removeNewestCopy_succeedsOnStoreDeletionSuccess() async throws {
        let (sut, store) = makeSUT()
        store.newestCopyDeletionResult = .success(())

        try await sut.removeNewestCopy(of: 7)
    }

    @Test(arguments: Change.allCases)
    func change_announcesChangeOnStoreSuccess(change: Change) async throws {
        let (sut, _) = makeSUT()
        var changes = sut.changes().makeAsyncIterator()

        try await change.make(in: sut)

        #expect(await changes.next() != nil)
    }

    @Test(arguments: Change.allCases)
    func change_announcesNoChangeOnStoreFailure(change: Change) async {
        var (sut, store): (OwnedCardCollection?, OwnedCardStoreSpy) = makeSUT()
        store.failEveryChange()
        var changes = sut?.changes().makeAsyncIterator()

        if let sut { try? await change.make(in: sut) }
        sut = nil

        #expect(await changes?.next() == nil)
    }

    @Test func addCopies_announcesNoChangeForRejectedCount() async {
        var sut: OwnedCardCollection? = makeSUT().sut
        var changes = sut?.changes().makeAsyncIterator()

        try? await sut?.addCopies(of: Card(id: 7, name: "a card"), count: 0)
        sut = nil

        #expect(await changes?.next() == nil)
    }

    // MARK: - Helpers
    enum Change: CaseIterable {
        case addCopies
        case remove
        case removeNewestCopy

        func make(in collection: OwnedCardCollection) async throws {
            switch self {
            case .addCopies: try await collection.addCopies(of: Card(id: 7, name: "a card"), count: 1)
            case .remove: try await collection.remove(ownedCardIDs: [UUID()])
            case .removeNewestCopy: try await collection.removeNewestCopy(of: 7)
            }
        }
    }

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
            case countCopies(Card.ID)
            case insert([OwnedCard])
            case delete([OwnedCard.ID])
            case deleteNewestCopy(Card.ID)
        }

        private(set) var messages = [Message]()

        func failEveryChange() {
            insertionResult = .failure(anyNSError())
            deletionResult = .failure(anyNSError())
            newestCopyDeletionResult = .failure(anyNSError())
        }
        var retrievalResult: Result<[OwnedCard], Error> = .success([])
        var countResult: Result<Int, Error> = .success(0)
        var insertionResult: Result<Void, Error> = .success(())
        var deletionResult: Result<Void, Error> = .success(())
        var newestCopyDeletionResult: Result<Void, Error> = .success(())

        func retrieveAll() async throws -> [OwnedCard] {
            messages.append(.retrieveAll)
            return try retrievalResult.get()
        }

        func countCopies(of cardID: Card.ID) async throws -> Int {
            messages.append(.countCopies(cardID))
            return try countResult.get()
        }

        func insert(_ ownedCards: [OwnedCard]) async throws {
            messages.append(.insert(ownedCards))
            try insertionResult.get()
        }

        func delete(ownedCardIDs: [OwnedCard.ID]) async throws {
            messages.append(.delete(ownedCardIDs))
            try deletionResult.get()
        }

        func deleteNewestCopy(of cardID: Card.ID) async throws {
            messages.append(.deleteNewestCopy(cardID))
            try newestCopyDeletionResult.get()
        }
    }
}
