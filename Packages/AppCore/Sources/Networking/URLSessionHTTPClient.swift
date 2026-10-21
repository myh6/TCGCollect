//
//  URLSessionHTTPClient.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation

public final class URLSessionHTTPClient: NetworkClient {
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    public func perform(_ request: URLRequest) async throws -> NetworkClient.URLResult {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }
}
