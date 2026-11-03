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

            try await sut.addCopies(of: luffy, count: 1)

            #expect(FileManager.default.fileExists(atPath: storeURL.path()))
        }

        // Like the app starting again: a collection made later on the same file finds what was saved before.
        @Test func makeLocalOwnedCardCollection_deliversCopiesAddedByAnotherCollectionInOrder() async throws {
            let collection = try makeSUT()
            try await collection.addCopies(of: luffy, count: 2)
            try await collection.addCopies(of: zoro, count: 1)

            let loaded = try await makeSUT().load()

            #expect(loaded.map(\.card) == [luffy, luffy, zoro])
        }

        @Test func makeLocalOwnedCardCollection_doesNotDeliverOwnedCardRemovedByAnotherCollection() async throws {
            let sut = try makeSUT()
            try await sut.addCopies(of: luffy, count: 1)
            try await sut.addCopies(of: zoro, count: 1)
            let zoroCopy = try #require(try await sut.load().last)

            try await sut.remove(ownedCardIDs: [zoroCopy.id])

            #expect(try await makeSUT().load().map(\.card) == [luffy])
        }

        @Test func makeLocalOwnedCardCollection_doesNotDeliverNewestCopyRemovedByAnotherCollection() async throws {
            let sut = try makeSUT()
            try await sut.addCopies(of: luffy, count: 2)
            let oldest = try #require(try await sut.load().first)

            try await sut.removeNewestCopy(of: luffy.id)

            #expect(try await makeSUT().load() == [oldest])
        }

        @Test func makeLocalOwnedCardCollection_countsCopiesAddedByAnotherCollection() async throws {
            let collection = try makeSUT()
            try await collection.addCopies(of: luffy, count: 2)
            try await collection.addCopies(of: zoro, count: 1)

            #expect(try await makeSUT().countCopies(of: luffy.id) == 2)
        }

        @Test func makeOwnedCardSearcher_findsOwnedCardsAddedToCollection() async throws {
            let collection = try makeSUT()
            try await collection.addCopies(of: luffy, count: 1)
            try await collection.addCopies(of: zoro, count: 1)
            let searcher = OwnedCardComposer.makeOwnedCardSearcher(searching: collection)

            #expect(try await searcher.search("luffy").map(\.card) == [luffy])
        }

        // The searcher reads the collection on every search, so it never misses a card added after it was made.
        @Test func makeOwnedCardSearcher_findsOwnedCardAddedAfterItWasMade() async throws {
            let collection = try makeSUT()
            let searcher = OwnedCardComposer.makeOwnedCardSearcher(searching: collection)

            try await collection.addCopies(of: zoro, count: 1)

            #expect(try await searcher.search("zoro").map(\.card) == [zoro])
        }

        // MARK: - Helpers
        private let luffy = Card(id: 1, name: "Monkey D. Luffy")
        private let zoro = Card(id: 2, name: "Roronoa Zoro")

        private var storeURL: URL {
            directory.appending(path: "OwnedCards.store")
        }

        private func makeSUT() throws -> OwnedCardCollection {
            try OwnedCardComposer.makeLocalOwnedCardCollection(storeURL: storeURL)
        }
    }
}
