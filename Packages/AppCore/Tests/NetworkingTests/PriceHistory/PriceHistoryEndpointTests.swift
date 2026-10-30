//
//  PriceHistoryEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking

struct PriceHistoryEndpointTests {

    @Test func history_sendsCardIDsAndDaysAsJSON() throws {
        let received = try PriceHistoryEndpoint.history(cardIDs: [675180, 2], days: 30).urlRequest(baseURL: anyBaseURL())

        #expect(try jsonBody(of: received) == ["card_ids": [675180, 2], "days": 30])
    }

    @Test func history_leavesOutDaysForWholeHistory() throws {
        let received = try PriceHistoryEndpoint.history(cardIDs: [7], days: nil).urlRequest(baseURL: anyBaseURL())

        #expect(try jsonBody(of: received) == ["card_ids": [7]])
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
