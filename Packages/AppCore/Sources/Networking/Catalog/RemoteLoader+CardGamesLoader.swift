//
//  RemoteLoader+CardGamesLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Domain

extension RemoteLoader: CardGamesLoader where Input == Void, Resource == [CardGame] {
    public func loadGames() async throws -> [CardGame] {
        try await load(())
    }
}
