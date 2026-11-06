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

    public static func makeRemoteCardSetsLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> CardSetsLoader {
        RemoteLoader(
            client: makeClient(apiKey: apiKey, session: session),
            makeRequest: { gameSlug in CatalogEndpoint.sets(gameSlug: gameSlug).urlRequest(baseURL: baseURL) },
            map: CardSetsResponseMapper.map
        )
    }

    public static func makeRemoteCardSetPageLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> CardSetPageLoader {
        RemoteLoader(
            client: makeClient(apiKey: apiKey, session: session),
            makeRequest: { page in CatalogEndpoint.cards(setID: page.setID, offset: page.offset).urlRequest(baseURL: baseURL) },
            map: CardSetPageResponseMapper.map
        )
    }

    private static func makeClient(apiKey: String, session: URLSession?) -> NetworkClient {
        BackendClient.make(apiKey: apiKey, session: session ?? URLSession(configuration: .default))
    }
}
