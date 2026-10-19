//
//  ChatResponseLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Foundation

struct ChatResponseLoader: ResponseLoader {
    let baseURL: URL
    let client: NetworkClient

    func load(from input: String) async throws -> String {
        let request = try ChatEndpoint.sendMessage(input).urlRequest(baseURL: baseURL)
        let (data, response) = try await client.perform(request)
        return try ChatResponseMapper.map(data, from: response)
    }
}
