//
//  CardSetPageResponseMapperTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct CardSetPageResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 404, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: CardSetPageResponseMapper.Error.invalidData) {
            try CardSetPageResponseMapper.map(makeJSON(cards: [], total: 0), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test(arguments: ["invalid json", "[]", #"{"cards": []}"#, #"{"total": 0}"#])
    func map_throwsInvalidDataErrorOn200HTTPResponseWithoutCardsAndTotal(json: String) {
        #expect(throws: CardSetPageResponseMapper.Error.invalidData) {
            try CardSetPageResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversEmptyPageWithTotal() throws {
        let page = try map(cards: [], total: 156)

        #expect(page == CardSetPage(cards: [], totalCount: 156))
    }

    @Test func map_deliversCardsInBackendOrderWithTotal() throws {
        let card0 = makeRemoteCard(id: 0, name: "a card", number: "OP01-001", setID: 1, setName: "a set")
        let card1 = makeRemoteCard(id: 1, name: "another card", number: "OP01-002", setID: 1, setName: "a set")

        let page = try map(cards: [card0.json, card1.json], total: 156)

        #expect(page == CardSetPage(cards: [card0.result, card1.result], totalCount: 156))
    }

    @Test func map_deliversCardWithoutPriceWhenPriceValuesAreNull() throws {
        var card = makeRemoteCard(id: 0, name: "a card")
        for key in ["current_price", "currency", "current_fetched_at"] {
            card.json[key] = NSNull()
        }

        let page = try map(cards: [card.json], total: 1)

        #expect(page.cards == [CardSearchResult(card: card.card, price: nil)])
    }

    @Test func map_skipsOnlyTheCardWithAMissingCardValue() throws {
        let validCard = makeRemoteCard(id: 0, name: "a card")
        var invalidJSON = makeRemoteCard(id: 1, name: "another card").json
        invalidJSON["card_id"] = nil

        let page = try map(cards: [invalidJSON, validCard.json], total: 2)

        #expect(page.cards == [validCard.result])
    }

    // MARK: - Helpers
    private func map(cards: [[String: Any]], total: Int) throws -> CardSetPage {
        try CardSetPageResponseMapper.map(makeJSON(cards: cards, total: total), from: httpResponse(statusCode: 200))
    }

    private func makeJSON(cards: [[String: Any]], total: Int) -> Data {
        try! JSONSerialization.data(withJSONObject: ["cards": cards, "total": total])
    }
}
