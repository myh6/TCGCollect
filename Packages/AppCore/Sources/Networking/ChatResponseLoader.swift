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
        let (data, response) = try await client.get(from: url)
        return try ChatResponseMapper.map(data, from: response)
    }
}
