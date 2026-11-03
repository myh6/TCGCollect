//
//  RemoteLoader+CollectionValueHistoryLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Domain

public struct CollectionValueQuery {
    let quantities: [Card.ID: Int]
    let days: Int?
}

extension RemoteLoader: CollectionValueHistoryLoader where Input == CollectionValueQuery, Resource == CollectionValueHistory {
    public func loadValueHistory(of quantities: [Card.ID: Int], days: Int?) async throws -> CollectionValueHistory {
        try await load(CollectionValueQuery(quantities: quantities, days: days))
    }
}
