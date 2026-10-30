//
//  CardDetailUIComposerTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

@MainActor
struct CardDetailUIComposerTests {

    @Test func copies_countsThisCardInCollection() async {
        let collection = CollectionStub(ownedCards: [OwnedCard(card: makeCard(id: 7)), OwnedCard(card: makeCard(id: 8))])
        let sut = CardDetailUIComposer.makeOwnership(of: 7, in: collection)

        await sut.copies.load()

        #expect(sut.copies.copies == .loaded(1))
    }

    @Test func addToCollection_savesToCollection() async {
        let card = makeCard(id: 7)
        let collection = CollectionStub()
        let sut = CardDetailUIComposer.makeOwnership(of: 7, in: collection)

        await sut.addToCollection.add(card)

        #expect(collection.ownedCards.map(\.card) == [card])
    }

    @Test func addToCollection_recountsCopiesAfterAdding() async {
        let card = makeCard(id: 7)
        let collection = CollectionStub()
        let sut = CardDetailUIComposer.makeOwnership(of: 7, in: collection)
        await sut.copies.load()

        await sut.addToCollection.add(card)

        #expect(sut.copies.copies == .loaded(1))
    }

    @Test func addToCollection_doesNotRecountWhenAddingFails() async {
        let collection = CollectionStub(saveError: NSError(domain: "any error", code: 0))
        let sut = CardDetailUIComposer.makeOwnership(of: 7, in: collection)
        await sut.copies.load()

        await sut.addToCollection.add(makeCard(id: 7))

        #expect(collection.loadCount == 1)
    }

    // MARK: - Helpers
    private func makeCard(id: Int) -> Card {
        Card(id: id, name: "card \(id)")
    }

    @MainActor
    private final class CollectionStub: OwnedCardLoader, OwnedCardSaver {
        private(set) var ownedCards: [OwnedCard]
        private(set) var loadCount = 0
        private let saveError: Error?

        init(ownedCards: [OwnedCard] = [], saveError: Error? = nil) {
            self.ownedCards = ownedCards
            self.saveError = saveError
        }

        func load() async throws -> [OwnedCard] {
            loadCount += 1
            return ownedCards
        }

        func save(_ newCards: [OwnedCard]) async throws {
            if let saveError { throw saveError }
            ownedCards += newCards
        }
    }
}
