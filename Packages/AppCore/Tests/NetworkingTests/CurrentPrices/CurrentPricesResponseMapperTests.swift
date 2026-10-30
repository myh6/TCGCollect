//
//  CurrentPricesResponseMapperTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct CurrentPricesResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: CurrentPricesResponseMapper.Error.invalidData) {
            try CurrentPricesResponseMapper.map(makeCardsJSON([]), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test(arguments: ["invalid json", #"{"cards": []}"#])
    func map_throwsInvalidDataErrorOn200HTTPResponseWithoutAListOfCards(json: String) {
        #expect(throws: CurrentPricesResponseMapper.Error.invalidData) {
            try CurrentPricesResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversNoPricesOn200HTTPResponseWithEmptyList() throws {
        #expect(try map([]).isEmpty)
    }

    @Test func map_deliversPricesInBackendOrder() throws {
        let card0 = makeRemoteCard(id: 0, name: "a card", price: "9.99")
        let card1 = makeRemoteCard(
            id: 1, name: "another card", price: "1234.50", currency: "JPY",
            fetchedAt: (Date(timeIntervalSince1970: 1_767_225_600), "2026-01-01T09:00:00+09:00")
        )

        let prices = try map([card0.json, card1.json])

        #expect(prices == [card0.price, card1.price])
    }

    @Test func map_skipsCardWithoutPrice() throws {
        let priced = makeRemoteCard(id: 0, name: "a card")
        var unpriced = makeRemoteCard(id: 1, name: "another card").json
        unpriced["current_price"] = NSNull()

        let prices = try map([unpriced, priced.json])

        #expect(prices == [priced.price])
    }

    @Test func map_skipsOnlyTheMalformedCard() throws {
        let valid = makeRemoteCard(id: 0, name: "a card")
        var malformed = makeRemoteCard(id: 1, name: "another card").json
        malformed["card_id"] = "not an id"

        let prices = try map([malformed, valid.json])

        #expect(prices == [valid.price])
    }

    // MARK: - Helpers
    private func map(_ cards: [[String: Any]]) throws -> [PricePoint] {
        try CurrentPricesResponseMapper.map(makeCardsJSON(cards), from: httpResponse(statusCode: 200))
    }

    private func makeCardsJSON(_ cards: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: cards)
    }
}
