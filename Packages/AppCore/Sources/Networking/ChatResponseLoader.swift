//
//  ChatResponseLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Foundation

struct ChatResponseLoader: ResponseLoader {
    let url: URL
    let client: NetworkClient

    func load(from input: String) async throws -> String {
        let body = try JSONEncoder().encode(ChatRequest(message: input))
        let (data, response) = try await client.post(body, to: url)
        return try ChatResponseMapper.map(data, from: response)
    }

    private struct ChatRequest: Encodable {
        let message: String
    }
}
