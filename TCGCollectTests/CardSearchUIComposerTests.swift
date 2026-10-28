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

    // MARK: - Helpers
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
}
