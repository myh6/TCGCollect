//
//  APIKeyHTTPClient.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/20.
//

import Foundation

/// Adds the backend's `X-API-Key` header to every request, then hands it to the decoratee.
public final class APIKeyHTTPClient: NetworkClient {
    private let decoratee: NetworkClient
    private let apiKey: String

    public init(decoratee: NetworkClient, apiKey: String) {
        self.decoratee = decoratee
        self.apiKey = apiKey
    }

    public func perform(_ request: URLRequest) async throws -> URLResult {
        var request = request
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        return try await decoratee.perform(request)
    }
}
