//
//  CardSearchComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Testing
import Networking

// The stub's state is shared by the tests in this suite, so run them one at a time.
@Suite(.serialized)
struct CardSearchComposerTests {

    @Test func makeRemoteCardSearcher_sendsQueryWithAPIKeyToBaseURL() async throws {
        let session = Stub.makeSession(replyingWith: makeResultsJSON([]))
        let sut = CardSearchComposer.makeRemoteCardSearcher(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        _ = try await sut.search("luffy")

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/search")!])
        #expect(requests.map(\.httpMethod) == ["POST"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
        #expect(Stub.requestJSONBodies == [["query": "luffy", "limit": 20]])
    }

    @Test func makeRemoteCardSearcher_deliversResultsFromBackend() async throws {
        let card: [String: Any] = ["card_id": 1, "name": "a card"]
        let session = Stub.makeSession(replyingWith: makeResultsJSON([card]))
        let sut = CardSearchComposer.makeRemoteCardSearcher(baseURL: URL(string: "http://base-url.com")!, apiKey: "an api key", session: session)

        let results = try await sut.search("luffy")

        #expect(results.map(\.card.id) == [1])
    }

    // MARK: - Helpers
    private func makeResultsJSON(_ cards: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: cards)
    }

    private final class Stub: URLProtocolStub {}
}
