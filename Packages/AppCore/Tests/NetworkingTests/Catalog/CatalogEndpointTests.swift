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

    @Test func cards_sendsLimitOfFiftyByDefault() {
        let received = CatalogEndpoint.cards(setID: 1, offset: 0).urlRequest(baseURL: URL(string: "http://base-url.com")!)

        #expect(received.url?.absoluteString == "http://base-url.com/v1/catalog/sets/1/cards?limit=50&offset=0")
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
        Endpoint(path: "v1/catalog/sets/1/cards?limit=10&offset=20") { CatalogEndpoint.cards(setID: 1, limit: 10, offset: 20).urlRequest(baseURL: $0) },
    ]
}
