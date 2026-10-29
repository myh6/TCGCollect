//
//  CardDetailsResponseMapperTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct CardDetailsResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 429, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: CardDetailsResponseMapper.Error.invalidData) {
            try CardDetailsResponseMapper.map(makeResponseJSON(details: nil), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test(arguments: ["invalid json", "[]", #"{"details": null}"#])
    func map_throwsInvalidDataErrorOn200HTTPResponseWithoutCardDetails(json: String) {
        #expect(throws: CardDetailsResponseMapper.Error.invalidData) {
            try CardDetailsResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversNoDetailsWhenDetailsAreNull() throws {
        #expect(try map(details: nil) == nil)
    }

    @Test func map_deliversOnePieceDetailsFromBackendExample() throws {
        let details: [String: Any] = [
            "description": "[Blocker] <em>(After your opponent declares an attack, you may rest this card to make it the new target of the attack.)</em>\r\n<br>\r\n[End of Your Turn] <strong>You may trash 1 Event from your hand</strong>: Set up to 1 of your [FILM] type Characters as active.",
            "attribute": ["Special"],
            "color": ["Green"],
            "cardType": ["Character"],
            "life": NSNull(),
            "counter": "1000",
            "power": "4000",
            "cost": "3",
            "subtypes": ["FILM"],
        ]

        let result = try map(details: details)

        #expect(result == .onePiece(OnePieceDetails(
            category: .character,
            colors: [.green],
            cost: 3,
            power: 4000,
            counter: 1000,
            life: nil,
            attributes: ["Special"],
            types: ["FILM"],
            effect: "[Blocker] *(After your opponent declares an attack, you may rest this card to make it the new target of the attack.)*\n[End of Your Turn] **You may trash 1 Event from your hand**: Set up to 1 of your [FILM] type Characters as active."
        )))
    }

    @Test(arguments: [
        ("Leader", OnePieceDetails.Category.leader),
        ("Character", .character),
        ("Event", .event),
        ("Stage", .stage),
        ("DON!!", .don),
        ("character", .character),
    ])
    func map_turnsCardTypeIntoCategory(cardType: String, expected: OnePieceDetails.Category) throws {
        let result = try map(details: ["cardType": [cardType]])

        #expect(result?.onePiece?.category == expected)
    }

    @Test(arguments: [[], ["an unknown type"]] as [[String]])
    func map_deliversNoDetailsWithoutKnownCardType(cardTypes: [String]) throws {
        #expect(try map(details: ["cardType": cardTypes]) == nil)
    }

    @Test func map_deliversNoDetailsWithoutCardType() throws {
        #expect(try map(details: ["power": "4000"]) == nil)
    }

    @Test func map_keepsKnownColorsInOrderAndSkipsUnknownOnes() throws {
        let result = try map(details: ["cardType": ["Leader"], "color": ["Red", "Rainbow", "purple"]])

        #expect(result?.onePiece?.colors == [.red, .purple])
    }

    @Test(arguments: [
        (#""4000""#, 4000),
        ("4000", 4000),
        (#""-""#, nil),
        (#""""#, nil),
        ("null", nil),
    ] as [(String, Int?)])
    func map_readsNumbersWrittenAsTextOrNumbers(jsonValue: String, expected: Int?) throws {
        let json = #"{"card_id": 1, "details": {"cardType": ["Character"], "cost": \#(jsonValue), "power": \#(jsonValue), "counter": \#(jsonValue), "life": \#(jsonValue)}}"#

        let result = try CardDetailsResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))

        #expect(result?.onePiece?.cost == expected)
        #expect(result?.onePiece?.power == expected)
        #expect(result?.onePiece?.counter == expected)
        #expect(result?.onePiece?.life == expected)
    }

    @Test func map_deliversEmptyListsAndNoNumbersOrEffectWhenValuesAreMissing() throws {
        let result = try map(details: ["cardType": ["Event"]])

        #expect(result == .onePiece(OnePieceDetails(category: .event, colors: [])))
    }

    @Test func map_deliversNoEffectForEmptyDescription() throws {
        let result = try map(details: ["cardType": ["Event"], "description": " <br> "])

        #expect(result?.onePiece?.effect == nil)
    }

    // MARK: - Helpers
    private func map(details: [String: Any]?) throws -> GameDetails? {
        try CardDetailsResponseMapper.map(makeResponseJSON(details: details), from: httpResponse(statusCode: 200))
    }

    private func makeResponseJSON(details: [String: Any]?) -> Data {
        try! JSONSerialization.data(withJSONObject: ["card_id": 1, "details": details.map { $0 as Any } ?? NSNull()])
    }
}

private extension GameDetails {
    var onePiece: OnePieceDetails? {
        switch self {
        case let .onePiece(details): details
        }
    }
}
