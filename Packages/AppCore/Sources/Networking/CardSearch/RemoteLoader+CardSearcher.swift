//
//  RemoteLoader+CardSearcher.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

extension RemoteLoader: CardSearcher where Input == String, Resource == [CardSearchResult] {
    public func search(_ query: String) async throws -> [CardSearchResult] {
        try await load(query)
    }
}
