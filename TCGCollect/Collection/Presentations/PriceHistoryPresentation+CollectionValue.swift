//
//  PriceHistoryPresentation+CollectionValue.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import AppCore

extension PriceHistoryPresentation {
    init(_ history: CollectionValueHistory, locale: Locale = .current) {
        self.init(prices: history.points.map { (date: $0.date, price: $0.value) }, locale: locale)
    }
}
