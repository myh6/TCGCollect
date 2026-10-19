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
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(ChatRequest(message: input))
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await client.perform(request)
        return try ChatResponseMapper.map(data, from: response)
    }

    private struct ChatRequest: Encodable {
        let message: String
    }
}
