//
//  CollectionValueComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Testing
import Networking
import Domain

@Suite(.serialized)
struct CollectionValueComposerTests {

    @Test func makeRemoteCollectionValueHistoryLoader_sendsQuantitiesAndDaysWithAPIKeyToBaseURL() async throws {
        let sut = makeSUT(replyingWith: makeJSON(currentTotal: nil, history: []))

        _ = try await sut.loadValueHistory(of: [675180: 2], days: 90)

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/collections/value-history")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
        #expect(Stub.requestJSONBodies == [["cards": [["card_id": 675180, "quantity": 2]], "days": 90]])
    }

    @Test func makeRemoteCollectionValueHistoryLoader_deliversValueHistoryFromBackend() async throws {
        let sut = makeSUT(replyingWith: makeJSON(currentTotal: "9.99", history: [["date": "2026-11-01", "total_value": "9.99"]]))

        let history = try await sut.loadValueHistory(of: [7: 1], days: nil)

        let nineNinetyNine = Money(amount: Decimal(string: "9.99")!, currencyCode: "USD")
        #expect(history == CollectionValueHistory(
            currentTotal: nineNinetyNine,
            points: [CollectionValuePoint(date: Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 1))!, value: nineNinetyNine)]
        ))
    }

    // MARK: - Helpers
    private func makeSUT(replyingWith data: Data) -> CollectionValueHistoryLoader {
        CollectionValueComposer.makeRemoteCollectionValueHistoryLoader(
            baseURL: URL(string: "http://base-url.com")!,
            apiKey: "an api key",
            session: Stub.makeSession(replyingWith: data)
        )
    }

    private func makeJSON(currentTotal: String?, history: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: ["current_total": currentTotal ?? NSNull(), "history": history] as [String: Any])
    }

    private final class Stub: URLProtocolStub {}
}
