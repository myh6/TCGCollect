//
//  CardPriceHistoryLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

public protocol CardPriceHistoryLoader {
    func loadPriceHistory(for cardIDs: [Card.ID], days: Int?) async throws -> [PricePoint]
}
