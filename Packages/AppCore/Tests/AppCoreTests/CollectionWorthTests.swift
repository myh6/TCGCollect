//
//  CollectionWorthTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/02.
//

import Foundation
import Testing
import AppCore

struct CollectionWorthTests {

    @Test func history_isEmptyWithoutOwnedCards() {
        let prices = [price(of: luffy, on: day(1), dollars: 10)]

        #expect(history(of: [], from: prices) == [])
    }

    @Test func history_multipliesEachPriceByCopiesOwned() {
        let prices = [price(of: luffy, on: day(1), dollars: 10)]

        #expect(history(of: [luffy, luffy, luffy], from: prices) == [worth(on: day(1), dollars: 30)])
    }

    @Test func history_addsUpCardsPricedOnTheSameDay() {
        let prices = [
            price(of: luffy, on: day(1, hour: 1), dollars: 10),
            price(of: zoro, on: day(1, hour: 23), dollars: 4.5),
        ]

        #expect(history(of: [luffy, zoro], from: prices) == [worth(on: day(1), dollars: 14.5)])
    }

    @Test func history_keepsCardsLastPriceOnDaysWithoutOne() {
        let prices = [
            price(of: luffy, on: day(1), dollars: 10),
            price(of: zoro, on: day(1), dollars: 4),
            price(of: zoro, on: day(2), dollars: 6),
        ]

        #expect(history(of: [luffy, zoro], from: prices) == [
            worth(on: day(1), dollars: 14),
            worth(on: day(2), dollars: 16),
        ])
    }

    @Test func history_leavesOutCardsBeforeTheirFirstPrice() {
        let prices = [
            price(of: luffy, on: day(1), dollars: 10),
            price(of: zoro, on: day(2), dollars: 4),
        ]

        #expect(history(of: [luffy, zoro], from: prices) == [
            worth(on: day(1), dollars: 10),
            worth(on: day(2), dollars: 14),
        ])
    }

    @Test func history_ignoresPricesOfCardsNotOwned() {
        let prices = [
            price(of: luffy, on: day(1), dollars: 10),
            price(of: zoro, on: day(1), dollars: 4),
        ]

        #expect(history(of: [luffy], from: prices) == [worth(on: day(1), dollars: 10)])
    }

    @Test func history_isInDateOrderWhicheverOrderPricesArrive() {
        let prices = [
            price(of: luffy, on: day(2), dollars: 12),
            price(of: luffy, on: day(1), dollars: 10),
        ]

        #expect(history(of: [luffy], from: prices) == [
            worth(on: day(1), dollars: 10),
            worth(on: day(2), dollars: 12),
        ])
    }

    // MARK: - Helpers
    private let luffy = Card(id: 1, name: "Monkey.D.Luffy")
    private let zoro = Card(id: 2, name: "Roronoa Zoro")

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func history(of cards: [Card], from prices: [PricePoint]) -> [CollectionWorthPoint] {
        CollectionWorth.history(of: cards.map { OwnedCard(card: $0) }, from: prices, in: utc)
    }

    private func day(_ day: Int, hour: Int = 0) -> Date {
        utc.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    private func dollars(_ amount: Decimal) -> Money {
        Money(amount: amount, currencyCode: "USD")
    }

    private func price(of card: Card, on date: Date, dollars amount: Decimal) -> PricePoint {
        PricePoint(cardID: card.id, date: date, price: dollars(amount))
    }

    private func worth(on date: Date, dollars amount: Decimal) -> CollectionWorthPoint {
        CollectionWorthPoint(date: date, worth: dollars(amount))
    }
}
