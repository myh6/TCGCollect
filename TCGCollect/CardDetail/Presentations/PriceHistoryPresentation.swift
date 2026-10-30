//
//  PriceHistoryPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import AppCore

nonisolated struct PriceHistoryPresentation: Equatable {
    enum Direction: Equatable {
        case up
        case down
        case flat
    }

    struct Change: Equatable {
        let amount: String
        let percent: String?
        let direction: Direction
    }

    struct ChartPoint: Equatable, Identifiable {
        let date: Date
        let price: Double

        var id: Date { date }
    }

    let currentPrice: String?
    let change: Change?
    let chartPoints: [ChartPoint]
    let chartPriceRange: ClosedRange<Double>?

    init(_ points: [PricePoint], locale: Locale = .current) {
        currentPrice = points.last?.price.formatted(locale: locale)
        chartPoints = points.map { ChartPoint(date: $0.date, price: NSDecimalNumber(decimal: $0.price.amount).doubleValue) }
        chartPriceRange = Self.range(around: chartPoints.map(\.price))
        guard points.count > 1, let oldest = points.first?.price, let newest = points.last?.price else {
            change = nil
            return
        }
        change = Self.change(from: oldest, to: newest, locale: locale)
    }

    private static func range(around prices: [Double]) -> ClosedRange<Double>? {
        guard let lowest = prices.min(), let highest = prices.max() else { return nil }
        let room = highest > lowest ? (highest - lowest) * 0.25 : highest * 0.05
        return (lowest - room)...(highest + room)
    }

    private static func change(from oldest: Money, to newest: Money, locale: Locale) -> Change {
        let difference = newest.amount - oldest.amount
        let percent = oldest.amount == 0 ? nil : (difference / oldest.amount).formatted(
            .percent.locale(locale).sign(strategy: .always(includingZero: false)).precision(.fractionLength(1))
        )
        return Change(
            amount: difference.formatted(.currency(code: newest.currencyCode).locale(locale).sign(strategy: .always(showZero: false))),
            percent: percent,
            direction: difference > 0 ? .up : difference < 0 ? .down : .flat
        )
    }
}
