//
//  CardSearchEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation

enum CardSearchEndpoint {
    case search(query: String, limit: Int = 20)

    func urlRequest(baseURL: URL) throws -> URLRequest {
        switch self {
        case let .search(query, limit):
            var request = URLRequest(url: baseURL.appending(path: "v1/search"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(SearchRequestBody(query: query, limit: limit))
            return request
        }
    }

    private struct SearchRequestBody: Encodable {
        let query: String
        let limit: Int
    }
}
