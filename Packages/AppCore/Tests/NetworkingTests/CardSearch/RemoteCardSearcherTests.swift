//
//  RemoteCardSearcherTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct RemoteCardSearcherTests {

    @Test func init_doesNotRequestFromClient() {
        let (_, client) = makeSUT()

        #expect(client.requests.isEmpty)
    }

    @Test func search_sendsSearchRequestFromBaseURL() async throws {
        let baseURL = URL(string: "https://a-base-url.com")!
        let (sut, client) = makeSUT(baseURL: baseURL)

        _ = try? await sut.search("luffy")

        let expected = try CardSearchEndpoint.search(query: "luffy").urlRequest(baseURL: baseURL)
        #expect(client.requests == [expected])
        // URLRequest's == ignores httpBody, so compare the bodies explicitly.
        #expect(jsonBodies(of: client.requests) == jsonBodies(of: [expected]))
    }

    @Test func searchTwice_sendsEachQueryInOrder() async throws {
        let baseURL = URL(string: "https://a-base-url.com")!
        let (sut, client) = makeSUT(baseURL: baseURL)

        _ = try? await sut.search("luffy")
        _ = try? await sut.search("zoro")

        let expected = [
            try CardSearchEndpoint.search(query: "luffy").urlRequest(baseURL: baseURL),
            try CardSearchEndpoint.search(query: "zoro").urlRequest(baseURL: baseURL),
        ]
        #expect(client.requests == expected)
        #expect(jsonBodies(of: client.requests) == jsonBodies(of: expected))
    }

    @Test func search_deliversClientErrorOnClientError() async {
        let clientError = anyNSError()
        let (sut, _) = makeSUT(result: .failure(clientError))

        await #expect(throws: clientError) {
            try await sut.search("any query")
        }
    }

    @Test func search_deliversMapperErrorOnInvalidResponse() async {
        let (sut, _) = makeSUT(result: .success((Data("[]".utf8), httpResponse(statusCode: 500))))

        await #expect(throws: CardSearchResponseMapper.Error.invalidData) {
            try await sut.search("any query")
        }
    }

    @Test func search_deliversResultsOn200HTTPResponseWithValidJSON() async throws {
        let json = Data(#"""
        [{
            "card_id": 1,
            "name": "a card",
            "current_price": "9.99",
            "currency": "USD",
            "current_fetched_at": "2026-01-01T00:00:00+00:00"
        }, {
            "card_id": 2,
            "name": "a card without a price",
            "current_price": null,
            "currency": null,
            "current_fetched_at": null
        }]
        """#.utf8)
        let (sut, _) = makeSUT(result: .success((json, httpResponse(statusCode: 200))))

        let results = try await sut.search("any query")

        #expect(results == [
            CardSearchResult(
                card: Card(id: 1, name: "a card"),
                price: PricePoint(
                    cardID: 1,
                    date: Date(timeIntervalSince1970: 1_767_225_600),
                    price: Money(amount: Decimal(string: "9.99")!, currencyCode: "USD")
                )
            ),
            CardSearchResult(card: Card(id: 2, name: "a card without a price"), price: nil),
        ])
    }

    // MARK: - Helpers
    private func makeSUT(
        baseURL: URL = anyURL(),
        result: Result<NetworkClient.URLResult, Error> = .failure(anyNSError())
    ) -> (sut: CardSearcher, client: NetworkClientSpy) {
        let client = NetworkClientSpy(result: result)
        let sut = RemoteCardSearcher(baseURL: baseURL, client: client)
        return (sut, client)
    }

    /// As JSON objects, since the order of the keys in the encoded bytes can differ from run to run.
    private func jsonBodies(of requests: [URLRequest]) -> [NSDictionary?] {
        requests.map { request in
            request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? NSDictionary }
        }
    }
}
