//
//  RemoteLoader+CardPriceHistoryLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

public struct PriceHistoryQuery {
    let cardIDs: [Card.ID]
    let days: Int?
}

extension RemoteLoader: CardPriceHistoryLoader where Input == PriceHistoryQuery, Resource == [PricePoint] {
    public func loadPriceHistory(for cardIDs: [Card.ID], days: Int?) async throws -> [PricePoint] {
        try await load(PriceHistoryQuery(cardIDs: cardIDs, days: days))
    }
}
