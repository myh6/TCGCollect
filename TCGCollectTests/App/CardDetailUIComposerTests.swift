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

    @Test func addToCollection_addsToCollection() async {
        let card = makeCard(id: 7)
        let collection = CollectionStub()
        let sut = CardDetailUIComposer.makeOwnership(of: 7, in: collection)

        await sut.addToCollection.add(card)

        #expect(collection.ownedCards.map(\.card) == [card])
    }

    @Test func removeFromCollection_removesNewestCopyFromCollection() async {
        let collection = CollectionStub(ownedCards: [OwnedCard(card: makeCard(id: 7)), OwnedCard(card: makeCard(id: 7))])
        let oldest = collection.ownedCards[0]
        let sut = CardDetailUIComposer.makeOwnership(of: 7, in: collection)

        await sut.removeFromCollection.removeNewestCopy(of: 7)

        #expect(collection.ownedCards == [oldest])
    }

    // MARK: - Helpers
    private func makeCard(id: Int) -> Card {
        Card(id: id, name: "card \(id)")
    }

    @MainActor
    private final class CollectionStub: OwnedCardCopyCounter, OwnedCardChangeObserver, OwnedCardAdder, OwnedCardRemover {
        private(set) var ownedCards: [OwnedCard]

        init(ownedCards: [OwnedCard] = []) {
            self.ownedCards = ownedCards
        }

        func countCopies(of cardID: Card.ID) async throws -> Int {
            ownedCards.filter { $0.card.id == cardID }.count
        }

        func changes() -> AsyncStream<Void> {
            AsyncStream { $0.finish() }
        }

        func addCopies(of card: Card, count: Int) async throws {
            ownedCards += (1...count).map { _ in OwnedCard(card: card) }
        }

        func removeNewestCopy(of cardID: Card.ID) async throws {
            guard let newest = ownedCards.lastIndex(where: { $0.card.id == cardID }) else { return }
            ownedCards.remove(at: newest)
        }

        func remove(ownedCardIDs: [OwnedCard.ID]) async throws {
            ownedCards.removeAll { ownedCardIDs.contains($0.id) }
        }
    }
}
