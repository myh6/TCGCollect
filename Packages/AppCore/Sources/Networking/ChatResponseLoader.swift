//
//  ChatResponseLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Foundation

public struct ChatResponseLoader: ResponseLoader {
    private let baseURL: URL
    private let client: NetworkClient

    public init(baseURL: URL, client: NetworkClient) {
        self.baseURL = baseURL
        self.client = client
    }

    public func load(from input: String) async throws -> String {
        let request = try ChatEndpoint.sendMessage(input).urlRequest(baseURL: baseURL)
        let (data, response) = try await client.perform(request)
        return try ChatResponseMapper.map(data, from: response).text
    }
}
