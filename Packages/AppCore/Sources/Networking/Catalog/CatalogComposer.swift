//
//  CatalogComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation

public enum CatalogComposer {
    public static func makeRemoteCardGamesLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> CardGamesLoader {
        RemoteLoader(
            client: makeClient(apiKey: apiKey, session: session),
            makeRequest: { CatalogEndpoint.games.urlRequest(baseURL: baseURL) },
            map: CardGamesResponseMapper.map
        )
    }

    private static func makeClient(apiKey: String, session: URLSession?) -> NetworkClient {
        BackendClient.make(apiKey: apiKey, session: session ?? URLSession(configuration: .default))
    }
}
