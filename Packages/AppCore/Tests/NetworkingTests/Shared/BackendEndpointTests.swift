//
//  BackendEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
@testable import Networking

/// What every backend endpoint's request does, checked once per endpoint.
/// What each one sends in its body is tested in that endpoint's own tests.
struct BackendEndpointTests {

    @Test(arguments: endpoints)
    func appendsPathToBaseURL(_ endpoint: Endpoint) throws {
        let received = try endpoint.makeRequest(URL(string: "http://base-url.com")!)

        #expect(received.url?.absoluteString == "http://base-url.com/\(endpoint.path)")
    }

    @Test(arguments: endpoints)
    func preservesBaseURLPath(_ endpoint: Endpoint) throws {
        let received = try endpoint.makeRequest(URL(string: "http://base-url.com/staging")!)

        #expect(received.url?.absoluteString == "http://base-url.com/staging/\(endpoint.path)")
    }

    @Test(arguments: endpoints)
    func usesPOSTMethod(_ endpoint: Endpoint) throws {
        let received = try endpoint.makeRequest(anyBaseURL())

        #expect(received.httpMethod == "POST")
    }

    @Test(arguments: endpoints)
    func sendsJSONContentType(_ endpoint: Endpoint) throws {
        let received = try endpoint.makeRequest(anyBaseURL())

        #expect(received.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    // MARK: - Helpers
    struct Endpoint: Sendable, CustomTestStringConvertible {
        let path: String
        let makeRequest: @Sendable (_ baseURL: URL) throws -> URLRequest

        var testDescription: String { path }
    }

    static let endpoints = [
        Endpoint(path: "v1/ask") { try ChatEndpoint.sendMessage("any message").urlRequest(baseURL: $0) },
        Endpoint(path: "v1/search") { try CardSearchEndpoint.search(query: "any query").urlRequest(baseURL: $0) },
    ]

    private func anyBaseURL() -> URL {
        URL(string: "http://base-url.com")!
    }
}
