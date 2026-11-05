//
//  CardGamesResponseMapperTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct CardGamesResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: CardGamesResponseMapper.Error.invalidData) {
            try CardGamesResponseMapper.map(makeJSON([]), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test(arguments: ["invalid json", #"{"games": []}"#])
    func map_throwsInvalidDataErrorOn200HTTPResponseWithoutAListOfGames(json: String) {
        #expect(throws: CardGamesResponseMapper.Error.invalidData) {
            try CardGamesResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversNoGamesOn200HTTPResponseWithEmptyList() throws {
        let games = try CardGamesResponseMapper.map(makeJSON([]), from: httpResponse(statusCode: 200))

        #expect(games.isEmpty)
    }

    @Test func map_deliversGamesInBackendOrder() throws {
        let json = makeJSON([
            ["slug": "one-piece-card-game", "name": "One Piece Card Game"],
            ["slug": "pokemon", "name": "Pokemon TCG"],
        ])

        let games = try CardGamesResponseMapper.map(json, from: httpResponse(statusCode: 200))

        #expect(games == [
            CardGame(slug: "one-piece-card-game", name: "One Piece Card Game"),
            CardGame(slug: "pokemon", name: "Pokemon TCG"),
        ])
    }

    @Test(arguments: ["slug", "name"])
    func map_skipsOnlyTheGameWithAMissingValue(key: String) throws {
        var invalid: [String: Any] = ["slug": "pokemon", "name": "Pokemon TCG"]
        invalid[key] = nil
        let json = makeJSON([invalid, ["slug": "one-piece-card-game", "name": "One Piece Card Game"]])

        let games = try CardGamesResponseMapper.map(json, from: httpResponse(statusCode: 200))

        #expect(games == [CardGame(slug: "one-piece-card-game", name: "One Piece Card Game")])
    }

    // MARK: - Helpers
    private func makeJSON(_ games: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: games)
    }
}
