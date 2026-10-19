//
//  URLSessionHTTPClient.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation

final class URLSessionHTTPClient: NetworkClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) async throws -> NetworkClient.URLResult {
        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }

    func post(_ data: Data, to url: URL) async throws -> NetworkClient.URLResult {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }
}
