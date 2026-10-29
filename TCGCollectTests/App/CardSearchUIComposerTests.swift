//
//  CardSearchUIComposerTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

@MainActor
struct CardSearchUIComposerTests {

    @Test func ownedCardsSection_searchesOwnedCardsWithQuery() async {
        let searcher = OwnedCardSearcherStub(result: [])
        let sut = CardSearchUIComposer.makeOwnedCardsSection(searching: searcher)

        await sut.search("luffy")

        #expect(searcher.queries == ["luffy"])
    }

    @Test func ownedCardsSection_deliversOwnedCopiesGroupedByCard() async {
        let luffy = makeCard(id: 1)
        let zoro = makeCard(id: 2)
        let searcher = OwnedCardSearcherStub(result: [OwnedCard(card: luffy), OwnedCard(card: zoro), OwnedCard(card: luffy)])
        let sut = CardSearchUIComposer.makeOwnedCardsSection(searching: searcher)

        await sut.search("any query")

        #expect(sut.state == .loaded([OwnedCardGroup(card: luffy, count: 2), OwnedCardGroup(card: zoro, count: 1)]))
    }

    @Test func onlineCardsSection_searchesOnlineWithQuery() async {
        let searcher = CardSearcherStub(result: [])
        let sut = CardSearchUIComposer.makeOnlineCardsSection(searching: searcher)

        await sut.search("luffy")

        #expect(searcher.queries == ["luffy"])
    }

    @Test func onlineCardsSection_deliversSearchResults() async {
        let results = [CardSearchResult(card: makeCard(id: 1), price: nil), CardSearchResult(card: makeCard(id: 2), price: nil)]
        let sut = CardSearchUIComposer.makeOnlineCardsSection(searching: CardSearcherStub(result: results))

        await sut.search("any query")

        #expect(sut.state == .loaded(results))
    }

    @Test func addToCollection_savesWithSaver() async {
        let card = makeCard(id: 1)
        let saver = OwnedCardSaverStub(result: .success(()))
        let sut = CardSearchUIComposer.makeAddToCollection(saving: saver, refreshing: makeOwnedCardsSection(searching: OwnedCardSearcherStub(result: [])))

        await sut.add(card)

        #expect(saver.savedCards == [[card]])
    }

    @Test func addToCollection_searchesOwnedCardsAgainAfterAdding() async {
        let searcher = OwnedCardSearcherStub(result: [])
        let ownedCards = makeOwnedCardsSection(searching: searcher)
        let sut = CardSearchUIComposer.makeAddToCollection(saving: OwnedCardSaverStub(result: .success(())), refreshing: ownedCards)
        await ownedCards.search("luffy")

        await sut.add(makeCard(id: 1))

        #expect(searcher.queries == ["luffy", "luffy"])
    }

    @Test func addToCollection_doesNotSearchOwnedCardsAgainWhenAddingFails() async {
        let searcher = OwnedCardSearcherStub(result: [])
        let ownedCards = makeOwnedCardsSection(searching: searcher)
        let sut = CardSearchUIComposer.makeAddToCollection(saving: OwnedCardSaverStub(result: .failure(anyError())), refreshing: ownedCards)
        await ownedCards.search("luffy")

        await sut.add(makeCard(id: 1))

        #expect(searcher.queries == ["luffy"])
    }

    // MARK: - Helpers
    private func makeOwnedCardsSection(searching searcher: OwnedCardSearcher) -> SearchSectionViewModel<OwnedCardGroup> {
        CardSearchUIComposer.makeOwnedCardsSection(searching: searcher)
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func makeCard(id: Int) -> Card {
        Card(id: id, name: "card \(id)")
    }

    @MainActor
    private final class OwnedCardSearcherStub: OwnedCardSearcher {
        private(set) var queries = [String]()
        private let result: [OwnedCard]

        init(result: [OwnedCard]) {
            self.result = result
        }

        func search(_ query: String) async throws -> [OwnedCard] {
            queries.append(query)
            return result
        }
    }

    @MainActor
    private final class CardSearcherStub: CardSearcher {
        private(set) var queries = [String]()
        private let result: [CardSearchResult]

        init(result: [CardSearchResult]) {
            self.result = result
        }

        func search(_ query: String) async throws -> [CardSearchResult] {
            queries.append(query)
            return result
        }
    }

    @MainActor
    private final class OwnedCardSaverStub: OwnedCardSaver {
        private(set) var savedCards = [[Card]]()
        private let result: Result<Void, Error>

        init(result: Result<Void, Error>) {
            self.result = result
        }

        func save(_ ownedCards: [OwnedCard]) async throws {
            savedCards.append(ownedCards.map(\.card))
            try result.get()
        }
    }
}
