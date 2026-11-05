//
//  CatalogEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
@testable import Networking

struct CatalogEndpointTests {

    @Test(arguments: endpoints)
    func appendsPathToBaseURL(_ endpoint: Endpoint) {
        let received = endpoint.makeRequest(URL(string: "http://base-url.com")!)

        #expect(received.url?.absoluteString == "http://base-url.com/\(endpoint.path)")
    }

    @Test(arguments: endpoints)
    func preservesBaseURLPath(_ endpoint: Endpoint) {
        let received = endpoint.makeRequest(URL(string: "http://base-url.com/staging")!)

        #expect(received.url?.absoluteString == "http://base-url.com/staging/\(endpoint.path)")
    }

    @Test(arguments: endpoints)
    func usesGETMethodWithoutBody(_ endpoint: Endpoint) {
        let received = endpoint.makeRequest(URL(string: "http://base-url.com")!)

        #expect(received.httpMethod == "GET")
        #expect(received.httpBody == nil)
    }

    // MARK: - Helpers
    struct Endpoint: Sendable, CustomTestStringConvertible {
        let path: String
        let makeRequest: @Sendable (_ baseURL: URL) -> URLRequest

        var testDescription: String { path }
    }

    static let endpoints = [
        Endpoint(path: "v1/catalog/games") { CatalogEndpoint.games.urlRequest(baseURL: $0) },
        Endpoint(path: "v1/catalog/games/a-game/sets") { CatalogEndpoint.sets(gameSlug: "a-game").urlRequest(baseURL: $0) },
    ]
}
