//
//  RemoteLoader+CardDetailsLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

extension RemoteLoader: CardDetailsLoader where Input == Card.ID, Resource == GameDetails? {
    public func loadDetails(for cardID: Card.ID) async throws -> GameDetails? {
        try await load(cardID)
    }
}
