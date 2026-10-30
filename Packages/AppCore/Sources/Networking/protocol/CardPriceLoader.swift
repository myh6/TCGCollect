//
//  CardPriceLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

public protocol CardPriceLoader {
    func loadCurrentPrices(for cardIDs: [Card.ID]) async throws -> [PricePoint]
}
