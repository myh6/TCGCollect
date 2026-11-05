//
//  CollectionValueEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Testing
@testable import Networking

struct CollectionValueEndpointTests {

    @Test func history_postsToCollectionValueHistory() throws {
        let request = try CollectionValueEndpoint.history(quantities: [7: 1], days: 30).urlRequest(baseURL: URL(string: "http://base-url.com/staging")!)

        #expect(request.url?.absoluteString == "http://base-url.com/staging/v1/collections/value-history")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func history_sendsEachCardsQuantityInCardIDOrderAndDaysAsJSON() throws {
        let request = try CollectionValueEndpoint.history(quantities: [675180: 2, 7: 1], days: 30).urlRequest(baseURL: anyBaseURL())

        #expect(try jsonBody(of: request) == [
            "cards": [["card_id": 7, "quantity": 1], ["card_id": 675180, "quantity": 2]],
            "days": 30,
        ])
    }

    @Test func history_leavesOutDaysForWholeHistory() throws {
        let request = try CollectionValueEndpoint.history(quantities: [7: 1], days: nil).urlRequest(baseURL: anyBaseURL())

        #expect(try jsonBody(of: request) == ["cards": [["card_id": 7, "quantity": 1]]])
    }

    // MARK: - Helpers
    private func anyBaseURL() -> URL {
        URL(string: "http://base-url.com")!
    }

    private func jsonBody(of request: URLRequest) throws -> NSDictionary? {
        guard let data = request.httpBody else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? NSDictionary
    }
}
