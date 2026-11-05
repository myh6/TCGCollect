//
//  CardSetsResponseMapperTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct CardSetsResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: CardSetsResponseMapper.Error.invalidData) {
            try CardSetsResponseMapper.map(makeJSON([]), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test(arguments: ["invalid json", #"{"sets": []}"#])
    func map_throwsInvalidDataErrorOn200HTTPResponseWithoutAListOfSets(json: String) {
        #expect(throws: CardSetsResponseMapper.Error.invalidData) {
            try CardSetsResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversNoSetsOn200HTTPResponseWithEmptyList() throws {
        #expect(try map([]).isEmpty)
    }

    @Test func map_deliversSetsInBackendOrderWithReleaseDayInLocalTime() throws {
        let sets = try map([
            makeSet(id: 2, name: "Paramount War", cardCount: 121, releasedOn: "2023-03-10"),
            makeSet(id: 1, name: "Romance Dawn", cardCount: 156, releasedOn: "2022-12-02"),
        ])

        #expect(sets == [
            CardSet(id: 2, name: "Paramount War", cardCount: 121, releaseDate: startOfDay(2023, 3, 10)),
            CardSet(id: 1, name: "Romance Dawn", cardCount: 156, releaseDate: startOfDay(2022, 12, 2)),
        ])
    }

    @Test(arguments: [nil, "not a date", "2022-12-02T00:00:00+00:00"] as [String?])
    func map_deliversSetWithoutReleaseDateWhenItIsMissingOrInvalid(releasedOn: String?) throws {
        let sets = try map([makeSet(id: 1, name: "a set", cardCount: 1, releasedOn: releasedOn)])

        #expect(sets == [CardSet(id: 1, name: "a set", cardCount: 1, releaseDate: nil)])
    }

    @Test(arguments: [
        ("set_id", nil),
        ("name", nil),
        ("card_count", nil),
        ("set_id", "not an id"),
        ("card_count", "not a count"),
    ] as [(String, String?)])
    func map_skipsOnlyTheSetWithAMissingOrInvalidValue(key: String, value: String?) throws {
        var invalid = makeSet(id: 1, name: "a set", cardCount: 1, releasedOn: nil)
        invalid[key] = value ?? NSNull()

        let sets = try map([invalid, makeSet(id: 2, name: "another set", cardCount: 2, releasedOn: nil)])

        #expect(sets.map(\.id) == [2])
    }

    // MARK: - Helpers
    private func map(_ sets: [[String: Any]]) throws -> [CardSet] {
        try CardSetsResponseMapper.map(makeJSON(sets), from: httpResponse(statusCode: 200))
    }

    private func makeSet(id: Int, name: String, cardCount: Int, releasedOn: String?) -> [String: Any] {
        ["set_id": id, "name": name, "code": NSNull(), "card_count": cardCount, "released_on": releasedOn ?? NSNull()]
    }

    private func makeJSON(_ sets: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: sets)
    }
}
