//
//  SwiftDataOwnedCardStoreTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import Domain
@testable import Persistence

extension SwiftDataStoreFileTests {
    /// Runs against a real store file. Swift Testing makes a new instance per test,
    /// so each test gets its own folder, and `deinit` removes it.
    /// Nested in `SwiftDataStoreFileTests` so it never sets up store files at the same time as another suite.
    final class SwiftDataOwnedCardStoreTests {
        private let directory = FileManager.default.temporaryDirectory
            .appending(path: "SwiftDataOwnedCardStoreTests-\(UUID().uuidString)")

        deinit {
            try? FileManager.default.removeItem(at: directory)
        }

        @Test func retrieveAll_deliversNothingOnEmptyStore() async throws {
            let sut = try makeSUT()

            let ownedCards = try await sut.retrieveAll()

            #expect(ownedCards.isEmpty)
        }

        @Test func retrieveAll_deliversInsertedOwnedCardWithAllItsValues() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let sut = try makeSUT()

            try await sut.insert([ownedCard])
            let ownedCards = try await sut.retrieveAll()

            #expect(ownedCards == [ownedCard])
        }

        @Test func retrieveAll_deliversInsertedOwnedCardWithoutOptionalValues() async throws {
            let ownedCard = OwnedCard(card: Card(id: 1, name: "a card"))
            let sut = try makeSUT()

            try await sut.insert([ownedCard])
            let ownedCards = try await sut.retrieveAll()

            #expect(ownedCards == [ownedCard])
        }

        @Test func retrieveAll_deliversOwnedCardsInInsertionOrder() async throws {
            let ownedCards = [3, 1, 2].map { OwnedCard(card: Card(id: $0, name: "card \($0)")) }
            let sut = try makeSUT()

            for ownedCard in ownedCards {
                try await sut.insert([ownedCard])
            }

            #expect(try await sut.retrieveAll() == ownedCards)
        }

        @Test func retrieveAll_hasNoSideEffects() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let sut = try makeSUT()
            try await sut.insert([ownedCard])

            _ = try await sut.retrieveAll()
            let ownedCards = try await sut.retrieveAll()

