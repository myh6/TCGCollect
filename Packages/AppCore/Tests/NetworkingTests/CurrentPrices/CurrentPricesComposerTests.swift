//
//  CurrentPricesComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import Networking
import Domain

@Suite(.serialized)
struct CurrentPricesComposerTests {

    @Test func makeRemoteCardPriceLoader_sendsCardIDsWithAPIKeyToBaseURL() async throws {
        let sut = makeSUT(replyingWith: makeCardsJSON([]))

        _ = try await sut.loadCurrentPrices(for: [675180, 2])

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/prices/current")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
        #expect(Stub.requestJSONBodies == [["card_ids": [675180, 2]]])
    }

    @Test func makeRemoteCardPriceLoader_deliversPricesFromBackend() async throws {
        let card: [String: Any] = [
            "card_id": 7,
            "name": "a card",
            "current_price": "9.99",
            "currency": "USD",
            "current_fetched_at": "2026-01-01T00:00:00+00:00",
        ]
        let sut = makeSUT(replyingWith: makeCardsJSON([card]))

        let prices = try await sut.loadCurrentPrices(for: [7])

        #expect(prices == [PricePoint(
            cardID: 7,
            date: Date(timeIntervalSince1970: 1_767_225_600),
            price: Money(amount: Decimal(string: "9.99")!, currencyCode: "USD")
        )])
    }

    // MARK: - Helpers
    private func makeSUT(replyingWith data: Data) -> CardPriceLoader {
        CurrentPricesComposer.makeRemoteCardPriceLoader(
            baseURL: URL(string: "http://base-url.com")!,
            apiKey: "an api key",
            session: Stub.makeSession(replyingWith: data)
        )
    }

    private func makeCardsJSON(_ cards: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: cards)
    }

    private final class Stub: URLProtocolStub {}
}
