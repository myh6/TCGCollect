//
//  CardSearchComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation

/// Builds a card searcher for our backend.
/// Search doesn't call the LLM, so URLSession's default timeout is enough.
public enum CardSearchComposer {
    public static func makeRemoteCardSearcher(baseURL: URL, apiKey: String, session: URLSession? = nil) -> CardSearcher {
        let client = BackendClient.make(apiKey: apiKey, session: session ?? URLSession(configuration: .default))
        return RemoteLoader(
            client: client,
            makeRequest: { query in try CardSearchEndpoint.search(query: query).urlRequest(baseURL: baseURL) },
            map: CardSearchResponseMapper.map
        )
    }
}
