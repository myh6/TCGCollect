//
//  CollectionValuePresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct CollectionValuePresentationTests {

    @Test func init_showsNothingWhenNoCardHasAPrice() {
        let sut = makeSUT(CollectionValueHistory(currentTotal: nil, points: []))

        #expect(sut.currentPrice == nil)
        #expect(sut.change == nil)
        #expect(sut.chartPoints.isEmpty)
    }

    @Test func init_showsNewestValueAndChangeSinceOldestDay() {
        let sut = makeSUT(history(values: ["1200.00", "1300.00", "1234.50"]))

        #expect(sut.currentPrice == "$1,234.50")
        #expect(sut.change == .init(amount: "+$34.50", percent: "+2.9%", direction: .up))
    }

    @Test func init_chartsEveryDayInOrder() {
        let sut = makeSUT(history(values: ["1200.00", "1234.50"]))

        #expect(sut.chartPoints == [
            .init(date: day(0), price: 1200),
            .init(date: day(1), price: 1234.5),
        ])
    }

    // MARK: - Helpers
    private func makeSUT(_ history: CollectionValueHistory) -> PriceHistoryPresentation {
        PriceHistoryPresentation(history, locale: Locale(identifier: "en_US"))
    }

    private func history(values: [String]) -> CollectionValueHistory {
        let points = values.enumerated().map { index, value in
            CollectionValuePoint(date: day(index), value: Money(amount: Decimal(string: value)!, currencyCode: "USD"))
        }
        return CollectionValueHistory(currentTotal: points.last?.value, points: points)
    }

    private func day(_ index: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(index) * 86_400)
    }
}