            #expect(ownedCards == [ownedCard])
        }

        // Like the app starting again: a new store on the same file finds what was inserted before.
        @Test func retrieveAll_deliversOwnedCardsInsertedByAnotherInstance() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            try await makeSUT().insert([ownedCard])

            let ownedCards = try await makeSUT().retrieveAll()

            #expect(ownedCards == [ownedCard])
        }

        @Test func insert_replacesOwnedCardWithSameID() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let edited = makeEdited(ownedCard)
            let sut = try makeSUT()
            try await sut.insert([ownedCard])

            try await sut.insert([edited])

            #expect(try await sut.retrieveAll() == [edited])
        }

        @Test func insert_keepsPlaceOfReplacedOwnedCard() async throws {
            let first = OwnedCard(card: Card(id: 1, name: "a card"))
            let second = OwnedCard(card: Card(id: 2, name: "another card"))
            let editedFirst = makeEdited(first)
            let sut = try makeSUT()
            try await sut.insert([first])
            try await sut.insert([second])

            try await sut.insert([editedFirst])

            #expect(try await sut.retrieveAll() == [editedFirst, second])
        }

        @Test func insert_replacesOwnedCardForAnotherInstanceToo() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let edited = makeEdited(ownedCard)
            let sut = try makeSUT()
            try await sut.insert([ownedCard])

            try await sut.insert([edited])

            #expect(try await makeSUT().retrieveAll() == [edited])
        }

        @Test func insert_addsBatchAfterStoredOwnedCardsInBatchOrder() async throws {
            let stored = OwnedCard(card: Card(id: 1, name: "a card"))
            let batch = [3, 2].map { OwnedCard(card: Card(id: $0, name: "card \($0)")) }
            let sut = try makeSUT()
            try await sut.insert([stored])

            try await sut.insert(batch)

            #expect(try await sut.retrieveAll() == [stored] + batch)
        }

        @Test func insert_addsBatchForAnotherInstanceToo() async throws {
            let batch = [1, 2].map { OwnedCard(card: Card(id: $0, name: "card \($0)")) }
            let sut = try makeSUT()

            try await sut.insert(batch)

            #expect(try await makeSUT().retrieveAll() == batch)
        }

        @Test func insert_ofEmptyBatchDoesNothing() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let sut = try makeSUT()
            try await sut.insert([ownedCard])

            try await sut.insert([])

            #expect(try await sut.retrieveAll() == [ownedCard])
        }

        @Test func insert_replacesAndAddsOwnedCardsInSameBatch() async throws {
            let first = OwnedCard(card: Card(id: 1, name: "a card"))
            let second = OwnedCard(card: Card(id: 2, name: "another card"))
            let added = OwnedCard(card: Card(id: 3, name: "a new card"))
            let editedFirst = makeEdited(first)
            let sut = try makeSUT()
            try await sut.insert([first, second])

            try await sut.insert([editedFirst, added])

            #expect(try await sut.retrieveAll() == [editedFirst, second, added])
        }

        @Test func insert_keepsLastOfOwnedCardsWithSameIDInBatch() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let edited = makeEdited(ownedCard)
            let sut = try makeSUT()

            try await sut.insert([ownedCard, edited])

            #expect(try await sut.retrieveAll() == [edited])
        }

        @Test func insert_storesNoneOfBatchWhenSaveFails() async throws {
            let stored = OwnedCard(card: Card(id: 1, name: "a card"))
            try await makeSUT().insert([stored])
            let sut = try makeReadOnlySUT()

            await #expect(throws: (any Error).self) {
                try await sut.insert([stored, makeOwnedCardWithAllValues()])
            }

            // Neither the store that failed nor another instance may show any of the failed batch.
            #expect(try await sut.retrieveAll() == [stored])
            #expect(try await makeSUT().retrieveAll() == [stored])
        }

        @Test func delete_removesOnlyOwnedCardsWithIDs() async throws {
            let ownedCards = [1, 2, 3].map { OwnedCard(card: Card(id: $0, name: "card \($0)")) }
            let sut = try makeSUT()
            try await sut.insert(ownedCards)

            try await sut.delete(ownedCardIDs: [ownedCards[0].id, ownedCards[2].id])

            #expect(try await sut.retrieveAll() == [ownedCards[1]])
        }

        @Test func delete_removesOwnedCardsForAnotherInstanceToo() async throws {
            let ownedCards = [1, 2].map { OwnedCard(card: Card(id: $0, name: "card \($0)")) }
            let sut = try makeSUT()
            try await sut.insert(ownedCards)

            try await sut.delete(ownedCardIDs: ownedCards.map(\.id))

            #expect(try await makeSUT().retrieveAll().isEmpty)
        }

        @Test func delete_ignoresIDsNotInStore() async throws {
            let kept = OwnedCard(card: Card(id: 1, name: "a card"))
            let deleted = OwnedCard(card: Card(id: 2, name: "another card"))
            let sut = try makeSUT()
            try await sut.insert([kept, deleted])

            try await sut.delete(ownedCardIDs: [UUID(), deleted.id])

            #expect(try await sut.retrieveAll() == [kept])
        }

        @Test func delete_ofEmptyBatchDoesNothing() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let sut = try makeSUT()
            try await sut.insert([ownedCard])

            try await sut.delete(ownedCardIDs: [])

            #expect(try await sut.retrieveAll() == [ownedCard])
        }

        @Test func delete_removesNoneOfBatchWhenSaveFails() async throws {
            let ownedCards = [1, 2].map { OwnedCard(card: Card(id: $0, name: "card \($0)")) }
            try await makeSUT().insert(ownedCards)
            let sut = try makeReadOnlySUT()

            await #expect(throws: (any Error).self) {
                try await sut.delete(ownedCardIDs: ownedCards.map(\.id))
            }

            #expect(try await sut.retrieveAll() == ownedCards)
            #expect(try await makeSUT().retrieveAll() == ownedCards)
        }

        @Test func deleteNewestCopy_removesOnlyTheLastStoredCopyOfCard() async throws {
            let firstLuffy = makeCopy(of: luffy)
            let zoroCopy = makeCopy(of: zoro)
            let secondLuffy = makeCopy(of: luffy)
            let sut = try makeSUT()
            try await sut.insert([firstLuffy, zoroCopy, secondLuffy])

            try await sut.deleteNewestCopy(of: luffy.id)

            #expect(try await sut.retrieveAll() == [firstLuffy, zoroCopy])
        }

        @Test func deleteNewestCopy_doesNothingWithoutCopiesOfCard() async throws {
            let zoroCopy = makeCopy(of: zoro)
            let sut = try makeSUT()
            try await sut.insert([zoroCopy])

            try await sut.deleteNewestCopy(of: luffy.id)

            #expect(try await sut.retrieveAll() == [zoroCopy])
        }

        @Test func deleteNewestCopy_removesCopyForAnotherInstanceToo() async throws {
            let sut = try makeSUT()
            try await sut.insert([makeCopy(of: luffy)])

            try await sut.deleteNewestCopy(of: luffy.id)

            #expect(try await makeSUT().retrieveAll().isEmpty)
        }

        @Test func deleteNewestCopy_removesNothingWhenSaveFails() async throws {
            let copies = [makeCopy(of: luffy), makeCopy(of: luffy)]
            try await makeSUT().insert(copies)
            let sut = try makeReadOnlySUT()

            await #expect(throws: (any Error).self) {
                try await sut.deleteNewestCopy(of: luffy.id)
            }

            #expect(try await sut.retrieveAll() == copies)
            #expect(try await makeSUT().retrieveAll() == copies)
        }

        @Test func deleteNewestCopy_removesADifferentCopyForEachCallMadeAtTheSameTime() async throws {
            let oldest = makeCopy(of: luffy)
            let cardID = luffy.id
            let sut = try SwiftDataOwnedCardStore(storeURL: storeURL)
            try await sut.insert([oldest, makeCopy(of: luffy), makeCopy(of: luffy)])

            async let first: Void = sut.deleteNewestCopy(of: cardID)
            async let second: Void = sut.deleteNewestCopy(of: cardID)
            _ = try await (first, second)

            #expect(try await sut.retrieveAll() == [oldest])
        }

        @Test func countCopies_isZeroWithoutCopiesOfCard() async throws {
            let sut = try makeSUT()
            try await sut.insert([makeCopy(of: zoro)])

            #expect(try await sut.countCopies(of: luffy.id) == 0)
        }

        @Test func countCopies_countsOnlyCopiesOfCard() async throws {
            let sut = try makeSUT()
            try await sut.insert([makeCopy(of: luffy), makeCopy(of: zoro), makeCopy(of: luffy)])

            #expect(try await sut.countCopies(of: luffy.id) == 2)
        }

        @Test func countCopies_countsCopiesStoredByAnotherInstance() async throws {
            try await makeSUT().insert([makeCopy(of: luffy), makeCopy(of: luffy)])

            #expect(try await makeSUT().countCopies(of: luffy.id) == 2)
        }

        @Test func countCopies_leavesOutDeletedCopies() async throws {
            let sut = try makeSUT()
            try await sut.insert([makeCopy(of: luffy), makeCopy(of: luffy)])

            try await sut.deleteNewestCopy(of: luffy.id)

            #expect(try await sut.countCopies(of: luffy.id) == 1)
        }

        // MARK: - Helpers
        private func makeSUT() throws -> OwnedCardStore {
            try SwiftDataOwnedCardStore(storeURL: storeURL)
        }

        /// Opens the same store file, but every save fails.
        private func makeReadOnlySUT() throws -> OwnedCardStore {
            try SwiftDataOwnedCardStore(storeURL: storeURL, allowsSave: false)
        }

        private let luffy = Card(id: 1, name: "Monkey.D.Luffy")
        private let zoro = Card(id: 2, name: "Roronoa Zoro")

        private func makeCopy(of card: Card) -> OwnedCard {
            OwnedCard(card: card)
        }

        private var storeURL: URL {
            directory.appending(path: "OwnedCards.store")
        }

        private func makeOwnedCardWithAllValues() -> OwnedCard {
            OwnedCard(
                card: Card(
                    id: 42,
                    name: "Monkey.D.Luffy",
                    number: "OP01-024",
                    setID: 7,
                    setName: "Romance Dawn",
                    imageURL: URL(string: "https://an-image-url.com/op01-024.png"),
                    rarity: "L",
                    printing: "Normal"
                ),
                purchasePrice: Money(amount: Decimal(string: "12.34")!, currencyCode: "USD"),
                acquiredOn: Date(timeIntervalSince1970: 1_700_000_000)
            )
        }

        /// The same owned card, i.e. the same `id`, after the user changed what they paid and when.
        private func makeEdited(_ ownedCard: OwnedCard) -> OwnedCard {
            var edited = ownedCard
            edited.purchasePrice = Money(amount: Decimal(string: "56.78")!, currencyCode: "JPY")
            edited.acquiredOn = Date(timeIntervalSince1970: 1_800_000_000)
            return edited
        }
    }
}
