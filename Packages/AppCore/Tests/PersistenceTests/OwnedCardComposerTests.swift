//
//  OwnedCardComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Testing
import Domain
import Persistence

extension SwiftDataStoreFileTests {
    /// Runs the whole chain against a real store file, in a new folder per test that `deinit` removes.
    /// Nested in `SwiftDataStoreFileTests` so it never sets up store files at the same time as another suite.
    final class OwnedCardComposerTests {
        private let directory = FileManager.default.temporaryDirectory
            .appending(path: "OwnedCardComposerTests-\(UUID().uuidString)")

        deinit {
            try? FileManager.default.removeItem(at: directory)
        }

        @Test func makeLocalOwnedCardCollection_keepsOwnedCardsInFileAtStoreURL() async throws {
            let sut = try makeSUT()

            try await sut.save([makeOwnedCard(cardID: 1)])

            #expect(FileManager.default.fileExists(atPath: storeURL.path()))
        }

        // Like the app starting again: a collection made later on the same file finds what was saved before.
        @Test func makeLocalOwnedCardCollection_deliversOwnedCardsSavedByAnotherCollection() async throws {
            let ownedCards = [makeOwnedCard(cardID: 1), makeOwnedCard(cardID: 2)]
            let saver = try makeSUT()
            try await saver.save(ownedCards)

            let loaded = try await makeSUT().load()

            #expect(loaded == ownedCards)
        }

        @Test func makeLocalOwnedCardCollection_doesNotDeliverOwnedCardRemovedByAnotherCollection() async throws {
            let kept = makeOwnedCard(cardID: 1)
            let removed = makeOwnedCard(cardID: 2)
            let sut = try makeSUT()
            try await sut.save([kept, removed])

            try await sut.remove(ownedCardID: removed.id)

            #expect(try await makeSUT().load() == [kept])
        }

        @Test func makeOwnedCardSearcher_findsOwnedCardsSavedInCollection() async throws {
            let luffy = makeOwnedCard(cardID: 1, name: "Monkey D. Luffy")
            let collection = try makeSUT()
            try await collection.save([luffy, makeOwnedCard(cardID: 2, name: "Roronoa Zoro")])
            let searcher = OwnedCardComposer.makeOwnedCardSearcher(searching: collection)

            #expect(try await searcher.search("luffy") == [luffy])
        }

        // The searcher reads the collection on every search, so it never misses a card added after it was made.
        @Test func makeOwnedCardSearcher_findsOwnedCardSavedAfterItWasMade() async throws {
            let collection = try makeSUT()
            let searcher = OwnedCardComposer.makeOwnedCardSearcher(searching: collection)
            let zoro = makeOwnedCard(cardID: 1, name: "Roronoa Zoro")

            try await collection.save([zoro])

            #expect(try await searcher.search("zoro") == [zoro])
        }

        // MARK: - Helpers
        private var storeURL: URL {
            directory.appending(path: "OwnedCards.store")
        }

        private func makeSUT() throws -> OwnedCardCollection {
            try OwnedCardComposer.makeLocalOwnedCardCollection(storeURL: storeURL)
        }

        private func makeOwnedCard(cardID: Int, name: String? = nil) -> OwnedCard {
            OwnedCard(card: Card(id: cardID, name: name ?? "card \(cardID)"))
        }
    }
}
