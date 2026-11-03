//
//  CollectionValueHistoryLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Domain

public protocol CollectionValueHistoryLoader {
    func loadValueHistory(of quantities: [Card.ID: Int], days: Int?) async throws -> CollectionValueHistory
}
