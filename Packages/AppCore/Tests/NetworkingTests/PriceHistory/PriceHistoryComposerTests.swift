//
//  PriceHistoryComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import Networking
import Domain

@Suite(.serialized)
struct PriceHistoryComposerTests {

    @Test func makeRemoteCardPriceHistoryLoader_sendsCardIDsAndDaysWithAPIKeyToBaseURL() async throws {
        let sut = makeSUT(replyingWith: makeHistoryJSON([]))

        _ = try await sut.loadPriceHistory(for: [675180], days: 90)

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/prices/history")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
        #expect(Stub.requestJSONBodies == [["card_ids": [675180], "days": 90]])
    }

    @Test func makeRemoteCardPriceHistoryLoader_deliversPricePointsFromBackend() async throws {
        let row: [String: Any] = ["card_id": 7, "market_price": "9.99", "currency": "USD", "fetched_at": "2026-01-01T00:00:00+00:00"]
        let sut = makeSUT(replyingWith: makeHistoryJSON([row]))

        let points = try await sut.loadPriceHistory(for: [7], days: nil)

        #expect(points == [PricePoint(
            cardID: 7,
            date: Date(timeIntervalSince1970: 1_767_225_600),
            price: Money(amount: Decimal(string: "9.99")!, currencyCode: "USD")
        )])
    }

    // MARK: - Helpers
    private func makeSUT(replyingWith data: Data) -> CardPriceHistoryLoader {
        PriceHistoryComposer.makeRemoteCardPriceHistoryLoader(
            baseURL: URL(string: "http://base-url.com")!,
            apiKey: "an api key",
            session: Stub.makeSession(replyingWith: data)
        )
    }

    private func makeHistoryJSON(_ rows: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: rows)
    }

    private final class Stub: URLProtocolStub {}
}
