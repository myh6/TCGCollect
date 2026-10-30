//
//  PriceHistoryComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

public enum PriceHistoryComposer {
    public static func makeRemoteCardPriceHistoryLoader(baseURL: URL, apiKey: String, session: URLSession? = nil) -> CardPriceHistoryLoader {
        let client = BackendClient.make(apiKey: apiKey, session: session ?? URLSession(configuration: .default))
        return RemoteLoader(
            client: client,
            makeRequest: { (query: PriceHistoryQuery) in
                try PriceHistoryEndpoint.history(cardIDs: query.cardIDs, days: query.days).urlRequest(baseURL: baseURL)
            },
            map: PriceHistoryResponseMapper.map
        )
    }
}
