//
//  CurrentPricesEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking

struct CurrentPricesEndpointTests {

    @Test func prices_sendsCardIDsAsJSON() throws {
        let received = try CurrentPricesEndpoint.prices(cardIDs: [675180, 2]).urlRequest(baseURL: URL(string: "http://base-url.com")!)

        #expect(try body(of: received) == PricesBody(card_ids: [675180, 2]))
    }

    // MARK: - Helpers
    private struct PricesBody: Decodable, Equatable {
        let card_ids: [Int]
    }

    private func body(of request: URLRequest) throws -> PricesBody? {
        guard let data = request.httpBody else { return nil }
        return try JSONDecoder().decode(PricesBody.self, from: data)
    }
}
