//
//  CollectionValueResponseMapperTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Testing
@testable import Networking
import TestHelpers
import Domain

struct CollectionValueResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: CollectionValueResponseMapper.Error.invalidData) {
            try CollectionValueResponseMapper.map(makeJSON(currentTotal: nil, history: []), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test(arguments: ["invalid json", #"{"current_total": null}"#, "[]"])
    func map_throwsInvalidDataErrorOn200HTTPResponseWithoutHistory(json: String) {
        #expect(throws: CollectionValueResponseMapper.Error.invalidData) {
            try CollectionValueResponseMapper.map(Data(json.utf8), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversNoValueWhenNoCardHasAPrice() throws {
        let history = try map(currentTotal: nil, history: [])

        #expect(history == CollectionValueHistory(currentTotal: nil, points: []))
    }

    @Test func map_deliversCurrentTotalAndDailyValuesInBackendOrderInDollars() throws {
        let history = try map(currentTotal: "1234.50", history: [
            makePoint(date: "2026-10-31", value: "1200.00"),
            makePoint(date: "2026-11-01", value: "1234.50"),
        ])

        #expect(history == CollectionValueHistory(
            currentTotal: dollars("1234.50"),
            points: [
                CollectionValuePoint(date: startOfDay(2026, 10, 31), value: dollars("1200.00")),
                CollectionValuePoint(date: startOfDay(2026, 11, 1), value: dollars("1234.50")),
            ]
        ))
    }

    @Test func map_deliversNoCurrentTotalWhenItIsNotAnAmount() throws {
        let history = try map(currentTotal: "not an amount", history: [])

        #expect(history.currentTotal == nil)
    }

    @Test(arguments: [
        ("date", nil),
        ("total_value", nil),
        ("date", "not a date"),
        ("date", "2026-11-01T00:00:00+00:00"),
        ("total_value", "not an amount"),
    ] as [(String, String?)])
    func map_skipsPointWithMissingOrInvalidValue(key: String, value: String?) throws {
        var invalid = makePoint(date: "2026-10-31", value: "1.00")
        invalid[key] = value ?? NSNull()

        let history = try map(currentTotal: "9.99", history: [invalid, makePoint(date: "2026-11-01", value: "9.99")])

        #expect(history.points.map(\.value) == [dollars("9.99")])
    }

    // MARK: - Helpers
    private func map(currentTotal: String?, history: [[String: Any]]) throws -> CollectionValueHistory {
        try CollectionValueResponseMapper.map(makeJSON(currentTotal: currentTotal, history: history), from: httpResponse(statusCode: 200))
    }

    private func makePoint(date: String, value: String) -> [String: Any] {
        ["date": date, "total_value": value]
    }

    private func makeJSON(currentTotal: String?, history: [[String: Any]]) -> Data {
        let json: [String: Any] = [
            "current_total": currentTotal ?? NSNull(),
            "change_24h": NSNull(),
            "change_7d": 1.5,
            "change_30d": NSNull(),
            "history": history,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func dollars(_ amount: String) -> Money {
        Money(amount: Decimal(string: amount)!, currencyCode: "USD")
    }

    private func startOfDay(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
