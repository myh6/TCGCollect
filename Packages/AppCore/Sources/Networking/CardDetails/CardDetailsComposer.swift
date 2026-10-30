//
//  CardDetailsComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

public enum CardDetailsComposer {
    public static func makeRemoteCardDetailsLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> CardDetailsLoader {
        let client = BackendClient.make(apiKey: apiKey, session: session ?? URLSession(configuration: .default))
        return RemoteLoader(
            client: client,
            makeRequest: { cardID in try CardDetailsEndpoint.details(cardID: cardID).urlRequest(baseURL: baseURL) },
            map: CardDetailsResponseMapper.map
        )
    }
}
