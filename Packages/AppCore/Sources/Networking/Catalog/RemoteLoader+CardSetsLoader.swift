//
//  RemoteLoader+CardSetsLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Domain

extension RemoteLoader: CardSetsLoader where Input == String, Resource == [CardSet] {
    public func loadSets(ofGame gameSlug: String) async throws -> [CardSet] {
        try await load(gameSlug)
    }
}
