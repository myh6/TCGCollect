//
//  CardDetailsEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking

struct CardDetailsEndpointTests {

    @Test func details_sendsCardIDAsJSON() throws {
        let received = try CardDetailsEndpoint.details(cardID: 675180).urlRequest(baseURL: URL(string: "http://base-url.com")!)

        #expect(try body(of: received) == DetailsBody(card_id: 675180))
    }

    // MARK: - Helpers
    private struct DetailsBody: Decodable, Equatable {
        let card_id: Int
    }

    private func body(of request: URLRequest) throws -> DetailsBody? {
        guard let data = request.httpBody else { return nil }
        return try JSONDecoder().decode(DetailsBody.self, from: data)
    }
}
