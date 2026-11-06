//
//  RemoteLoader+CardSetPageLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Domain

extension RemoteLoader: CardSetPageLoader where Input == (setID: CardSet.ID, offset: Int), Resource == CardSetPage {
    public func loadCards(inSet setID: CardSet.ID, offset: Int) async throws -> CardSetPage {
        try await load((setID, offset))
    }
}
