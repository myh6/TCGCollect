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

        @Test func delete_removesOnlyOwnedCardWithID() async throws {
            let kept = OwnedCard(card: Card(id: 1, name: "a card"))
            let deleted = OwnedCard(card: Card(id: 2, name: "another card"))
            let sut = try makeSUT()
            try await sut.insert([kept])
            try await sut.insert([deleted])

            try await sut.delete(ownedCardID: deleted.id)

            #expect(try await sut.retrieveAll() == [kept])
        }

        @Test func delete_removesOwnedCardForAnotherInstanceToo() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let sut = try makeSUT()
            try await sut.insert([ownedCard])

            try await sut.delete(ownedCardID: ownedCard.id)

            #expect(try await makeSUT().retrieveAll().isEmpty)
        }

        @Test func delete_doesNothingForIDNotInStore() async throws {
            let ownedCard = makeOwnedCardWithAllValues()
            let sut = try makeSUT()
            try await sut.insert([ownedCard])

            try await sut.delete(ownedCardID: UUID())

            #expect(try await sut.retrieveAll() == [ownedCard])
        }

        // MARK: - Helpers
        private func makeSUT() throws -> OwnedCardStore {
            try SwiftDataOwnedCardStore(storeURL: storeURL)
        }

        /// Opens the same store file, but every save fails.
        private func makeReadOnlySUT() throws -> OwnedCardStore {
            try SwiftDataOwnedCardStore(storeURL: storeURL, allowsSave: false)
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
