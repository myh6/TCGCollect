//
//  CardSearchResponseMapperTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct CardSearchResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: CardSearchResponseMapper.Error.invalidData) {
            try CardSearchResponseMapper.map(makeResultsJSON([]), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test(arguments: ["invalid json", #"{"cards": []}"#])
    func map_throwsInvalidDataErrorOn200HTTPResponseWithoutAListOfCards(json: String) {
        #expect(throws: CardSearchResponseMapper.Error.invalidData) {
            try CardSearchResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversNoResultsOn200HTTPResponseWithEmptyList() throws {
        let results = try CardSearchResponseMapper.map(makeResultsJSON([]), from: httpResponse(statusCode: 200))

        #expect(results.isEmpty)
    }

    @Test func map_deliversResultsInBackendOrderOn200HTTPResponseWithCards() throws {
        let card0 = makeRemoteCard(id: 0, name: "a card")
        let card1 = makeRemoteCard(
            id: 1,
            name: "another card",
            number: "OP01-001",
            setID: 2,
            setName: "a set",
            imageURL: URL(string: "https://an-image.com/card.png"),
            rarity: "L",
            printing: "a printing",
            price: "1234.50",
            currency: "JPY",
            fetchedAt: (Date(timeIntervalSince1970: 1_767_225_600), "2026-01-01T09:00:00+09:00")
        )

        let results = try CardSearchResponseMapper.map(makeResultsJSON([card0.json, card1.json]), from: httpResponse(statusCode: 200))

        #expect(results == [card0.result, card1.result])
    }

    // A card the backend has no price for yet should still be found.
    @Test func map_deliversResultWithoutPriceWhenPriceValuesAreNull() throws {
        var card = makeRemoteCard(id: 0, name: "a card")
        for key in priceKeys {
            card.json[key] = NSNull()
        }

        let results = try CardSearchResponseMapper.map(makeResultsJSON([card.json]), from: httpResponse(statusCode: 200))

        #expect(results == [CardSearchResult(card: card.card, price: nil)])
    }

    @Test(arguments: [
        ("current_price", nil),
        ("currency", nil),
        ("current_fetched_at", nil),
        ("current_price", "not a price"),
        ("current_fetched_at", "not a date"),
    ] as [(String, String?)])
    func map_deliversResultWithoutPriceWhenAPriceValueIsMissingOrInvalid(key: String, value: String?) throws {
        var card = makeRemoteCard(id: 0, name: "a card")
        card.json[key] = value

        let results = try CardSearchResponseMapper.map(makeResultsJSON([card.json]), from: httpResponse(statusCode: 200))

        #expect(results == [CardSearchResult(card: card.card, price: nil)])
    }

    @Test(arguments: [
        ("card_id", nil),
        ("name", nil),
        ("card_id", "not an id"),
    ] as [(String, String?)])
    func map_skipsOnlyTheCardWithAMissingOrInvalidCardValue(key: String, value: String?) throws {
        let validCard = makeRemoteCard(id: 0, name: "a card")
        var invalidJSON = makeRemoteCard(id: 1, name: "another card").json
        invalidJSON[key] = value

        let results = try CardSearchResponseMapper.map(makeResultsJSON([invalidJSON, validCard.json]), from: httpResponse(statusCode: 200))

        #expect(results == [validCard.result])
    }

    // MARK: - Helpers
    private let priceKeys = ["current_price", "currency", "current_fetched_at"]

    private func makeResultsJSON(_ cards: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: cards)
    }
}

private extension RemoteCardFixture {
    var result: CardSearchResult { CardSearchResult(card: card, price: price) }
}
