//
//  CurrentPricesComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

public enum CurrentPricesComposer {
    public static func makeRemoteCardPriceLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> CardPriceLoader {
        let client = BackendClient.make(apiKey: apiKey, session: session ?? URLSession(configuration: .default))
        return RemoteLoader(
            client: client,
            makeRequest: { cardIDs in try CurrentPricesEndpoint.prices(cardIDs: cardIDs).urlRequest(baseURL: baseURL) },
            map: CurrentPricesResponseMapper.map
        )
    }
}
