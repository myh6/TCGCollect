//
//  RemoteChatLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/22.
//

import Foundation
import Domain

public struct RemoteChatLoader: ChatLoader {
    private let baseURL: URL
    private let client: NetworkClient

    public init(baseURL: URL, client: NetworkClient) {
        self.baseURL = baseURL
        self.client = client
    }

    public func load(question: String) async throws -> ChatAnswer {
        let request = try ChatEndpoint.sendMessage(question).urlRequest(baseURL: baseURL)
        let (data, response) = try await client.perform(request)
        return try ChatResponseMapper.map(data, from: response)
    }
}
