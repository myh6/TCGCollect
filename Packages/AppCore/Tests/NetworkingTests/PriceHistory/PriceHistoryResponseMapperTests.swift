//
//  PriceHistoryResponseMapperTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct PriceHistoryResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: PriceHistoryResponseMapper.Error.invalidData) {
            try PriceHistoryResponseMapper.map(makeHistoryJSON([]), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test(arguments: ["invalid json", #"{"points": []}"#])
    func map_throwsInvalidDataErrorOn200HTTPResponseWithoutAListOfPoints(json: String) {
        #expect(throws: PriceHistoryResponseMapper.Error.invalidData) {
            try PriceHistoryResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversNoPointsOn200HTTPResponseWithEmptyList() throws {
        #expect(try map([]).isEmpty)
    }

    @Test func map_deliversPointsInBackendOrder() throws {
        let first = makeRow(cardID: 7, price: "9.99", fetchedAt: "2026-01-01T00:00:00+00:00")
        let second = makeRow(cardID: 7, price: "1234.50", fetchedAt: "2026-01-02T09:00:00+09:00")

        let points = try map([first, second])

        #expect(points == [
            PricePoint(cardID: 7, date: Date(timeIntervalSince1970: 1_767_225_600), price: Money(amount: Decimal(string: "9.99")!, currencyCode: "USD")),
            PricePoint(cardID: 7, date: Date(timeIntervalSince1970: 1_767_312_000), price: Money(amount: Decimal(string: "1234.50")!, currencyCode: "USD")),
        ])
    }

    @Test func map_readsTimesWithFractionsOfASecond() throws {
        let row = makeRow(cardID: 7, price: "4.84", fetchedAt: "2026-01-01T00:00:00.399929+00:00")

        let points = try map([row])

        let date = try #require(points.first?.date)
        #expect(abs(date.timeIntervalSince1970 - 1_767_225_600.399929) < 0.001)
    }

    @Test(arguments: [
        ("market_price", nil),
        ("currency", nil),
        ("fetched_at", nil),
        ("market_price", "not a price"),
        ("fetched_at", "not a date"),
    ] as [(String, String?)])
    func map_skipsPointWithMissingOrInvalidValue(key: String, value: String?) throws {
        let valid = makeRow(cardID: 7, price: "9.99", fetchedAt: "2026-01-01T00:00:00+00:00")
        var invalid = makeRow(cardID: 7, price: "1.00", fetchedAt: "2026-01-02T00:00:00+00:00")
        invalid[key] = value ?? NSNull()

        let points = try map([invalid, valid])

        #expect(points.map(\.price.amount) == [Decimal(string: "9.99")!])
    }

    @Test func map_skipsPointWithInvalidCardID() throws {
        let valid = makeRow(cardID: 7, price: "9.99", fetchedAt: "2026-01-01T00:00:00+00:00")
        var invalid = makeRow(cardID: 7, price: "1.00", fetchedAt: "2026-01-02T00:00:00+00:00")
        invalid["card_id"] = "not an id"

        let points = try map([invalid, valid])

        #expect(points.map(\.cardID) == [7])
    }

    // MARK: - Helpers
    private func map(_ rows: [[String: Any]]) throws -> [PricePoint] {
        try PriceHistoryResponseMapper.map(makeHistoryJSON(rows), from: httpResponse(statusCode: 200))
    }

    private func makeRow(cardID: Int, price: String, fetchedAt: String) -> [String: Any] {
        ["card_id": cardID, "market_price": price, "currency": "USD", "fetched_at": fetchedAt]
    }

    private func makeHistoryJSON(_ rows: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: rows)
    }
}
