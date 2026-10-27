//
//  CardSearchEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
@testable import Networking

struct CardSearchEndpointTests {

    @Test
    func search_endpointURL() throws {
        let baseURL = URL(string: "http://base-url.com")!

        let received = try CardSearchEndpoint.search(query: "any query").urlRequest(baseURL: baseURL)

        #expect(received.url?.absoluteString == "http://base-url.com/v1/search")
    }

    @Test
    func search_preservesBaseURLPath() throws {
        let baseURL = URL(string: "http://base-url.com/staging")!

        let received = try CardSearchEndpoint.search(query: "any query").urlRequest(baseURL: baseURL)

        #expect(received.url?.absoluteString == "http://base-url.com/staging/v1/search")
    }

    @Test
    func search_usesPOSTMethod() throws {
        let received = try CardSearchEndpoint.search(query: "any query").urlRequest(baseURL: anyBaseURL())

        #expect(received.httpMethod == "POST")
    }

    @Test
    func search_sendsJSONContentType() throws {
        let received = try CardSearchEndpoint.search(query: "any query").urlRequest(baseURL: anyBaseURL())

        #expect(received.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func search_sendsQueryAndLimitAsJSON() throws {
        let received = try CardSearchEndpoint.search(query: "luffy", limit: 5).urlRequest(baseURL: anyBaseURL())

        #expect(try body(of: received) == SearchBody(query: "luffy", limit: 5))
    }

    // Sent explicitly, so the number of results doesn't change if the backend's default does.
    @Test
    func search_sendsLimitOfTwentyByDefault() throws {
        let received = try CardSearchEndpoint.search(query: "luffy").urlRequest(baseURL: anyBaseURL())

        #expect(try body(of: received)?.limit == 20)
    }

    // MARK: - Helpers
    private struct SearchBody: Decodable, Equatable {
        let query: String
        let limit: Int
    }

    private func anyBaseURL() -> URL {
        URL(string: "http://base-url.com")!
    }

    private func body(of request: URLRequest) throws -> SearchBody? {
        guard let data = request.httpBody else { return nil }
        return try JSONDecoder().decode(SearchBody.self, from: data)
    }
}
