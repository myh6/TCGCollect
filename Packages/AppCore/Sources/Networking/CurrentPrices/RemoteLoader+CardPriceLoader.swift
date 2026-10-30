//
//  RemoteLoader+CardPriceLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

extension RemoteLoader: CardPriceLoader where Input == [Card.ID], Resource == [PricePoint] {
    public func loadCurrentPrices(for cardIDs: [Card.ID]) async throws -> [PricePoint] {
        try await load(cardIDs)
    }
}
