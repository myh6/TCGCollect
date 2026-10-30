//
//  PriceHistoryPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct PriceHistoryPresentationTests {

    @Test func init_showsNothingWithoutPoints() {
        let sut = makeSUT(prices: [])

        #expect(sut.currentPrice == nil)
        #expect(sut.change == nil)
        #expect(sut.chartPoints.isEmpty)
    }

    @Test func init_showsPriceButNoChangeForOnePoint() {
        let sut = makeSUT(prices: ["4.85"])

        #expect(sut.currentPrice == "$4.85")
        #expect(sut.change == nil)
    }

    @Test func init_showsNewestPointAsCurrentPrice() {
        let sut = makeSUT(prices: ["4.43", "5.10", "4.85"])

        #expect(sut.currentPrice == "$4.85")
    }

    @Test(arguments: [
        (["4.43", "4.85"], "+$0.42", "+9.5%", PriceHistoryPresentation.Direction.up),
        (["4.85", "4.43"], "-$0.42", "-8.7%", .down),
        (["4.85", "4.85"], "$0.00", "0.0%", .flat),
        (["4.43", "9.99", "4.85"], "+$0.42", "+9.5%", .up),
    ])
    func init_comparesNewestWithOldestPoint(prices: [String], amount: String, percent: String, direction: PriceHistoryPresentation.Direction) {
        let sut = makeSUT(prices: prices)

        #expect(sut.change == .init(amount: amount, percent: percent, direction: direction))
    }

    @Test func init_hasNoPercentWhenOldestPriceIsZero() {
        let sut = makeSUT(prices: ["0", "1.50"])

        #expect(sut.change == .init(amount: "+$1.50", percent: nil, direction: .up))
    }

    @Test func init_chartsEveryPointInOrder() {
        let sut = makeSUT(prices: ["4.43", "4.85"])

        #expect(sut.chartPoints == [
            .init(date: day(0), price: 4.43),
            .init(date: day(1), price: 4.85),
        ])
    }

    @Test(arguments: [
        (["4.00", "5.00"], 3.75...5.25),
        (["4.00", "4.00"], 3.8...4.2),
        (["4.50", "4.00", "5.00"], 3.75...5.25),
    ])
    func init_chartsPricesAroundTheirSpread(prices: [String], expected: ClosedRange<Double>) throws {
        let range = try #require(makeSUT(prices: prices).chartPriceRange)

        #expect(abs(range.lowerBound - expected.lowerBound) < 0.0001)
        #expect(abs(range.upperBound - expected.upperBound) < 0.0001)
    }

    @Test func init_hasNoChartRangeWithoutPoints() {
        #expect(makeSUT(prices: []).chartPriceRange == nil)
    }

    @Test func init_formatsForLocale() {
        let sut = PriceHistoryPresentation([point("1234.5", day: 0), point("1300", day: 1)], locale: Locale(identifier: "de_DE"))

        #expect(sut.currentPrice == "1.300,00\u{00A0}$")
    }

    // MARK: - Helpers
    private func makeSUT(prices: [String]) -> PriceHistoryPresentation {
        PriceHistoryPresentation(
            prices.enumerated().map { index, price in point(price, day: index) },
            locale: Locale(identifier: "en_US")
        )
    }

    private func point(_ price: String, day index: Int) -> PricePoint {
        PricePoint(cardID: 1, date: day(index), price: Money(amount: Decimal(string: price)!, currencyCode: "USD"))
    }

    private func day(_ index: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(index) * 86_400)
    }
}
