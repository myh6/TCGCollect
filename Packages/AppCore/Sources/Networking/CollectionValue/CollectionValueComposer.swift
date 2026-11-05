//
//  CollectionValueComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation

public enum CollectionValueComposer {
    public static func makeRemoteCollectionValueHistoryLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> CollectionValueHistoryLoader {
        let client = BackendClient.make(apiKey: apiKey, session: session ?? URLSession(configuration: .default))
        return RemoteLoader(
            client: client,
            makeRequest: { (query: CollectionValueQuery) in
                try CollectionValueEndpoint.history(quantities: query.quantities, days: query.days).urlRequest(baseURL: baseURL)
            },
            map: CollectionValueResponseMapper.map
        )
    }
}
