//
//  CatalogComposerTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
import Networking
import Domain

@Suite(.serialized)
struct CatalogComposerTests {

    @Test func makeRemoteCardGamesLoader_requestsGamesWithAPIKeyFromBaseURL() async throws {
        let session = Stub.makeSession(replyingWith: makeJSON([]))
        let sut = CatalogComposer.makeRemoteCardGamesLoader(baseURL: anyBaseURL(), apiKey: "an api key", session: session)

        _ = try await sut.loadGames()

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/catalog/games")!])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
    }

    @Test func makeRemoteCardGamesLoader_deliversGamesFromBackend() async throws {
        let session = Stub.makeSession(replyingWith: makeJSON([["slug": "a-game", "name": "A Game"]]))
        let sut = CatalogComposer.makeRemoteCardGamesLoader(baseURL: anyBaseURL(), apiKey: "an api key", session: session)

        #expect(try await sut.loadGames() == [CardGame(slug: "a-game", name: "A Game")])
    }

    @Test func makeRemoteCardSetsLoader_requestsSetsOfGameWithAPIKeyFromBaseURL() async throws {
        let session = Stub.makeSession(replyingWith: makeJSON([]))
        let sut = CatalogComposer.makeRemoteCardSetsLoader(baseURL: anyBaseURL(), apiKey: "an api key", session: session)

        _ = try await sut.loadSets(ofGame: "a-game")

        let requests = Stub.requests
        #expect(requests.map(\.url) == [URL(string: "http://base-url.com/v1/catalog/games/a-game/sets")!])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-API-Key") } == ["an api key"])
    }

    @Test func makeRemoteCardSetsLoader_deliversSetsFromBackend() async throws {
        let set: [String: Any] = ["set_id": 1, "name": "A Set", "code": NSNull(), "card_count": 3, "released_on": NSNull()]
        let session = Stub.makeSession(replyingWith: makeJSON([set]))
        let sut = CatalogComposer.makeRemoteCardSetsLoader(baseURL: anyBaseURL(), apiKey: "an api key", session: session)

        #expect(try await sut.loadSets(ofGame: "a-game") == [CardSet(id: 1, name: "A Set", cardCount: 3, releaseDate: nil)])
    }

    // MARK: - Helpers
    private func anyBaseURL() -> URL {
        URL(string: "http://base-url.com")!
    }

    private func makeJSON(_ object: Any) -> Data {
        try! JSONSerialization.data(withJSONObject: object)
    }

    private final class Stub: URLProtocolStub {}
}
