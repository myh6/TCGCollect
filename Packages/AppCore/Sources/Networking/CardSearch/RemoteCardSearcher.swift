//
//  RemoteCardSearcher.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Domain

public struct RemoteCardSearcher: CardSearcher {
    private let baseURL: URL
    private let client: NetworkClient

    public init(baseURL: URL, client: NetworkClient) {
        self.baseURL = baseURL
        self.client = client
    }

    public func search(_ query: String) async throws -> [CardSearchResult] {
        let request = try CardSearchEndpoint.search(query: query).urlRequest(baseURL: baseURL)
        let (data, response) = try await client.perform(request)
        return try CardSearchResponseMapper.map(data, from: response)
    }
}
