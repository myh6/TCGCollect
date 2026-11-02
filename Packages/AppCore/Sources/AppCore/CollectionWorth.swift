//
//  CollectionWorth.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/02.
//

import Foundation

public struct CollectionWorthPoint: Hashable, Sendable {
    public let date: Date
    public let worth: Money

    public init(date: Date, worth: Money) {
        self.date = date
        self.worth = worth
    }
}

public enum CollectionWorth {
    public static func history(of ownedCards: [OwnedCard], from prices: [PricePoint], in calendar: Calendar) -> [CollectionWorthPoint] {
        let copies = Dictionary(grouping: ownedCards, by: \.card.id).mapValues(\.count)
        let pricesByDay = Dictionary(grouping: prices.filter { copies[$0.cardID] != nil }) { calendar.startOfDay(for: $0.date) }
        var latestPrices = [Card.ID: Money]()

        return pricesByDay.keys.sorted().compactMap { day in
            for point in pricesByDay[day, default: []].sorted(by: { $0.date < $1.date }) {
                latestPrices[point.cardID] = point.price
            }
            return worth(of: latestPrices, copies: copies).map { CollectionWorthPoint(date: day, worth: $0) }
        }
    }

    private static func worth(of prices: [Card.ID: Money], copies: [Card.ID: Int]) -> Money? {
        guard let currencyCode = prices.values.first?.currencyCode else { return nil }
        let amount = prices.reduce(Decimal.zero) { total, price in
            total + price.value.amount * Decimal(copies[price.key, default: 0])
        }
        return Money(amount: amount, currencyCode: currencyCode)
    }
}
